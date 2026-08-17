import blogatto/dev
import blogatto/error
import gleam/io
import site

pub fn main() {
  case site.site_config() {
    Error(message) -> io.println(message)
    Ok(config) -> {
      let result =
        config
        |> dev.new()
        |> dev.build_command("gleam run -m site")
        |> dev.port(3000)
        |> dev.start()

      case result {
        Ok(Nil) -> io.println("Development server stopped.")
        Error(err) -> io.println(error.describe_error(err))
      }
    }
  }
}
