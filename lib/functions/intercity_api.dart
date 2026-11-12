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

  /// «ذهاب ورجوع · الكابتن يستناك»: {suggested, min, max, max_wait_hours}, null when the admin turned it off
  Map? get roundTrip => raw['round_trip'] is Map ? raw['round_trip'] as Map : null;

  /// the drive one way, roughly (from where he stands)
  int? get travelMinutes => (raw['travel_minutes'] as num?)?.toInt();
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

/// «نفس السفرة مرة ثانية»: his last finished travel from this city, with the price to book it again.
/// The price is what he paid while the route's price is the same; once the admin changed it, the new one.
class IntercityLastTrip {
  IntercityLastTrip(this.raw);
  final Map raw;

  bool get isSeat => raw['kind'] == 'seat';
  int get routeId => (raw['route_id'] as num?)?.toInt() ?? 0;
  String get to => '${raw['to'] ?? ''}';
  String get date => '${raw['date'] ?? ''}';
  int get passengers => (raw['passengers'] as num?)?.toInt() ?? 1;
  int get seats => (raw['seats'] as num?)?.toInt() ?? 1;
  bool get bigBag => raw['big_bag'] == true;
  bool get roundTrip => raw['round_trip'] == true;
  int get waitHours => (raw['wait_hours'] as num?)?.toInt() ?? 4;
  num get paid => (raw['paid'] as num?) ?? 0;
  num get price => (raw['price'] as num?) ?? paid;
  bool get priceChanged => raw['price_changed'] == true;
  int get openTrips => (raw['open_trips'] as num?)?.toInt() ?? 0;
  num? get cheapestSeat => raw['cheapest_seat'] as num?;
  IcPlace? get drop {
    final d = raw['drop'];
    if (d is! Map || d['lat'] is! num || d['lng'] is! num) return null;
    return IcPlace((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble(), '${d['address'] ?? ''}');
  }

  /// «3 نوفمبر»
  String get dateLabel {
    final t = DateTime.tryParse(date);
    if (t == null) return date;
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${t.day} ${months[t.month - 1]}';
  }
}

/// «كيف كانت السفرة مع محمد؟»: a seat he travelled in and has not rated yet
class IntercityToRate {
  IntercityToRate(this.raw);
  final Map raw;

  int get bookingId => (raw['booking_id'] as num?)?.toInt() ?? 0;
  String get to => '${raw['to'] ?? ''}';
  String get driver => '${raw['driver'] ?? 'الكابتن'}';
  int get seats => (raw['seats'] as num?)?.toInt() ?? 1;
  num get price => (raw['price'] as num?) ?? 0;
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
  bool get roundTripOn => (raw['rules'] is Map ? raw['rules']['round_trip'] : null) == true;
  int get maxWaitHours => ((raw['rules'] is Map ? raw['rules']['max_wait_hours'] : null) as num?)?.toInt() ?? 8;
  IntercityLastTrip? get lastTrip => raw['last_trip'] is Map ? IntercityLastTrip(raw['last_trip'] as Map) : null;
  IntercityToRate? get toRate => raw['to_rate'] is Map ? IntercityToRate(raw['to_rate'] as Map) : null;
  IcPayment get payment => IcPayment(raw['payment'] is Map ? raw['payment'] as Map : const {});
}

/// The answer of a call: ok with data, or the server's own Arabic reason.
class IntercityResult {
  IntercityResult(this.ok, this.message, [this.data, this.code]);
  final bool ok;
  final String message;
  final dynamic data;
  final String? code;

  /// «اشحن محفظتك»: the booking pays online first and the wallet is short
  bool get needsTopUp => code == 'intercity_needs_topup';
  num get amount => (data is Map ? data['amount'] as num? : null) ?? 0;
  num get balance => (data is Map ? data['balance'] as num? : null) ?? 0;
  num get missing => (data is Map ? data['missing'] as num? : null) ?? 0;
}

/// «الدفع» in travel, as the admin set it: cash to the driver, online first from the wallet, or the
/// rider chooses — for a whole car and/or seats — and how much first (100 = the whole price).
class IcPayment {
  IcPayment(this.raw);
  final Map raw;

  String get mode => '${raw['mode'] ?? 'cash'}';
  bool get car => raw['car'] != false;
  bool get seats => raw['seats'] != false;
  int get depositPercent => (raw['deposit_percent'] as num?)?.toInt() ?? 100;
  int get latePercent => (raw['late_cancel_driver_percent'] as num?)?.toInt() ?? 10;
  int get freeCancelHours => (raw['free_cancel_hours'] as num?)?.toInt() ?? 2;
  num get balance => (raw['balance'] as num?) ?? 0;

  /// may he choose? (else it is forced one way)
  bool choiceFor(bool isCar) => mode == 'choice' && (isCar ? car : seats);

  /// does this booking pay online, given what he picked when he could choose
  bool onlineFor(bool isCar, {bool chose = false}) => (isCar ? car : seats) && (mode == 'online' || (mode == 'choice' && chose));

  num firstPart(num fare) => (fare * depositPercent / 100 * 100).round() / 100;
}

class IntercityApi {
  /// the last answer for the place the rider stands, kept so the search screen shows it at once
  static IntercityHome? last;
  static final notifier = ValueNotifier<IntercityHome?>(null);
  static DateTime? _askedAt;
  static double? _askedLat, _askedLng;

  /// where he stood the last time the travel offer was read (a push opens with it)
  static (double, double)? get lastPlace => _askedLat == null ? null : (_askedLat!, _askedLng!);

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
      return IntercityResult(ok, msg.isEmpty ? (ok ? 'تم' : 'ما قدرناش، جرّب مرة ثانية.') : msg, j is Map ? j['data'] : null, j is Map ? j['code']?.toString() : null);
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
    int? waitHours,
    bool payOnline = false,
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
      // «ذهاب ورجوع · الكابتن يستناك» the same day
      if (waitHours != null) 'intercity_round_trip': 1,
      if (waitHours != null) 'intercity_wait_hours': waitHours,
      // «الزبون يختار»: he picked online (the server decides for «online» and «cash»)
      if (payOnline) 'intercity_pay_online': 1,
    });
  }

  static Future<IntercityResult> rateSeat(int bookingId, int stars, List<String> tags) =>
      _post('api/v1/request/intercity/seats/rate', {'booking_id': bookingId, 'rating': stars, 'tags': tags});

  static Future<IntercityResult> bookSeats(int tripId, int seats, {String pickAddress = '', double? pickLat, double? pickLng, bool payOnline = false}) =>
      _post('api/v1/request/intercity/seats/book', {
        'trip_id': tripId, 'seats': seats,
        if (payOnline) 'pay_online': true,
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
