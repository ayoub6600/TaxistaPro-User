import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RecurringLiveBundle: WidgetBundle {
  var body: some Widget {
    RecurringDayLiveActivity()
  }
}

private let taxiBlue = Color(red: 0.08, green: 0.40, blue: 0.86)
private let cardInk = Color(red: 0.06, green: 0.09, blue: 0.14)

/// «🚕 مشوارك غدًا · 9:30 صباحًا · من البيت إلى العمل» with [✅ تأكيد] [⏭ تخطي] on the lock screen;
/// after an answer, the server's words in its place; past the deadline, no buttons.
struct RecurringDayLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RecurringDayAttributes.self) { context in
      RecurringDayCard(context: context)
        .environment(\.layoutDirection, .rightToLeft)
        .activityBackgroundTint(cardInk.opacity(0.92))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { TaxiBadge(size: 36).padding(.leading, 4) }
        DynamicIslandExpandedRegion(.trailing) {
          Text(timeOnly(context.state.line)).font(.headline).monospacedDigit().foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 2) {
            Text(plainTitle(context.state.title)).font(.headline).foregroundStyle(.white)
            Text(context.state.line).font(.caption).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          if asks(context) { DayButtons(attributes: context.attributes).padding(.top, 4) }
        }
      } compactLeading: {
        Text("🚕")
      } compactTrailing: {
        Text(asks(context) ? timeOnly(context.state.line) : mark(context.state.phase)).font(.caption).monospacedDigit()
      } minimal: {
        Text("🚕")
      }
      .keylineTint(taxiBlue)
    }
  }
}

private func asks(_ context: ActivityViewContext<RecurringDayAttributes>) -> Bool {
  (context.state.phase == "ask" || context.state.phase == "retry") && !context.isStale
}

private func plainTitle(_ t: String) -> String { t.replacingOccurrences(of: "🚕 ", with: "") }

/// «9:30 صباحًا · من البيت إلى العمل» → «9:30»
private func timeOnly(_ line: String) -> String {
  let first = line.components(separatedBy: " · ").first ?? line
  return first.components(separatedBy: " ").first ?? first
}

private func mark(_ phase: String) -> String {
  switch phase {
  case "done", "demo": return "✅"
  case "skipped": return "⏭"
  default: return "•"
  }
}

struct TaxiBadge: View {
  var size: CGFloat
  var body: some View {
    ZStack {
      Circle().fill(taxiBlue)
      Text("🚕").font(.system(size: size * 0.5))
    }
    .frame(width: size, height: size)
  }
}

struct RecurringDayCard: View {
  let context: ActivityViewContext<RecurringDayAttributes>

  var body: some View {
    let s = context.state
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        if asks(context) || s.phase == "expired" || s.phase == "off" {
          TaxiBadge(size: 40)
        } else {
          ZStack {
            Circle().fill(s.phase == "skipped" ? Color.white.opacity(0.18) : Color(red: 0.12, green: 0.62, blue: 0.38))
            Image(systemName: s.phase == "skipped" ? "forward.end.fill" : "checkmark").font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
          }
          .frame(width: 40, height: 40)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(context.isStale && s.phase == "ask" ? "فات وقت الرد" : plainTitle(s.title))
            .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
          // a lost connection says so in place of the second line: the card never grows past Apple's height
          if !s.note.isEmpty && asks(context) {
            Text(s.note).font(.system(size: 13, weight: .medium)).foregroundStyle(Color(red: 1, green: 0.78, blue: 0.4)).lineLimit(2)
          } else {
            Text(context.isStale && s.phase == "ask" ? "المشوار ماشي في موعده" : s.line)
              .font(.system(size: 13.5)).foregroundStyle(.white.opacity(0.72)).lineLimit(2)
          }
        }
        Spacer(minLength: 4)
        Text("تاكسيستا").font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
      }
      if asks(context) {
        DayButtons(attributes: context.attributes)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}

/// [✅ تأكيد] runs right there; [⏭ تخطي] opens the app (Face ID / code on a locked phone) to confirm it
struct DayButtons: View {
  let attributes: RecurringDayAttributes

  var body: some View {
    HStack(spacing: 8) {
      Button(intent: RecurringConfirmIntent(occurrenceId: attributes.occurrenceId, dayToken: attributes.dayToken, seenAt: attributes.seenAt)) {
        Text("✅ تأكيد").font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 40)
          .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(taxiBlue)).foregroundStyle(.white)
      }
      .buttonStyle(.plain)
      Link(destination: attributes.skipURL) {
        Text("⏭ تخطي").font(.system(size: 15, weight: .medium)).frame(maxWidth: .infinity, minHeight: 40)
          .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.14))).foregroundStyle(.white)
      }
    }
  }
}
