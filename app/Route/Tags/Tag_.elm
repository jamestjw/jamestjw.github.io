module Route.Tags.Tag_ exposing (ActionData, Data, Model, Msg, route)

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
    { tag : String }


type alias Data =
    { tag : String
    , posts : List Post
    }


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
    Blog.allPosts
        |> BackendTask.map (Blog.tags >> List.map (\tag -> { tag = tag }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Blog.allPosts
        |> BackendTask.map
            (\posts ->
                { tag = routeParams.tag
                , posts = List.filter (\post -> List.member routeParams.tag post.tags) posts
                }
            )


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "James' Adventures!"
        , image = { url = Pages.Url.external "https://jamestjw.github.io/images/logo.png", alt = "James' Adventures!", dimensions = Nothing, mimeType = Nothing }
        , description = "Posts tagged " ++ app.data.tag
        , locale = Nothing
        , title = "Tag: " ++ app.data.tag
        }
        |> Seo.website


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = "Tag: " ++ app.data.tag
    , body =
        [ Html.h1 [] [ Html.text ("Tag: " ++ app.data.tag) ]
        , Html.ul [ Attr.class "post-list" ] (List.map postListItem app.data.posts)
        ]
    }


postListItem : Post -> Html.Html msg
postListItem post =
    Html.li []
        [ Html.div [ Attr.class "post-meta" ] [ Html.text post.date ]
        , Html.h3 [] [ Html.a [ Attr.href ("/posts/" ++ post.slug) ] [ Html.text post.title ] ]
        ]
