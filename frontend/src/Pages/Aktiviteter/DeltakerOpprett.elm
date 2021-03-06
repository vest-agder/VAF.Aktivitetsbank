module Pages.Aktiviteter.DeltakerOpprett exposing (..)

import Html exposing (Html, text, div, span, p, a)
import Material
import Material.Grid as Grid exposing (grid, size, cell, Device(..))
import Material.Elevation as Elevation
import Material.Button as Button
import Material.Textfield as Textfield
import Material.Options as Options exposing (when, css, cs, Style, onClick)
import Material.Typography as Typo
import Material.Typography as Typography
import Material.Spinner as Loading
import RemoteData exposing (WebData, RemoteData(..))
import Types exposing (..)
import Http exposing (Error)
import Decoders exposing (..)
import Dropdown
import Shared.Validation exposing (..)


type alias Model =
    { mdl : Material.Model
    , apiEndpoint : String
    , statusText : String
    , visLagreKnapp : Bool
    , aktivitetId : String
    , aktivitet : WebData Aktivitet
    , deltaker : DeltakerEdit
    , dropdownStateUtdanningsprogram : Dropdown.State
    , dropdownStateTrinn : Dropdown.State
    , dropdownStateFag : Dropdown.State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | AktivitetResponse (WebData Aktivitet)
    | OnSelectUtdanningsprogram (Maybe Utdanningsprogram)
    | OnSelectTrinn (Maybe Trinn)
    | OnSelectFag (Maybe Fag)
    | UtdanningsprogramDropdown (Dropdown.Msg Utdanningsprogram)
    | TrinnDropdown (Dropdown.Msg Trinn)
    | FagDropdown (Dropdown.Msg Fag)
    | EndretKompetansemaal String
    | EndretTimer String
    | EndretLarertimer String
    | EndretElevgrupper String
    | OpprettNyDeltaker
    | NyDeltakerRespons (Result Error NyDeltaker)
    | NavigerTilbake


init : String -> String -> ( Model, Cmd Msg )
init apiEndpoint id =
    ( { mdl = Material.model
      , apiEndpoint = apiEndpoint
      , statusText = ""
      , visLagreKnapp = False
      , aktivitetId = id
      , aktivitet = RemoteData.NotAsked
      , dropdownStateUtdanningsprogram = Dropdown.newState "1"
      , dropdownStateTrinn = Dropdown.newState "1"
      , dropdownStateFag = Dropdown.newState "1"
      , deltaker = initDeltaker
      }
    , Cmd.batch
        [ (hentAktivitetDetalj id apiEndpoint)
        ]
    )


initDeltaker : DeltakerEdit
initDeltaker =
    { id = Nothing
    , aktivitetId = Nothing
    , utdanningsprogram = Nothing
    , trinn = Nothing
    , fag = Nothing
    , timer = Nothing
    , larertimer = Nothing
    , elevgrupper = Nothing
    , kompetansemaal = Nothing
    }


hentAktivitetDetalj : String -> String -> Cmd Msg
hentAktivitetDetalj id endPoint =
    let
        queryUrl =
            endPoint ++ "aktiviteter/" ++ id

        req =
            Http.request
                { method = "GET"
                , headers = []
                , url = queryUrl
                , body = Http.emptyBody
                , expect = Http.expectJson Decoders.decodeAktivitet
                , timeout = Nothing
                , withCredentials = True
                }
    in
        req
            |> RemoteData.sendRequest
            |> Cmd.map AktivitetResponse


postOpprettNyDeltaker : String -> String -> DeltakerGyldigNy -> (Result Error NyDeltaker -> msg) -> Cmd msg
postOpprettNyDeltaker endPoint aktivitetId deltaker responseMsg =
    let
        url =
            endPoint ++ "aktiviteter/" ++ aktivitetId ++ "/opprettDeltaker"

        body =
            encodeOpprettNyDeltaker aktivitetId deltaker |> Http.jsonBody

        req =
            Http.request
                { method = "POST"
                , headers = []
                , url = url
                , body = body
                , expect = Http.expectJson decodeNyDeltaker
                , timeout = Nothing
                , withCredentials = True
                }
    in
        req
            |> Http.send responseMsg


update : Msg -> Model -> ( Model, Cmd Msg, SharedMsg )
update msg model =
    case msg of
        Mdl msg_ ->
            let
                ( model_, cmd_ ) =
                    Material.update Mdl msg_ model
            in
                ( model_, cmd_, NoSharedMsg )

        AktivitetResponse response ->
            let
                deltaker =
                    model.deltaker

                oppdatertDeltaker =
                    case response of
                        Success aktivitet ->
                            { deltaker | aktivitetId = Just aktivitet.id }

                        _ ->
                            { deltaker | aktivitetId = Nothing }
            in
                ( { model | aktivitet = response, deltaker = oppdatertDeltaker }, Cmd.none, NoSharedMsg )

        OnSelectUtdanningsprogram valg ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | utdanningsprogram = valg }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        OnSelectTrinn valg ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | trinn = valg }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        OnSelectFag valg ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | fag = valg }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        UtdanningsprogramDropdown utdanningsprogram ->
            let
                ( updated, cmd ) =
                    Dropdown.update dropdownConfigUtdanningsprogram utdanningsprogram model.dropdownStateUtdanningsprogram
            in
                ( { model | dropdownStateUtdanningsprogram = updated }, cmd, NoSharedMsg )

        TrinnDropdown trinn ->
            let
                ( updated, cmd ) =
                    Dropdown.update dropdownConfigTrinn trinn model.dropdownStateTrinn
            in
                ( { model | dropdownStateTrinn = updated }, cmd, NoSharedMsg )

        FagDropdown fag ->
            let
                ( updated, cmd ) =
                    Dropdown.update dropdownConfigFag fag model.dropdownStateFag
            in
                ( { model | dropdownStateFag = updated }, cmd, NoSharedMsg )

        EndretKompetansemaal endretKompetansemaal ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | kompetansemaal = Just endretKompetansemaal }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        EndretTimer endretOmfangTimer ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | timer = Just <| Result.withDefault 0 (String.toInt endretOmfangTimer) }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        EndretLarertimer endretOmfangTimer ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | larertimer = Just <| Result.withDefault 0 (String.toInt endretOmfangTimer) }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        EndretElevgrupper antall ->
            let
                gammelDeltaker =
                    model.deltaker

                oppdatertDeltaker =
                    { gammelDeltaker | elevgrupper = Just <| Result.withDefault 0 (String.toInt antall) }

                ( visLagreKnapp, statusTekst ) =
                    valideringsInfo oppdatertDeltaker
            in
                ( { model | deltaker = oppdatertDeltaker, statusText = statusTekst, visLagreKnapp = visLagreKnapp }, Cmd.none, NoSharedMsg )

        OpprettNyDeltaker ->
            let
                validering =
                    validerDeltakerGyldigNy model.deltaker

                ( statusTekst, cmd ) =
                    case validering of
                        Ok resultat ->
                            ( "", postOpprettNyDeltaker model.apiEndpoint resultat.aktivitetId resultat NyDeltakerRespons )

                        Err feil ->
                            ( feil, Cmd.none )
            in
                ( { model | statusText = statusTekst }, cmd, NoSharedMsg )

        NyDeltakerRespons (Ok nyId) ->
            let
                cmdShared =
                    case model.aktivitet of
                        Success data ->
                            NavigateToAktivitet data.id

                        _ ->
                            NoSharedMsg
            in
                ( model, Cmd.none, cmdShared )

        NyDeltakerRespons (Err error) ->
            let
                ( cmd, statusText, _ ) =
                    case error of
                        Http.BadUrl info ->
                            ( Cmd.none, "Feil i url til API.", 0 )

                        Http.BadPayload _ _ ->
                            ( Cmd.none, "Feil i innhold ved sending av data til API.", 0 )

                        Http.BadStatus status ->
                            ( Cmd.none, "Feil i sending av data til API.", 0 )

                        Http.NetworkError ->
                            ( Cmd.none, "Feil i sending av data til API. Nettverksfeil.", 0 )

                        Http.Timeout ->
                            ( Cmd.none, "Nettverksfeil - timet ut ved kall til API.", 0 )
            in
                ( { model | statusText = statusText }, cmd, NoSharedMsg )

        NavigerTilbake ->
            ( model, Cmd.none, NavigateToAktivitet model.aktivitetId )


