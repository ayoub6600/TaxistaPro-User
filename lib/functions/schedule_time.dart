/// Human, RTL-aware relative-time formatting for scheduled rides.
///
/// Pure functions only (no globals, no app state) so the schedule-creation
/// sheet and the upcoming-rides list share the exact same wording instead
/// of drifting apart. `trip_start_time_raw` (added to TripRequestTransformer
/// alongside this feature) is a naive local Africa/Tripoli wall-clock
/// string with no timezone suffix - DateTime.parse() reads it as a naive
/// local DateTime, which is exactly right to compare against the device's
/// own local clock on this single-region-market app.
library schedule_time;

const _arWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const _arMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _enWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Parses the raw scheduled-ride timestamp out of an API item map. Prefers
/// `trip_start_time_raw`; returns null (never throws) when it's missing or
/// unparseable, so callers can fall back to the pre-formatted display string.
DateTime? parseTripStart(Map item) {
  final raw = item['trip_start_time_raw'];
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

/// "3:30 م" / "3:30 PM" - Western digits + a hand-picked AM/PM marker, kept
/// independent of intl's locale digit-shaping so the exact spec wording is
/// guaranteed regardless of device locale data.
String scheduleTimeLabel(DateTime t, {required bool isRtl}) {
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  if (isRtl) {
    final marker = t.hour >= 12 ? 'م' : 'ص';
    return '$hour12:$minute $marker';
  }
  final marker = t.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $marker';
}

/// "الأحد، 13 سبتمبر" / "Sunday, 13 Sep".
String scheduleDateLabel(DateTime t, {required bool isRtl}) {
  final weekday = isRtl ? _arWeekdays[t.weekday - 1] : _enWeekdays[t.weekday - 1];
  final month = isRtl ? _arMonths[t.month - 1] : _enMonths[t.month - 1];
  return isRtl ? '$weekday، ${t.day} $month' : '$weekday, ${t.day} $month';
}

/// "اليوم" / "غدًا" / "لاحقًا" (or the English equivalents).
String scheduleDayBucket(DateTime t, {required bool isRtl, DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime(t.year, t.month, t.day)
      .difference(DateTime(n.year, n.month, n.day))
      .inDays;
  if (days <= 0) return isRtl ? 'اليوم' : 'Today';
  if (days == 1) return isRtl ? 'غدًا' : 'Tomorrow';
  return isRtl ? 'لاحقًا' : 'Later';
}

/// The single "how far away is this" label used across the app:
/// - within the next 60 minutes: "تبدأ بعد 12 دقيقة" / "Starts in 12 min"
/// - later today: "اليوم • 3:30 م" / "Today • 3:30 PM"
/// - tomorrow: "غدًا 3:30 م" / "Tomorrow 3:30 PM"
/// - further out: "الأحد، 13 سبتمبر 3:30 م" / "Sunday, 13 Sep 3:30 PM"
/// - already past due (activation running late): a neutral "الآن" / "Now"
///   rather than a nonsensical negative countdown.
String scheduleRelativeLabel(DateTime t, {required bool isRtl, DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = t.difference(n);
  final timeLabel = scheduleTimeLabel(t, isRtl: isRtl);

  if (diff.inMinutes <= 0) {
    return isRtl ? 'الآن' : 'Now';
  }
  if (diff.inMinutes < 60) {
    return isRtl ? 'تبدأ بعد ${diff.inMinutes} دقيقة' : 'Starts in ${diff.inMinutes} min';
  }

  final days = DateTime(t.year, t.month, t.day)
      .difference(DateTime(n.year, n.month, n.day))
      .inDays;

  if (days == 0) {
    return isRtl ? 'اليوم • $timeLabel' : 'Today • $timeLabel';
  }
  if (days == 1) {
    return isRtl ? 'غدًا $timeLabel' : 'Tomorrow $timeLabel';
  }
  final dateLabel = scheduleDateLabel(t, isRtl: isRtl);
  return isRtl ? '$dateLabel $timeLabel' : '$dateLabel $timeLabel';
}

/// Whether this ride is inside its own "about to start" window - used to
/// decide when a card should visually elevate. 15 minutes matches the
/// spec's own worked example and only affects presentation, never
/// dispatch/lifecycle behaviour.
bool isStartingSoon(DateTime t, {DateTime? now, int withinMinutes = 15}) {
  final n = now ?? DateTime.now();
  final diff = t.difference(n);
  return diff.inMinutes <= withinMinutes;
}
