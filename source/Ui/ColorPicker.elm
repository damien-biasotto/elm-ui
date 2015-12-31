module Ui.ColorPicker
  (Model, Action, init, update, view, handleMove, handleClick) where

{-| Color picker input component.

# Model
@docs Model, Action, init, update

# View
@docs view

# Functions
@docs handleMove, handleClick
-}
import Html.Extra exposing (onWithDropdownDimensions,onKeysWithDimensions)
import Html.Attributes exposing (classList, style)
import Html.Events exposing (onBlur, onClick)
import Html exposing (node, div, text)
import Html.Lazy

import Signal exposing (forwardTo)
import Ext.Color
import Color
import Dict

import Ui.Helpers.Dropdown as Dropdown
import Ui.ColorPanel as ColorPanel
import Ui

{-| Representation of a color picker:
  - **colorPanel** (internal) - The model of a color panel
  - **disabled** - Whether or not the color picker is disabled
  - **open** - Whether or not the color picker is open
  - **readonly** - Whether or not the color picker is readonly
  - **dropdownPosition** (Internal) - Where the dropdown is positioned
-}
type alias Model =
  { colorPanel : ColorPanel.Model
  , dropdownPosition : String
  , disabled : Bool
  , readonly : Bool
  , open : Bool
  }

{-| Actions that a color picker can make. -}
type Action
  = Focus Html.Extra.DropdownDimensions
  | Close Html.Extra.DropdownDimensions
  | Toggle Html.Extra.DropdownDimensions
  | ColorPanel ColorPanel.Action
  | Blur

{-| Initializes a color picker with the given color.

    ColorPicker.init Color.yellow
-}
init : Color.Color -> Model
init color =
  { colorPanel = ColorPanel.init color
  , dropdownPosition = "bottom"
  , disabled = False
  , readonly = False
  , open = False
  }

{-| Updates a color picker. -}
update : Action -> Model -> Model
update action model =
  case action of
    Focus dimensions ->
      Dropdown.openWithDimensions dimensions model

    Close _ ->
      Dropdown.close model

    Blur ->
      Dropdown.close model

    Toggle dimensions ->
      Dropdown.toggleWithDimensions dimensions model

    ColorPanel act ->
      { model | colorPanel = ColorPanel.update act model.colorPanel }

{-| Renders a color picker. -}
view : Signal.Address Action -> Model -> Html.Html
view address model =
  Html.Lazy.lazy2 render address model

{-| Updates a color picker by coordinates. -}
handleMove : Int -> Int -> Model -> Model
handleMove x y model =
  { model | colorPanel = ColorPanel.handleMove x y model.colorPanel }

{-| Updates a color picker, stopping the drags if the mouse isnt pressed. -}
handleClick : Bool-> Model -> Model
handleClick pressed model =
  { model | colorPanel = ColorPanel.handleClick pressed model.colorPanel }

-- Render internal.
render : Signal.Address Action -> Model -> Html.Html
render address model =
  let
    color = Ext.Color.toCSSRgba model.colorPanel.value
    actions =
      if model.disabled || model.readonly then []
      else [ onWithDropdownDimensions "focus" address Focus
           , onBlur address Blur
           , onKeysWithDimensions address [ (27, Close)
                                          , (13, Toggle)
                                          ]
           ]
  in
    node "ui-color-picker" ([ classList [ ("dropdown-open", model.open)
                                        , ("disabled", model.disabled)
                                        , ("readonly", model.readonly)
                                        ]
                            ] ++ actions ++ (Ui.tabIndex model))
      [ div [] [text color]
      , node "ui-color-picker-rect" []
        [ div [style [("background-color", color)]] [] ]
      , Dropdown.view model.dropdownPosition
        [ node "ui-dropdown-overlay" [onClick address Blur] []
        , ColorPanel.view (forwardTo address ColorPanel) model.colorPanel
        ]
      ]