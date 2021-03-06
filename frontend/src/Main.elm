module Main exposing (..)

import Navigation exposing (Location)
import Html exposing (..)
import Types exposing (..)
import Html exposing (Html, text, div, span, p, a)
import Material.Typography as Typo
import Material.Options as Options exposing (when, css, cs, Style, onClick)
import Time exposing (Time)
import RemoteData exposing (RemoteData(..))
import Routing.Router as Router
import Http
import Decoders
import Material.Progress as Loading
import Material.Options as Options exposing (when, css, cs, Style, onClick)
import Material.Typography as Typo
import Dict


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Time.every Time.minute TimeChange
        }


type alias Model =
    { appState : AppState
    , location : Location
    , loadUserRetryCount : Int
    , apiEndpoint : String
    , statusText : String
    , logo : String
    , userInformation : RemoteData.WebData UserInformation
    , appMetadata : RemoteData.WebData AppMetadata
    }


type AppState
    = NotReady Flags
    | Ready Taco Router.Model
    | Unauthorized
    | AppNetworkError


type alias Flags =
    { currentTime : Time
    , apiEndpoint : String
    , vafLogo : String
    }


type Msg
    = UrlChange Location
    | TimeChange Time
    | RouterMsg Router.Msg
    | HandleUserInformationResponse (RemoteData.WebData UserInformation)
    | HandleAppMetadataResponse (RemoteData.WebData AppMetadata)


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    let
        endPoint =
            flags.apiEndpoint
    in
        ( { appState = NotReady flags
          , location = location
          , loadUserRetryCount = 0
          , apiEndpoint = flags.apiEndpoint
          , statusText = ""
          , logo = flags.vafLogo
          , userInformation = RemoteData.NotAsked
          , appMetadata = RemoteData.NotAsked
          }
        , Cmd.batch
            [ fetchUserInformation endPoint
            , fetchAppMetadata flags.apiEndpoint

            -- , Cmd.map RouterMsg (Router.getInitialCommand (RouterHelpers.parseLocation location) endPoint)
            ]
        )


fetchUserInformation : String -> Cmd Msg
fetchUserInformation endPoint =
    let
        url =
            endPoint ++ "user"

        req =
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson Decoders.decodeUserInformation
                , timeout = Nothing
                , withCredentials = True
                }
    in
        req
            |> RemoteData.sendRequest
            |> Cmd.map HandleUserInformationResponse


fetchAppMetadata : String -> Cmd Msg
fetchAppMetadata endPoint =
    let
        queryUrl =
            endPoint ++ "AktivitetsbankMetadata"

        req =
            Http.request
                { method = "GET"
                , headers = []
                , url = queryUrl
                , body = Http.emptyBody
                , expect = Http.expectJson Decoders.decodeAppMetadata
                , timeout = Nothing
                , withCredentials = True
                }
    in
        req
            |> RemoteData.sendRequest
            |> Cmd.map HandleAppMetadataResponse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimeChange time ->
            updateTime model time

        HandleUserInformationResponse webData ->
            updateUserInfo model webData

        HandleAppMetadataResponse webData ->
            updateAppMetadata model webData

        UrlChange location ->
            updateRouter { model | location = location } (Router.UrlChange location)

        RouterMsg routerMsg ->
            updateRouter model routerMsg


updateTime : Model -> Time -> ( Model, Cmd Msg )
updateTime model time =
    case model.appState of
        NotReady oldModel ->
            ( { model | appState = NotReady { oldModel | currentTime = time } }
            , Cmd.none
            )

        Ready taco routerModel ->
            ( { model | appState = Ready (updateTaco taco (UpdateTime time)) routerModel }
            , Cmd.none
            )

        Unauthorized ->
            ( model
            , Cmd.none
            )

        AppNetworkError ->
            ( model
            , Cmd.none
            )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready taco routerModel ->
            let
                nextTaco =
                    updateTaco taco tacoUpdate

                ( nextRouterModel, routerCmd, tacoUpdate ) =
                    Router.update routerMsg routerModel taco
            in
                ( { model | appState = Ready nextTaco nextRouterModel }
                , Cmd.map RouterMsg routerCmd
                )

        NotReady _ ->
            let
                tmp =
                    Debug.log "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?" model
            in
                ( model, Cmd.none )

        Unauthorized ->
            ( model
            , Cmd.none
            )

        AppNetworkError ->
            ( model
            , Cmd.none
            )


