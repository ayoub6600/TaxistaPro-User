import ActivityKit
import CryptoKit
import Flutter
import UIKit

/// The ride card on the lock screen and in the Dynamic Island (TaxistaRideAttributes, iOS 17.2+).
/// The server starts it with Apple's push-to-start token and moves it with the card's own update token.
/// Both tokens go to the server from here, natively, with the rider's saved login (flutter.Bearer):
/// iOS may wake the app in the background only to hand them over, before Flutter has run anything.
/// A token that could not go yet (signed out, no internet) goes the next time the app becomes active.
@MainActor
enum RideLiveActivities {
  private static var channel: FlutterMethodChannel?
  private static var watched = Set<String>()
  /// card id → the update token the server already has
  private static var sentUpdate: [String: String] = [:]
  private static let startTokenKey = "taxista_ride_start_token"
  private static let startSentKey = "taxista_ride_start_token_sent"
  private static let startSentAtKey = "taxista_ride_start_token_sent_at"
  /// the same start token is sent again after a few days, in case the server lost it
  private static let startResendAfter: TimeInterval = 3 * 24 * 3600

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "taxista/ride_live_activity", binaryMessenger: messenger)
    channel = ch
    ch.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "endRide":
        // rated inside the app: its card leaves the lock screen
        end(requestId: args["request_id"].map { "\($0)" } ?? "")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func start() {
    guard #available(iOS 17.2, *) else { return }
    Task {
      for await data in Activity<TaxistaRideAttributes>.pushToStartTokenUpdates {
        let hex = hexString(data)
        NSLog("TaxistaRideLive push-to-start token received (%d chars)", hex.count)
        UserDefaults.standard.set(hex, forKey: startTokenKey)
        await sendStartToken(hex)
      }
    }
    for a in Activity<TaxistaRideAttributes>.activities { watch(a, fresh: false) }
    Task {
      for await a in Activity<TaxistaRideAttributes>.activityUpdates { watch(a, fresh: true) }
    }
    _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
      Task { @MainActor in resend() }
    }
    #if targetEnvironment(simulator)
    rigCard()
    #endif
  }

  /// what could not go before (signed in since, the internet is back)
  static func resend() {
    guard #available(iOS 17.2, *) else { return }
    Task {
      if let hex = UserDefaults.standard.string(forKey: startTokenKey), !hex.isEmpty { await sendStartToken(hex) }
      for a in Activity<TaxistaRideAttributes>.activities {
        if let t = a.pushToken { await sendUpdateToken(a, hexString(t)) }
      }
    }
    #if targetEnvironment(simulator)
    rigCard()
    #endif
  }

  /// the card of one ride off the lock screen
  static func end(requestId: String) {
    guard #available(iOS 16.2, *), !requestId.isEmpty else { return }
    for a in Activity<TaxistaRideAttributes>.activities where a.attributes.requestId == requestId {
      Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
  }

  /// a tap on the card (taxistarider://ride-live/open?id=…): the app opens on its ride by itself
  static func open(_ url: URL) -> Bool {
    url.scheme == "taxistarider" && url.host == "ride-live"
  }

  // MARK: tokens to the server

  @available(iOS 17.2, *)
  private static func watch(_ a: Activity<TaxistaRideAttributes>, fresh: Bool) {
    guard watched.insert(a.id).inserted else { return }
    let requestId = a.attributes.requestId
    if fresh {
      // a second card for the same ride (the server started it again) replaces the older one
      for old in Activity<TaxistaRideAttributes>.activities where old.id != a.id && old.attributes.requestId == requestId {
        Task { await old.end(nil, dismissalPolicy: .immediate) }
      }
    }
    Task {
      for await data in a.pushTokenUpdates {
        NSLog("TaxistaRideLive card %@ update token received", requestId)
        await sendUpdateToken(a, hexString(data))
      }
    }
  }

  @available(iOS 17.2, *)
  private static func sendUpdateToken(_ a: Activity<TaxistaRideAttributes>, _ hex: String) async {
    let requestId = a.attributes.requestId
    guard !requestId.isEmpty, !hex.isEmpty, sentUpdate[a.id] != hex, let jwt = bearer else { return }
    if await post("api/v1/request/live-activity/update-token", ["request_id": requestId, "token": hex], bearer: jwt) {
      sentUpdate[a.id] = hex
    }
  }

  @available(iOS 16.2, *)
  private static func sendStartToken(_ hex: String) async {
    guard let jwt = bearer else { return }
    // one send per token and login (another account on this phone sends it again)
    let key = hex + "|" + SHA256.hash(data: Data(jwt.utf8)).map { String(format: "%02x", $0) }.joined()
    let d = UserDefaults.standard
    let fresh = Date().timeIntervalSince1970 - d.double(forKey: startSentAtKey) < startResendAfter
    guard d.string(forKey: startSentKey) != key || !fresh else { return }
    if await post("api/v1/user/live-activity/ride-start-token", ["token": hex], bearer: jwt) {
      d.set(key, forKey: startSentKey)
      d.set(Date().timeIntervalSince1970, forKey: startSentAtKey)
    }
  }

  /// the rider's login as the Flutter app keeps it (shared_preferences «Bearer»: the raw token)
  private static var bearer: String? {
    guard let b = UserDefaults.standard.string(forKey: "flutter.Bearer")?.trimmingCharacters(in: .whitespacesAndNewlines),
          !b.isEmpty, b != "null" else { return nil }
    return b
  }

  @available(iOS 16.2, *)
  private static func post(_ path: String, _ body: [String: Any], bearer jwt: String) async -> Bool {
    guard let url = URL(string: RecurringDayAnswer.apiBase + path) else { return false }
    var req = URLRequest(url: url, timeoutInterval: 20)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)
    let time = BackgroundTime("ride-live-token")
    defer { time.finish() }
    for attempt in 0..<2 {
      if let reply = try? await URLSession.shared.data(for: req) {
        let status = (reply.1 as? HTTPURLResponse)?.statusCode ?? 0
        if (200..<300).contains(status) { return true }
        NSLog("TaxistaRideLive %@ answered %d", path, status)
        if status < 500 { return false } // signed out, refused: the next activation tries again
      }
      if attempt == 0 { try? await Task.sleep(nanoseconds: 3_000_000_000) }
    }
    return false
  }

  private static func hexString(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
  }

  // MARK: Simulator rig (never on a phone)

  #if targetEnvironment(simulator)
  /// `xcrun simctl spawn booted defaults write com.taxistapro.user rig_ride_card '{"attributes":{…},"state":{…}}'`
  /// then bring the app to the front: starts the card (or moves the one of that ride) exactly as the
  /// server's push would. The Simulator cannot receive a Live Activity push.
  private static func rigCard() {
    guard #available(iOS 17.2, *) else { return }
    let d = UserDefaults.standard
    guard let raw = d.string(forKey: "rig_ride_card"), let json = raw.data(using: .utf8),
          let j = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
          let st = (try? JSONSerialization.data(withJSONObject: j["state"] ?? [:])).flatMap({ try? JSONDecoder().decode(TaxistaRideAttributes.ContentState.self, from: $0) }),
          let at = (try? JSONSerialization.data(withJSONObject: j["attributes"] ?? [:])).flatMap({ try? JSONDecoder().decode(TaxistaRideAttributes.self, from: $0) })
    else { return }
    d.removeObject(forKey: "rig_ride_card")
    let content = ActivityContent(state: st, staleDate: nil)
    if let running = Activity<TaxistaRideAttributes>.activities.first(where: { $0.attributes.requestId == at.requestId }) {
      Task { await running.update(content) }
      return
    }
    do {
      let a = try Activity.request(attributes: at, content: content, pushType: nil)
      NSLog("TaxistaRideLive rig card started %@", a.id)
    } catch {
      NSLog("TaxistaRideLive rig card failed %@", "\(error)")
    }
  }
  #endif
}

/// a little background time so a token still reaches the server when iOS woke the app only for it
@MainActor
private final class BackgroundTime {
  private var id = UIBackgroundTaskIdentifier.invalid

  init(_ name: String) {
    id = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in self?.finish() }
  }

  func finish() {
    guard id != .invalid else { return }
    UIApplication.shared.endBackgroundTask(id)
    id = .invalid
  }
}
