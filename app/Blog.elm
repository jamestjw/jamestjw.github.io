module Blog exposing (Post, PostFile, allPosts, markdownToHtml, postBodyHtml, postBySlug, postFiles, tags)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Decode exposing (Decoder)
import List.Extra
import Markdown.Block as Block
import Markdown.Parser
import Markdown.Renderer
import Regex
import String


type alias PostFile =
    { filePath : String
    , date : String
    , slug : String
    }


type alias Post =
    { filePath : String
    , date : String
    , slug : String
    , title : String
    , tags : List String
    , body : String
    }


postFiles : BackendTask FatalError (List PostFile)
postFiles =
    Glob.succeed
        (\filePath year month day slug ->
            { filePath = filePath
            , date = String.join "-" [ year, month, day ]
            , slug = normalizeSlug slug
            }
        )
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "_posts/")
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        |> Glob.capture Glob.digits
        |> Glob.match (Glob.literal "-")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.allowFatal


allPosts : BackendTask FatalError (List Post)
allPosts =
    postFiles
        |> BackendTask.andThen
            (\files ->
                files
                    |> List.map readPost
                    |> BackendTask.combine
                    |> BackendTask.map (List.sortBy .date >> List.reverse)
            )


postBySlug : String -> BackendTask FatalError Post
postBySlug slug =
    allPosts
        |> BackendTask.andThen
            (\posts ->
                posts
                    |> List.Extra.find (\post -> post.slug == slug)
                    |> Result.fromMaybe (FatalError.fromString ("Could not find post " ++ slug))
                    |> BackendTask.fromResult
            )


tags : List Post -> List String
tags posts =
    posts
        |> List.concatMap .tags
        |> List.Extra.unique
        |> List.sort


readPost : PostFile -> BackendTask FatalError Post
readPost file =
    File.bodyWithFrontmatter (postDecoder file) file.filePath
        |> BackendTask.allowFatal


postDecoder : PostFile -> String -> Decoder Post
postDecoder file body =
    Decode.map
        (\frontmatterTags ->
            { filePath = file.filePath
            , date = file.date
            , slug = file.slug
            , title = titleFromMarkdown body
            , tags = frontmatterTags
            , body = body
            }
        )
        (Decode.field "tags" tagsDecoder)


tagsDecoder : Decoder (List String)
tagsDecoder =
    Decode.string
        |> Decode.map (String.words >> List.filter (not << String.isEmpty))


titleFromMarkdown : String -> String
titleFromMarkdown body =
    body
        |> String.lines
        |> List.filterMap
            (\line ->
                if String.startsWith "# " line then
                    Just (String.dropLeft 2 line)

                else
                    Nothing
            )
        |> List.head
        |> Maybe.withDefault "Untitled"


markdownToHtml : String -> List (Html msg)
markdownToHtml markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (\_ -> "Markdown parse error")
        |> Result.andThen (Markdown.Renderer.render rendererWithHeadingIds)
        |> Result.withDefault [ Html.text markdown ]


rendererWithHeadingIds : Markdown.Renderer.Renderer (Html msg)
rendererWithHeadingIds =
    let
        defaultRenderer : Markdown.Renderer.Renderer (Html msg)
        defaultRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defaultRenderer
        | heading = headingWithId
        , image = imageWithCaption
    }


imageWithCaption : { alt : String, src : String, title : Maybe String } -> Html msg
imageWithCaption imageInfo =
    Html.figure []
        ([ Html.img
            ([ Attr.src imageInfo.src
             , Attr.alt imageInfo.alt
             ]
                ++ (imageInfo.title
                        |> Maybe.map (\title -> [ Attr.title title ])
                        |> Maybe.withDefault []
                   )
            )
            []
         ]
            ++ (if String.isEmpty imageInfo.alt then
                    []

                else
                    [ Html.figcaption [] [ Html.text imageInfo.alt ] ]
               )
        )


headingWithId : { level : Block.HeadingLevel, rawText : String, children : List (Html msg) } -> Html msg
headingWithId { level, rawText, children } =
    let
        attrs : List (Html.Attribute msg)
        attrs =
            [ Attr.id (slugFromHeading rawText) ]
    in
    case level of
        Block.H1 ->
            Html.h1 attrs children

        Block.H2 ->
            Html.h2 attrs children

        Block.H3 ->
            Html.h3 attrs children

        Block.H4 ->
            Html.h4 attrs children

        Block.H5 ->
            Html.h5 attrs children

        Block.H6 ->
            Html.h6 attrs children


slugFromHeading : String -> String
slugFromHeading heading =
    heading
        |> normalizeSlug
        |> String.toLower
        |> replaceRegex "[\u{2000}-\u{206F}⸀-⹿\\'!\"#$%&()*+,./:;<=>?@[\\]^`{|}~’]" ""
        |> replaceRegex "\\s+" "-"


normalizeSlug : String -> String
normalizeSlug value =
    value
        |> String.replace "à" "a"
        |> String.replace "â" "a"
        |> String.replace "ä" "a"
        |> String.replace "ç" "c"
        |> String.replace "é" "e"
        |> String.replace "è" "e"
        |> String.replace "ê" "e"
        |> String.replace "ë" "e"
        |> String.replace "î" "i"
        |> String.replace "ï" "i"
        |> String.replace "ô" "o"
        |> String.replace "ö" "o"
        |> String.replace "ù" "u"
        |> String.replace "û" "u"
        |> String.replace "ü" "u"
        |> String.replace "ÿ" "y"


replaceRegex : String -> String -> String -> String
replaceRegex pattern replacement value =
    case Regex.fromString pattern of
        Just regex ->
            Regex.replace regex (\_ -> replacement) value

        Nothing ->
            value


postBodyHtml : String -> List (Html msg)
postBodyHtml markdown =
    markdown
        |> stripFirstHeading
        |> markdownToHtml


stripFirstHeading : String -> String
stripFirstHeading markdown =
    markdown
        |> String.lines
        |> dropFirstHeadingLine
        |> String.join "\n"


dropFirstHeadingLine : List String -> List String
dropFirstHeadingLine lines =
    case lines of
        [] ->
            []

        line :: rest ->
            if String.startsWith "# " line then
                rest

            else
                line :: dropFirstHeadingLine rest
