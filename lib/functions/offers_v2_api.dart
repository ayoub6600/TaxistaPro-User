import 'dart:convert';

import 'package:http/http.dart' as http;

import 'functions.dart';

/// «العروض والبحث» v2: the new search screen for a negotiated ride now, when the admin turned it on.
/// The server sends `offers_v2` in the profile (on/off, minutes) and in the ride (offer time, the
/// favourite who sees it first, the auto-accept price).
class OffersV2 {
  static Map? _profile(Map user) => user['offers_v2'] is Map ? user['offers_v2'] as Map : null;
  static Map? _ride(Map ride) => ride['offers_v2'] is Map ? ride['offers_v2'] as Map : null;

  static bool _on(Object? v) => v == true || v == 1 || '$v' == '1' || '$v'.toLowerCase() == 'true';

  static bool isBidding(Map ride) => _on(ride['is_bid_ride']) || '${ride['pricing_mode'] ?? ''}'.toLowerCase() == 'bidding';

  /// a negotiated ride now, the admin's switch on
  static bool activeFor(Map ride, Map user) =>
      ride.isNotEmpty && isBidding(ride) && !_on(ride['is_later']) && (_on(_profile(user)?['enabled']) || _ride(ride) != null);

  static int searchSeconds(Map ride, Map user) =>
      int.tryParse('${_ride(ride)?['search_seconds'] ?? _profile(user)?['search_seconds'] ?? ''}') ?? 120;

  /// how long a driver's price waits for the rider (the admin's «مهلة رد الزبون»)
  static int offerSeconds(Map ride) => (int.tryParse('${_ride(ride)?['offer_seconds'] ?? ''}') ?? 30).clamp(5, 600);

  static bool autoAcceptAllowed(Map user) => _profile(user)?['auto_accept'] != false;

  static double? autoAcceptMax(Map ride) => double.tryParse('${_ride(ride)?['auto_accept_max'] ?? ''}');

  /// «طلبك عند أحمد أول»: {driver_id, name, seconds_left}
  static Map? favorite(Map ride) => _ride(ride)?['favorite'] is Map ? _ride(ride)!['favorite'] as Map : null;

  /// the rider's own price now
  static double currentFare(Map ride) =>
      double.tryParse('${ride['rider_proposed_fare'] ?? ''}') ??
      double.tryParse('${ride['offerred_ride_fare'] ?? ''}') ??
      double.tryParse('${ride['request_eta_amount'] ?? ''}') ??
      0;

  /// the step of − / + (the admin's bidding step, 1 by default)
  static double step(Map user) {
    final s = double.tryParse('${user['bidding_amount_increase_or_decrease'] ?? ''}') ?? 1;
    return s > 0 ? s : 1;
  }

  static Future<OffersV2Result> _post(String path, Map body) async {
    try {
      final r = await http
          .post(Uri.parse('${url}api/v1/request/$path'),
              headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json', 'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      final j = jsonDecode(r.body);
      final ok = r.statusCode == 200 && j is Map && j['success'] == true;
      return OffersV2Result(ok, j is Map ? '${j['message'] ?? ''}' : '', j is Map && j['data'] is Map ? j['data'] as Map : const {});
    } catch (_) {
      return OffersV2Result(false, 'تعذر الاتصال. تأكد من الإنترنت.', const {});
    }
  }

  /// «كمّل البحث»
  static Future<OffersV2Result> keepSearching(String requestId) => _post('search/keep-searching', {'request_id': requestId});

  /// «أرسل 18»: the new price goes to the drivers who saw the ride
  static Future<OffersV2Result> raise(String requestId, double fare) => _post('search/raise', {'request_id': requestId, 'fare': fare});

  /// «اقبل تلقائيًا لين X» (null switches it off)
  static Future<OffersV2Result> autoAccept(String requestId, double? max) => _post('search/auto-accept', {'request_id': requestId, 'max_fare': max});

  static String money(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  static String clock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class OffersV2Result {
  const OffersV2Result(this.ok, this.message, this.data);
  final bool ok;
  final String message;
  final Map data;
}
