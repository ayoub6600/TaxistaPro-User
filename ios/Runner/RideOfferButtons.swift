import UIKit
import UserNotifications

/// A driver asked more than the rider offered: «قبول» / «رفض» on the notification, answered natively
/// because the phone may be locked and Flutter not running. The offer's token is in the notification;
/// the server checks it and the ride's latest state, and its own words replace the question.
enum RideOfferButtons {
  static let category = "RIDE_OFFER"
  static let accept = "RIDE_OFFER_ACCEPT"
  static let refuse = "RIDE_OFFER_REFUSE"

  static func register() {
    let yes = UNNotificationAction(identifier: accept, title: "قبول", options: [])
    let no = UNNotificationAction(identifier: refuse, title: "غالي شوية", options: [])
    let cat = UNNotificationCategory(identifier: category, actions: [yes, no], intentIdentifiers: [], options: [])
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      var all = existing.filter { $0.identifier != category }
      all.insert(cat)
      center.setNotificationCategories(all)
    }
  }

  static func handle(_ response: UNNotificationResponse, completion: @escaping () -> Void) -> Bool {
    let content = response.notification.request.content
    let action = response.actionIdentifier
    guard content.categoryIdentifier == category, action == accept || action == refuse else { return false }
    let info = content.userInfo
    guard let id = info["offer_id"] as? String, let token = info["offer_token"] as? String, !id.isEmpty, !token.isEmpty else {
      completion()
      return true
    }
    var task = UIBackgroundTaskIdentifier.invalid
    task = UIApplication.shared.beginBackgroundTask(withName: "ride-offer-answer") {
      UIApplication.shared.endBackgroundTask(task)
      task = .invalid
    }
    send(id: id, answer: action == accept ? "accept" : "refuse", token: token) { title, message in
      let c = UNMutableNotificationContent()
      c.title = title
      c.body = message
      c.userInfo = ["recurring_result": "done"] // shows even while the app is open
      let center = UNUserNotificationCenter.current()
      center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
      center.add(UNNotificationRequest(identifier: "offer-\(id)", content: c, trigger: nil))
      completion()
      if task != .invalid { UIApplication.shared.endBackgroundTask(task); task = .invalid }
    }
    return true
  }

  private static func send(id: String, answer: String, token: String, done: @escaping (String, String) -> Void) {
    var base = UserDefaults.standard.string(forKey: "flutter.taxista_api_base") ?? "https://taxista.aljidartech.com/"
    if !base.hasSuffix("/") { base += "/" }
    guard let url = URL(string: base + "api/v1/ride-offer/\(id)/\(answer)") else {
      done("ما تسجلش ردك", "افتح تاكسيستا ورد من هناك.")
      return
    }
    var req = URLRequest(url: url, timeoutInterval: 20)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["t": token])
    URLSession.shared.dataTask(with: req) { body, _, _ in
      if let body = body, let j = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any], let title = j["title"] as? String {
        done(title, (j["message"] as? String) ?? "")
      } else {
        done("ما تسجلش ردك", "تأكد من الإنترنت وافتح تاكسيستا ورد من هناك.")
      }
    }.resume()
  }
}
