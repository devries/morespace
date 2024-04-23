import gleam/erlang/process
import mist
import morespace/router
import morespace/web.{Context}
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory: static_directory())

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("morespace")
  priv_directory <> "/static"
}
