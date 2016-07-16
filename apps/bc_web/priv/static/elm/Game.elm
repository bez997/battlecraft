port module Game exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Json.Decode exposing (..)
import Task exposing (Task)
import WebSocket
import Effects exposing (Effects)

-- Local imports

import Join
import Map
import GameState exposing (GameState)
import Message exposing (..)

-- Action

type Msg =
    UpdateGameState GameState |
    JoinMsg Join.Msg |
    MapMsg Map.Msg |
    PerformCmd (Cmd Msg) |
    WsReceiveMessage String |
    WsSendMessage String

-- Model

type alias Flags = {
    address : String
}

type alias Model = {
    state : GameState,
    address: String,
    joinModel : Join.Model,
    mapModel : Map.Model
}

init : Flags -> Effects Model (Cmd Msg)
init flags =
    let
        (joinModel, joinEffects) = Join.init

        (mapModel, mapEffects) = Map.init
    in
        Effects.return {
            state = GameState.Joining,
            address = flags.address,
            joinModel = joinModel
        } `Effects.andThen` Effects.handle handleJoinEffect joinEffects
            `Effects.andThen` Effects.handle handleMapEffects mapEffects

-- Update

update : Msg -> Model -> Effects Model (Cmd Msg)
update msg model =
    case msg of

        UpdateGameState state ->
            Effects.return {model | state = state}

        JoinMsg sub ->
            let
                (updateJoinModel, joinEffects) =
                    Join.update sub model.joinModel
            in
                Effects.return {model | joinModel = updateJoinModel}
                    `Effects.andThen` Effects.handle handleJoinEffect joinEffects

        MapMsg sub ->
            let
                (updateMapModel, mapEffects) =
                    Map.update sub model.mapModel
            in
                Effects.return {model | mapModel = updateMapModel}
                    `Effects.andThen` Effects.handle handleMapEffect mapEffects

        PerformCmd Cmd msg ->
            Effects.init model [msg]

        WsReceiveMessage str ->
            case decodeString message str of
                Ok message ->
                    onWsReceiveMessage message model
                Err reason ->
                    Debug.crash reason
                    -- TODO handle error
                    -- Effects.return model

        WsSendMessage str ->
            Effects.init model [WebSocket.send model.address str]

onWsReceiveMessage : Message -> Model -> Effects Model (Cmd Msg)
onWsReceiveMessage message model =
    case message of

        JoinResp joinResp ->
            update (JoinMsg (Join.OnJoinResponse joinResp)) model

        GameEv gameEv ->
            -- TODO handle game event
            Effects.return model

handleJoinEffect : Effects.Handler Join.Effect Model (Cmd Msg)
handleJoinEffect effect model =
    case effect of

        Join.UpdateGameState state ->
            update (UpdateGameState state) model

        Join.WsSendMessage str ->
            update (WsSendMessage str) model

handleMapEffect : Effects.Handler Map.Effect Model (Cmd Msg)
handleMapEffect effect model =
    case effect of

        Map.PerformCmd (Cmd msg) ->
            update (PerformCmd (Cmd msg)) model

        Map.NoOp ->
            Effects.ignoreUnused

-- Subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen model.address WsReceiveMessage

-- View

view : Model -> Html Msg
view model =
    let
        body =
            case model.state of

                GameState.Joining ->
                    App.map JoinMsg <| Join.view model.joinModel

                GameState.Pending ->
                    -- TODO create pending view
                    div [] [
                        text "Waiting for others to join..."
                    ]

                GameState.Started ->
                    -- TODO create map view
                    div [] []

    in
        div [class "game-content is-full-width"] [
            body
        ]

-- Main

main : Program Flags
main =
    App.programWithFlags {
        init = \flags ->
                    let
                        (model, effects) = init flags
                    in
                        (model, effects) |> Effects.toCmd,
        view = view,
        update = \msg model -> update msg model |> Effects.toCmd,
        subscriptions = subscriptions
    }
