import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';
import 'intercity_api.dart' show IntercityResult;

/// One choice the car owner picks (what happened, which car); `flatbed` = it needs a flatbed.
class TowChoice {
  const TowChoice(this.key, this.label, this.flatbed);
  final String key;
  final String label;
  final bool flatbed;
}

class TowWorkshop {
  TowWorkshop(this.raw);
  final Map raw;

  int get id => (raw['id'] as num?)?.toInt() ?? 0;
  String get name => '${raw['name'] ?? ''}';
  String get address => '${raw['address'] ?? ''}';
  double get lat => ((raw['lat'] as num?) ?? 0).toDouble();
  double get lng => ((raw['lng'] as num?) ?? 0).toDouble();
}

/// «ساحبة» where he stands: open or not, the choices, the known workshops, the price rules.
class TowHome {
  TowHome(this.raw);
  final Map raw;

  bool get enabled => raw['enabled'] == true;
  String get city => '${raw['city'] ?? ''}';
  String get currency => '${raw['currency'] ?? 'LYD'}';
  String get emergencyText => '${raw['emergency_text'] ?? ''}';
  /// «طريقة السعر»: fixed, offers or choice (the admin's)
  String get priceMode => const ['offers', 'choice'].contains(raw['price_mode']) ? '${raw['price_mode']}' : 'fixed';
  int get offerMinPercent => (raw['offer_min_percent'] as num?)?.toInt() ?? 80;
  int get offerMaxPercent => (raw['offer_max_percent'] as num?)?.toInt() ?? 200;
  int get trucksOnline => (raw['trucks_online'] as num?)?.toInt() ?? 0;
  num get liftFee => (raw['lift_fee'] as num?) ?? 0;

  static List<TowChoice> _choices(Object? list) => [
        for (final c in (list as List? ?? const []))
          if (c is Map) TowChoice('${c['key']}', '${c['label']}', c['flatbed'] == true),
      ];
  List<TowChoice> get conditions => _choices(raw['conditions']);
  List<TowChoice> get cars => _choices(raw['cars']);
  List<TowWorkshop> get workshops => [for (final w in (raw['workshops'] as List? ?? const [])) if (w is Map) TowWorkshop(w)];
}

/// The fixed price, line by line.
class TowQuote {
  TowQuote(this.raw);
  final Map raw;

  num get total => (raw['total'] as num?) ?? 0;
  num get km => (raw['km'] as num?) ?? 0;
  num get lift => (raw['lift'] as num?) ?? 0;
  num get distance => (raw['distance'] as num?) ?? 0;
  num get flatbed => (raw['flatbed'] as num?) ?? 0;
  num get night => (raw['night'] as num?) ?? 0;
  bool get needsFlatbed => raw['needs_flatbed'] == true;
}

class TowApi {
  static final notifier = ValueNotifier<TowHome?>(null);
  static DateTime? _askedAt;
  static double? _lat, _lng;

  static Map<String, String> get _headers =>
      {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json', 'Content-Type': 'application/json'};

  /// asked again when the last answer is old (3 minutes) or he moved (about 2 km); never before sign-in
  static Future<void> refresh(double lat, double lng) async {
    if (bearerToken.isEmpty) return;
    final moved = _lat == null || (lat - _lat!).abs() > 0.02 || (lng - _lng!).abs() > 0.02;
    if (_askedAt != null && !moved && DateTime.now().difference(_askedAt!) < const Duration(minutes: 3)) return;
    _askedAt = DateTime.now();
    _lat = lat;
    _lng = lng;
    try {
      final r = await http
          .get(Uri.parse('${url}api/v1/request/tow').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final d = r.statusCode == 200 ? jsonDecode(r.body)['data'] : null;
      if (d is Map) {
        notifier.value = TowHome(d);
      } else {
        _askedAt = null;
      }
    } catch (_) {
      _askedAt = null;
    }
  }

  static Future<IntercityResult> _post(String path, Map body) async {
    try {
      final r = await http.post(Uri.parse('$url$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      final j = jsonDecode(r.body);
      final ok = r.statusCode == 200 && j is Map && j['success'] == true;
      String msg = j is Map ? '${j['message'] ?? ''}' : '';
      if (!ok && j is Map && j['errors'] is Map) {
        final first = (j['errors'] as Map).values.first;
        if (first is List && first.isNotEmpty) msg = '${first.first}';
      }
      return IntercityResult(ok, msg.isEmpty ? (ok ? 'تم' : 'ما قدرناش، جرّب مرة ثانية.') : msg, j is Map ? j['data'] : null);
    } catch (_) {
      return IntercityResult(false, 'تعذر الاتصال. تأكد من الإنترنت.');
    }
  }

  static Map<String, Object?> _places(double pLat, double pLng, String pAddr, double dLat, double dLng, String dAddr) =>
      {'pick_lat': pLat, 'pick_lng': pLng, 'pick_address': pAddr, 'drop_lat': dLat, 'drop_lng': dLng, 'drop_address': dAddr};

  static Future<TowQuote?> quote(double pLat, double pLng, double dLat, double dLng, String condition, String car) async {
    final r = await _post('api/v1/request/tow/quote', {..._places(pLat, pLng, '', dLat, dLng, ''), 'condition': condition, 'car_type': car});
    return r.ok && r.data is Map ? TowQuote(r.data as Map) : null;
  }

  static Future<IntercityResult> create({
    required double pickLat,
    required double pickLng,
    required String pickAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String condition,
    required String car,
    int? workshopId,
    String note = '',
    required bool injuriesCleared,
    num? offerFare,
  }) =>
      _post('api/v1/request/tow', {
        ..._places(pickLat, pickLng, pickAddress, dropLat, dropLng, dropAddress),
        'condition': condition, 'car_type': car, if (workshopId != null) 'workshop_id': workshopId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'owner_confirmed': true, 'injuries_cleared': injuriesCleared,
        if (offerFare != null) ...{'price_mode': 'offers', 'fare': offerFare},
      });

  /// the owner's photo of the car, after the request (optional)
  static Future<bool> photo(String rideId, File file) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('${url}api/v1/request/tow/$rideId/photo'))
        ..headers.addAll({'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'})
        ..files.add(await http.MultipartFile.fromPath('image', file.path));
      final r = await req.send().timeout(const Duration(seconds: 40));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
