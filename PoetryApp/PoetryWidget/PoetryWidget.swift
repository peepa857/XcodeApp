import WidgetKit
import SwiftUI
import Intents

struct Poetry {
  let content: String // 内容
  let origin: String // 名字
  let author: String // 作者
}

struct PoetryRequest {
  static func request(completion: @escaping (Result<Poetry, Error>) -> Void) {
    let url = URL(string: "https://v1.alapi.cn/api/shici?type=shuqing")!
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      guard error == nil else {
        completion(.failure(error!))
        return
      }
      let poetry = poetryFromJson(fromData: data!)
      completion(.success(poetry))
    }
    task.resume()
  }
    
  static func poetryFromJson(fromData data: Data) -> Poetry {
    let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    //因为免费接口请求频率问题，如果太频繁了，请求可能失败，这里做下处理，放置crash
    guard let data = json["data"] as? [String: Any] else {
      return Poetry(content: "诗词加载失败，请稍微再试！", origin: "耐依福", author: "佚名")
    }
    let content = data["content"] as! String
    let origin = data["origin"] as! String
    let author = data["author"] as! String
    return Poetry(content: content, origin: origin, author: author)
  }
}

struct PoetryWidgetView: View {
  let entry: PoetryEntry
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.poetry.origin)
        .font(.system(size: 20))
        .fontWeight(.bold)
      Text(entry.poetry.author)
        .font(.system(size: 16))
      Text(entry.poetry.content)
        .font(.system(size: 18))
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
    .padding()
    .background(LinearGradient(gradient: Gradient(colors: [.init(red: 144 / 255.0, green: 252 / 255.0, blue: 231 / 255.0), .init(red: 50 / 204, green: 188 / 255.0, blue: 231 / 255.0)]), startPoint: .topLeading, endPoint: .bottomTrailing))
  }
}

struct PoetryEntry: TimelineEntry {
  var date: Date
  let poetry: Poetry // 可以理解为绑定了Poetry模型数据
}

struct PoetryProvider: TimelineProvider {
  func placeholder(in context: Context) -> PoetryEntry {
    let poetry = Poetry(content: "床前明月光，疑似地上霜", origin: "耐依福", author: "佚名")
    return PoetryEntry(date: Date(), poetry: poetry)
  }
  func getSnapshot(in context: Context, completion: @escaping (PoetryEntry) -> Void) {
    let poetry = Poetry(content: "床前明月光，疑似地上霜", origin: "月光光", author: "佚名")
    let entry = PoetryEntry(date: Date(), poetry: poetry)
    completion(entry)
  }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PoetryEntry>) -> Void) {
    let currentDate = Date()
    // 下一次更新间隔以分钟为单位，间隔5分钟请求一次新的数据
    let updateDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)
    PoetryRequest.request { result in
      let poetry: Poetry
      if case .success(let response) = result {
        poetry = response
      } else {
        poetry = Poetry(content: "诗词加载失败，请稍微再试！", origin: "耐依福", author: "佚名")
      }
      let entry = PoetryEntry(date: currentDate, poetry: poetry)
      let timeline = Timeline(entries: [entry], policy: .after(updateDate!))
      completion(timeline)
    }
  }
}

@main
struct PoetryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PoetryWidget", provider: PoetryProvider()) { entry in
      PoetryWidgetView(entry: entry)
    }
    .configurationDisplayName("每日一诗")
    .description("默读并背诵全文")
    //supportedFamiliesのデフォルト値は下記の3つ
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
