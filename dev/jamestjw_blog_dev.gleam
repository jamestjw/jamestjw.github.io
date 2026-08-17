import blogatto/dev
import blogatto/error
import gleam/io
import site

pub fn main() {
  let result =
    site.site_config()
    |> dev.new()
    |> dev.build_command("gleam run -m site")
    |> dev.port(3000)
    |> dev.start()

  case result {
    Ok(Nil) -> io.println("Development server stopped.")
    Error(err) -> io.println(error.describe_error(err))
  }
}