updateUserInfo : Model -> RemoteData.WebData UserInformation -> ( Model, Cmd Msg )
updateUserInfo model webData =
    let
        ( modelErr, cmdErr ) =
            case webData of
                Failure error ->
                    let
                        ( newAppstate, cmd, statusText, retryCount ) =
                            case error of
                                Http.BadUrl info ->
                                    ( model.appState, Cmd.none, "Feil i url til API", model.loadUserRetryCount )

                                Http.BadPayload _ _ ->
                                    ( model.appState, Cmd.none, "Feil i sending av data til API", model.loadUserRetryCount )

                                Http.BadStatus status ->
                                    if model.loadUserRetryCount < 5 then
                                        ( model.appState, fetchUserInformation model.apiEndpoint, "Prøver henting av data på nytt", model.loadUserRetryCount + 1 )
                                    else
                                        ( Unauthorized, Cmd.none, "Stoppet henting av data på nytt.", model.loadUserRetryCount )

                                Http.NetworkError ->
                                    if model.loadUserRetryCount < 5 then
                                        ( model.appState, fetchUserInformation model.apiEndpoint, "Nettverksfeil - Prøver henting av data på nytt", model.loadUserRetryCount + 1 )
                                    else
                                        ( AppNetworkError, Cmd.none, "Stoppet henting av data på nytt.", model.loadUserRetryCount )

                                Http.Timeout ->
                                    ( model.appState, Cmd.none, "Nettverksfeil - timet ut", model.loadUserRetryCount )
                    in
                        ( { model | loadUserRetryCount = retryCount, appState = newAppstate }, cmd )

                _ ->
                    ( model, Cmd.none )

        combinedData =
            RemoteData.map2 (,) webData model.appMetadata

        ( model_, cmd_ ) =
            updateSuccessLoad combinedData ( modelErr, cmdErr )
    in
        ( { model_ | userInformation = webData }, cmd_ )


updateAppMetadata : Model -> RemoteData.WebData AppMetadata -> ( Model, Cmd Msg )
updateAppMetadata model webData =
    let
        ( modelErr, cmdErr ) =
            case webData of
                Failure error ->
                    let
                        ( newAppstate, cmd, statusText, retryCount ) =
                            case error of
                                Http.BadUrl info ->
                                    ( model.appState, Cmd.none, "Feil i url til API", model.loadUserRetryCount )

                                Http.BadPayload _ _ ->
                                    ( model.appState, Cmd.none, "Feil i sending av data til API", model.loadUserRetryCount )

                                Http.BadStatus status ->
                                    if model.loadUserRetryCount < 5 then
                                        ( model.appState, fetchAppMetadata model.apiEndpoint, "Prøver henting av data på nytt", model.loadUserRetryCount + 1 )
                                    else
                                        ( Unauthorized, Cmd.none, "Stoppet henting av data på nytt.", model.loadUserRetryCount )

                                Http.NetworkError ->
                                    if model.loadUserRetryCount < 5 then
                                        ( model.appState, fetchAppMetadata model.apiEndpoint, "Nettverksfeil - Prøver henting av data på nytt", model.loadUserRetryCount + 1 )
                                    else
                                        ( AppNetworkError, Cmd.none, "Stoppet henting av data på nytt.", model.loadUserRetryCount )

                                Http.Timeout ->
                                    ( model.appState, Cmd.none, "Nettverksfeil - timet ut", model.loadUserRetryCount )
                    in
                        ( { model | loadUserRetryCount = retryCount, appState = newAppstate }, cmd )

                _ ->
                    ( model, Cmd.none )

        combinedData =
            RemoteData.map2 (,) model.userInformation webData

        ( model_, cmd_ ) =
            updateSuccessLoad combinedData ( modelErr, cmdErr )
    in
        ( { model_ | appMetadata = webData }, cmd_ )


