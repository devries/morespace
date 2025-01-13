import gleam/http.{Get}
import gleam/http/request
import morespace/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> main_page(req)
    ["quote"] -> quote_response(req)
    _ -> wisp.not_found()
  }
}

fn main_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let html = web.full_page()
  wisp.ok()
  |> wisp.html_body(html)
}

fn quote_response(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let resp = wisp.ok() |> wisp.set_header("cache-control", "no-cache, no-store")

  case request.get_header(req, "accept") {
    Ok(value) if value == "application/json" ->
      wisp.json_body(resp, web.quote_json())
    _ -> wisp.html_body(resp, web.quote_html())
  }
}
