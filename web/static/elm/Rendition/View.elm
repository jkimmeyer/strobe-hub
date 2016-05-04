module Rendition.View (..) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Rendition
import Source.View


playing : Signal.Address () -> Rendition.Model -> Html
playing playPauseAddress rendition =
  div
    [ id rendition.id, class "player" ]
    [ div
        [ class "player-icon" ]
        [ img [ src "/images/cover.jpg", alt "", onClick playPauseAddress () ] []
        , div
            [ class "player-song" ]
            [ div
                [ class "player-title" ]
                [ text (renditionTitle rendition)
                , div [ class "block player-duration duration" ] [ text (Source.View.duration rendition.source) ]
                ]
            , div
                [ class "player-meta" ]
                [ div [ class "player-artist" ] [ text (renditionPerformer rendition) ]
                , div [ class "player-album" ] [ text (renditionAlbum rendition) ]
                ]
            ]
        ]
    ]


progress : Signal.Address () -> Rendition.Model -> Html
progress address rendition =
  case rendition.source.metadata.duration_ms of
    Nothing ->
      div [] []

    Just duration ->
      let
        percent =
          100.0 * (toFloat rendition.playbackPosition) / (toFloat duration)

        progressStyle =
          [ ( "width", (toString percent) ++ "%" ) ]
      in
        div
          [ class "progress" ]
          [ div [ class "progress-complete", style progressStyle ] []
          ]


playlist : Signal.Address Rendition.Action -> Rendition.Model -> Html
playlist address rendition =
  div
    [ key rendition.id
    , class "block playlist-entry"
    , onDoubleClick address (Rendition.Skip)
    ]
    [ div
        [ class "playlist-entry--title" ]
        [ strong [] [ text (renditionTitle rendition) ] ]
    , div
        [ class "playlist-entry--album" ]
        [ strong
            []
            [ text (renditionPerformer rendition) ]
        , text ", "
        , text (renditionAlbum rendition)
        ]
    ]


renditionTitle : Rendition.Model -> String
renditionTitle rendition =
  Maybe.withDefault "Untitled" rendition.source.metadata.title


renditionAlbum : Rendition.Model -> String
renditionAlbum rendition =
  Maybe.withDefault "Untitled Album" rendition.source.metadata.album


renditionPerformer : Rendition.Model -> String
renditionPerformer rendition =
  Maybe.withDefault "" rendition.source.metadata.performer
