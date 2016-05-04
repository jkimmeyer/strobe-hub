module Main (main) where

import Effects exposing (Effects, Never)
import Html exposing (Html)
import Task exposing (Task)
import StartApp
import Root
import State
import View
import Rendition
import Channel
import Channel.Signals
import Volume.Signals
import Receiver.Signals


app : StartApp.App Root.Model
app =
  StartApp.start
    { init = ( State.initialState, Effects.none )
    , update = State.update
    , view = View.root
    , inputs =
        [ broadcasterStateActions
        , receiverStatusActions
          -- , zoneStatusActions
        , sourceProgressActions
        , sourceChangeActions
          -- , volumeChangeActions
          -- , playListAdditionActions
          -- , libraryRegistrationActions
          -- , libraryResponseActions
        ]
    }


main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks


port broadcasterState : Signal Root.BroadcasterState
broadcasterStateActions : Signal Root.Action
broadcasterStateActions =
  Signal.map Root.InitialState broadcasterState


port receiverStatus : Signal ( String, Root.ReceiverStatusEvent )
receiverStatusActions : Signal Root.Action
receiverStatusActions =
  Signal.map Root.ReceiverStatus receiverStatus


port zoneStatus : Signal ( String, Root.ZoneStatusEvent )



-- zoneStatusActions : Signal Root.Action
-- zoneStatusActions =
--   Signal.map ZoneStatus zoneStatus


port sourceProgress : Signal Rendition.ProgressEvent
sourceProgressActions : Signal Root.Action
sourceProgressActions =
  let
    forward event =
      (Root.ModifyChannel event.zoneId) (Channel.RenditionProgress event)
  in
    Signal.map forward sourceProgress


port sourceChange : Signal Rendition.ChangeEvent
sourceChangeActions : Signal Root.Action
sourceChangeActions =
  let
    forward event =
      (Root.ModifyChannel event.zoneId) (Channel.RenditionChange event)
  in
    Signal.map forward sourceChange


port volumeChange : Signal Root.VolumeChangeEvent



-- volumeChangeActions : Signal Root.Action
-- volumeChangeActions =
--   Signal.map VolumeChange volumeChange


port playlistAddition : Signal Root.PlaylistEntry



-- playListAdditionActions : Signal Root.Action
-- playListAdditionActions =
--   Signal.map PlayListAddition playlistAddition
-- port libraryRegistration : Signal Library.Node
--
-- libraryRegistrationActions : Signal Root.Action
-- libraryRegistrationActions =
--   Signal.map LibraryRegistration libraryRegistration
-- port libraryResponse : Signal Library.FolderResponse
--
--
-- libraryResponseActions : Signal Root.Action
-- libraryResponseActions =
--   let
--       translate response =
--         -- log ("Translate " ++ toString(response.folder))
--
--         Library (Library.Response response.folder)
--   in
--       Signal.map translate libraryResponse


port volumeChangeRequests : Signal ( String, String, Float )
port volumeChangeRequests =
  let
    mailbox =
      Volume.Signals.volumeChange
  in
    mailbox.signal


port playPauseChanges : Signal ( String, Bool )
port playPauseChanges =
  let
    mailbox =
      Channel.Signals.playPause
  in
    mailbox.signal


playlistSkipRequestsBox : Signal.Mailbox ( String, String )
playlistSkipRequestsBox =
  Signal.mailbox ( "", "" )


port playlistSkipRequests : Signal ( String, String )
port playlistSkipRequests =
  playlistSkipRequestsBox.signal


port attachReceiverRequests : Signal ( String, String )
port attachReceiverRequests =
  let
    mailbox =
      Receiver.Signals.attach
  in
    mailbox.signal



-- port libraryRequests : Signal (String, String)
-- port libraryRequests =
--   let
--       mailbox = Library.libraryRequestsBox
--   in
--       mailbox.signal
