module Pages.Aktiviteter.Aktivitet exposing (..)

import Html exposing (Html, text, div, span, p, a)
import Material
import Material.Grid as Grid exposing (grid, size, cell, Device(..))
import Material.Elevation as Elevation
import Material.Textfield as Textfield
import Material.Options as Options exposing (when, css, cs, Style, onClick)
import Material.Typography as Typo
import Material.Spinner as Loading
import Material.Typography as Typography
import RemoteData exposing (WebData, RemoteData(..))
import Types exposing (..)
import Http exposing (Error)
import Decoders exposing (..)
import Dropdown


type alias Model =
    { mdl : Material.Model
    , apiEndpoint : String
    , statusText : String
    , aktivitet : WebData Aktivitet
    , appMetadata : WebData AppMetadata
    , valgtSkole : Maybe Skole
    , dropdownStateSkole : Dropdown.State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | AppMetadataResponse (WebData AppMetadata)
    | AktivitetResponse (WebData Aktivitet)
    | OnSelectSkole (Maybe Skole)
    | SkoleDropdown (Dropdown.Msg Skole)


dropdownConfigSkole : Dropdown.Config Msg Skole
dropdownConfigSkole =
    Dropdown.newConfig OnSelectSkole .navn
        |> Dropdown.withItemClass "border-bottom border-silver p1 gray"
        |> Dropdown.withMenuClass "border border-gray"
        |> Dropdown.withMenuStyles [ ( "background", "white" ) ]
        |> Dropdown.withPrompt "Velg skole"
        |> Dropdown.withPromptClass "silver"
        |> Dropdown.withSelectedClass "bold"
        |> Dropdown.withSelectedStyles [ ( "color", "black" ) ]
        |> Dropdown.withTriggerClass "col-4 border bg-white p1"


init : String -> ( Model, Cmd Msg )
init apiEndpoint =
    ( { mdl = Material.model
      , apiEndpoint = apiEndpoint
      , statusText = ""
      , aktivitet = RemoteData.NotAsked
      , appMetadata = RemoteData.NotAsked
      , valgtSkole = Nothing
      , dropdownStateSkole = Dropdown.newState "1"
      }
    , Cmd.none
    )


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
            |> Cmd.map AppMetadataResponse


update : Msg -> Model -> ( Model, Cmd Msg, SharedMsg )
update msg model =
    case msg of
        Mdl msg_ ->
            let
                ( model_, cmd_ ) =
                    Material.update Mdl msg_ model
            in
                ( model_, cmd_, NoSharedMsg )

        AppMetadataResponse response ->
            ( { model | appMetadata = response }, Cmd.none, NoSharedMsg )

        AktivitetResponse response ->
            let
              valgtSkole =
                case response of
                  Success aktivitet ->
                    Just {id = aktivitet.skoleId, navn = aktivitet.skoleNavn, kode = ""}
                  _ ->
                    Nothing
            in

            ( Debug.log "aktivitet-item-response" { model | aktivitet = response, valgtSkole = valgtSkole }, Cmd.none, NoSharedMsg )

        OnSelectSkole skole ->
            ( { model | valgtSkole = skole }, Cmd.none, NoSharedMsg )

        SkoleDropdown skole ->
            let
                ( updated, cmd ) =
                    Dropdown.update dropdownConfigSkole skole model.dropdownStateSkole
            in
                ( { model | dropdownStateSkole = updated }, cmd, NoSharedMsg )


view : Taco -> Model -> Html Msg
view taco model =
    grid []
        [ cell
            [ size All 12
            , Elevation.e0
            , Options.css "align-items" "top"
            , Options.cs "mdl-grid"
            ]
            [ Options.styled p [ Typo.display2 ] [ text "Aktivitet" ]
            ]
        , cell
            [ size All 12
            , Elevation.e2
            , Options.css "padding" "16px 32px"
            , Options.css "display" "flex"
              -- , Options.css "flex-direction" "column"
              -- , Options.css "align-items" "left"
            ]
            [ visAktivitet model
            ]
        ]


visAktivitet : Model -> Html Msg
visAktivitet model =
    case model.aktivitet of
        NotAsked ->
            text "Venter på henting av .."

        Loading ->
            Options.div []
                [ Loading.spinner [ Loading.active True ]
                ]

        Failure err ->
            text "Feil ved henting av data"

        Success data ->
            visAktivitetSuksess model data


visSkole : Model -> Html Msg
visSkole model =
    case model.appMetadata of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure err ->
            text ("Error: " ++ toString err)

        Success data ->
            visSkoleDropdown
                model.valgtSkole
                data.skoler
                model.dropdownStateSkole


visSkoleDropdown : Maybe Skole -> List Skole -> Dropdown.State -> Html Msg
visSkoleDropdown selectedSkoleId model dropdownStateSkole =
    span []
        [ Html.map SkoleDropdown (Dropdown.view dropdownConfigSkole dropdownStateSkole model selectedSkoleId)
        ]


visAktivitetSuksess : Model -> Aktivitet -> Html Msg
visAktivitetSuksess model aktivitet =
    Options.div
        [ css "width" "100%"
        ]
        [ Textfield.render Mdl
            [ 1 ]
            model.mdl
            [ Textfield.label "Navn"
            , Textfield.floatingLabel
            , Textfield.text_
            , Textfield.value <| aktivitet.navn
            ]
            []
        , Textfield.render Mdl
            [ 2 ]
            model.mdl
            [ Textfield.label "Beskrivelse"
            , Textfield.floatingLabel
            , Textfield.text_
            , Textfield.textarea
            , Textfield.rows 6
            , Textfield.value <| aktivitet.beskrivelse
            , cs "text-area"
            ]
            []
        , Textfield.render Mdl
            [ 3 ]
            model.mdl
            [ Textfield.label "Omfang"
            , Textfield.floatingLabel
            , Textfield.text_
            , Textfield.value <| toString aktivitet.omfangTimer
            ]
            []
        , Textfield.render Mdl
            [ 4 ]
            model.mdl
            [ Textfield.label "Type"
            , Textfield.floatingLabel
            , Textfield.text_
            , Textfield.value <| aktivitet.aktivitetsType
            ]
            []
        , visSkole model
        ]