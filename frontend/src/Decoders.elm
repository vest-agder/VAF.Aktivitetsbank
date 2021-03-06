module Decoders exposing (..)

import Types exposing (..)
import Json.Decode as Json exposing (field)
import Json.Encode
import Json.Decode.Pipeline


decodeUserInformation : Json.Decoder UserInformation
decodeUserInformation =
    Json.map3 UserInformation
        (field "navn" Json.string)
        (field "brukernavn" Json.string)
        (field "rolle" Json.string)


decodeMaybeString : Maybe String -> Json.Decoder (Maybe String)
decodeMaybeString maybeString =
    Json.succeed (Maybe.withDefault Nothing (Just maybeString))


decodeUtdanningsprogram : Json.Decoder Utdanningsprogram
decodeUtdanningsprogram =
    Json.Decode.Pipeline.decode Utdanningsprogram
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.optional "overordnetUtdanningsprogramId" (Json.string) "topp"
        |> Json.Decode.Pipeline.required "navn" (Json.string)


decodeTrinn : Json.Decoder Trinn
decodeTrinn =
    Json.Decode.Pipeline.decode Trinn
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)


decodeAktivitetsType : Json.Decoder AktivitetsType
decodeAktivitetsType =
    Json.Decode.Pipeline.decode AktivitetsType
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)


decodeSkoleAar : Json.Decoder SkoleAar
decodeSkoleAar =
    Json.Decode.Pipeline.decode SkoleAar
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)


decodeFag : Json.Decoder Fag
decodeFag =
    Json.Decode.Pipeline.decode Fag
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)


decodeSkole : Json.Decoder Skole
decodeSkole =
    Json.Decode.Pipeline.decode Skole
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)
        |> Json.Decode.Pipeline.required "kode" (Json.string)



--


decodeAppMetadata : Json.Decoder AppMetadata
decodeAppMetadata =
    Json.Decode.Pipeline.decode AppMetadata
        |> Json.Decode.Pipeline.required "skoler" (Json.list decodeSkole)
        |> Json.Decode.Pipeline.required "fagListe" (Json.list decodeFag)
        |> Json.Decode.Pipeline.required "trinnListe" (Json.list decodeTrinn)
        |> Json.Decode.Pipeline.required "aktivitetstyper" (Json.list decodeAktivitetsType)
        |> Json.Decode.Pipeline.required "utdanningsprogrammer" (Json.list decodeUtdanningsprogram)
        |> Json.Decode.Pipeline.required "skoleAar" (Json.list decodeSkoleAar)


decodeAktivitet : Json.Decoder Aktivitet
decodeAktivitet =
    Json.Decode.Pipeline.decode Aktivitet
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "navn" (Json.string)
        |> Json.Decode.Pipeline.required "beskrivelse" (Json.string)
        |> Json.Decode.Pipeline.required "omfangTimer" (Json.int)
        |> Json.Decode.Pipeline.required "skoleId" (Json.string)
        |> Json.Decode.Pipeline.required "skoleNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeAktivitetSkole) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.required "aktivitetstypeId" (Json.string)
        |> Json.Decode.Pipeline.required "aktivitetstypeNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeAktivitetAktivitetsType) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.required "skoleAarId" (Json.string)
        |> Json.Decode.Pipeline.required "skoleAarNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeAktivitetSkoleAar) |> Json.andThen (\x -> Json.succeed <| Just x))


decodeAktivitetEdit : Json.Decoder AktivitetEdit
decodeAktivitetEdit =
    Json.Decode.Pipeline.decode AktivitetEdit
        |> Json.Decode.Pipeline.custom ((field "id" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "navn" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "beskrivelse" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "omfangTimer" Json.int) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeAktivitetSkole) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeAktivitetAktivitetsType) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeAktivitetSkoleAar) |> Json.andThen (\x -> Json.succeed <| Just x))


decodeAktivitetSkole : Json.Decoder Skole
decodeAktivitetSkole =
    Json.map3 Skole
        (field "skoleId" Json.string)
        (field "skoleNavn" Json.string)
        (Json.succeed "")


