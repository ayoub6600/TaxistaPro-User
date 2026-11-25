import ActivityKit
import AppIntents
import Foundation

/// The ride on the iPhone lock screen and in the Dynamic Island (Live Activity, iOS 17.2+): the server
/// starts it with Apple's push-to-start («attributes-type»: TaxistaRideAttributes) once a captain takes
/// the ride, and moves it with each card's own update token: coming → arrived → on_trip → rate → done.
/// This file is in the app AND the widget extension: the card's data, the five stars (an App Intent that
/// iOS runs inside the app, even on a locked phone) and the rating sent to the server.
@available(iOS 16.1, *)
struct TaxistaRideAttributes: ActivityAttributes {
  /// what the server's pushes change on the card
  struct ContentState: Codable, Hashable {
    /// coming | arrived | on_trip | rate | done (anything else: title and subtitle only)
    var stage: String
    var title: String
    var subtitle: String
    var etaMinutes: Int?
    /// 0…1 along the way (to the rider while coming, to the destination on the trip)
    var progress: Double?
    /// «11 د.ل»
    var payAmount: String?
    var payLine: String?
    var note: String?
    /// the stars he gave (gold on the card)
    var rated: Int?

    enum CodingKeys: String, CodingKey {
      case stage, title, subtitle, progress, note, rated
      case etaMinutes = "eta_minutes"
      case payAmount = "pay_amount"
      case payLine = "pay_line"
    }
  }

  var requestId: String
  var ratingToken: String
  var driverName: String
  var plate: String
  var car: String

  enum CodingKeys: String, CodingKey {
    case requestId = "request_id"
    case ratingToken = "rating_token"
    case driverName = "driver_name"
    case plate, car
  }

  /// a tap on the card: the app opens (on its ride)
  var openURL: URL {
    var c = URLComponents()
    c.scheme = "taxistarider"
    c.host = "ride-live"
    c.path = "/open"
    c.queryItems = [URLQueryItem(name: "id", value: requestId)]
    return c.url ?? URL(string: "taxistarider://ride-live")!
  }

  /// «حمزة» from «حمزة الفيتوري»
  var firstName: String {
    driverName.split(separator: " ").first.map(String.init) ?? driverName
  }
}

// Lenient reading: a number sent as text (or text as a number), a missing key, null — the card still
// shows. Kept in extensions so the memberwise initialisers stay.
@available(iOS 16.1, *)
extension TaxistaRideAttributes {
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    requestId = c.looseString(.requestId) ?? ""
    ratingToken = c.looseString(.ratingToken) ?? ""
    driverName = c.looseString(.driverName) ?? ""
    plate = c.looseString(.plate) ?? ""
    car = c.looseString(.car) ?? ""
  }
}

@available(iOS 16.1, *)
extension TaxistaRideAttributes.ContentState {
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    stage = c.looseString(.stage) ?? ""
    title = c.looseString(.title) ?? ""
    subtitle = c.looseString(.subtitle) ?? ""
    etaMinutes = c.looseDouble(.etaMinutes).map { Int($0.rounded()) }
    progress = c.looseDouble(.progress).map { $0 > 1 && $0 <= 100 ? $0 / 100 : $0 }
    payAmount = c.looseString(.payAmount)
    payLine = c.looseString(.payLine)
    note = c.looseString(.note)
    rated = c.looseDouble(.rated).map { Int($0.rounded()) }
  }
}

fileprivate extension KeyedDecodingContainer {
  func looseString(_ key: Key) -> String? {
    if let s = try? decodeIfPresent(String.self, forKey: key) { return s }
    if let i = try? decodeIfPresent(Int.self, forKey: key) { return String(i) }
    if let d = try? decodeIfPresent(Double.self, forKey: key) { return String(d) }
    return nil
  }

  /// a number, kept to a sane range (a wrong value never crashes the card)
  func looseDouble(_ key: Key) -> Double? {
    var d = try? decodeIfPresent(Double.self, forKey: key)
    if d == nil, let s = try? decodeIfPresent(String.self, forKey: key) {
      d = Double(s.trimmingCharacters(in: .whitespaces))
    }
    guard let v = d, v.isFinite else { return nil }
    return min(max(v, -100_000), 100_000)
  }
}

/// One star on the card: runs in the app's process in the background, the app stays closed
@available(iOS 17.0, *)
struct RateRideIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "تقييم الرحلة"
  static var isDiscoverable: Bool = false

  @Parameter(title: "الرحلة") var requestId: String
  @Parameter(title: "الرمز") var token: String
  @Parameter(title: "النجوم") var stars: Int

  init() {}

  init(requestId: String, token: String, stars: Int) {
    self.requestId = requestId
    self.token = token
    self.stars = stars
  }

  func perform() async throws -> some IntentResult {
    await RideLiveRating.rate(requestId: requestId, token: token, stars: stars)
    return .result()
  }
}

/// The stars to the server (no login: the card's own rating token) and the answer on the card
@available(iOS 16.2, *)
enum RideLiveRating {
  static let sendingNote = "جاري إرسال تقييمك…"
  static let failedNote = "ما وصلش التقييم، افتح التطبيق"

  static func post(requestId: String, token: String, stars: Int) async -> Bool {
    guard let url = URL(string: RecurringDayAnswer.apiBase + "api/v1/request/live-rate") else { return false }
    var req = URLRequest(url: url, timeoutInterval: 15)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["request_id": requestId, "t": token, "rating": stars])
    for attempt in 0..<2 {
      if let reply = try? await URLSession.shared.data(for: req) {
        let status = (reply.1 as? HTTPURLResponse)?.statusCode ?? 0
        if (200..<300).contains(status) {
          let j = (try? JSONSerialization.jsonObject(with: reply.0)) as? [String: Any]
          return (j?["success"] as? Bool) != false
        }
        if status < 500 { return false } // refused (token, already rated…): a retry would not help
      }
      if attempt == 0 { try? await Task.sleep(nanoseconds: 3_000_000_000) }
    }
    return false
  }

  /// The stars turn gold at once («جاري إرسال تقييمك…», no second tap meanwhile; stale after 25 s in case
  /// iOS stops the app mid-way, then the stars come back). Nothing says «thank you» before the server does.
  static func rate(requestId: String, token: String, stars: Int) async {
    let activity = Activity<TaxistaRideAttributes>.activities.first { $0.attributes.requestId == requestId }
    let before = activity?.content.state
    if let a = activity, var s = before {
      s.rated = stars
      s.note = sendingNote
      await a.update(ActivityContent(state: s, staleDate: Date().addingTimeInterval(25)))
    }
    let ok = await post(requestId: requestId, token: token, stars: stars)
    guard let a = activity else { return }
    var s = before ?? a.content.state
    if ok {
      s.stage = "done"
      s.title = "شكرًا على تقييمك"
      s.subtitle = "تقييمك: \(stars) من 5"
      s.rated = stars
      s.note = nil
      s.etaMinutes = nil
      s.progress = nil
      await a.end(ActivityContent(state: s, staleDate: nil), dismissalPolicy: .after(Date().addingTimeInterval(6)))
    } else {
      s.rated = nil
      s.note = failedNote
      await a.update(ActivityContent(state: s, staleDate: nil))
    }
  }
}
