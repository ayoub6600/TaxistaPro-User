import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RecurringLiveBundle: WidgetBundle {
  var body: some Widget {
    RecurringDayLiveActivity()
  }
}

// MARK: - Look (one place for the card's colours and sizes)

/// The card: near-black, the real Taxista Rider icon, «مشوارك غدًا», «9:30 صباحًا · من البيت إلى العمل»,
/// and two buttons side by side: [تأكيد] blue, [تخطي] dark grey. No extra words.
enum CardLook {
  static let background = Color(red: 0.043, green: 0.043, blue: 0.059)      // #0B0B0F
  static let confirm = Color(red: 0.039, green: 0.478, blue: 1.0)            // #0A7AFF, white text 4:1+
  static let skip = Color(white: 0.22)                                       // #383838
  static let secondary = Color.white.opacity(0.68)
  static let success = Color(red: 0.19, green: 0.82, blue: 0.35)             // #30D158
  static let warning = Color(red: 1.0, green: 0.80, blue: 0.40)
  static let buttonHeight: CGFloat = 44                                      // Apple's minimum tap target
  static let buttonRadius: CGFloat = 13
  static let margin: CGFloat = 14                                            // HIG Lock Screen margin
}

// MARK: - Live Activity

/// Lock Screen (and the banner on iPhones without the Dynamic Island) + the three Dynamic Island shapes.
struct RecurringDayLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RecurringDayAttributes.self) { context in
      RecurringDayCard(context: context)
        .environment(\.layoutDirection, .rightToLeft)
        .activityBackgroundTint(CardLook.background)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(context.attributes.openURL)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          AppMark(size: 38).padding(.leading, 2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          if let time = clockParts(context.state.line) {
            VStack(alignment: .trailing, spacing: 0) {
              Text(time.hm).font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit()
              Text(time.period).font(.system(size: 12, weight: .semibold)).foregroundStyle(CardLook.secondary)
            }
            .foregroundStyle(.white)
            .padding(.trailing, 2)
          }
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 2) {
            Text(headline(context)).font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1)
            let second = secondLine(context)
            Text(second.warning ? second.text : placesOnly(second.text))
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(second.warning ? CardLook.warning : CardLook.secondary)
              .lineLimit(1)
          }
          .environment(\.layoutDirection, .rightToLeft)
        }
        DynamicIslandExpandedRegion(.bottom) {
          CardFooter(context: context)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.top, 6)
        }
      } compactLeading: {
        AppMark(size: 22)
      } compactTrailing: {
        CompactTrailing(context: context)
      } minimal: {
        AppMark(size: 22)
      }
      .widgetURL(context.attributes.openURL)
      .keylineTint(CardLook.confirm)
    }
  }
}

// MARK: - States

/// ask | retry | sending | done | skipped | expired | off | changed | demo
private func pastDeadline(_ context: ActivityViewContext<RecurringDayAttributes>) -> Bool {
  !context.attributes.isDemo && Date().timeIntervalSince1970 >= context.attributes.deadline
}

/// «sending» is stale after 25 s only when iOS stopped the answer mid-way: then the buttons come back
private func sendingStuck(_ context: ActivityViewContext<RecurringDayAttributes>) -> Bool {
  context.state.phase == "sending" && context.isStale && !pastDeadline(context)
}

private func asks(_ context: ActivityViewContext<RecurringDayAttributes>) -> Bool {
  ((context.state.phase == "ask" || context.state.phase == "retry") && !context.isStale) || sendingStuck(context)
}

private func sending(_ context: ActivityViewContext<RecurringDayAttributes>) -> Bool {
  context.state.phase == "sending" && !context.isStale
}

private func headline(_ context: ActivityViewContext<RecurringDayAttributes>) -> String {
  let s = context.state.phase
  if context.isStale && (s == "ask" || s == "retry" || (s == "sending" && pastDeadline(context))) {
    return "فات وقت الرد"
  }
  return plainTitle(context.state.title)
}

private func secondLine(_ context: ActivityViewContext<RecurringDayAttributes>) -> (text: String, warning: Bool) {
  let s = context.state
  if sendingStuck(context) { return ("ما وصلناش رد. اضغط مرة ثانية.", true) }
  if s.phase == "retry" && !s.note.isEmpty && asks(context) { return (s.note, true) }
  if context.isStale && (s.phase == "ask" || s.phase == "retry") { return ("المشوار ماشي في موعده", false) }
  return (s.line, false)
}

/// the server's title without its emoji («🚕 », «✅ », «⏭ »): the card draws the real icon and Apple's symbols
func plainTitle(_ t: String) -> String {
  ["🚕", "✅", "⏭️", "⏭"].reduce(t) { $0.replacingOccurrences(of: $1, with: "") }.trimmingCharacters(in: .whitespaces)
}

/// «9:30 صباحًا · من البيت إلى العمل» → («9:30», «صباحًا»)
func clockParts(_ line: String) -> (hm: String, period: String)? {
  let first = line.components(separatedBy: " · ").first ?? ""
  let bits = first.split(separator: " ", maxSplits: 1).map(String.init)
  guard let hm = bits.first, hm.contains(":") else { return nil }
  return (hm, bits.count > 1 ? bits[1] : "")
}

