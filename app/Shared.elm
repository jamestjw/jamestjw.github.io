module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.Attributes as Attr
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = SharedMsg SharedMsg


type SharedMsg
    = NoOp


type alias Data =
    ()


type alias Model =
    {}


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init _ _ =
    ( {}, Effect.none )


update : Msg -> Model -> ( Model, Effect Msg )
update _ model =
    ( model, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view _ _ _ _ pageView =
    { title = pageView.title
    , body =
        [ Html.header [ Attr.class "site-header" ]
            [ Html.div [ Attr.class "wrapper site-nav" ]
                [ Html.a [ Attr.class "site-title", Attr.href "/" ] [ Html.text "James' Adventures!" ]
                , Html.nav [ Attr.class "nav-links" ]
                    [ Html.a [ Attr.href "/" ] [ Html.text "Home" ]
                    , Html.a [ Attr.href "/about" ] [ Html.text "About" ]
                    ]
                ]
            ]
        , Html.main_ [ Attr.class "wrapper" ] pageView.body
        , Html.footer [ Attr.class "site-footer" ]
            [ Html.div [ Attr.class "wrapper" ]
                [ Html.p []
                    [ Html.text "Welcome to my blog. Feel free to contact me on Mastodon to continue the conversation." ]
                , Html.ul [ Attr.class "social-links" ]
                    [ socialLink "GitHub" "https://github.com/jamestjw"
                    , socialLink "LinkedIn" "https://www.linkedin.com/in/jamestjw"
                    , socialLink "Mastodon" "https://types.pl/@jamestjw"
                    , socialLink "Twitter" "https://www.twitter.com/youknowjamest"
                    ]
                ]
            ]
        ]
    }


socialLink : String -> String -> Html msg
socialLink label url =
    Html.li []
        [ Html.a [ Attr.href url ] [ Html.text label ] ]
