import 'dart:convert';

import 'package:http/http.dart' as http;

import '../functions/functions.dart';

/// Taxista Growth for riders (api/v1/user/growth/*): «هداياي», the gift a fare would use before
/// booking, the gift line of a receipt, and "tell me when a driver is free". Every call returns
/// null when it could not be done; the screens then show nothing extra, because a gift is never
/// in the way of a ride. All amounts and the countdown come from the server.
class GrowthApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${url}api/v1/user/growth/$path').replace(queryParameters: query);

  static Map<String, dynamic>? _data(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) return null;
    if (response.statusCode != 200 || body['success'] == false) {
      return {'_error': (body['message'] ?? '').toString()};
    }
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> _get(String path, [Map<String, String>? query]) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http.get(_u(path, query), headers: _headers).timeout(const Duration(seconds: 12)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http.post(_u(path), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12)));
    } catch (_) {
      return null;
    }
  }

  /// balance, server_time, gifts[] (state, amount, remaining, seconds_left), rules
  static Future<Map<String, dynamic>?> gifts() async {
    final d = await _get('gifts');
    return d == null || d.containsKey('_error') ? null : d;
  }

  static Future<Map<String, dynamic>?> offer(String ref) => _get('offers/$ref');

  /// How much of the rider's gift this fare would use (the booking applies the same rule).
  static Future<Map<String, dynamic>?> preview(
      {required String zoneTypeId, required double fare, required String pricingMode, bool coupon = false, bool later = false}) async {
    final d = await _get('preview', {
      'zone_type_id': zoneTypeId,
      'fare': fare.toStringAsFixed(2),
      'pricing_mode': pricingMode,
      if (coupon) 'coupon': '1',
      if (later) 'later': '1',
    });
    return d == null || d.containsKey('_error') ? null : d;
  }

  /// The gift used on one of the rider's own rides, for the receipt.
  static Future<Map<String, dynamic>?> rideGift(String requestId) async {
    final d = await _get('rides/$requestId');
    return d == null || d.containsKey('_error') ? null : d;
  }

  /// Watch for a free driver near the last request that found none (15, 30 or 60 minutes).
  /// Returns {message} or {_error}.
  static Future<Map<String, dynamic>?> rescue(int minutes, {String? requestId}) =>
      _post('rescue', {'minutes': minutes, if (requestId != null && requestId.isNotEmpty) 'request_id': requestId});

  static Future<void> cancelRescue() => _post('rescue/cancel', {});
}

/// A gift link (https://taxista.aljidartech.com/offers/<ref>) that opened the app: kept until the
/// rider reaches the home screen signed in, then «هداياي» opens on that gift.
class GrowthLinks {
  static String? pendingRef;

  static String? refFrom(String? route) {
    if (route == null) return null;
    final m = RegExp(r'^/offers/([A-Za-z0-9]{1,40})/?$').firstMatch(Uri.tryParse(route)?.path ?? route);
    return m?.group(1);
  }
}

/// The one-tap reasons the server knows (their Arabic labels are the server's own).
const quickCancelReasons = [
  ('price', 'السعر أعلى من المتوقع'),
  ('wait', 'الانتظار طويل'),
  ('changed_mind', 'غيّرت رأيي'),
  ('mistake', 'طلبت بالغلط'),
  ('other_ride', 'لقيت مواصلة أخرى'),
];

Future<bool> sendQuickCancelReason(String key) async {
  final d = await GrowthApi._post('cancel-reason', {'key': key});
  return d != null && d['saved'] == true;
}
