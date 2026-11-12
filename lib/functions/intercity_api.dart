import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// a place on the trip: where he leaves from, or the exact place in the other city
class IcPlace {
  const IcPlace(this.lat, this.lng, this.address);
  final double lat;
  final double lng;
  final String address;
}

/// «سفر بين المدن»: a city the rider can travel to from where he stands, with the admin's price.
class IntercityRoute {
  IntercityRoute(this.raw);
  final Map raw;

  int get id => (raw['route_id'] as num?)?.toInt() ?? 0;
  String get to => '${raw['to'] ?? ''}';
  String get from => '${raw['from'] ?? ''}';
  num get suggested => (raw['suggested'] as num?) ?? 0;
  num get min => (raw['min'] as num?) ?? 0;
  num get max => (raw['max'] as num?) ?? 0;
  num? get seatPrice => raw['seat_price'] as num?;

  /// «أغلب الطلبات تنقبل من X» (only once the route has enough taken rides)
  num? get acceptedFrom => raw['accepted_from'] as num?;
  double get lat => ((raw['to_lat'] as num?) ?? 0).toDouble();
  double get lng => ((raw['to_lng'] as num?) ?? 0).toDouble();
}

/// A shared trip a chosen driver posted: «مسافر بكرة لطرابلس، عندي 3 كراسي».
class SharedTrip {
  SharedTrip(this.raw);
  final Map raw;

  int get id => (raw['id'] as num?)?.toInt() ?? 0;
  String get to => '${raw['to'] ?? ''}';
  String get departAt => '${raw['depart_at'] ?? ''}';
  num get seatPrice => (raw['seat_price'] as num?) ?? 0;
  int get seatsLeft => (raw['seats_left'] as num?)?.toInt() ?? 0;
  int get seatsTotal => (raw['seats_total'] as num?)?.toInt() ?? 0;
  String get meetingPoint => '${raw['meeting_point'] ?? ''}';
  Map get driver => raw['driver'] is Map ? raw['driver'] as Map : const {};
}

class IntercityHome {
  IntercityHome(this.raw);
  final Map raw;

  bool get enabled => raw['enabled'] == true;
  String get from => '${raw['from'] ?? ''}';
  String? get zoneTypeId => raw['zone_type_id']?.toString();
  List<IntercityRoute> get routes => [for (final r in (raw['routes'] as List? ?? const [])) if (r is Map) IntercityRoute(r)];
  List<SharedTrip> get shared => [for (final t in (raw['shared'] as List? ?? const [])) if (t is Map) SharedTrip(t)];
  List<Map> get mySeats => [for (final t in (raw['my_seats'] as List? ?? const [])) if (t is Map) t];
  int get horizonDays => ((raw['rules'] is Map ? raw['rules']['horizon_days'] : null) as num?)?.toInt() ?? 7;
  int get maxPassengers => ((raw['rules'] is Map ? raw['rules']['max_passengers'] : null) as num?)?.toInt() ?? 4;
  int get freeCancelHours => ((raw['rules'] is Map ? raw['rules']['free_cancel_hours'] : null) as num?)?.toInt() ?? 2;
}

/// The answer of a call: ok with data, or the server's own Arabic reason.
class IntercityResult {
  IntercityResult(this.ok, this.message, [this.data]);
  final bool ok;
  final String message;
  final dynamic data;
}

class IntercityApi {
  /// the last answer for the place the rider stands, kept so the search screen shows it at once
  static IntercityHome? last;
  static final notifier = ValueNotifier<IntercityHome?>(null);
  static DateTime? _askedAt;
  static double? _askedLat, _askedLng;

  /// ask again only when the last answer is old (3 minutes) or he moved (about 2 km)
  static Future<void> refresh(double lat, double lng) async {
    final at = _askedAt;
    final moved = _askedLat == null || (lat - _askedLat!).abs() > 0.02 || (lng - _askedLng!).abs() > 0.02;
    if (at != null && !moved && DateTime.now().difference(at) < const Duration(minutes: 3)) return;
    _askedAt = DateTime.now();
    _askedLat = lat;
    _askedLng = lng;
    final h = await home(lat, lng);
    if (h != null) notifier.value = h;
  }

