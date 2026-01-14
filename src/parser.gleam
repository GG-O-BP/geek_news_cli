/// HTML 파서 모듈 - GeekNews HTML을 뉴스 항목으로 변환
/// 정규표현식을 사용한 파싱

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/string
import news_item.{type NewsItem, NewsItem}
import topic_detail.{type TopicDetail, TopicDetail}

/// HTML 문자열에서 뉴스 항목 목록 추출
pub fn parse_news_list(html: String) -> List(NewsItem) {
  // 각 뉴스 항목을 id='tr 로 분할
  let parts = string.split(html, "id='tr")

  parts
  |> list.drop(1)
  |> list.filter_map(fn(part) { parse_news_block(part) })
}

/// 개별 뉴스 블록 파싱
/// 블록 형태: 1'><h1>제목</h1></a> <span class=topicurl>(도메인)</span>...
fn parse_news_block(block: String) -> Result(NewsItem, Nil) {
  // ID 추출 (블록 시작 부분의 숫자)
  let id = extract_id(block)

  // 제목 추출 (<h1> 태그 내용)
  let title = extract_title(block)

  // URL 추출 (topic?id=... 에서)
  let url = extract_url(block, id)

  // 도메인 추출 (topicurl 스팬 내용)
  let domain = extract_domain(block)

  // 포인트 추출 (tp... 스팬 내용)
  let points = extract_points(block)

  // 작성자 추출
  let author = extract_author(block)

  // 시간 추출
  let time_ago = extract_time(block)

  // 댓글 수 추출
  let comments = extract_comments(block)

  case id, title {
    Some(i), Some(t) ->
      Ok(NewsItem(
        id: i,
        title: t,
        url: option.unwrap(url, "https://news.hada.io/topic?id=" <> i),
        domain: option.unwrap(domain, ""),
        points: option.unwrap(points, 0),
        author: option.unwrap(author, ""),
        time_ago: option.unwrap(time_ago, ""),
        comments_count: option.unwrap(comments, 0),
      ))
    _, _ -> Error(Nil)
  }
}

