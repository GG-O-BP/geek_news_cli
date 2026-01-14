/// 뉴스 항목 데이터 모델

pub type NewsItem {
  NewsItem(
    id: String,
    title: String,
    url: String,
    domain: String,
    points: Int,
    author: String,
    time_ago: String,
    comments_count: Int,
  )
}

pub fn new(
  id: String,
  title: String,
  url: String,
  domain: String,
  points: Int,
  author: String,
  time_ago: String,
  comments_count: Int,
) -> NewsItem {
  NewsItem(id, title, url, domain, points, author, time_ago, comments_count)
}
