/// 터미널 출력 모듈 - 뉴스 항목을 보기 좋게 표시

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam_community/ansi
import news_item.{type NewsItem}
import topic_detail.{type TopicDetail}

/// 뉴스 목록 출력
pub fn print_news_list(items: List(NewsItem)) -> Nil {
  print_header()
  print_separator()
  list.index_map(items, fn(item, index) {
    print_news_item(item, index + 1)
  })
  print_separator()
  print_footer(list.length(items))
}

/// 헤더 출력
fn print_header() -> Nil {
  io.println("")
  io.println(
    ansi.bold(ansi.cyan("  GeekNews - 개발/기술 뉴스 (https://news.hada.io)")),
  )
  io.println("")
}

/// 구분선 출력
fn print_separator() -> Nil {
  io.println(ansi.dim(string.repeat("─", 70)))
}

/// 개별 뉴스 항목 출력
fn print_news_item(item: NewsItem, index: Int) -> Nil {
  let index_str = case index < 10 {
    True -> " " <> int.to_string(index)
    False -> int.to_string(index)
  }

  // 제목 라인
  let title_line =
    ansi.yellow(index_str <> ". ")
    <> ansi.bold(item.title)
    <> case item.domain {
      "" -> ""
      d -> " " <> ansi.dim("(" <> d <> ")")
    }

  io.println(title_line)

  // 메타 정보 라인
  let meta_line =
    "    "
    <> ansi.green(int.to_string(item.points) <> " points")
    <> ansi.dim(" | ")
    <> ansi.blue(item.author)
    <> ansi.dim(" | ")
    <> item.time_ago
    <> ansi.dim(" | ")
    <> ansi.magenta("댓글 " <> int.to_string(item.comments_count) <> "개")
    <> ansi.dim(" [ID: " <> item.id <> "]")

  io.println(meta_line)
  io.println("")
}

/// 푸터 출력
fn print_footer(count: Int) -> Nil {
  io.println("")
  io.println(
    ansi.dim("  총 " <> int.to_string(count) <> "개 항목 | "),
  )
  io.println(ansi.dim("  명령어: list, show <id>, next, prev, help, quit"))
  io.println("")
}

/// 에러 메시지 출력
pub fn print_error(message: String) -> Nil {
  io.println(ansi.red("오류: " <> message))
}

/// 성공 메시지 출력
pub fn print_success(message: String) -> Nil {
  io.println(ansi.green("✓ " <> message))
}

/// 정보 메시지 출력
pub fn print_info(message: String) -> Nil {
  io.println(ansi.cyan("ℹ " <> message))
}

/// 도움말 출력
pub fn print_help() -> Nil {
  io.println("")
  io.println(ansi.bold(ansi.cyan("GeekNews CLI - 사용법")))
  io.println("")
  print_separator()
  io.println("")
  io.println(ansi.bold("명령어:"))
  io.println("")
  io.println(
    "  "
    <> ansi.yellow("list")
    <> "            뉴스 목록 보기 (기본 명령)",
  )
  io.println(
    "  " <> ansi.yellow("list <page>") <> "     특정 페이지의 뉴스 목록 보기",
  )
  io.println(
    "  " <> ansi.yellow("show <id>") <> "       특정 뉴스의 상세 정보 보기",
  )
  io.println("  " <> ansi.yellow("open <id>") <> "       뉴스 URL을 브라우저에서 열기")
  io.println("  " <> ansi.yellow("help") <> "            이 도움말 보기")
  io.println("")
  io.println(ansi.bold("예시:"))
  io.println("")
  io.println(ansi.dim("  $ geek_news_cli_gleam list"))
  io.println(ansi.dim("  $ geek_news_cli_gleam list 2"))
  io.println(ansi.dim("  $ geek_news_cli_gleam show 12345"))
  io.println("")
}

/// 상세 정보 출력
pub fn print_news_detail(item: NewsItem) -> Nil {
  io.println("")
  print_separator()
  io.println("")
  io.println(ansi.bold(ansi.cyan(item.title)))
  io.println("")
  io.println("  URL: " <> ansi.blue(item.url))
  io.println("  도메인: " <> item.domain)
  io.println("")
  io.println(
    "  "
    <> ansi.green(int.to_string(item.points) <> " points")
    <> " | "
    <> ansi.blue(item.author)
    <> " | "
    <> item.time_ago,
  )
  io.println(
    "  댓글: " <> ansi.magenta(int.to_string(item.comments_count) <> "개"),
  )
  io.println("")
  io.println(
    "  상세 페이지: "
    <> ansi.dim("https://news.hada.io/topic?id=" <> item.id),
  )
  io.println("")
  print_separator()
  io.println("")
}

/// 로딩 메시지 출력
pub fn print_loading() -> Nil {
  io.println(ansi.dim("불러오는 중..."))
}

/// 본문 내용 줄 출력
fn print_content_lines(lines: List(String), _prev_was_bullet: Bool) -> Nil {
  case lines {
    [] -> Nil
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case trimmed {
        // 빈 줄이나 bullet만 있는 줄은 건너뛰기
        "" -> print_content_lines(rest, False)
        "•" -> print_content_lines(rest, True)
        // 실제 내용이 있는 줄
        l -> {
          io.println("  " <> l)
          print_content_lines(rest, string.starts_with(l, "•"))
        }
      }
    }
  }
}

/// 상세 페이지 출력 (실제 상세 내용 포함)
pub fn print_topic_detail(detail: TopicDetail) -> Nil {
  io.println("")
  print_separator()
  io.println("")

  // 제목
  io.println(ansi.bold(ansi.cyan(detail.title)))
  io.println("")

  // 원문 URL
  case detail.original_url {
    "" -> Nil
    url -> {
      io.println("  " <> ansi.yellow("원문: ") <> ansi.blue(url))
      Nil
    }
  }

  // 도메인
  case detail.domain {
    "" -> Nil
    d -> {
      io.println("  " <> ansi.yellow("도메인: ") <> d)
      Nil
    }
  }

  io.println("")

  // 메타 정보
  io.println(
    "  "
    <> ansi.green(int.to_string(detail.points) <> " points")
    <> " | "
    <> ansi.blue(detail.author)
    <> " | "
    <> detail.time_ago
    <> " | "
    <> ansi.magenta("댓글 " <> int.to_string(detail.comments_count) <> "개"),
  )

  io.println("")
  print_separator()
  io.println("")

  // 본문 내용
  case detail.content {
    "" -> {
      io.println(ansi.dim("  (본문 내용 없음)"))
      Nil
    }
    content -> {
      io.println(ansi.bold("요약:"))
      io.println("")
      // 줄바꿈으로 분할하여 출력 (연속 빈 줄 방지)
      print_content_lines(string.split(content, "\n"), False)
      Nil
    }
  }

  io.println("")
  print_separator()
  io.println("")

  // 상세 페이지 링크
  io.println(
    ansi.dim("  GeekNews 페이지: https://news.hada.io/topic?id=" <> detail.id),
  )
  io.println("")
}
