import blogatto
import blogatto/config
import blogatto/config/post
import blogatto/error
import blogatto/post as blog_post
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute.{type Attribute}
import lustre/element.{type Element, unsafe_raw_html}
import lustre/element/html
import mork
import simplifile
import site/config as site_config

pub fn main() {
  case site_config() {
    Ok(config) ->
      case blogatto.build(config) {
        Ok(Nil) -> io.println("Site built successfully!")
        Error(err) -> io.println(error.describe_error(err))
      }
    Error(message) -> io.println(message)
  }
}

pub fn site_config() {
  use tags <- result.try(content_tags())
  use home <- result.try(read_content("./content/index.md"))
  use about <- result.try(read_content("./content/about.md"))
  Ok(site_config_with_content(tags, home, about))
}

fn site_config_with_content(tags: List(String), home: String, about: String) {
  let posts =
    post.default()
    |> post.path("./content/posts")
    |> post.route_prefix("posts")
    |> post.options(post.Options(True, True, True, True, True, True))
    |> post.h1(heading(html.h1))
    |> post.h2(heading(html.h2))
    |> post.h3(heading(html.h3))
    |> post.h4(heading(html.h4))
    |> post.h5(heading(html.h5))
    |> post.h6(heading(html.h6))
    |> post.img(image)
    |> post.template(post_page)

  let config =
    config.new(site_config.url)
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.post(posts)
    |> config.route("/", home_page(home))
    |> config.route("/about", about_page(about))

  add_tag_routes(config, tags)
}

fn add_tag_routes(config, tags: List(String)) {
  case tags {
    [] -> config
    [tag, ..rest] ->
      config
      |> config.route("/tags/" <> tag, tag_page(tag))
      |> add_tag_routes(rest)
  }
}

fn content_tags() -> Result(List(String), String) {
  use files <- result.try(
    simplifile.get_files("./content/posts")
    |> result.map_error(simplifile.describe_error),
  )
  files
  |> list.filter(fn(file) { string.ends_with(file, ".md") })
  |> list.try_map(fn(file) {
    simplifile.read(from: file)
    |> result.map(tags_from_markdown)
    |> result.map_error(fn(error) {
      "Could not read " <> file <> ": " <> simplifile.describe_error(error)
    })
  })
  |> result.map(fn(tags) {
    tags |> list.flatten |> list.unique |> list.sort(string.compare)
  })
}

fn read_content(path: String) -> Result(String, String) {
  simplifile.read(from: path)
  |> result.map_error(fn(error) {
    "Could not read " <> path <> ": " <> simplifile.describe_error(error)
  })
}

fn tags_from_markdown(markdown: String) -> List(String) {
  case string.split(markdown, "---") {
    [_, frontmatter, ..] ->
      tags_from_frontmatter(string.split(frontmatter, "\n"))
    _ -> []
  }
}