valideringsInfo : DeltakerEdit -> ( Bool, String )
valideringsInfo deltaker =
    case validerDeltakerGyldigNy deltaker of
        Ok _ ->
            ( True, "" )

        Err feil ->
            ( False, feil )


validerDeltakerGyldigNy : DeltakerEdit -> Result String DeltakerGyldigNy
validerDeltakerGyldigNy form =
    Ok DeltakerGyldigNy
        |: required "Mangler gyldig aktivitet" form.aktivitetId
        |: required "Velg utdanningsprogram" form.utdanningsprogram
        |: required "Velg trinn" form.trinn
        |: required "Elevtimer må fylles ut." form.timer
        |: required "Lærertimer må fylles ut." form.larertimer
        |: required "Elevgrupper må fylles ut." form.elevgrupper
        |: required "Velg fag" form.fag
        |: notBlank "Kompetansemål må fylles ut." form.kompetansemaal


showText : (List (Html.Attribute m) -> List (Html msg) -> a) -> Options.Property c m -> String -> a
showText elementType displayStyle text_ =
    Options.styled elementType [ displayStyle, Typo.left ] [ text text_ ]


vis : Taco -> Model -> Html Msg
vis taco model =
    grid []
        (visHeading model :: visAktivitet model taco ++ visOpprettDeltaker model taco model.deltaker)


