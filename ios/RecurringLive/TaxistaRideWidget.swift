import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Look

/// The ride card: dark like the lock screen's own, Taxista blue, the yellow Libyan plate. No emoji.
enum RideLook {
  static let background = Color.black.opacity(0.72)
  static let blue = Color(red: 0.086, green: 0.467, blue: 1.0)               // #1677FF
  static let green = Color(red: 0.19, green: 0.82, blue: 0.35)               // #30D158
  static let gold = Color(red: 1.0, green: 0.8, blue: 0.0)                   // #FFCC00
  static let plate = Color(red: 1.0, green: 0.831, blue: 0.231)              // #FFD43B
  static let red = Color(red: 1.0, green: 0.27, blue: 0.23)                  // #FF453A
  static let warning = Color(red: 1.0, green: 0.80, blue: 0.40)
  static let secondary = Color.white.opacity(0.62)
  static let track = Color.white.opacity(0.18)
  static let soft = Color.white.opacity(0.10)
  static let margin: CGFloat = 14
}

// MARK: - Live Activity

/// Lock Screen (and the banner on iPhones without the Dynamic Island) + the three Dynamic Island shapes.
struct TaxistaRideLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TaxistaRideAttributes.self) { context in
      TaxistaRideCard(ride: RideView(context))
        .environment(\.layoutDirection, .rightToLeft)
        .activityBackgroundTint(RideLook.background)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(context.attributes.openURL)
    } dynamicIsland: { context in
      let ride = RideView(context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          IslandLeading(ride: ride).environment(\.layoutDirection, .rightToLeft)
        }
        DynamicIslandExpandedRegion(.trailing) {
          IslandTrailing(ride: ride).environment(\.layoutDirection, .rightToLeft)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(ride.islandTitle)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .environment(\.layoutDirection, .rightToLeft)
        }
        DynamicIslandExpandedRegion(.bottom) {
          IslandBottom(ride: ride)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.top, 4)
            // clear of the island's rounded corners: the first letter of the line was cut (rig check 25 Nov)
            .padding(.horizontal, 10)
        }
      } compactLeading: {
        StageIcon(ride: ride, size: 15)
      } compactTrailing: {
        CompactTrailing(ride: ride)
          .environment(\.layoutDirection, .rightToLeft)
      } minimal: {
        StageIcon(ride: ride, size: 15)
      }
      .widgetURL(context.attributes.openURL)
      .keylineTint(RideLook.blue)
    }
  }
}

// MARK: - What the card says (the server's words first, the approved wording when it sends none)

struct RideView {
  let attributes: TaxistaRideAttributes
  let state: TaxistaRideAttributes.ContentState
  let stale: Bool

  init(_ context: ActivityViewContext<TaxistaRideAttributes>) {
    attributes = context.attributes
    state = context.state
    stale = context.isStale
  }

  var stage: String { state.stage }
  var name: String { attributes.firstName.isEmpty ? "الكابتن" : attributes.firstName }
  var initial: String { attributes.driverName.first.map { String($0) } ?? "T" }

  var title: String {
    if !state.title.isEmpty { return state.title }
    switch stage {
    case "coming": return "\(name) جاي لك"
    case "arrived": return "\(name) وصل"
    case "on_trip": return "في الطريق لوجهتك"
    case "rate": return "وصلت بالسلامة"
    default: return "تاكسيستا"
    }
  }

  var subtitle: String {
    if !state.subtitle.isEmpty { return state.subtitle }
    switch stage {
    case "coming", "arrived": return attributes.car
    case "rate": return "كيف كانت رحلتك مع \(name)؟"
    default: return ""
    }
  }

  var islandTitle: String { stage == "rate" ? "وصلت بالسلامة · قيّم \(name)" : title }

  var eta: Int? { state.etaMinutes.map { max($0, 1) } }
  var progress: Double? { state.progress.map { min(max($0, 0), 1) } }
  var amount: String? { nonEmpty(state.payAmount) }
  var payLine: String? { nonEmpty(state.payLine) }
  var note: String? { nonEmpty(state.note) }