  static Map<String, String> get _headers =>
      {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json', 'Content-Type': 'application/json'};

  static Future<IntercityHome?> home(double lat, double lng) async {
    if (bearerToken.isEmpty) return null;
    try {
      final r = await http
          .get(Uri.parse('${url}api/v1/request/intercity').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final data = jsonDecode(r.body)['data'];
      return last = data is Map ? IntercityHome(data) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<IntercityResult> _post(String path, Map body) async {
    try {
      final r = await http.post(Uri.parse('$url$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      final ok = r.statusCode == 200 && j is Map && j['success'] == true;
      final msg = j is Map ? '${j['message'] ?? ''}' : '';
      return IntercityResult(ok, msg.isEmpty ? (ok ? 'تم' : 'ما قدرناش، جرّب مرة ثانية.') : msg, j is Map ? j['data'] : null);
    } catch (_) {
      return IntercityResult(false, 'تعذر الاتصال. تأكد من الإنترنت.');
    }
  }

  /// the price for an exact drop (the fixed price + per km beyond the city centre)
  static Future<Map?> quote(double pickLat, double pickLng, double dropLat, double dropLng) async {
    final r = await _post('api/v1/request/intercity/quote', {'pick_lat': pickLat, 'pick_lng': pickLng, 'drop_lat': dropLat, 'drop_lng': dropLng});
    return r.ok && r.data is Map && r.data['intercity'] == true ? r.data as Map : null;
  }

  /// a whole car: a scheduled bidding ride; drivers answer with a price and a time
  static Future<IntercityResult> requestCar({
    required String zoneTypeId,
    required double pickLat,
    required double pickLng,
    required String pickAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required DateTime start,
    required num fare,
    required int passengers,
    required bool bigBag,
    String note = '',
  }) {
    return _post('api/v1/request/create', {
      'pick_lat': pickLat, 'pick_lng': pickLng, 'pick_address': pickAddress,
      'drop_lat': dropLat, 'drop_lng': dropLng, 'drop_address': dropAddress,
      'vehicle_type': zoneTypeId, 'ride_type': 1, 'payment_opt': 1,
      'is_later': 1, 'is_out_station': 1, 'is_bid_ride': 1,
      'trip_start_time': wallClock(start),
      'rider_proposed_fare': fare, 'offerred_ride_fare': fare,
      'passengers': passengers, 'big_bag': bigBag, 'is_luggage_available': bigBag,
      if (note.trim().isNotEmpty) 'intercity_note': note.trim(),
    });
  }

  static Future<IntercityResult> bookSeats(int tripId, int seats, {String pickAddress = '', double? pickLat, double? pickLng}) =>
      _post('api/v1/request/intercity/seats/book', {
        'trip_id': tripId, 'seats': seats,
        if (pickAddress.isNotEmpty) 'pick_address': pickAddress,
        if (pickLat != null) 'pick_lat': pickLat,
        if (pickLng != null) 'pick_lng': pickLng,
      });

  static Future<IntercityResult> cancelSeats(int bookingId) => _post('api/v1/request/intercity/seats/cancel', {'booking_id': bookingId});

  /// the whole-car request with its offers (scheduled_offers), as the rider sees it
  static Future<Map?> ride(String id) async {
    try {
      final r = await http.get(Uri.parse('${url}api/v1/request/scheduled/$id'), headers: _headers).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(r.body)['data'];
      return d is Map ? (d['data'] is Map ? d['data'] as Map : d) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<IntercityResult> acceptOffer(int offerId) => _post('api/v1/request/scheduled/offers/accept', {'offer_id': offerId});

  static Future<IntercityResult> raise(String rideId, num fare) => _post('api/v1/request/intercity/$rideId/raise', {'fare': fare});

  static Future<IntercityResult> cancel(String rideId, String reason) =>
      _post('api/v1/request/cancel', {'request_id': rideId, 'custom_reason': reason});

  /// the market wall clock the server expects: Y-m-d H:i:s
  static String wallClock(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:00';
  }

  /// «بكرة 7:00 الصبح» from a server Y-m-d H:i[:s]
  static String dayLabel(String s, {DateTime? now}) {
    final t = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (t == null) return s;
    final today = now ?? DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final diff = DateTime(t.year, t.month, t.day).difference(d0).inDays;
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final day = diff == 0 ? 'اليوم' : diff == 1 ? 'بكرة' : days[t.weekday - 1];
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final part = t.hour < 12 ? 'الصبح' : (t.hour < 17 ? 'الظهر' : 'بالليل');
    return '$day $h:${t.minute.toString().padLeft(2, '0')} $part';
  }
}