visHeading : Model -> Grid.Cell Msg
visHeading model =
    cell
        [ size All 12
        ]
        [ Options.span
            [ Typo.headline
            , Options.css "padding" "16px 32px"
            ]
            [ text "Opprett deltaker" ]
        ]


visAktivitet : Model -> Taco -> List (Grid.Cell Msg)
visAktivitet model taco =
    case model.aktivitet of
        NotAsked ->
            [ cell
                [ size All 12
                , Elevation.e0
                , Options.css "padding" "16px 32px"
                ]
                [ text "Venter på henting av .."
                ]
            ]

        Loading ->
            [ cell
                [ size All 12
                , Elevation.e0
                , Options.css "padding" "16px 32px"
                ]
                [ Options.div []
                    [ Loading.spinner [ Loading.active True ]
                    ]
                ]
            ]

        Failure err ->
            [ cell
                [ size All 12
                , Elevation.e0
                , Options.css "padding" "16px 32px"
                ]
                [ text "Feil ved henting av data"
                ]
            ]

        Success data ->
            visAktivitetSuksess model taco data


visAktivitetSuksess : Model -> Taco -> Aktivitet -> List (Grid.Cell Msg)
visAktivitetSuksess model taco aktivitet =
    [ cell
        [ size All 4
        , Elevation.e0
        , Options.css "padding" "0px 32px"

        -- , Options.css "display" "flex"
        -- , Options.css "flex-direction" "column"
        -- , Options.css "align-items" "left"
        ]
        [ Options.div
            [ css "width" "100%"
            ]
            [ p []
                [ Options.styled div [ Typo.title ] [ text aktivitet.navn ]
                ]
            , p []
                [ Options.styled div [ Typo.caption ] [ text "Beskrivelse: " ]
                , Options.styled div [ Typo.subhead ] [ text (aktivitet.beskrivelse) ]
                ]
            ]
        ]
    , cell
        [ size All 8
        , Elevation.e0
        , Options.css "padding" "16px 32px"

        -- , Options.css "display" "flex"
        -- , Options.css "flex-direction" "column"
        -- , Options.css "align-items" "left"
        ]
        [ Options.div
            [ css "width" "100%"
            ]
            [ p []
                [ Options.styled div [ Typo.caption ] [ text "Klokketimer: " ]
                , Options.styled div [ Typo.subhead ] [ text (toString aktivitet.omfangTimer) ]
                ]
            , p []
                [ Options.styled div [ Typo.caption ] [ text "Skole: " ]
                , Options.styled div [ Typo.subhead ] [ text (aktivitet.skoleNavn) ]
                ]
            , p []
                [ Options.styled div [ Typo.caption ] [ text "Aktivitetstype" ]
                , Options.styled div [ Typo.subhead ] [ text aktivitet.aktivitetsTypeNavn ]
                ]
            ]
        ]
    ]