/// «9:30 صباحًا · من البيت إلى العمل» → «من البيت إلى العمل» (the time sits on its own in the island)
func placesOnly(_ line: String) -> String {
  let parts = line.components(separatedBy: " · ")
  return parts.count > 1 ? parts.dropFirst().joined(separator: " · ") : line
}

// MARK: - Pieces

/// The real Taxista Rider icon (ios/RecurringLive/LiveAssets.xcassets/TaxistaIcon, made from the app's
/// own AppIcon), with the iOS icon corner. Never an emoji.
struct AppMark: View {
  var size: CGFloat
  var body: some View {
    Image("TaxistaIcon")
      .resizable()
      .interpolation(.high)
      .scaledToFill()
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
      .accessibilityHidden(true)
  }
}

private struct CompactTrailing: View {
  let context: ActivityViewContext<RecurringDayAttributes>
  // (when several activities share the island, iOS shows the minimal view: the icon alone)

  var body: some View {
    if asks(context), let t = clockParts(context.state.line) {
      Text(t.hm).font(.system(size: 15, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(.white)
    } else {
      Image(systemName: statusSymbol(context.state.phase))
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(statusColor(context.state.phase))
    }
  }
}

private func statusSymbol(_ phase: String) -> String {
  switch phase {
  case "done", "demo": return "checkmark.circle.fill"
  case "skipped": return "forward.end.fill"
  case "sending": return "ellipsis"
  default: return "clock"
  }
}

private func statusColor(_ phase: String) -> Color {
  switch phase {
  case "done", "demo": return CardLook.success
  default: return .white
  }
}

/// The Lock Screen card (also the Home Screen banner on iPhones without the Dynamic Island).
struct RecurringDayCard: View {
  let context: ActivityViewContext<RecurringDayAttributes>

  var body: some View {
    let s = context.state
    let second = secondLine(context)
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        AppMark(size: 38)
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            if let symbol = finishedSymbol(s.phase) {
              Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(symbol == "checkmark.circle.fill" ? CardLook.success : .white)
            }
            Text(headline(context)).font(.system(size: 17, weight: .bold)).foregroundStyle(.white).lineLimit(1)
          }
          // a lost connection says so in place of the second line: the card never grows past Apple's height
          Text(second.text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(second.warning ? CardLook.warning : CardLook.secondary)
            .lineLimit(second.warning ? 2 : 1)
            .minimumScaleFactor(0.9)
        }
        Spacer(minLength: 0)
      }
      .accessibilityElement(children: .combine)
      CardFooter(context: context)
    }
    .padding(CardLook.margin)
  }

  private func finishedSymbol(_ phase: String) -> String? {
    switch phase {
    case "done", "demo": return "checkmark.circle.fill"
    case "skipped": return "forward.end.fill"
    default: return nil
    }
  }
}

/// The two buttons while it asks, «جاري التأكيد…» while the answer is on its way, nothing after.
struct CardFooter: View {
  let context: ActivityViewContext<RecurringDayAttributes>

  var body: some View {
    if asks(context) {
      DayButtons(attributes: context.attributes)
    } else if sending(context) {
      HStack(spacing: 8) {
        ProgressView().tint(.white).controlSize(.small)
        Text(context.state.note == "skip" ? "جاري تخطي المشوار…" : "جاري تأكيد مشوارك…")
          .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
      }
      .frame(maxWidth: .infinity, minHeight: CardLook.buttonHeight)
      .background(RoundedRectangle(cornerRadius: CardLook.buttonRadius, style: .continuous).fill(Color.white.opacity(0.10)))
    }
  }
}

/// [تأكيد] runs right there (an App Intent, the phone can stay locked);
/// [تخطي] opens the app, which asks Face ID / the code on a locked phone and then «تخطي مشوار الغد؟»
struct DayButtons: View {
  let attributes: RecurringDayAttributes

  var body: some View {
    HStack(spacing: 10) {
      Button(intent: RecurringConfirmIntent(occurrenceId: attributes.occurrenceId, dayToken: attributes.dayToken, seenAt: attributes.seenAt)) {
        DayButtonLabel(title: "تأكيد", symbol: "checkmark", fill: CardLook.confirm, weight: .bold)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("تأكيد مشوار الغد")

      Link(destination: attributes.skipURL) {
        DayButtonLabel(title: "تخطي", symbol: "forward.end.fill", fill: CardLook.skip, weight: .semibold)
      }
      .accessibilityLabel("تخطي مشوار الغد")
    }
  }
}

private struct DayButtonLabel: View {
  let title: String
  let symbol: String
  let fill: Color
  let weight: Font.Weight

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol).font(.system(size: 14, weight: .bold))
      Text(title).font(.system(size: 16, weight: weight))
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, minHeight: CardLook.buttonHeight)
    .background(RoundedRectangle(cornerRadius: CardLook.buttonRadius, style: .continuous).fill(fill))
    .contentShape(RoundedRectangle(cornerRadius: CardLook.buttonRadius, style: .continuous))
  }
}