updateSuccessLoad : RemoteData.WebData ( UserInformation, AppMetadata ) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateSuccessLoad combinedData ( model, cmd ) =
    case combinedData of
        Success ( userInfo, appMetadata ) ->
            case model.appState of
                NotReady notreadyModel ->
                    let
                        initTaco =
                            { currentTime = notreadyModel.currentTime
                            , userInfo = userInfo
                            , appMetadata = appMetadata
                            , filter = initFilter
                            }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.location notreadyModel.apiEndpoint model.logo initTaco
                    in
                        ( { model | appState = Ready initTaco initRouterModel }
                        , Cmd.batch [ cmd, Cmd.map RouterMsg routerCmd ]
                        )

                Ready taco routerModel ->
                    ( { model | appState = Ready (updateTaco taco (UpdateUserInfo userInfo)) routerModel }
                    , cmd
                    )

                Unauthorized ->
                    ( model
                    , cmd
                    )

                AppNetworkError ->
                    ( model
                    , cmd
                    )

        _ ->
            ( model, cmd )


updateTaco : Taco -> TacoUpdate -> Taco
updateTaco taco tacoUpdate =
    case tacoUpdate of
        UpdateTime time ->
            { taco | currentTime = time }

        UpdateUserInfo userInfo ->
            { taco | userInfo = userInfo }

        UpdateFilter newFilter ->
            { taco | filter = newFilter }

        InitFilter ->
            { taco | filter = initFilter }

        NoUpdate ->
            taco


initFilter : Filter
initFilter =
    { ekspandertFilter = IngenFilterEkspandert

    -- { ekspandertFilter = SkoleFilterEkspandert
    , navnFilter = ""
    , skoleFilter = Dict.empty
    , aktivitetsTypeFilter = Dict.empty
    , utdanningsprogramFilter = Dict.empty
    , trinnFilter = Dict.empty
    , skoleAarFilter = Dict.empty
    , fagFilter = Dict.empty
    }


view : Model -> Html Msg
view model =
    case model.appState of
        Ready taco routerModel ->
            Router.view taco routerModel
                |> Html.map RouterMsg

        NotReady _ ->
            Options.div
                [ css "display" "flex"
                , css "flex-direction" "column"
                , css "width" "100%"
                , css "height" "100vh"
                , css "align-items" "center"
                , css "justify-content" "center"
                ]
                [ Options.span [ Typo.headline ] [ text "Klargjør Aktivitetsbank" ]
                , Loading.indeterminate
                , Options.span []
                    [ text "Henter brukerdata.."
                    ]
                    |> (\x ->
                            if RemoteData.isSuccess model.userInformation then
                                text ""
                            else
                                x
                       )
                , Options.span []
                    [ text "Henter metadata.."
                    ]
                    |> (\x ->
                            if RemoteData.isSuccess model.appMetadata then
                                text ""
                            else
                                x
                       )
                ]

        Unauthorized ->
            Options.div
                [ css "display" "flex"
                , css "width" "100%"
                , css "height" "100vh"
                , css "align-items" "center"
                , css "justify-content" "center"
                ]
                [ Options.styled div [ Typo.title ] [ text "Du har ikke tilgang til Aktivitetsbank." ] ]

        AppNetworkError ->
            Options.div
                [ css "display" "flex"
                , css "width" "100%"
                , css "height" "100vh"
                , css "align-items" "center"
                , css "justify-content" "center"
                ]
                [ Options.styled div [ Typo.title ] [ text "Nettverksfeil - sjekk at du er på rett nett og at du har tilgang til Aktivitetsbank." ] ]
