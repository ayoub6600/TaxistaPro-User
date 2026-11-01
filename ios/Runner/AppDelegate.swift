import UIKit
import Flutter
import GoogleMaps
import Firebase
import Vision
import WebKit
import webview_flutter_wkwebview
import PushKit
import CallKit
import AVFoundation
import WebRTC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyCLVX-Jnqqo89cZ2xQ6CJflSueG-laba7g")
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "TaxistaCardOcr") {
      CardOcr.register(messenger: registrar.messenger())
    }
    if let registrar = self.registrar(forPlugin: "TaxistaCardFill") {
      CardFillBridge.register(messenger: registrar.messenger(), registry: self)
    }
    if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
    application.registerForRemoteNotifications()
 UIApplication.shared.beginReceivingRemoteControlEvents()

    // Calls (with the driver of the ride, or the administration): PushKit rings the phone through
    // CallKit even when locked; WebRTC's audio starts only once CallKit has activated the session.
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [PKPushType.voIP]
    voipRegistry = registry
    #if targetEnvironment(simulator)
    // the Simulator has no CallKit audio session: WebRTC manages the audio itself there
    RTCAudioSession.sharedInstance().useManualAudio = false
    #else
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit (incoming calls)

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    guard type == .voIP else { completion(); return }
    // iOS requires every VoIP push to be reported to CallKit at once
    let p = payload.dictionaryPayload
    let id = (p["call_id"] as? String) ?? UUID().uuidString
    let fromDriver = (p["caller_role"] as? String) == "driver"
    let data = flutter_callkit_incoming.Data(id: id, nameCaller: (p["caller_name"] as? String) ?? "إدارة تاكسيستا",
                                             handle: fromDriver ? "سائق · تاكسيستا" : "إدارة تاكسيستا", type: 0)
    data.extra = ["call_id": id]
    data.duration = 45000
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
    // the (locked) iPhone shows the call: tell the server through the signed link in the push, so the
    // caller sees "ringing" only now (no login needed - the app may not even be running)
    if let link = p["alerted_url"] as? String, let url = URL(string: link) {
      URLSession.shared.dataTask(with: url).resume()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { completion() }
  }

  // MARK: - CallKit actions (the Dart side receives the same events and does the work)

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) { action.fulfill() }
  func onDecline(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onEnd(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onTimeOut(_ call: Call) {}
  func providerDidReset() {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
  }
}


/// Optional "scan card" text recognition. Apple's Vision framework, on the
/// device: the photo is only read from the path Dart hands over (Dart deletes
/// it straight afterwards), nothing is sent anywhere, and nothing is logged.
final class CardOcr {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "taxista/card_ocr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize",
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let outcome = recognize(path: path)
        DispatchQueue.main.async {
          switch outcome {
          case .success(let lines): result(lines)
          case .failure: result(FlutterError(code: "ocr_failed", message: "Text recognition failed", details: nil))
          }
        }
      }
    }
  }

  private static func recognize(path: String) -> Result<[String], Error> {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      return .failure(NSError(domain: "CardOcr", code: 1))
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    // Digits and names must be read as printed, never "corrected" into words.
    request.usesLanguageCorrection = false
    if let supported = try? request.supportedRecognitionLanguages() {
      let wanted = ["en-US", "ar-SA"].filter { supported.contains($0) }
      if !wanted.isEmpty { request.recognitionLanguages = wanted }
    }
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation(of: image), options: [:])
    do {
      try handler.perform([request])
    } catch {
      return .failure(error)
    }
    let observations = (request.results ?? []).sorted { a, b in
      // Reading order: top to bottom (Vision's origin is the bottom-left).
      if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.02 { return a.boundingBox.midY > b.boundingBox.midY }
      return a.boundingBox.minX < b.boundingBox.minX
    }
    return .success(observations.compactMap { $0.topCandidates(1).first?.string })
  }

  private static func orientation(of image: UIImage) -> CGImagePropertyOrientation {
    switch image.imageOrientation {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }
}


/// Smart Fill: puts one saved card into the bank's payment form in one tap.
///
/// The bank's card form lives in a cross-origin iframe, so the page around it
/// can never reach it. This host can: it installs a script into EVERY frame of
/// the payment web view (`forMainFrameOnly: false`, in an isolated content
/// world the page's own JavaScript cannot see); the script does nothing unless
/// the frame's own origin is on the exact allow-list and its own document has
/// the card-form fingerprint. Native code then delivers the card only to that
/// verified frame, only after the customer's tap, as call arguments (never in
/// a URL, storage, log or global), and forgets it. The CVV never enters here.
final class CardFillBridge: NSObject {
  static let shared = CardFillBridge()

  private var channel: FlutterMethodChannel?
  private weak var registry: FlutterPluginRegistry?
  private var sessions: [Int64: Session] = [:]

