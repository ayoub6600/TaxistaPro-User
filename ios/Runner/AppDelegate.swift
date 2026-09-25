import UIKit
import Flutter
import GoogleMaps
import Firebase
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
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
    if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
    application.registerForRemoteNotifications()
 UIApplication.shared.beginReceivingRemoteControlEvents()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
