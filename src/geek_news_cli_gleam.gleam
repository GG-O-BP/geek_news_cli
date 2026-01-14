/// GeekNews CLI - 메인 진입점
/// https://news.hada.io/ 웹사이트를 CLI로 탐색

import argv
import display
import gleam/int
import gleam/list
import gleam/result
import glint
import http_client
import parser

pub fn main() -> Nil {
  glint.new()
  |> glint.with_name("geeknews")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: list_command())
  |> glint.add(at: ["list"], do: list_command())
  |> glint.add(at: ["show"], do: show_command())
  |> glint.add(at: ["help"], do: help_command())
  |> glint.run(argv.load().arguments)
}

/// list 명령어 - 뉴스 목록 표시
fn list_command() -> glint.Command(Nil) {
  use <- glint.command_help("뉴스 목록을 표시합니다")
  use _named, args, _flags <- glint.command()

  let page = case args {
    [page_str, ..] ->
      result.unwrap(int.parse(page_str), 1)
    [] -> 1
  }

  display.print_loading()

  case http_client.fetch_news_page(page) {
    Ok(html) -> {
      let items = parser.parse_news_list(html)
      case list.length(items) {
        0 -> {
          display.print_error("뉴스 항목을 찾을 수 없습니다.")
        }
        _ -> {
          display.print_news_list(items)
        }
      }
    }
    Error(err) -> {
      case err {
        http_client.RequestError(msg) -> display.print_error(msg)
        http_client.HttpError(_) ->
          display.print_error("네트워크 오류가 발생했습니다.")
      }
    }
  }
}

/// show 명령어 - 특정 뉴스 상세 보기
fn show_command() -> glint.Command(Nil) {
  use <- glint.command_help("특정 뉴스의 상세 정보를 표시합니다")
  use _named, args, _flags <- glint.command()

  case args {
    [topic_id, ..] -> {
      display.print_loading()
      // 실제 상세 페이지를 가져와서 파싱
      case http_client.fetch_topic(topic_id) {
        Ok(html) -> {
          case parser.parse_topic_detail(html, topic_id) {
            Ok(detail) -> display.print_topic_detail(detail)
            Error(_) ->
              display.print_error("상세 정보를 파싱할 수 없습니다.")
          }
        }
        Error(_) -> display.print_error("네트워크 오류가 발생했습니다.")
      }
    }
    [] -> {
      display.print_error("뉴스 ID를 지정해주세요. 예: geeknews show 12345")
    }
  }
}

/// help 명령어 - 도움말 표시
fn help_command() -> glint.Command(Nil) {
  use <- glint.command_help("도움말을 표시합니다")
  use _named, _args, _flags <- glint.command()
  display.print_help()
}