  private struct Origin: Equatable {
    let scheme: String, host: String, port: Int
    init?(_ raw: String) {
      guard let url = URL(string: raw), let scheme = url.scheme, let host = url.host else { return nil }
      self.scheme = scheme; self.host = host; self.port = url.port ?? (scheme == "https" ? 443 : 80)
    }
    init(_ origin: WKSecurityOrigin) {
      scheme = origin.protocol; host = origin.host
      port = origin.port != 0 ? origin.port : (origin.protocol == "https" ? 443 : 80)
    }
  }

  private final class Session: NSObject, WKScriptMessageHandler {
    let id: Int64
    let origins: [Origin]
    weak var owner: CardFillBridge?
    weak var webView: WKWebView?
    var ready: WKFrameInfo?

    init(id: Int64, origins: [Origin], owner: CardFillBridge) {
      self.id = id; self.origins = origins; self.owner = owner
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
      guard let body = message.body as? [String: Any], let kind = body["t"] as? String else { return }
      // Native re-checks who is talking: only an approved origin's frame counts.
      guard origins.contains(Origin(message.frameInfo.securityOrigin)) else { return }
      switch kind {
      case "ready": ready = message.frameInfo; owner?.emit(id, "ready")
      case "gone": ready = nil; owner?.emit(id, "gone")
      default: break
      }
    }
  }

  @available(iOS 14.0, *)
  private static let world = WKContentWorld.world(name: "taxista-card-fill")

  static func register(messenger: FlutterBinaryMessenger, registry: FlutterPluginRegistry) {
    let bridge = CardFillBridge.shared
    bridge.registry = registry
    let channel = FlutterMethodChannel(name: "taxista/card_fill", binaryMessenger: messenger)
    bridge.channel = channel
    channel.setMethodCallHandler { call, result in bridge.handle(call, result) }
  }

  private func emit(_ id: Int64, _ state: String) {
    DispatchQueue.main.async { self.channel?.invokeMethod("state", arguments: ["webViewId": Int(id), "state": state]) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *), let args = call.arguments as? [String: Any],
          let id = (args["webViewId"] as? NSNumber)?.int64Value else {
      result(call.method == "dispose" ? nil : (call.method == "install" ? false : ["ok": false, "reason": "unsupported"]))
      return
    }
    switch call.method {
    case "install": result(install(id, args))
    case "fill": fill(id, args, result)
    case "dispose": dispose(id); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 14.0, *)
  private func install(_ id: Int64, _ args: [String: Any]) -> Bool {
    guard let script = args["script"] as? String, let raw = args["origins"] as? [String], !raw.isEmpty,
          let registry = registry,
          let webView = FWFWebViewFlutterWKWebViewExternalAPI.webView(forIdentifier: id, withPluginRegistry: registry) else { return false }
    let origins = raw.compactMap(Origin.init)
    guard origins.count == raw.count else { return false }
    dispose(id)
    let session = Session(id: id, origins: origins, owner: self)
    session.webView = webView
    let controller = webView.configuration.userContentController
    controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: CardFillBridge.world))
    controller.add(session, contentWorld: CardFillBridge.world, name: "taxistaFill")
    sessions[id] = session
    return true
  }

  @available(iOS 14.0, *)
  private func fill(_ id: Int64, _ args: [String: Any], _ result: @escaping FlutterResult) {
    guard let session = sessions[id], let webView = session.webView, let frame = session.ready,
          session.origins.contains(Origin(frame.securityOrigin)) else {
      result(["ok": false, "reason": "no_ready_frame"])
      return
    }
    var values: [String: Any] = [
      "pan": args["pan"] as? String ?? "", "exp": args["exp"] as? String ?? "",
      "name": args["name"] as? String ?? "", "terms": (args["terms"] as? Bool) ?? false,
    ]
    webView.callAsyncJavaScript("return window.__tfFill(pan, exp, name, terms);", arguments: values, in: frame, in: CardFillBridge.world) { outcome in
      values.removeAll()  // drop our copy of the card
      switch outcome {
      case .success(let value):
        // Hand back labels only, whatever the page context returned.
        let map = value as? [String: Any] ?? [:]
        var clean: [String: Any] = ["ok": (map["ok"] as? Bool) ?? false]
        for key in ["pan", "exp", "name", "terms", "reason"] { if let text = map[key] as? String { clean[key] = text } }
        result(clean)
      case .failure:
        result(["ok": false, "reason": "no_ready_frame"])
      }
    }
  }

  private func dispose(_ id: Int64) {
    guard let session = sessions.removeValue(forKey: id) else { return }
    if #available(iOS 14.0, *), let webView = session.webView {
      webView.configuration.userContentController.removeScriptMessageHandler(forName: "taxistaFill", contentWorld: CardFillBridge.world)
    }
  }
}