visOpprettDeltaker : Model -> Taco -> DeltakerEdit -> List (Grid.Cell Msg)
visOpprettDeltaker model taco deltaker =
    [ cell
        [ size All 4
        , Options.css "padding" "0px 32px"
        ]
        [ Options.div
            [ css "width" "100%" ]
            [ showText p Typo.menu "Utdanningsprogram"
            , visUtdanningsprogram model taco deltaker
            , showText p Typo.menu "Trinn"
            , visTrinn model taco deltaker
            , Textfield.render Mdl
                [ 3 ]
                model.mdl
                [ Textfield.label "Elevtimer (klokketimer)"
                , Textfield.floatingLabel
                , Textfield.text_
                , Textfield.value <| Maybe.withDefault "" <| Maybe.map toString deltaker.timer
                , Options.onInput EndretTimer
                ]
                []
            , Textfield.render Mdl
                [ 3 ]
                model.mdl
                [ Textfield.label "Lærertimer (klokketimer)"
                , Textfield.floatingLabel
                , Textfield.text_
                , Textfield.value <| Maybe.withDefault "" <| Maybe.map toString deltaker.larertimer
                , Options.onInput EndretLarertimer
                ]
                []
            , Textfield.render Mdl
                [ 3 ]
                model.mdl
                [ Textfield.label "Elevgrupper (antall)"
                , Textfield.floatingLabel
                , Textfield.text_
                , Textfield.value <| Maybe.withDefault "" <| Maybe.map toString deltaker.elevgrupper
                , Options.onInput EndretElevgrupper
                ]
                []
            , showText p Typo.menu "Fag"
            , visFag model taco deltaker
            ]
        ]
    , cell
        [ size All 8
        , Options.css "padding" "16px 32px"
        ]
        [ Options.div
            []
            [ Textfield.render Mdl
                [ 2 ]
                model.mdl
                [ Textfield.label "Kompetansemål"
                , Textfield.floatingLabel
                , Textfield.text_
                , Textfield.textarea
                , Textfield.rows 12
                , Textfield.value <| Maybe.withDefault "" deltaker.kompetansemaal
                , Options.onInput EndretKompetansemaal
                , cs "text-area"
                ]
                []
            ]
        ]
    , cell
        [ size All 12
        ]
        [ Options.div
            []
            [ Options.div [] [ showText p Typo.subhead model.statusText ]

            -- , showText p Typo.menu "Aktivitetstype"
            -- , visAktivitetstype model
            , Button.render Mdl
                [ 10, 1 ]
                model.mdl
                [ Button.ripple
                , Button.colored
                , Button.raised
                , Options.onClick (NavigerTilbake)
                , css "float" "left"
                , Options.css "margin" "6px 6px"
                ]
                [ text "Avbryt" ]
            , Button.render Mdl
                [ 10, 11 ]
                model.mdl
                [ Button.ripple
                , Button.colored
                , Options.when (not model.visLagreKnapp) Button.disabled
                , Button.raised
                , Options.onClick (OpprettNyDeltaker)
                , css "float" "left"
                , Options.css "margin" "6px 6px"

                -- , css "margin-left" "1em"
                -- , Options.onClick (SearchAnsatt "Test")
                ]
                [ text "Lagre" ]
            ]
        ]
    ]


visUtdanningsprogram : Model -> Taco -> DeltakerEdit -> Html Msg
visUtdanningsprogram model taco deltaker =
    Html.map UtdanningsprogramDropdown (Dropdown.view dropdownConfigUtdanningsprogram model.dropdownStateUtdanningsprogram taco.appMetadata.utdanningsprogrammer deltaker.utdanningsprogram)


visTrinn : Model -> Taco -> DeltakerEdit -> Html Msg
visTrinn model taco deltaker =
    Html.map TrinnDropdown (Dropdown.view dropdownConfigTrinn model.dropdownStateTrinn taco.appMetadata.trinnListe deltaker.trinn)


visFag : Model -> Taco -> DeltakerEdit -> Html Msg
visFag model taco deltaker =
    Html.map FagDropdown (Dropdown.view dropdownConfigFag model.dropdownStateFag taco.appMetadata.fagListe deltaker.fag)


dropdownConfigUtdanningsprogram : Dropdown.Config Msg Utdanningsprogram
dropdownConfigUtdanningsprogram =
    Dropdown.newConfig OnSelectUtdanningsprogram .navn
        |> Dropdown.withItemClass "border-bottom border-silver p1 gray"
        |> Dropdown.withMenuClass "border border-gray dropdown"
        |> Dropdown.withMenuStyles [ ( "background", "white" ) ]
        |> Dropdown.withPrompt "Velg utdanningsprogram"
        |> Dropdown.withPromptClass "silver"
        |> Dropdown.withSelectedClass "bold"
        |> Dropdown.withSelectedStyles [ ( "color", "black" ) ]
        |> Dropdown.withTriggerClass "col-12 border bg-white p1"


dropdownConfigTrinn : Dropdown.Config Msg Trinn
dropdownConfigTrinn =
    Dropdown.newConfig OnSelectTrinn .navn
        |> Dropdown.withItemClass "border-bottom border-silver p1 gray"
        |> Dropdown.withMenuClass "border border-gray dropdown"
        |> Dropdown.withMenuStyles [ ( "background", "white" ) ]
        |> Dropdown.withPrompt "Velg trinn"
        |> Dropdown.withPromptClass "silver"
        |> Dropdown.withSelectedClass "bold"
        |> Dropdown.withSelectedStyles [ ( "color", "black" ) ]
        |> Dropdown.withTriggerClass "col-12 border bg-white p1"


dropdownConfigFag : Dropdown.Config Msg Fag
dropdownConfigFag =
    Dropdown.newConfig OnSelectFag .navn
        |> Dropdown.withItemClass "border-bottom border-silver p1 gray"
        |> Dropdown.withMenuClass "border border-gray dropdown"
        |> Dropdown.withMenuStyles [ ( "background", "white" ) ]
        |> Dropdown.withPrompt "Velg fag"
        |> Dropdown.withPromptClass "silver"
        |> Dropdown.withSelectedClass "bold"
        |> Dropdown.withSelectedStyles [ ( "color", "black" ) ]
        |> Dropdown.withTriggerClass "col-12 border bg-white p1"
