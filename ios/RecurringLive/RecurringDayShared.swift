import ActivityKit
import AppIntents
import Foundation

/// «🚕 مشوارك غدًا» on the iPhone lock screen (Live Activity, iOS 17+), both buttons in view.
/// This file is in the app AND the widget extension: the card's data, its ✅ تأكيد button (an App
/// Intent that iOS runs inside the app, even when the phone is locked) and the answer to the server.
/// ⏭ تخطي is a link instead: opening the app from a locked phone asks Face ID / the code first, so
/// nobody else holding the phone can skip his day.
@available(iOS 16.1, *)
struct RecurringDayAttributes: ActivityAttributes {
  /// what changes on the card: the question, then the server's answer
  struct ContentState: Codable, Hashable {
    /// ask | retry | done | skipped | expired | off | demo
    var phase: String
    var title: String
    var line: String
    var note: String
  }

  var occurrenceId: String
  var recurringId: String
  var dayToken: String
  /// the ride's time as the rider saw it («2026-11-14 09:30»): an old card after a change never acts
  var seenAt: String
  /// unix seconds: half an hour before the ride, the buttons stop
  var deadline: Double

  var isDemo: Bool { occurrenceId == "demo" }

  var skipURL: URL {
    var c = URLComponents()
    c.scheme = "taxistarider"
    c.host = "recurring-day"
    c.path = "/skip"
    c.queryItems = [URLQueryItem(name: "id", value: occurrenceId), URLQueryItem(name: "t", value: dayToken), URLQueryItem(name: "s", value: seenAt)]
    return c.url ?? URL(string: "taxistarider://recurring-day")!
  }
}

/// ✅ تأكيد on the card: runs in the app's process in the background, the app stays closed
@available(iOS 17.0, *)
struct RecurringConfirmIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "تأكيد مشوار الغد"
  static var isDiscoverable: Bool = false

  @Parameter(title: "اليوم") var occurrenceId: String
  @Parameter(title: "الرمز") var dayToken: String
  @Parameter(title: "الموعد") var seenAt: String

  init() {}

  init(occurrenceId: String, dayToken: String, seenAt: String) {
    self.occurrenceId = occurrenceId
    self.dayToken = dayToken
    self.seenAt = seenAt
  }

  func perform() async throws -> some IntentResult {
    await RecurringDayAnswer.answer(occurrenceId: occurrenceId, answer: "attend", token: dayToken, seenAt: seenAt)
    return .result()
  }
}

/// one answer (attend | skip) to the server and its words on the card. The server re-checks the day
/// (its token, its time, its deadline, an earlier answer); nothing is shown as done unless it is.
@available(iOS 16.2, *)
enum RecurringDayAnswer {
  static var apiBase: String {
    var base = UserDefaults.standard.string(forKey: "flutter.taxista_api_base") ?? "https://taxista.aljidartech.com/"
    if !base.hasSuffix("/") { base += "/" }
    return base
  }

  struct Reply {
    var ok: Bool
    var network: Bool
    var title: String
    var message: String
  }

  static func post(occurrenceId: String, answer: String, token: String, seenAt: String) async -> Reply {
    guard let url = URL(string: apiBase + "api/v1/recurring-day/\(occurrenceId)/\(answer)") else {
      return Reply(ok: false, network: false, title: "ما تسجلش ردك", message: "افتح «رحلاتي المتكررة» ورد من هناك.")
    }
    var req = URLRequest(url: url, timeoutInterval: 15)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["t": token, "seen_at": seenAt, "platform": "ios_live"])
    for attempt in 0..<2 {
      do {
        let (body, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if let j = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any], let title = j["title"] as? String {
          return Reply(ok: (j["success"] as? Bool) == true, network: false, title: title, message: (j["message"] as? String) ?? "")
        }
        if status >= 500 && attempt == 0 { try? await Task.sleep(nanoseconds: 3_000_000_000); continue }
        return Reply(ok: false, network: true, title: "ما تسجلش ردك", message: "ما وصلناش رد واضح من تاكسيستا (\(status)). جرب مرة ثانية.")
      } catch {
        if attempt == 0 { try? await Task.sleep(nanoseconds: 3_000_000_000); continue }
      }
    }
    return Reply(ok: false, network: true, title: "ما تسجلش ردك", message: "ما فيش اتصال بالإنترنت. اضغط مرة ثانية لما يرجع الاتصال.")
  }

  /// the answer, then the card: the server's words and off the lock screen a little later; a lost
  /// connection keeps the buttons with a ⚠️ line, to press again
  @discardableResult
  static func answer(occurrenceId: String, answer: String, token: String, seenAt: String) async -> Reply {
    let activity = Activity<RecurringDayAttributes>.activities.first { $0.attributes.occurrenceId == occurrenceId }
    if occurrenceId == "demo" {
      let reply = Reply(ok: true, network: false, title: answer == "attend" ? "✅ تجربة: زر التأكيد يشتغل" : "⏭ تجربة: زر التخطي يشتغل",
                        message: "هذه تجربة فقط؛ ما تسجل شي في حسابك.")
      if let a = activity {
        await a.end(ActivityContent(state: .init(phase: "demo", title: reply.title, line: reply.message, note: ""), staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(60)))
      }
      return reply
    }
    let reply = await post(occurrenceId: occurrenceId, answer: answer, token: token, seenAt: seenAt)
    guard let a = activity else { return reply }
    if reply.network {
      let s = a.content.state
      await a.update(ActivityContent(state: .init(phase: "retry", title: s.title, line: s.line, note: "⚠️ ما تسجلش ردك: الاتصال ضعيف. اضغط مرة ثانية."), staleDate: a.content.staleDate))
    } else {
      let phase = !reply.ok ? "off" : (answer == "attend" ? "done" : "skipped")
      await a.end(ActivityContent(state: .init(phase: phase, title: reply.title, line: reply.message, note: ""), staleDate: nil),
                  dismissalPolicy: .after(Date().addingTimeInterval(90)))
    }
    return reply
  }
}
