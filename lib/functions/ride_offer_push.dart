import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'api_base_url.dart';

/// A driver asked more than the rider offered: the notification answers it with two buttons.
/// iPhone: the APNs category and ios/Runner/RideOfferButtons.swift. Android: shown here from a
/// data-only message, answered in the background. The words shown afterwards are the server's own.
class RideOfferPush {
  static const category = 'RIDE_OFFER';
  static const pushType = 'ride_counter_offer';
  static const acceptAction = 'RIDE_OFFER_ACCEPT';
  static const refuseAction = 'RIDE_OFFER_REFUSE';
  static const channelId = 'ride_offers';
  static const feature = 'ride_offer_actions';

  static bool handles(Map? data) => data?['category']?.toString() == category;

  static int notificationId(Map data) => 770000 + ((int.tryParse('${data['offer_id']}') ?? 0) % 100000);

  static AndroidNotificationChannel get channel =>
      const AndroidNotificationChannel(channelId, 'عروض السائقين', description: 'عرض سائق على طلبك، بزرين: قبول أو رفض', importance: Importance.high);

  static String payload(Map data) => jsonEncode({
        'category': category,
        'offer_id': '${data['offer_id'] ?? ''}',
        'offer_token': '${data['offer_token'] ?? ''}',
        'title': '${data['title'] ?? ''}',
        'message': '${data['message'] ?? ''}',
        'expires_at': '${data['expires_at'] ?? ''}',
      });

  static Map<String, dynamic>? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final m = jsonDecode(payload);
      if (m is Map && m['category'] == category) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return null;
  }

  static bool isAnswer(NotificationResponse r) => fromPayload(r.payload) != null && (r.actionId == acceptAction || r.actionId == refuseAction);

  static Future<void> show(FlutterLocalNotificationsPlugin plugin, Map data) async {
    final expires = int.tryParse('${data['expires_at'] ?? ''}');
    final left = expires == null ? null : expires * 1000 - DateTime.now().millisecondsSinceEpoch;
    if (left != null && left <= 0) return;
    final body = '${data['message'] ?? ''}';
    await plugin.show(
      notificationId(data),
      '${data['title'] ?? ''}',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, 'عروض السائقين',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
            timeoutAfter: left,
            actions: const [
              AndroidNotificationAction(acceptAction, 'قبول', showsUserInterface: false, cancelNotification: false),
              AndroidNotificationAction(refuseAction, 'رفض', showsUserInterface: false, cancelNotification: false),
            ]),
      ),
      payload: payload(data),
    );
  }

  /// the server's own words; [retry] true when the answer never reached it
  static Future<({String title, String message, bool retry})> answer(Map data, String answer, {http.Client? client}) async {
    final c = client ?? http.Client();
    try {
      final r = await c
          .post(Uri.parse('${apiBaseUrl}api/v1/ride-offer/${data['offer_id']}/$answer'),
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: jsonEncode({'t': '${data['offer_token'] ?? ''}'}))
          .timeout(const Duration(seconds: 20));
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['title'] != null) return (title: '${j['title']}', message: '${j['message'] ?? ''}', retry: false);
    } catch (_) {
      // no answer from the server: say so, and keep the buttons
    } finally {
      if (client == null) c.close();
    }
    return (title: 'ما تسجلش ردك', message: 'تأكد من الإنترنت وجرب مرة ثانية، أو افتح تاكسيستا.', retry: true);
  }
}

/// A button pressed on Android (a background isolate; the app may be closed).
Future<void> rideOfferNotificationAction(NotificationResponse response) async {
  final data = RideOfferPush.fromPayload(response.payload);
  if (data == null) return;
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {}
  final plugin = FlutterLocalNotificationsPlugin();
  if (Platform.isAndroid) {
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  }
  final said = await RideOfferPush.answer(data, response.actionId == RideOfferPush.acceptAction ? 'accept' : 'refuse');
  if (said.retry) {
    await RideOfferPush.show(plugin, {...data, 'message': '⚠️ ${said.message}\n${data['message']}'});
    return;
  }
  await plugin.show(
      RideOfferPush.notificationId(data), said.title, said.message, NotificationDetails(android: AndroidNotificationDetails(RideOfferPush.channelId, 'عروض السائقين', styleInformation: BigTextStyleInformation(said.message))));
}
