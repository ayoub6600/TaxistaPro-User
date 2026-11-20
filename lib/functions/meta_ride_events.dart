import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What Meta's ads learn from (owner 2026-11-20: «فيسبوك يجيبلنا ناس يطلبوا فعلًا، مش ينزّلوا بس»):
/// every finished ride is a Purchase with its fare, and the first one is also «FirstRide».
/// Sent once per ride, whatever reopens the invoice. Nothing personal goes with it.
class MetaRideEvents {
  static final _fb = FacebookAppEvents();
  static const _key = 'meta_ride_events_logged';
  static const _firstKey = 'meta_first_ride_logged';

  static Future<void> rideFinished(Map ride) async {
    final id = '${ride['id'] ?? ''}';
    if (id.isEmpty || ride['is_completed'] != 1 && ride['is_completed'] != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getStringList(_key) ?? <String>[];
      if (done.contains(id)) return;
      final bill = ride['requestBill'] is Map ? ride['requestBill']['data'] : null;
      final amount = double.tryParse('${bill is Map ? bill['total_amount'] : ride['request_eta_amount']}') ?? 0;
      final currency = '${ride['requested_currency_code'] ?? 'LYD'}';
      final kind = '${ride['service_kind'] ?? 'ride'}';
      await _fb.logPurchase(amount: amount, currency: currency, parameters: {'service': kind});
      await _fb.logEvent(name: 'RideCompleted', parameters: {'service': kind, 'value': amount, 'currency': currency}, valueToSum: amount);
      if (prefs.getBool(_firstKey) != true) {
        await _fb.logEvent(name: 'FirstRide', parameters: {'service': kind}, valueToSum: amount);
        await prefs.setBool(_firstKey, true);
      }
      await prefs.setStringList(_key, [...done.skip(done.length > 50 ? done.length - 50 : 0), id]);
    } catch (_) {}
  }
}
