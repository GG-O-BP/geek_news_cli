/// HTTP 클라이언트 모듈 - GeekNews 페이지 가져오기

import gleam/http/request
import gleam/httpc
import gleam/result

const base_url = "https://news.hada.io"

pub type FetchError {
  RequestError(String)
  HttpError(httpc.HttpError)
}

/// 메인 뉴스 목록 페이지 가져오기
pub fn fetch_news_list() -> Result(String, FetchError) {
  fetch_page("/")
}

/// 특정 페이지 가져오기
pub fn fetch_page(path: String) -> Result(String, FetchError) {
  let url = base_url <> path

  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { RequestError("Invalid URL: " <> url) }),
  )

  let config =
    httpc.configure()
    |> httpc.follow_redirects(True)
    |> httpc.timeout(30_000)

  use resp <- result.try(
    httpc.dispatch(config, req)
    |> result.map_error(HttpError),
  )

  Ok(resp.body)
}

/// 토픽 상세 페이지 가져오기
pub fn fetch_topic(topic_id: String) -> Result(String, FetchError) {
  fetch_page("/topic?id=" <> topic_id)
}

/// 페이지 번호로 뉴스 목록 가져오기
pub fn fetch_news_page(page: Int) -> Result(String, FetchError) {
  case page {
    1 -> fetch_page("/")
    n -> fetch_page("/news?p=" <> int_to_string(n))
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> {
      let div = n / 10
      let rem = n % 10
      int_to_string(div) <> int_to_string(rem)
    }
  }
}