/// ID 추출 (tp 스팬에서 실제 topic ID 추출)
fn extract_id(block: String) -> Option(String) {
  case regexp.from_string("id='tp(\\d+)'") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [Some(id), ..] -> Some(id)
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 제목 추출 (<h1> 태그 내용)
fn extract_title(block: String) -> Option(String) {
  case regexp.from_string("<h1>([^<]+)</h1>") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [Some(title), ..] -> Some(string.trim(title))
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// URL 추출 (topic?id=...)
fn extract_url(_block: String, id: Option(String)) -> Option(String) {
  case id {
    Some(i) -> Some("https://news.hada.io/topic?id=" <> i)
    None -> None
  }
}

/// 도메인 추출 (topicurl 내의 괄호 안 내용)
fn extract_domain(block: String) -> Option(String) {
  case regexp.from_string("topicurl[^>]*>\\(([^)]+)\\)") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [Some(domain), ..] -> Some(domain)
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 포인트 추출 (tp 스팬 내용)
fn extract_points(block: String) -> Option(Int) {
  case regexp.from_string("id='tp\\d+'>(\\d+)</span>\\s*points?") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [Some(num), ..] -> {
              case int.parse(num) {
                Ok(n) -> Some(n)
                Error(_) -> None
              }
            }
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 작성자 추출
fn extract_author(block: String) -> Option(String) {
  case regexp.from_string("/user\\?id=([^'\"]+)['\"][^>]*>([^<]+)</a>") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [_, Some(author), ..] -> Some(string.trim(author))
            [Some(author), ..] -> Some(string.trim(author))
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 시간 추출
fn extract_time(block: String) -> Option(String) {
  // "5시간전" 형태의 시간 추출
  case regexp.from_string("(\\d+(?:분|시간|일|개월|년)전)") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> Some(string.trim(match.content))
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 댓글 수 추출
fn extract_comments(block: String) -> Option(Int) {
  case regexp.from_string("댓글\\s*(\\d+)\\s*개") {
    Ok(re) -> {
      case regexp.scan(re, block) {
        [match, ..] -> {
          case match.submatches {
            [Some(num), ..] -> {
              case int.parse(num) {
                Ok(n) -> Some(n)
                Error(_) -> None
              }
            }
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

// ============================================
// 상세 페이지 파싱
// ============================================

/// 상세 페이지 HTML 파싱
pub fn parse_topic_detail(html: String, topic_id: String) -> Result(TopicDetail, Nil) {
  let title = extract_detail_title(html)
  let original_url = extract_original_url(html)
  let domain = extract_detail_domain(html)
  let points = extract_detail_points(html)
  let author = extract_detail_author(html)
  let time_ago = extract_detail_time(html)
  let comments = extract_detail_comments(html)
  let content = extract_content(html)

  case title {
    Some(t) ->
      Ok(TopicDetail(
        id: topic_id,
        title: t,
        original_url: option.unwrap(original_url, ""),
        domain: option.unwrap(domain, ""),
        points: option.unwrap(points, 0),
        author: option.unwrap(author, ""),
        time_ago: option.unwrap(time_ago, ""),
        comments_count: option.unwrap(comments, 0),
        content: option.unwrap(content, ""),
      ))
    None -> Error(Nil)
  }
}

/// 상세 페이지 제목 추출
fn extract_detail_title(html: String) -> Option(String) {
  case regexp.from_string("<h1>([^<]+)</h1>") {
    Ok(re) -> {
      case regexp.scan(re, html) {
        [match, ..] -> {
          case match.submatches {
            [Some(title), ..] -> Some(string.trim(title))
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 원문 URL 추출 (bold ud 클래스의 a 태그)
fn extract_original_url(html: String) -> Option(String) {
  case regexp.from_string("href='([^']+)'\\s+class='bold ud'") {
    Ok(re) -> {
      case regexp.scan(re, html) {
        [match, ..] -> {
          case match.submatches {
            [Some(url), ..] -> Some(url)
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 상세 페이지 도메인 추출
fn extract_detail_domain(html: String) -> Option(String) {
  extract_domain(html)
}

/// 상세 페이지 포인트 추출 (형태: <span id='tpNNNNN'>N</span>P)
fn extract_detail_points(html: String) -> Option(Int) {
  case regexp.from_string("id='tp\\d+'>(\\d+)</span>P") {
    Ok(re) -> {
      case regexp.scan(re, html) {
        [match, ..] -> {
          case match.submatches {
            [Some(num), ..] -> {
              case int.parse(num) {
                Ok(n) -> Some(n)
                Error(_) -> None
              }
            }
            _ -> None
          }
        }
        _ -> None
      }
    }
    Error(_) -> None
  }
}

/// 상세 페이지 작성자 추출
fn extract_detail_author(html: String) -> Option(String) {
  extract_author(html)
}

/// 상세 페이지 시간 추출
fn extract_detail_time(html: String) -> Option(String) {
  extract_time(html)
}

/// 상세 페이지 댓글 수 추출
fn extract_detail_comments(html: String) -> Option(Int) {
  extract_comments(html)
}

/// 본문 내용 추출 (topic_contents 스팬 내용)
fn extract_content(html: String) -> Option(String) {
  case string.split_once(html, "id='topic_contents'>") {
    Ok(#(_, after)) -> {
      case string.split_once(after, "</span>") {
        Ok(#(content, _)) -> {
          // HTML 태그 제거 및 정리
          let cleaned = clean_html_content(content)
          Some(cleaned)
        }
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}

/// HTML 태그를 텍스트로 변환
fn clean_html_content(html: String) -> String {
  html
  // 중첩 리스트의 ul 태그 제거
  |> string.replace("<ul>", "")
  |> string.replace("</ul>", "")
  // li 태그를 bullet point로 변환
  |> string.replace("<li>", "• ")
  |> string.replace("</li>", "\n")
  // 텍스트 스타일
  |> string.replace("<strong>", "")
  |> string.replace("</strong>", "")
  |> string.replace("<code>", "`")
  |> string.replace("</code>", "`")
  // 코드 블록
  |> string.replace("<pre>", "\n```\n")
  |> string.replace("</pre>", "\n```\n")
  // 단락과 줄바꿈
  |> string.replace("<p>", "\n")
  |> string.replace("</p>", "\n")
  |> string.replace("<br>", " ")
  |> string.replace("<br/>", " ")
  |> string.replace("<br />", " ")
  // HTML 엔티티
  |> string.replace("&amp;", "&")
  |> string.replace("&lt;", "<")
  |> string.replace("&gt;", ">")
  |> string.replace("&quot;", "\"")
  |> string.replace("&#39;", "'")
  |> string.replace("&nbsp;", " ")
  // 남은 태그 제거
  |> remove_remaining_tags()
  // bullet point 정리 (줄 시작에만 bullet이 오도록)
  |> clean_bullet_points()
  // 연속 줄바꿈 정리
  |> normalize_newlines()
  |> string.trim()
}

/// 남은 HTML 태그 제거
fn remove_remaining_tags(text: String) -> String {
  case regexp.from_string("<[^>]+>") {
    Ok(re) -> regexp.replace(re, text, "")
    Error(_) -> text
  }
}

/// bullet point 정리
fn clean_bullet_points(text: String) -> String {
  text
  // 줄 중간의 bullet을 줄바꿈 후 bullet으로
  |> string.replace(" • ", "\n• ")
  // 연속 공백 정리
  |> string.replace("  ", " ")
}

/// 연속 줄바꿈을 하나로 정리
fn normalize_newlines(text: String) -> String {
  // 2개 이상 연속 줄바꿈을 1개로
  case regexp.from_string("\n\\s*\n+") {
    Ok(re) -> {
      let result = regexp.replace(re, text, "\n")
      // 재귀적으로 정리
      case result == text {
        True -> result
        False -> normalize_newlines(result)
      }
    }
    Error(_) -> text
  }
}
