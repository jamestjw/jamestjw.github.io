pub const title = "James' Adventures!"

pub const url = "https://jamestjw.github.io"

pub type SocialLink {
  SocialLink(label: String, url: String)
}

pub fn social_links() -> List(SocialLink) {
  [
    SocialLink("GitHub", "https://github.com/jamestjw"),
    SocialLink("LinkedIn", "https://www.linkedin.com/in/jamestjw"),
    SocialLink("Mastodon", "https://types.pl/@jamestjw"),
    SocialLink("Twitter", "https://www.twitter.com/youknowjamest"),
  ]
}