decodeAktivitetAktivitetsType : Json.Decoder AktivitetsType
decodeAktivitetAktivitetsType =
    Json.map2 AktivitetsType
        (field "aktivitetstypeId" Json.string)
        (field "aktivitetstypeNavn" Json.string)


decodeAktivitetSkoleAar : Json.Decoder SkoleAar
decodeAktivitetSkoleAar =
    Json.map2 SkoleAar
        (field "skoleAarId" Json.string)
        (field "skoleAarNavn" Json.string)


encodeOpprettNyAktivitet : AktivitetGyldigNy -> Json.Encode.Value
encodeOpprettNyAktivitet model =
    let
        encodings =
            [ ( "navn", Json.Encode.string model.navn )
            , ( "beskrivelse", Json.Encode.string model.beskrivelse )
            , ( "omfangTimer", Json.Encode.int model.omfangTimer )
            , ( "skoleId", Json.Encode.string model.skole.id )
            , ( "aktivitetsTypeId", Json.Encode.string model.aktivitetsType.id )
            , ( "skoleAarId", Json.Encode.string model.skoleAar.id )
            ]
    in
        encodings
            |> Json.Encode.object


encodeEndreAktivitet : AktivitetGyldigEndre -> Json.Encode.Value
encodeEndreAktivitet model =
    let
        encodings =
            [ ( "id", Json.Encode.string model.id )
            , ( "navn", Json.Encode.string model.navn )
            , ( "beskrivelse", Json.Encode.string model.beskrivelse )
            , ( "omfangTimer", Json.Encode.int model.omfangTimer )
            , ( "skoleId", Json.Encode.string model.skole.id )
            , ( "aktivitetsTypeId", Json.Encode.string model.aktivitetsType.id )
            , ( "skoleAarId", Json.Encode.string model.skoleAar.id )
            ]
    in
        encodings
            |> Json.Encode.object


encodeKopierAktivitet : AktivitetGyldigKopier -> Json.Encode.Value
encodeKopierAktivitet model =
    let
        encodings =
            [ ( "id", Json.Encode.string model.id )
            , ( "skoleId", Json.Encode.string model.skoleId )
            ]
    in
        encodings
            |> Json.Encode.object



-- encodeOpprettNyAktivitet : Aktivitet -> Json.Encode.Value
-- encodeOpprettNyAktivitet model =
--     let
--         encodings =
--             [ ( "navn", Json.Encode.string model.navn )
--             , ( "beskrivelse", Json.Encode.string model.beskrivelse )
--             , ( "omfangTimer", Json.Encode.int model.omfangTimer )
--             , ( "skoleId", model.skole
--                             |> Maybe.andThen (\skole -> Just skole.id)
--                             |> Maybe.withDefault "feil"
--                             |> Json.Encode.string
--                             )
--             , ( "aktivitetsTypeId", model.aktivitetsType
--                                     |> Maybe.andThen (\aktivitetsType -> Just aktivitetsType.id)
--                                     |> Maybe.withDefault "feil"
--                                     |> Json.Encode.string
--                                     )
--             ]
--     in
--         encodings
--             |> Json.Encode.object


encodeOpprettNyDeltaker : String -> DeltakerGyldigNy -> Json.Encode.Value
encodeOpprettNyDeltaker aktivitetId model =
    let
        encodings =
            [ ( "aktivitetId", Json.Encode.string aktivitetId )
            , ( "kompetansemaal", Json.Encode.string model.kompetansemaal )
            , ( "timer", Json.Encode.int model.timer )
            , ( "larertimer", Json.Encode.int model.larertimer )
            , ( "elevgrupper", Json.Encode.int model.elevgrupper )
            , ( "utdanningsprogramId", Json.Encode.string model.utdanningsprogram.id )
            , ( "trinnId", Json.Encode.string model.trinn.id )
            , ( "fagId", Json.Encode.string model.fag.id )
            ]
    in
        encodings
            |> Json.Encode.object