  /// «توصل 9:42»: now + the minutes left (the card is drawn again with each push)
  var arrivalClock: String? {
    guard let eta = eta else { return nil }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "h:mm"
    return f.string(from: Date().addingTimeInterval(Double(eta) * 60))
  }

  /// rate: «11 د.ل · نقدًا» (or the server's pay line)
  var payStatus: String? {
    if let a = amount { return "\(a) · نقدًا" }
    return payLine
  }

  /// the short status at the far side of the header
  var status: (text: String, color: Color)? {
    switch stage {
    case "coming": return eta.map { ("يوصلك خلال \($0) د", RideLook.blue) }
    case "arrived": return ("ينتظر فيك", RideLook.green)
    case "on_trip": return arrivalClock.map { ("توصل \($0)", RideLook.blue) }
    case "rate": return payStatus.map { ($0, RideLook.secondary) }
    default: return nil
    }
  }

  // the stars: «جاري إرسال تقييمك…» that never got its answer (iOS stopped the app) gives them back
  var sending: Bool { state.note == RideLiveRating.sendingNote && !stale }
  var sendingStuck: Bool { state.note == RideLiveRating.sendingNote && stale }
  var stars: Int { sendingStuck ? 0 : (state.rated ?? 0) }
  var canRate: Bool { !sending && !attributes.requestId.isEmpty && !attributes.ratingToken.isEmpty }

  var rateLine: (text: String, warning: Bool) {
    if sendingStuck { return (RideLiveRating.failedNote, true) }
    if let n = note { return (n, n == RideLiveRating.failedNote) }
    return ("اضغط نجمة من هنا، أو افتح التطبيق وزيد كلمة للكابتن", false)
  }

  /// the one small line under the island's bar
  var islandLine: String? {
    switch stage {
    case "on_trip":
      // short: the island is narrow (the full words cut «تدفع» on the 25 Nov rig check)
      if let a = amount { return payLine.map { "تدفع \(a) · \($0)" } ?? "تدفع للكابتن \(a) نقدًا" }
      return payLine ?? nonEmpty(subtitle)
    case "arrived": return note ?? nonEmpty(subtitle)
    default: return nonEmpty(subtitle)
    }
  }

  private func nonEmpty(_ s: String?) -> String? {
    guard let s = s?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
    return s
  }
}

// MARK: - Lock Screen card

struct TaxistaRideCard: View {
  let ride: RideView

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      CardHeader(ride: ride)
      switch ride.stage {
      case "coming":
        DriverRow(ride: ride)
        RideTrack(progress: ride.progress, toDestination: false)
      case "arrived":
        DriverRow(ride: ride)
        if let note = ride.note { NoteBox(text: note) }
      case "on_trip":
        TitleBlock(title: ride.title, subtitle: ride.subtitle)
        RideTrack(progress: ride.progress, toDestination: true)
        if let amount = ride.amount { PayRow(amount: amount, line: ride.payLine) }
      case "rate":
        TitleBlock(title: ride.title, subtitle: ride.subtitle)
        VStack(spacing: 4) {
          StarRow(ride: ride, size: 26)
          let line = ride.rateLine
          Text(line.text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(line.warning ? RideLook.warning : RideLook.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
      default:
        TitleBlock(title: ride.title, subtitle: ride.subtitle)
      }
    }
    .padding(RideLook.margin)
  }
}

/// «T تاكسيستا» on the start side, the short status in its colour on the far side
private struct CardHeader: View {
  let ride: RideView

  var body: some View {
    HStack(spacing: 6) {
      TMark(size: 18)
      Text("تاكسيستا").font(.system(size: 13, weight: .semibold)).foregroundStyle(RideLook.secondary)
      Spacer(minLength: 8)
      if let s = ride.status {
        Text(s.text).font(.system(size: 13, weight: .semibold)).foregroundStyle(s.color).lineLimit(1)
      }
    }
  }
}

/// avatar (first letter) · «حمزة جاي لك» / the car · the plate
private struct DriverRow: View {
  let ride: RideView

