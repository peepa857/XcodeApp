import WidgetKit
import SwiftUI
import Intents

struct Learning {
  let content: String // 内容(EN)
  let translation: String // 内容(CN)
  let author: String // 作者
}

struct LearningRequest {
  static func request(completion: @escaping (Result<Learning, Error>) -> Void) {
    let url = URL(string: "https://rest.shanbay.com/api/v2/quote/quotes/today/")!
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      guard error == nil else {
        completion(.failure(error!))
        return
      }
      let Learning = LearningFromJson(fromData: data!)
      completion(.success(Learning))
    }
    task.resume()
  }

  static func LearningFromJson(fromData data: Data) -> Learning {
    let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    // 戻り値なしの場合
    guard let data = json["data"] as? [String: Any] else {
      return Learning(content: "NULL", translation: "NULL", author: "NULL")
    }
    let content = data["content"] as! String
    let translation = data["translation"] as! String
    let author = data["author"] as! String
    return Learning(content: content, translation: translation, author: author)
  }
}

struct LearningWidgetView: View {
  let entry: LearningEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.learning.content)
        .font(.system(size: 16))
        .fontWeight(.bold)
      Text(entry.learning.translation)
        .font(.system(size: 14))
      Text(entry.learning.author)
        .font(.system(size: 14))
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
    .padding()
    .background(LinearGradient(gradient: Gradient(colors: [.init(red: 144 / 255.0, green: 252 / 255.0, blue: 231 / 255.0), .init(red: 50 / 204, green: 188 / 255.0, blue: 231 / 255.0)]), startPoint: .topLeading, endPoint: .bottomTrailing))
  }
}

struct LearningEntry: TimelineEntry {
  var date: Date
  let learning: Learning // Learning model data
}

struct LearningProvider: TimelineProvider {
  func placeholder(in context: Context) -> LearningEntry {
    let learning = Learning(content: "内容(英語)", translation: "内容(中国語)", author: "作者")
    return LearningEntry(date: Date(), learning: learning)
  }
  func getSnapshot(in context: Context, completion: @escaping (LearningEntry) -> Void) {
    let learning = Learning(content: "内容(英語)", translation: "内容(中国語)", author: "作者")
    let entry = LearningEntry(date: Date(), learning: learning)
    completion(entry)
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<LearningEntry>) -> Void) {
    let currentDate = Date()
    // 2時間ごとのリクエスト
    let updateDate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)
    LearningRequest.request { result in
      let learning: Learning
      if case .success(let response) = result {
        learning = response
      } else {
        learning = Learning(content: "内容(英語)", translation: "内容(中国語)", author: "作者")
      }
      let entry = LearningEntry(date: currentDate, learning: learning)
      let timeline = Timeline(entries: [entry], policy: .after(updateDate!))
      completion(timeline)
    }
  }
}
@main
struct LearningWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LearningWidget", provider: LearningProvider()) { entry in
      LearningWidgetView(entry: entry)
    }
    .configurationDisplayName("毎日一言")
    .description("英語を勉強しよう")
    // supportedFamiliesのデフォルト値は下記の3つ
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
