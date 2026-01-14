/// 상세 페이지 데이터 모델

pub type TopicDetail {
  TopicDetail(
    id: String,
    title: String,
    original_url: String,
    domain: String,
    points: Int,
    author: String,
    time_ago: String,
    comments_count: Int,
    content: String,
  )
}
