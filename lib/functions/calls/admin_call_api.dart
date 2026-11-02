import 'dart:convert';

import 'package:http/http.dart' as http;

import '../functions.dart';

/// Calls with the administration and with the driver of the current ride: the rider API side of
/// the backend's CallService. The server only relays the two session descriptions (offer /
/// answer) and mints short-lived TURN credentials; the voice itself is WebRTC.
class AdminCallApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Uri _u(String path) => Uri.parse('${url}api/v1/user/$path');

  static Future<AdminCallResult> _send(Future<http.Response> request) async {
    try {
      final r = await request.timeout(const Duration(seconds: 12));
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(r.body) as Map<String, dynamic>;
      } catch (_) {}
      return AdminCallResult(r.statusCode, body);
    } catch (e) {
      return AdminCallResult(0, {'message': 'تعذّر الاتصال بالخادم. تحقق من الإنترنت.'});
    }
  }

  /// With [requestId]: whether the driver of that ride (from the trip history) can be called.
  static Future<AdminCallResult> availability({String? requestId}) => _send(http.get(
      _u('calls/availability').replace(queryParameters: {if (requestId != null) 'request_id': requestId}),
      headers: _headers));

  /// [to]: 'admin' or 'driver' (the driver of [requestId], or of the current ride).
  static Future<AdminCallResult> start({String to = 'admin', String? requestId}) => _send(http.post(_u('calls'),
      headers: _headers, body: jsonEncode({'to': to, if (requestId != null) 'request_id': requestId})));

  static Future<AdminCallResult> log() => _send(http.get(_u('calls/log'), headers: _headers));

  /// This app version can take calls (the server never rings older versions). [fullScreen]: whether
  /// this Android phone may show a call over the lock screen (the caller is told when not).
  static Future<AdminCallResult> ready(String platform, String version, {bool? fullScreen, bool? batteryRestricted}) => _send(http.post(_u('calls/ready'),
      headers: _headers,
      // alerts: this version confirms every call it shows (AdminCallApi.alerted), so "ringing" means ringing
      body: jsonEncode({
        'platform': platform,
        'version': version,
        'alerts': true,
        if (fullScreen != null) 'full_screen': fullScreen,
        if (batteryRestricted != null) 'battery_restricted': batteryRestricted,
      })));

  /// The phone shows the incoming call: open the signed link that came with the push (no login
  /// needed, so it works from the background isolate too). Only then does the caller see "ringing".
  static Future<void> alerted(Map data) async {
    final u = Uri.tryParse((data['alerted_url'] ?? '').toString());
    if (u == null || !u.hasScheme) return;
    try {
      await http.get(u).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  static Future<AdminCallResult> state(String id, {bool ice = false}) =>
      _send(http.get(_u('calls/$id${ice ? '?ice=1' : ''}'), headers: _headers));

  static Future<AdminCallResult> offer(String id, String sdp) => _send(http
      .post(_u('calls/$id/offer'), headers: _headers, body: jsonEncode({'sdp': sdp})));

  static Future<AdminCallResult> answer(String id, String sdp) => _send(http
      .post(_u('calls/$id/answer'), headers: _headers, body: jsonEncode({'sdp': sdp})));

  static Future<AdminCallResult> decline(String id) =>
      _send(http.post(_u('calls/$id/decline'), headers: _headers, body: '{}'));

  static Future<AdminCallResult> end(String id) =>
      _send(http.post(_u('calls/$id/end'), headers: _headers, body: '{}'));

  static Future<AdminCallResult> voipToken(String token) => _send(http.post(
      _u('calls/voip-token'),
      headers: _headers,
      body: jsonEncode({'token': token})));
}

class AdminCallResult {
  final int status;
  final Map<String, dynamic> body;

  AdminCallResult(this.status, this.body);

  bool get ok => status >= 200 && status < 300 && body['success'] != false;

  Map<String, dynamic> get data =>
      (body['data'] is Map) ? Map<String, dynamic>.from(body['data']) : {};

  List<Map<String, dynamic>> get list => (body['data'] is List)
      ? List<Map<String, dynamic>>.from((body['data'] as List).map((e) => Map<String, dynamic>.from(e)))
      : [];

  List<Map<String, dynamic>> get ice => (body['ice'] is List)
      ? List<Map<String, dynamic>>.from(
          (body['ice'] as List).map((e) => Map<String, dynamic>.from(e)))
      : [];

  String get message => status == 429
      ? 'محاولات كثيرة خلال دقيقة. انتظر قليلًا ثم حاول مرة أخرى.'
      : (body['message'] ?? 'تعذّر تنفيذ الطلب، حاول مرة أخرى.').toString();
}
