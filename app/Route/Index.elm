module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
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
    {}


type alias Data =
    { intro : String
    , posts : List Post
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.map2 Data
        (File.rawFile "index.md" |> BackendTask.allowFatal)
        Blog.allPosts


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "James' Adventures!"
        , image = { url = Pages.Url.external "https://jamestjw.github.io/images/logo.png", alt = "James' Adventures!", dimensions = Nothing, mimeType = Nothing }
        , description = "Welcome to James' blog."
        , locale = Nothing
        , title = "James' Adventures!"
        }
        |> Seo.website


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = "James' Adventures!"
    , body =
        Blog.markdownToHtml app.data.intro
            ++ [ Html.h2 [] [ Html.text "Posts" ]
               , Html.ul [ Attr.class "post-list" ] (List.map postListItem app.data.posts)
               ]
    }


postListItem : Post -> Html.Html msg
postListItem post =
    Html.li []
        [ Html.div [ Attr.class "post-meta" ] [ Html.text post.date ]
        , Html.h3 [] [ Html.a [ Attr.href ("/posts/" ++ post.slug) ] [ Html.text post.title ] ]
        ]
