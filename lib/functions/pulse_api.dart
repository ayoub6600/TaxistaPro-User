import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// «نبض تاكسيستا» in the rider app: routine trips and their reminders, approved pickup points near
/// events, and changing the pickup of an accepted ride by agreement. Nothing here books a ride.
class PulseApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Uri _u(String path) => Uri.parse('${url}api/v1/$path');

  static Future<PulseResult> settings() => _send(http.get(_u('user/pulse/settings'), headers: _headers));

  static Future<PulseResult> saveSettings(Map<String, dynamic> body) =>
      _send(http.post(_u('user/pulse/settings'), headers: _headers, body: jsonEncode(body)));

  static Future<PulseResult> routines() => _send(http.get(_u('user/pulse/routines'), headers: _headers));

  static Future<PulseResult> saveRoutine(Map<String, dynamic> body, {int? id}) =>
      _send(http.post(_u('user/pulse/routines${id == null ? '' : '/$id'}'), headers: _headers, body: jsonEncode(body)));

  /// confirm | pause | resume | dismiss | delete
  static Future<PulseResult> routineAction(int id, String action) =>
      _send(http.post(_u('user/pulse/routines/$id/$action'), headers: _headers, body: '{}'));

  static Future<PulseResult> pickupPoints(double lat, double lng) =>
      _send(http.get(_u('user/pulse/pickup-points?lat=$lat&lng=$lng'), headers: _headers));

  static Uri _pc(String rideId, [String tail = '']) => _u('request/$rideId/pickup-change$tail');

  static Future<PulseResult> pickupCurrent(String rideId) => _send(http.get(_pc(rideId), headers: _headers));

  static Future<PulseResult> pickupQuote(String rideId, double lat, double lng) =>
      _send(http.post(_pc(rideId, '/quote'), headers: _headers, body: jsonEncode({'lat': lat, 'lng': lng})));

  static Future<PulseResult> pickupPropose(String rideId, double lat, double lng, {double? acceptFareDelta}) => _send(http.post(_pc(rideId),
      headers: _headers, body: jsonEncode({'lat': lat, 'lng': lng, if (acceptFareDelta != null) 'accept_fare_delta': acceptFareDelta})));

  static Future<PulseResult> pickupRespond(String rideId, int changeId, bool accept, {double? acceptFareDelta}) => _send(http.post(
      _pc(rideId, '/$changeId/respond'),
      headers: _headers,
      body: jsonEncode({'decision': accept ? 'accept' : 'reject', if (acceptFareDelta != null) 'accept_fare_delta': acceptFareDelta})));

  static Future<PulseResult> pickupCancel(String rideId, int changeId) =>
      _send(http.post(_pc(rideId, '/$changeId/cancel'), headers: _headers, body: '{}'));

  static Future<PulseResult> _send(Future<http.Response> request) async {
    try {
      final r = await request.timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
      } catch (_) {}
      return PulseResult(r.statusCode, body);
    } catch (_) {
      return const PulseResult(0, {});
    }
  }
}

class PulseResult {
  final int status;
  final Map<String, dynamic> body;

  const PulseResult(this.status, this.body);

  bool get ok => status == 200 && body['success'] == true;
  dynamic get rawData => body['data'];
  Map<String, dynamic> get data => rawData is Map ? Map<String, dynamic>.from(rawData as Map) : <String, dynamic>{};
  List<Map<String, dynamic>> get list => rawData is List ? (rawData as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
  String? get code => body['code']?.toString();
  String get message => (body['message']?.toString().isNotEmpty ?? false)
      ? body['message'].toString()
      : (status == 0 ? 'انقطع الاتصال بالخادم.' : 'تعذّر تنفيذ الطلب. حاول مرة أخرى.');
}

/// Reminders need to know the rider is near his usual start. The app tells the server where it is
/// ONLY when it is open (start and every return to the foreground), only if the rider switched
/// reminders on, and the server keeps that one last position, never a track.
class PulsePresence {
  static bool remindersOn = false;
  static DateTime? _last;

  static Future<void> refreshConsent() async {
    final r = await PulseApi.settings();
    if (r.ok) remindersOn = r.data['reminders'] == true;
  }

  static Future<void> report() async {
    if (!remindersOn || bearerToken.isEmpty) return;
    if (_last != null && DateTime.now().difference(_last!).inMinutes < 3) return;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return;
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)));
      _last = DateTime.now();
      await http.post(Uri.parse('${url}api/v1/user/pulse/presence'),
          headers: {
            'Authorization': 'Bearer ${bearerToken[0].token}',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'lat': p.latitude, 'lng': p.longitude, 'accuracy': p.accuracy, 'captured_at': p.timestamp.toUtc().toIso8601String()}));
    } catch (_) {
      // no position = no reminder; that is the safe outcome
    }
  }
}

/// A routine reminder was tapped: the home map fills the destination and the rider confirms the
/// booking himself on the usual confirmation screen.
class PulseBookingIntent {
  static final ValueNotifier<Map<String, dynamic>?> pending = ValueNotifier<Map<String, dynamic>?>(null);

  static void fromPush(Map<String, dynamic> data) {
    final lat = double.tryParse('${data['drop_lat']}');
    final lng = double.tryParse('${data['drop_lng']}');
    if (lat == null || lng == null || lat == 0) return;
    pending.value = {'pick_lat': lat, 'pick_lng': lng, 'pick_address': '${data['drop_address'] ?? ''}'.trim().isEmpty ? 'وجهتك المعتادة' : '${data['drop_address']}'};
  }
}

/// The ride's pickup-change proposal, read from the server whenever Firebase or a push says it moved.
class PickupChangeState {
  static final ValueNotifier<Map<String, dynamic>?> current = ValueNotifier<Map<String, dynamic>?>(null);

  static Future<void> reload(String rideId) async {
    final r = await PulseApi.pickupCurrent(rideId);
    if (r.ok) {
      final d = r.rawData;
      current.value = d is Map ? Map<String, dynamic>.from(d) : null;
    }
  }

  static void clear() => current.value = null;
}