  var body: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(Color.white.opacity(0.16))
        .frame(width: 40, height: 40)
        .overlay { Text(ride.initial).font(.system(size: 18, weight: .bold)).foregroundStyle(.white) }
        .accessibilityHidden(true)
      TitleBlock(title: ride.title, subtitle: ride.subtitle)
      Spacer(minLength: 6)
      if !ride.attributes.plate.isEmpty { PlateChip(plate: ride.attributes.plate) }
    }
  }
}

private struct TitleBlock: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.85)
      if !subtitle.isEmpty {
        Text(subtitle).font(.system(size: 13.5, weight: .medium)).foregroundStyle(RideLook.secondary).lineLimit(1)
      }
    }
  }
}

private struct NoteBox: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(Color.white.opacity(0.85))
      .lineLimit(2)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(RideLook.soft))
  }
}

/// «تدفع للكابتن نقدًا» (+ the pay line under it) · the amount, big
private struct PayRow: View {
  let amount: String
  let line: String?

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      VStack(alignment: .leading, spacing: 1) {
        Text("تدفع للكابتن نقدًا").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
        if let line = line {
          Text(line).font(.system(size: 12, weight: .medium)).foregroundStyle(RideLook.secondary).lineLimit(1)
        }
      }
      Spacer(minLength: 6)
      Text(amount).font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(.white).lineLimit(1)
    }
  }
}

// MARK: - Pieces

/// Taxista's mark drawn here: a blue rounded square with a white «T»
struct TMark: View {
  var size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
      .fill(RideLook.blue)
      .frame(width: size, height: size)
      .overlay { Text("T").font(.system(size: size * 0.64, weight: .heavy, design: .rounded)).foregroundStyle(.white) }
      .accessibilityHidden(true)
  }
}

/// the Libyan plate: yellow, black digits
struct PlateChip: View {
  let plate: String
  var size: CGFloat = 14

  var body: some View {
    Text(plate)
      .font(.system(size: size, weight: .bold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.black)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(RideLook.plate))
      .accessibilityLabel("اللوحة \(plate)")
  }
}

/// The way as a thin bar. Coming: the car moves toward the pickup ring. On the trip: from the pickup ring
/// toward the red pin. Without a progress the car waits at the start of the bar.
struct RideTrack: View {
  let progress: Double?
  let toDestination: Bool

  var body: some View {
    HStack(spacing: 6) {
      if toDestination { Ring() }
      GeometryReader { g in
        let w = g.size.width
        let p = progress ?? 0
        ZStack(alignment: .leading) {
          Capsule().fill(RideLook.track).frame(height: 4)
          if progress != nil {
            Capsule().fill(RideLook.blue).frame(width: max(4, w * p), height: 4)
          }
          Image(systemName: "car.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(RideLook.blue))
            .padding(.leading, max(0, min(w * p - 9, w - 18)))
        }
        .frame(width: w, height: 18, alignment: .leading)
      }
      .frame(height: 18)
      if toDestination {
        Image(systemName: "mappin.circle.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white, RideLook.red)
      } else {
        Ring()
      }
    }
    .accessibilityHidden(true)
  }
}

private struct Ring: View {
  var body: some View {
    Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 2.5).frame(width: 12, height: 12)
  }
}

/// Five stars. Each one is the rating itself (an App Intent: the phone can stay locked); gold up to the
/// one he pressed. While its answer is on the way they are only drawn (no second tap).
struct StarRow: View {
  let ride: RideView
  var size: CGFloat