encodeEndreDeltaker : String -> DeltakerGyldigEndre -> Json.Encode.Value
encodeEndreDeltaker aktivitetId model =
    let
        encodings =
            [ ( "id", Json.Encode.string model.id )
            , ( "aktivitetId", Json.Encode.string aktivitetId )
            , ( "kompetansemaal", Json.Encode.string model.kompetansemaal )
            , ( "timer", Json.Encode.int model.timer )
            , ( "larertimer", Json.Encode.int model.larertimer )
            , ( "elevgrupper", Json.Encode.int model.elevgrupper )
            , ( "utdanningsprogramId", Json.Encode.string model.utdanningsprogram.id )
            , ( "trinnId", Json.Encode.string model.trinn.id )
            , ( "fagId", Json.Encode.string model.fag.id )
            ]
    in
        encodings
            |> Json.Encode.object


decodeAktivitetListe : Json.Decoder (List Aktivitet)
decodeAktivitetListe =
    Json.list decodeAktivitet


decodeNyAktivitet : Json.Decoder NyAktivitet
decodeNyAktivitet =
    Json.Decode.Pipeline.decode NyAktivitet
        |> Json.Decode.Pipeline.required "id" (Json.string)


decodeNyDeltaker : Json.Decoder NyDeltaker
decodeNyDeltaker =
    Json.Decode.Pipeline.decode NyDeltaker
        |> Json.Decode.Pipeline.required "id" (Json.string)


decodeDeltaker : Json.Decoder Deltaker
decodeDeltaker =
    Json.Decode.Pipeline.decode Deltaker
        |> Json.Decode.Pipeline.required "id" (Json.string)
        |> Json.Decode.Pipeline.required "aktivitetId" (Json.string)
        |> Json.Decode.Pipeline.required "aktivitetNavn" (Json.string)
        |> Json.Decode.Pipeline.required "utdanningsprogramId" (Json.string)
        |> Json.Decode.Pipeline.required "utdanningsprogramNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeDeltakerUtdanningsprogram) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.required "trinnId" (Json.string)
        |> Json.Decode.Pipeline.required "trinnNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeDeltakerTrinn) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.required "fagId" (Json.string)
        |> Json.Decode.Pipeline.required "fagNavn" (Json.string)
        |> Json.Decode.Pipeline.custom ((decodeDeltakerFag) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.required "timer" (Json.int)
        |> Json.Decode.Pipeline.required "larertimer" (Json.int)
        |> Json.Decode.Pipeline.required "elevgrupper" (Json.int)
        |> Json.Decode.Pipeline.required "kompetansemaal" (Json.string)


decodeDeltakerEdit : Json.Decoder DeltakerEdit
decodeDeltakerEdit =
    Json.Decode.Pipeline.decode DeltakerEdit
        |> Json.Decode.Pipeline.custom ((field "id" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "aktivitetId" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeDeltakerUtdanningsprogram) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeDeltakerTrinn) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((decodeDeltakerFag) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "timer" Json.int) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "larertimer" Json.int) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "elevgrupper" Json.int) |> Json.andThen (\x -> Json.succeed <| Just x))
        |> Json.Decode.Pipeline.custom ((field "kompetansemaal" Json.string) |> Json.andThen (\x -> Json.succeed <| Just x))


decodeDeltakerUtdanningsprogram : Json.Decoder Utdanningsprogram
decodeDeltakerUtdanningsprogram =
    Json.map3 Utdanningsprogram
        (field "utdanningsprogramId" Json.string)
        (Json.succeed "")
        (field "utdanningsprogramNavn" Json.string)


decodeDeltakerTrinn : Json.Decoder Trinn
decodeDeltakerTrinn =
    Json.map2 Trinn
        (field "trinnId" Json.string)
        (field "trinnNavn" Json.string)


decodeDeltakerFag : Json.Decoder Fag
decodeDeltakerFag =
    Json.map2 Fag
        (field "fagId" Json.string)
        (field "fagNavn" Json.string)


decodeDeltakerListe : Json.Decoder (List Deltaker)
decodeDeltakerListe =
    Json.list decodeDeltaker
