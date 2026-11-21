import 'dart:convert';

import 'package:http/http.dart' as http;

/// The address under the map pin, asked from Taxista's server instead of Google (owner 2026-11-21:
/// Google billed Geocoding over the free 10,000/month because every pin stop asked Google and the
/// app's cache keyed on the exact coordinates, so it never hit).
///
/// The server keeps one shared answer per ~30 m cell for everybody; the app keeps the same cell
/// for 30 days, so moving the pin a few metres asks nobody.
class PinAddress {
  PinAddress._();

  /// must match the server's ReverseGeocoder::CELL
  static const double cell = 0.0003;
  static const Duration keep = Duration(days: 30);

  static String lang(String chosen) => chosen == 'en' ? 'en' : 'ar';

  static String _centre(double v) => (((v / cell).floor() + 0.5) * cell).toStringAsFixed(5);

  static String cacheKey(double lat, double lng, String lang) => 'v2:$lang:${_centre(lat)},${_centre(lng)}';

  /// `answered` false = the server could not be asked (no sign-in, offline, an older server):
  /// the caller may fall back to its old way. `answered` true with a null address = nothing to show
  /// (no street there, or today's ceiling reached) and must NOT go to Google behind the server's back.
  static Future<({bool answered, String? address, bool cacheable})> fromServer({
    required String baseUrl,
    required String? token,
    required double lat,
    required double lng,
    required String lang,
    http.Client? client,
  }) async {
    if (token == null || token.isEmpty) return (answered: false, address: null, cacheable: false);
    final uri = Uri.parse('${baseUrl}api/v1/common/reverse-geocode').replace(queryParameters: {
      'lat': lat.toStringAsFixed(6),
      'lng': lng.toStringAsFixed(6),
      'lang': lang,
    });
    try {
      final c = client ?? http.Client();
      final res = await c
          .get(uri, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (client == null) c.close();
      if (res.statusCode != 200) return (answered: false, address: null, cacheable: false);
      // utf8 always: a JSON reply without a charset would otherwise be read as latin1 and garble Arabic
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is! Map || body['success'] != true) return (answered: false, address: null, cacheable: false);
      final a = body['address'];
      final address = a is String && a.trim().isNotEmpty ? a.trim() : null;
      return (answered: true, address: address, cacheable: address != null);
    } catch (_) {
      return (answered: false, address: null, cacheable: false);
    }
  }
}
