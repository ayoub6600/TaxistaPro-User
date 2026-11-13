import 'dart:convert';
import 'tr.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';
import 'intercity_api.dart' show IntercityResult;

/// «توصيل»: is it open where he stands, and the admin's sizes and prices.
class ParcelHome {
  ParcelHome(this.raw);
  final Map raw;

  bool get enabled => raw['enabled'] == true;
  String get city => '${raw['city'] ?? ''}';
  String get currency => '${raw['currency'] ?? 'LYD'}';
  String get banned => '${raw['banned'] ?? ''}';
  /// «طريقة السعر»: fixed, offers or choice (the admin's)
  String get priceMode => const ['offers', 'choice'].contains(raw['price_mode']) ? '${raw['price_mode']}' : 'fixed';
  int get offerMinPercent => (raw['offer_min_percent'] as num?)?.toInt() ?? 80;
  int get offerMaxPercent => (raw['offer_max_percent'] as num?)?.toInt() ?? 200;
  int get waitMinutes => (raw['receiver_wait_minutes'] as num?)?.toInt() ?? 10;
  List<Map> get sizes => [for (final s in (raw['sizes'] as List? ?? const [])) if (s is Map) s];
}

class ParcelApi {
  static final notifier = ValueNotifier<ParcelHome?>(null);
  static DateTime? _askedAt;
  static double? _lat, _lng;

  static Map<String, String> get _headers =>
      {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json', 'Content-Type': 'application/json'};

  /// ask again only when the last answer is old (3 minutes) or he moved (about 2 km)
  static Future<void> refresh(double lat, double lng) async {
    // not signed in yet: ask on the next build, never mark it as asked
    if (bearerToken.isEmpty) return;
    final moved = _lat == null || (lat - _lat!).abs() > 0.02 || (lng - _lng!).abs() > 0.02;
    if (_askedAt != null && !moved && DateTime.now().difference(_askedAt!) < const Duration(minutes: 3)) return;
    _askedAt = DateTime.now();
    _lat = lat;
    _lng = lng;
    try {
      final r = await http
          .get(Uri.parse('${url}api/v1/request/parcels').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final d = r.statusCode == 200 ? jsonDecode(r.body)['data'] : null;
      if (d is Map) {
        notifier.value = ParcelHome(d);
      } else {
        _askedAt = null; // a failed answer is asked again on the next build
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
      return IntercityResult(ok, msg.isEmpty ? (ok ? tr('تم', 'Done') : tr('ما قدرناش، جرّب مرة ثانية.', 'We could not do it, try again.')) : msg, j is Map ? j['data'] : null);
    } catch (_) {
      return IntercityResult(false, tr('تعذر الاتصال. تأكد من الإنترنت.', 'No connection. Check the internet.'));
    }
  }

  static Map<String, Object?> _places(double pLat, double pLng, String pAddr, double dLat, double dLng, String dAddr) =>
      {'pick_lat': pLat, 'pick_lng': pLng, 'pick_address': pAddr, 'drop_lat': dLat, 'drop_lng': dLng, 'drop_address': dAddr};

  static Future<IntercityResult> quote(double pLat, double pLng, double dLat, double dLng, String size) =>
      _post('api/v1/request/parcels/quote', {..._places(pLat, pLng, '', dLat, dLng, ''), 'size': size});

  static Future<IntercityResult> create({
    required double pickLat,
    required double pickLng,
    required String pickAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String size,
    required String receiverName,
    required String receiverPhone,
    required String note,
    required String payer,
    required String payment,
    num? offerFare,
  }) =>
      _post('api/v1/request/parcels', {
        ..._places(pickLat, pickLng, pickAddress, dropLat, dropLng, dropAddress),
        'size': size, 'receiver_name': receiverName, 'receiver_phone': receiverPhone,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'payer': payer, 'payment': payment, 'accept_rules': true,
        if (offerFare != null) ...{'price_mode': 'offers', 'fare': offerFare},
      });
}