  var body: some View {
    HStack(spacing: 2) {
      ForEach(1...5, id: \.self) { n in
        if ride.canRate {
          Button(intent: RateRideIntent(requestId: ride.attributes.requestId, token: ride.attributes.ratingToken, stars: n)) {
            StarLabel(on: n <= ride.stars, size: size)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("\(n) من 5")
        } else {
          StarLabel(on: n <= ride.stars, size: size)
        }
      }
    }
  }
}

private struct StarLabel: View {
  let on: Bool
  let size: CGFloat

  var body: some View {
    Image(systemName: "star.fill")
      .font(.system(size: size, weight: .semibold))
      .foregroundStyle(on ? RideLook.gold : Color.white.opacity(0.28))
      .frame(width: size + 18, height: size + 12)
      .contentShape(Rectangle())
  }
}

// MARK: - Dynamic Island

/// car (coming, on the way) · green check (he is there) · gold star (rate)
private struct StageIcon: View {
  let ride: RideView
  let size: CGFloat

  var body: some View {
    switch ride.stage {
    case "coming", "on_trip":
      Image(systemName: "car.fill").font(.system(size: size, weight: .bold)).foregroundStyle(RideLook.blue)
    case "arrived", "done":
      Image(systemName: "checkmark.circle.fill").font(.system(size: size + 1, weight: .bold)).foregroundStyle(RideLook.green)
    case "rate":
      Image(systemName: "star.fill").font(.system(size: size, weight: .bold)).foregroundStyle(RideLook.gold)
    default:
      TMark(size: size + 5)
    }
  }
}

private struct CompactTrailing: View {
  let ride: RideView

  var body: some View {
    switch ride.stage {
    case "coming", "on_trip":
      if let eta = ride.eta {
        Text("\(eta) د").font(.system(size: 14, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(.white)
      }
    case "arrived":
      Text("وصل").font(.system(size: 14, weight: .semibold)).foregroundStyle(RideLook.green)
    case "rate":
      Text("قيّم").font(.system(size: 14, weight: .semibold)).foregroundStyle(RideLook.gold)
    default:
      EmptyView()
    }
  }
}

private struct IslandLeading: View {
  let ride: RideView

  var body: some View {
    if ride.stage != "rate" && !ride.attributes.plate.isEmpty {
      PlateChip(plate: ride.attributes.plate, size: 13).padding(.leading, 4)
    } else {
      TMark(size: 26).padding(.leading, 4)
    }
  }
}

/// the minutes, big («ينتظر» once he is there)
private struct IslandTrailing: View {
  let ride: RideView

  var body: some View {
    switch ride.stage {
    case "coming", "on_trip":
      if let eta = ride.eta {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
          Text("\(eta)").font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit()
          Text("د").font(.system(size: 13, weight: .semibold)).foregroundStyle(RideLook.secondary)
        }
        .foregroundStyle(.white)
        .padding(.trailing, 4)
      }
    case "arrived":
      Text("ينتظر").font(.system(size: 17, weight: .bold)).foregroundStyle(RideLook.green).padding(.trailing, 4)
    default:
      EmptyView()
    }
  }
}

private struct IslandBottom: View {
  let ride: RideView

  var body: some View {
    VStack(spacing: 6) {
      switch ride.stage {
      case "coming":
        RideTrack(progress: ride.progress, toDestination: false)
      case "on_trip":
        RideTrack(progress: ride.progress, toDestination: true)
      case "rate":
        StarRow(ride: ride, size: 22)
      default:
        EmptyView()
      }
      if ride.stage == "rate" {
        let line = ride.rateLine
        let text = line.warning || ride.sending ? line.text : (ride.payStatus ?? "")
        if !text.isEmpty {
          Text(text).font(.system(size: 12, weight: .medium))
            .foregroundStyle(line.warning ? RideLook.warning : RideLook.secondary).lineLimit(1)
        }
      } else if let line = ride.islandLine {
        Text(line).font(.system(size: 12.5, weight: .medium)).foregroundStyle(RideLook.secondary).lineLimit(1)
          .minimumScaleFactor(0.8)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
