import 'dart:convert';

import 'package:http/http.dart' as http;

import '../functions/functions.dart';

/// The home map's real captains (api/v1/request/map-around) and «فيه فلان بعيد عليك» while
/// searching (api/v1/request/{id}/far-captains). Every call returns null when it could not be
/// done; the screens then simply show nothing extra.
class SupplyApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${url}api/v1/request/$path').replace(queryParameters: query);

  static Map<String, dynamic>? _data(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) return null;
    if (response.statusCode != 200 || body['success'] == false) {
      return {'_error': (body['message'] ?? '').toString()};
    }
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>?> mapAround(double lat, double lng) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http
          .get(_u('map-around', {'lat': '$lat', 'lng': '$lng'}), headers: _headers)
          .timeout(const Duration(seconds: 10)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> farCaptains(String requestId) async {
    if (bearerToken.isEmpty || requestId.isEmpty) return null;
    try {
      return _data(await http.get(_u('$requestId/far-captains'), headers: _headers).timeout(const Duration(seconds: 10)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> pick(String requestId, int driverId) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http.post(_u('$requestId/far-captains/$driverId'), headers: _headers).timeout(const Duration(seconds: 12)));
    } catch (_) {
      return null;
    }
  }
}
