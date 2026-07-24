module ErrorPage exposing (ErrorPage(..), Model, Msg, head, init, internalError, notFound, statusCode, update, view)

import Effect exposing (Effect)
import Head
import Html
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type ErrorPage
    = NotFound
    | InternalError String


init : ErrorPage -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )


update : ErrorPage -> Msg -> Model -> ( Model, Effect Msg )
update _ _ model =
    ( model, Effect.none )


head : ErrorPage -> List Head.Tag
head _ =
    []


notFound : ErrorPage
notFound =
    NotFound


internalError : String -> ErrorPage
internalError =
    InternalError


view : ErrorPage -> Model -> View Msg
view error _ =
    { title =
        case error of
            NotFound ->
                "Page not found"

            InternalError _ ->
                "Unexpected error"
    , body =
        [ Html.h1 []
            [ Html.text <|
                case error of
                    NotFound ->
                        "Page not found"

                    InternalError message ->
                        "Something went wrong: " ++ message
            ]
        ]
    }


statusCode : ErrorPage -> Int
statusCode error =
    case error of
        NotFound ->
            404

        InternalError _ ->
            500
