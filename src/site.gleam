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
import lustre/element.{type Element}
import lustre/element/html

const site_url = "https://jamestjw.github.io"

pub fn main() {
  case blogatto.build(site_config()) {
    Ok(Nil) -> io.println("Site built successfully!")
    Error(err) -> io.println(error.describe_error(err))
  }
}

pub fn site_config() {
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
    config.new(site_url)
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.post(posts)
    |> config.route("/", home_page)
    |> config.route("/about", about_page)

  add_tag_routes(config, tags())
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

fn tags() -> List(String) {
  [
    "awk", "c", "canada", "chess", "comp_sci", "compiler", "data_processing",
    "discord", "foreign_languages", "french", "gcp", "git", "productivity",
    "random", "serverless", "soen", "tutorial", "type_theory",
  ]
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

fn home_page(posts: List(blog_post.Post(Nil))) -> Element(Nil) {
  page("James' Adventures!", "Welcome to James' blog.", [
    html.h2([attribute.id("home")], [html.text("Home")]),
    html.p([], [
      html.text(
        "Bienvenue sur le blog de James! Je vous parlerai des choses qui m'intéressent, en ce moment il s'agit surtout des bases de données, de la latence p99 et du cyclisme.",
      ),
    ]),
    html.p([], [
      html.text("Did that catch you by surprise? My name is "),
      html.strong([], [html.text("James")]),
      html.text(
        " and welcome to my blog! Like all other Malaysians, I pride myself on being a polyglot (one of who knows many languages). In descending order of fluency, I speak English, Chinese, French and Malay. In this blog, I share my ideas and experiences related to tech and some of my thoughts on what's going on in my life. From time to time, I shall also share my language learning experiences! I am an aficionado of chess, I intend to share to more of my chess related experiences here. Academically, my interests lie in databases and type theory. Naturally, I'm a big fan of functional programming. Oh and when I write in English, I insist on spelling things the British way.",
      ),
    ]),
    html.h2([], [html.text("Posts")]),
    post_list(posts),
  ])
}

fn about_page(_posts: List(blog_post.Post(Nil))) -> Element(Nil) {
  page("About", "About James.", [
    html.h1([attribute.id("about")], [html.text("About")]),
    html.p([], [
      html.text(
        "Hello there and welcome to my blog! My name is James, I am 28 years old this year (2025) and I'm based in Montréal, Québec. I am currently working as a Software Developer. My recent interests include programming languages, databases, foreign languages, cycling and chess. I plan to share my ideas and thoughts on these subjects more frequently throughout the span of the next year in this blog!",
      ),
    ]),
    html.p([], [
      html.text(
        "I graduated from l'Université de Montréal in August 2024 where I did a bunch of work on programming languages and type theory. I'm especially a fan of functional programming languages, my favourite one being OCaml at the moment. At the present moment I'm primarily interested in using Rust for high performance stuff.",
      ),
    ]),
    html.p([], [
      html.text(
        "Connect and network with me on various platforms below. Feel free to strike up a conversation with me on just about any topic.",
      ),
    ]),
  ])
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
      html.link([attribute.rel("canonical"), attribute.href(site_url)]),
      html.meta([attribute.name("description"), attribute.content(description)]),
      html.meta([
        attribute.attribute("property", "og:image"),
        attribute.content(site_url <> "/images/logo.png"),
      ]),
      html.meta([
        attribute.attribute("property", "og:title"),
        attribute.content(title),
      ]),
      html.meta([
        attribute.attribute("property", "og:url"),
        attribute.content(site_url),
      ]),
      html.meta([
        attribute.attribute("property", "og:description"),
        attribute.content(description),
      ]),
      html.meta([
        attribute.attribute("property", "og:site_name"),
        attribute.content("James' Adventures!"),
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
        html.text("James' Adventures!"),
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
      html.ul([attribute.class("social-links")], [
        social_link("GitHub", "https://github.com/jamestjw"),
        social_link("LinkedIn", "https://www.linkedin.com/in/jamestjw"),
        social_link("Mastodon", "https://types.pl/@jamestjw"),
        social_link("Twitter", "https://www.twitter.com/youknowjamest"),
      ]),
    ]),
  ])
}

fn social_link(label: String, url: String) -> Element(Nil) {
  html.li([], [html.a([attribute.href(url)], [html.text(label)])])
}
