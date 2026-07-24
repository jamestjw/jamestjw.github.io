module Route.Posts.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Blog exposing (Post)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias Data =
    Post


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Blog.postFiles
        |> BackendTask.map (List.map (\post -> { slug = post.slug }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Blog.postBySlug routeParams.slug


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "James' Adventures!"
        , image = { url = Pages.Url.external "https://jamestjw.github.io/images/logo.png", alt = "James' Adventures!", dimensions = Nothing, mimeType = Nothing }
        , description = app.data.title
        , locale = Nothing
        , title = app.data.title
        }
        |> Seo.article
            { tags = app.data.tags
            , section = Nothing
            , publishedTime = Nothing
            , modifiedTime = Nothing
            , expirationTime = Nothing
            }


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = app.data.title
    , body =
        [ Html.article [ Attr.class "post" ]
            ([ Html.header []
                [ Html.h1 [] [ Html.text app.data.title ]
                , Html.div [ Attr.class "post-meta" ] [ Html.text app.data.date ]
                , Html.div [ Attr.class "tags" ] (List.map tagLink app.data.tags)
                ]
             ]
                ++ Blog.postBodyHtml app.data.body
            )
        ]
    }


tagLink : String -> Html.Html msg
tagLink tag =
    Html.a [ Attr.class "tag", Attr.href ("/tags/" ++ tag) ] [ Html.text tag ]