fn tags_from_frontmatter(lines: List(String)) -> List(String) {
  case lines {
    [] -> []
    [line, ..rest] ->
      case string.split_once(line, ":") {
        Ok(#("tags", tags)) ->
          list.append(
            string.split(string.trim(tags), " "),
            tags_from_frontmatter(rest),
          )
        _ -> tags_from_frontmatter(rest)
      }
  }
}

fn heading(tag: fn(List(Attribute(msg)), List(Element(msg))) -> Element(msg)) {
  fn(_attributes, id, children) { tag([attribute.id(id)], children) }
}

fn image(_attributes, src: String, alt: String, title) {
  let image =
    html.img([attribute.src(src), attribute.alt(alt), title_attribute(title)])

  case alt {
    "" -> html.figure([], [image])
    _ -> html.figure([], [image, html.figcaption([], [html.text(alt)])])
  }
}

fn title_attribute(title) {
  case title {
    option.Some(value) -> attribute.title(value)
    option.None -> attribute.none()
  }
}

fn post_page(
  post: blog_post.Post(Nil),
  _all_posts: List(blog_post.Post(Nil)),
) -> Element(Nil) {
  let tags = post_tags(post)
  let post_header =
    html.header([], [
      html.h1([], [html.text(post.title)]),
      html.div([attribute.class("post-meta")], [html.text(post_date(post))]),
      html.div(
        [attribute.class("tags")],
        list.map(tags, fn(tag) {
          html.a([attribute.class("tag"), attribute.href("/tags/" <> tag)], [
            html.text(tag),
          ])
        }),
      ),
    ])

  page(post.title, post.description, [
    html.article([attribute.class("post")], [post_header, ..post.contents]),
  ])
}

fn home_page(
  markdown: String,
) -> fn(List(blog_post.Post(Nil))) -> Element(Nil) {
  fn(posts) {
    page(site_config.title, "Welcome to James' blog.", [
      markdown_html(markdown),
      html.h2([], [html.text("Posts")]),
      post_list(posts),
    ])
  }
}

fn about_page(
  markdown: String,
) -> fn(List(blog_post.Post(Nil))) -> Element(Nil) {
  fn(_posts) { page("About", "About James.", [markdown_html(markdown)]) }
}

fn markdown_html(markdown: String) -> Element(Nil) {
  let options = mork.configure() |> mork.extended(True)
  unsafe_raw_html(
    "",
    "div",
    [],
    mork.parse_with_options(options, markdown) |> mork.to_html(),
  )
}

fn tag_page(tag: String) -> fn(List(blog_post.Post(Nil))) -> Element(Nil) {
  fn(posts) {
    page("Tag: " <> tag, "Posts tagged " <> tag, [
      html.h1([], [html.text("Tag: " <> tag)]),
      post_list(
        list.filter(posts, fn(post) { list.contains(post_tags(post), tag) }),
      ),
    ])
  }
}

fn post_list(posts: List(blog_post.Post(Nil))) -> Element(Nil) {
  html.ul(
    [attribute.class("post-list")],
    list.map(posts, fn(post) {
      html.li([], [
        html.div([attribute.class("post-meta")], [html.text(post_date(post))]),
        html.h3([], [
          html.a([attribute.href("/posts/" <> post.slug)], [
            html.text(post.title),
          ]),
        ]),
      ])
    }),
  )
}

fn post_tags(post: blog_post.Post(msg)) -> List(String) {
  post.extras
  |> dict.get("tags")
  |> result.unwrap("")
  |> string.split(" ")
  |> list.filter(fn(tag) { tag != "" })
}

fn post_date(post: blog_post.Post(msg)) -> String {
  post.extras |> dict.get("display_date") |> result.unwrap("")
}

fn page(
  title: String,
  description: String,
  content: List(Element(Nil)),
) -> Element(Nil) {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width,initial-scale=1"),
      ]),
      html.title([], title),
      html.link([attribute.rel("stylesheet"), attribute.href("/style.css")]),
      html.link([attribute.rel("canonical"), attribute.href(site_config.url)]),
      html.meta([attribute.name("description"), attribute.content(description)]),
      html.meta([
        attribute.attribute("property", "og:image"),
        attribute.content(site_config.url <> "/images/logo.png"),
      ]),
      html.meta([
        attribute.attribute("property", "og:title"),
        attribute.content(title),
      ]),
      html.meta([
        attribute.attribute("property", "og:url"),
        attribute.content(site_config.url),
      ]),
      html.meta([
        attribute.attribute("property", "og:description"),
        attribute.content(description),
      ]),
      html.meta([
        attribute.attribute("property", "og:site_name"),
        attribute.content(site_config.title),
      ]),
      html.meta([
        attribute.attribute("property", "og:type"),
        attribute.content("website"),
      ]),
      html.link([
        attribute.rel("sitemap"),
        attribute.attribute("type", "application/xml"),
        attribute.href("/sitemap.xml"),
      ]),
    ]),
    html.body([], [
      header(),
      html.main([attribute.class("wrapper")], content),
      footer(),
    ]),
  ])
}

fn header() -> Element(Nil) {
  html.header([attribute.class("site-header")], [
    html.div([attribute.class("wrapper site-nav")], [
      html.a([attribute.class("site-title"), attribute.href("/")], [
        html.text(site_config.title),
      ]),
      html.nav([attribute.class("nav-links")], [
        html.a([attribute.href("/")], [html.text("Home")]),
        html.a([attribute.href("/about")], [html.text("About")]),
      ]),
    ]),
  ])
}

fn footer() -> Element(Nil) {
  html.footer([attribute.class("site-footer")], [
    html.div([attribute.class("wrapper")], [
      html.p([], [
        html.text(
          "Welcome to my blog. Feel free to contact me on Mastodon to continue the conversation.",
        ),
      ]),
      html.ul(
        [attribute.class("social-links")],
        site_config.social_links()
          |> list.map(fn(link) { social_link(link.label, link.url) }),
      ),
    ]),
  ])
}

fn social_link(label: String, url: String) -> Element(Nil) {
  html.li([], [html.a([attribute.href(url)], [html.text(label)])])
}
