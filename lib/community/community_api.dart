import 'dart:convert';

import 'package:http/http.dart' as http;

import '../functions/functions.dart';

/// TAXISTA 2.0 community and rewards (api/v1/community/*, api/v1/rewards/*). Every call returns
/// null when it could not be done; the screens then show nothing extra rather than an error,
/// because all of this is optional around a ride.
class CommunityApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${url}api/v1/$path').replace(queryParameters: query);

  static Map<String, dynamic>? _data(http.Response response) {
    if (response.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map || body['success'] == false) return null;
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{'items': data};
  }

  static Future<Map<String, dynamic>?> _get(String path, [Map<String, String>? query]) async {
    try {
      return _data(await http.get(_u(path, query), headers: _headers).timeout(const Duration(seconds: 12)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      return _data(await http.post(_u(path), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12)));
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- after a ride

  /// What the after-ride screen offers for this ride (heart, badges, comment, gold gift).
  static Future<Map<String, dynamic>?> afterRide(String requestId) => _get('community/rides/$requestId/after');

  static Future<Map<String, dynamic>?> submitAfterRide(String requestId,
          {bool? favorite, List<String> badges = const [], String? comment, bool gift = false, String? giftReason}) =>
      _post('community/rides/$requestId/after', {
        if (favorite != null) 'favorite': favorite,
        if (badges.isNotEmpty) 'badges': badges,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        if (gift) 'gift': true,
        if (gift && giftReason != null) 'gift_reason': giftReason,
      });

  // ---------------------------------------------------------------- "سواقيني"

  static Future<List<Map<String, dynamic>>?> favorites() async {
    final data = await _get('community/favorites');
    final items = data?['items'];
    return items is List ? [for (final f in items) if (f is Map) Map<String, dynamic>.from(f)] : null;
  }

  static Future<bool> addFavorite(int driverId, {String? requestId}) async =>
      await _post('community/favorites', {'driver_id': driverId, if (requestId != null) 'request_id': requestId}) != null;

  static Future<bool> removeFavorite(int driverId) async {
    try {
      final response = await http.delete(_u('community/favorites/$driverId'), headers: _headers);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// At booking: favourite drivers who can take this ride now (nearest first, at most three).
  static Future<List<Map<String, dynamic>>> availableFavorites(double lat, double lng, String zoneTypeId) async {
    final data = await _get('community/favorites/available',
        {'pick_lat': '$lat', 'pick_lng': '$lng', 'vehicle_type': zoneTypeId});
    final drivers = data?['drivers'];
    return drivers is List ? [for (final d in drivers) if (d is Map) Map<String, dynamic>.from(d)] : const [];
  }

  static Future<Map<String, dynamic>?> driverProfile(int driverId) => _get('community/drivers/$driverId/profile');

  // ---------------------------------------------------------------- safety

  static Future<bool> report(String targetType, String targetId, String reason, {String? details}) async =>
      await _post('community/report', {
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
      }) !=
      null;

  static Future<bool> blockDriver(int driverId) async => await _post('community/block', {'driver_id': driverId}) != null;

  // ---------------------------------------------------------------- rewards

  static Future<Map<String, dynamic>?> rewards() => _get('rewards/summary');

  /// Returns the server's message (Arabic) on success, null otherwise.
  static Future<String?> convertGold(String idempotencyKey) async {
    final data = await _post('rewards/gold/convert', {'idempotency_key': idempotencyKey});
    return data?['message_ar']?.toString();
  }

  static Future<bool> setMarketingOptOut(bool optedOut) async =>
      await _post('rewards/marketing', {'opted_out': optedOut}) != null;
}

/// The favourite driver the rider chose for the next immediate request (null = the usual search).
int? chosenFavoriteDriverId;

/// Adds the chosen favourite to an immediate request's JSON body; the server checks it again.
String withChosenFavorite(dynamic body) {
  if (chosenFavoriteDriverId == null || body is! String) return body.toString();
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return body;
    return jsonEncode({...decoded, 'preferred_driver_id': chosenFavoriteDriverId});
  } catch (_) {
    return body;
  }
}
