import ActivityKit
import Flutter
import UIKit
import UserNotifications
/// The lock-screen card «🚕 مشوارك غدًا» (Live Activity): Apple's push-to-start token for the server
/// (iOS 17.2+, only while Live Activities are allowed), each card's update token reported to the
/// server (so it can take the card off), a card past its deadline taken off here, ⏭ تخطي confirmed
/// in the app, and the TestFlight tryout (a card / a notification that never reach the server).
enum RecurringLiveActivities {
  private static var channel: FlutterMethodChannel?
  private static var watched = Set<String>()
  private static let tokenKey = "taxista_la_start_token"

  static var isTryoutBuild: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    #endif
  }

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "taxista/live_activity", binaryMessenger: messenger)
    channel = ch
    ch.setMethodCallHandler { call, result in
      switch call.method {
      case "info": result(info())
      case "demoCard":
        if #available(iOS 17.0, *) { result(startDemo()) } else { result("iOS 17 أو أحدث مطلوب لبطاقة شاشة القفل") }
      case "demoNotification": demoNotification(); result(true)
      case "endDay":
        let id = (call.arguments as? [String: Any])?["id"] as? String ?? ""
        if #available(iOS 16.2, *) { Task { await end(id, phase: "done", title: "", line: "") } }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  static func info() -> [String: Any] {
    var supported = false
    var enabled = false
    if #available(iOS 17.2, *) {
      supported = true
      enabled = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    return ["supported": supported, "enabled": enabled, "token": UserDefaults.standard.string(forKey: tokenKey) ?? "", "tryout": isTryoutBuild]
  }

  static func start() {
    guard #available(iOS 17.2, *) else { return }
    Task {
      for await data in Activity<RecurringDayAttributes>.pushToStartTokenUpdates {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        NSLog("TaxistaLive push-to-start token received (%d chars)", hex.count)
        if UserDefaults.standard.string(forKey: tokenKey) != hex {
          UserDefaults.standard.set(hex, forKey: tokenKey)
          DispatchQueue.main.async { channel?.invokeMethod("tokenChanged", arguments: nil) }
        }
      }
    }
    #if targetEnvironment(simulator)
    // rig only (never on a phone): `defaults write com.taxistapro.user rig_live_card '<json of the server's start push>'`
    // starts the card exactly as the push would (the Simulator cannot receive a Live Activity push)
    if let raw = UserDefaults.standard.string(forKey: "rig_live_card"), let d = raw.data(using: .utf8),
       let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
       let at = (try? JSONSerialization.data(withJSONObject: j["attributes"] ?? [:])).flatMap({ try? JSONDecoder().decode(RecurringDayAttributes.self, from: $0) }),
       let st = (try? JSONSerialization.data(withJSONObject: j["state"] ?? [:])).flatMap({ try? JSONDecoder().decode(RecurringDayAttributes.ContentState.self, from: $0) }) {
      UserDefaults.standard.removeObject(forKey: "rig_live_card")
      let stale = (j["staleAt"] as? Double).map { Date(timeIntervalSince1970: $0) }
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        do {
          let a = try Activity.request(attributes: at, content: ActivityContent(state: st, staleDate: stale), pushType: .token)
          NSLog("TaxistaLive rig card started %@", a.id)
        } catch { NSLog("TaxistaLive rig card failed %@", "\(error)") }
      }
    }
    #endif
    for a in Activity<RecurringDayAttributes>.activities { watch(a) }
    Task {
      for await a in Activity<RecurringDayAttributes>.activityUpdates { watch(a, fresh: true) }
    }
  }

  @available(iOS 17.2, *)
  private static func watch(_ a: Activity<RecurringDayAttributes>, fresh: Bool = false) {
    guard !watched.contains(a.id) else { return }
    watched.insert(a.id)
    let at = a.attributes
    if fresh {
      // a new card for the same day (a resend) replaces the older one: one card per day
      for old in Activity<RecurringDayAttributes>.activities where old.id != a.id && old.attributes.occurrenceId == at.occurrenceId {
        Task { await old.end(nil, dismissalPolicy: .immediate) }
      }
    }
    if !at.isDemo && Date().timeIntervalSince1970 >= at.deadline {
      Task { await a.end(nil, dismissalPolicy: .immediate) }
      return
    }
    guard !at.isDemo else { return }
    Task {
      for await data in a.pushTokenUpdates {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        NSLog("TaxistaLive card %@ update token received", at.occurrenceId)
        report(at, event: "started", token: hex) { end in
          if end { Task { await a.end(nil, dismissalPolicy: .immediate) } }
        }
      }
    }
  }

  @available(iOS 16.2, *)
  private static func report(_ at: RecurringDayAttributes, event: String, token: String?, done: @escaping (Bool) -> Void) {
    guard let url = URL(string: RecurringDayAnswer.apiBase + "api/v1/recurring-day/\(at.occurrenceId)/live") else { return }
    var req = URLRequest(url: url, timeoutInterval: 15)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    var body: [String: String] = ["t": at.dayToken, "event": event]
    if let token = token { body["push_token"] = token }
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    var task = UIBackgroundTaskIdentifier.invalid
    task = UIApplication.shared.beginBackgroundTask(withName: "recurring-live") {
      UIApplication.shared.endBackgroundTask(task)
      task = .invalid
    }
    URLSession.shared.dataTask(with: req) { data, _, _ in
      let j = data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
      done((j?["end"] as? Bool) == true)
      if task != .invalid { UIApplication.shared.endBackgroundTask(task); task = .invalid }
    }.resume()
  }

  /// the card of one day off the lock screen (answered inside the app)
  @available(iOS 16.2, *)
  static func end(_ id: String, phase: String, title: String, line: String) async {
    for a in Activity<RecurringDayAttributes>.activities where a.attributes.occurrenceId == id {
      await a.end(nil, dismissalPolicy: .immediate)
    }
  }

  // MARK: ⏭ تخطي from the card: taxistarider://recurring-day/skip?id=…&t=…&s=…

  static func open(_ url: URL) -> Bool {
    guard url.scheme == "taxistarider", url.host == "recurring-day", url.path == "/skip" else { return false }
    let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    let v = { (n: String) in q.first { $0.name == n }?.value ?? "" }
    let id = v("id"), token = v("t"), seenAt = v("s")
    guard !id.isEmpty, !token.isEmpty else { return true }
    // the app may still be starting (opened from the card): ask once its window is up
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { askSkip(id: id, token: token, seenAt: seenAt) }
    return true
  }

  private static func top() -> UIViewController? {
    var vc = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController
      ?? UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
    while let p = vc?.presentedViewController { vc = p }
    return vc
  }

  private static func askSkip(id: String, token: String, seenAt: String) {
    guard let vc = top() else { return }
    let demo = id == "demo"
    let alert = UIAlertController(title: "تخطي مشوار الغد؟",
                                  message: demo ? "تجربة: ما يتسجل شي في حسابك." : "ما يجيك سائق في هذا اليوم فقط، وباقي الأيام تكمل عادي. التخطي مجاني.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "رجوع", style: .cancel))
    alert.addAction(UIAlertAction(title: "⏭ تخطي", style: .destructive) { _ in
      guard #available(iOS 16.2, *) else { return }
      Task {
        let reply = await RecurringDayAnswer.answer(occurrenceId: id, answer: "skip", token: token, seenAt: seenAt)
        DispatchQueue.main.async {
          let done = UIAlertController(title: reply.title, message: reply.message, preferredStyle: .alert)
          done.addAction(UIAlertAction(title: "تمام", style: .default))
          top()?.present(done, animated: true)
          channel?.invokeMethod("answered", arguments: ["id": id])
        }
      }
    })
    vc.present(alert, animated: true)
  }

  // MARK: TestFlight tryout (nothing reaches the server)

  @available(iOS 17.0, *)
  private static func startDemo() -> String {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      return "بطاقات شاشة القفل مقفولة لتاكسيستا: الإعدادات ← تاكسيستا ← الأنشطة الحية (Live Activities)."
    }
    for a in Activity<RecurringDayAttributes>.activities where a.attributes.isDemo {
      Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
    let at = RecurringDayAttributes(occurrenceId: "demo", recurringId: "demo", dayToken: "demo", seenAt: "demo",
                                    deadline: Date().addingTimeInterval(3600).timeIntervalSince1970)
    let state = RecurringDayAttributes.ContentState(phase: "ask", title: "🚕 مشوارك غدًا", line: "9:30 صباحًا · من البيت إلى العمل", note: "")
    do {
      _ = try Activity.request(attributes: at, content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(3600)), pushType: nil)
      return "ok"
    } catch {
      return "ما قدرناش نبدأ البطاقة: \(error.localizedDescription)"
    }
  }

  private static func demoNotification() {
    let c = UNMutableNotificationContent()
    c.title = "🚕 مشوارك غدًا"
    c.body = "9:30 صباحًا · من البيت إلى العمل"
    c.sound = .default
    c.categoryIdentifier = RecurringReminderButtons.category
    c.threadIdentifier = "rday-demo"
    c.userInfo = ["category": RecurringReminderButtons.category, "occurrence_id": "demo", "day_token": "demo", "seen_at": "demo",
                  "title": c.title, "message": c.body]
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "rday-demo-ask", content: c,
                                                                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)))
  }
}
