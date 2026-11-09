/// What the server says about today's gift. Every amount and countdown comes from the server.
class DailyGiftOffer {
  const DailyGiftOffer({
    required this.state,
    required this.secondsLeft,
    required this.amount,
    required this.startLabel,
    required this.endLabel,
    required this.minFare,
    required this.date,
  });

  final String state; // live | upcoming | used | sold_out
  final int secondsLeft;
  final String amount;
  final String startLabel;
  final String endLabel;
  final String minFare;
  final String date;

  bool get isLive => state == 'live';

  /// null when there is nothing to show here (the campaign is off in this city)
  static DailyGiftOffer? fromJson(Map<String, dynamic>? d) {
    final state = d?['state']?.toString();
    if (d == null || state == null || state == 'off') return null;
    return DailyGiftOffer(
      state: state,
      secondsLeft: (d['seconds_left'] as num?)?.toInt() ?? 0,
      amount: d['amount']?.toString() ?? '',
      startLabel: d['start_label']?.toString() ?? '',
      endLabel: d['end_label']?.toString() ?? '',
      minFare: d['min_fare']?.toString() ?? '',
      date: d['date']?.toString() ?? '',
    );
  }

  String get headline => switch (state) {
        'live' => 'هديتك اليوم',
        'used' => 'استعملت هدية اليوم',
        'sold_out' => 'خلصت هدايا اليوم',
        _ => 'هديتك',
      };

  String get timerLabel => switch (state) {
        'live' => 'تنتهي صلاحية الهدية بعد',
        'upcoming' => 'تبدأ الهدية بعد',
        _ => 'الهدية الجاية بعد',
      };

  static String clock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  }
}
