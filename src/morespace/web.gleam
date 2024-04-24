import birl
import gleam/http
import gleam/int
import gleam/list
import gleam/string
import gleam/string_builder.{type StringBuilder}
import nakai
import nakai/attr
import nakai/html
import wisp

pub type Context {
  Context(static_directory: String)
}

pub type Quote {
  Quote(text: String, author: String)
}

const quotes = [
  Quote(
    "Awareness is like the sun. When it shines on things, they are transformed.",
    "Thich Nhat Hanh",
  ),
  Quote(
    "Realize deeply that the present moment is all you ever have. Make the NOW the primary focus of your life.",
    "Eckhart Tolle",
  ),
  Quote(
    "The future is completely open, and we are writing it moment to moment.",
    "Pema Chodron",
  ),
  Quote(
    "Breathing in, I calm body and mind. Breathing out, I smile. Dwelling in the present moment I know this is the only moment.",
    "Thich Nhat Hanh",
  ),
  Quote("Change is one thing. Acceptance is another.", "Arundhati Roy"),
  Quote(
    "Life is all memory, except for the one present moment that goes by you so quickly you hardly catch it going.",
    "Tennessee Williams",
  ),
  Quote(
    "Perhaps a man really dies when his brain stops, when he loses the power to take in a new idea.",
    "George Orwell",
  ),
  Quote("Depression is rage spread thin.", "George Santayana"),
  Quote(
    "There must have been a moment, at the beginning, were we could have said — no. But somehow we missed it.",
    "Tom Stoppard",
  ),
  Quote("The truly free man creates his own morality.", "Alexander Herzen"),
  Quote(
    "While timorous knowledge stands considering, audacious ignorance hath done the deed.",
    "Samuel Daniel",
  ),
  Quote(
    "If one man has a dollar he didn't work for, some other man worked for a dollar he didn't get.",
    "Big Bill Haywood",
  ),
  Quote(
    "Don't rush me, sonny. You rush a miracle man, you get rotten miracles.",
    "Miracle Max",
  ),
  Quote("Compassion costs nothing", ""),
]

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- detail_log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

pub fn full_page() -> StringBuilder {
  html.div(
    [
      attr.class("pane"),
      attr.Attr("hx-get", "/quote"),
      attr.Attr("hx-trigger", "load, every 20s"),
      attr.Attr("hx-swap", "innerHTML swap:2s"),
    ],
    [
      html.Head([
        html.meta([attr.http_equiv("X-UA-Compatible"), attr.content("IE=edge")]),
        html.meta([
          attr.name("viewport"),
          attr.content("width=device-width, initial-scale=1"),
        ]),
        html.title("In this Shared Space"),
        html.link([attr.rel("icon"), attr.href("static/img/favicon.png")]),
        html.link([attr.rel("stylesheet"), attr.href("static/css/space.css")]),
        html.Element("script", [attr.src("static/js/htmx.min.js")], []),
      ]),
    ],
  )
  |> nakai.to_string_builder
}

pub fn quote_html() -> StringBuilder {
  let assert Ok(Quote(text, author)) =
    list.shuffle(quotes)
    |> list.first

  let author_div = case author {
    "" -> html.div([attr.class("signature")], [])
    _ ->
      html.div([attr.class("signature")], [
        html.UnsafeInlineHtml("&mdash; "),
        html.Text(author),
      ])
  }

  html.Fragment([
    html.div([attr.class("content")], [html.Text(text)]),
    author_div,
  ])
  |> nakai.to_inline_string_builder
}

pub fn detail_log_request(
  req: wisp.Request,
  handler: fn() -> wisp.Response,
) -> wisp.Response {
  let response = handler()

  let now = birl.now()

  let client_ip = {
    case list.key_find(req.headers, "fly-client-ip") {
      Ok(ip) -> ip
      Error(_) -> "unknown_ip"
    }
  }

  [
    birl.to_iso8601(now),
    " ",
    client_ip,
    " ",
    int.to_string(response.status),
    " ",
    string.uppercase(http.method_to_string(req.method)),
    " ",
    req.path,
  ]
  |> string.concat
  |> wisp.log_info
  response
}
