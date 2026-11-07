import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_base_url.dart';

/// «🚕 مشوارك غدًا!» - the evening reminder of a recurring ride, with two real buttons on the
/// notification itself: ✅ تأكيد مشوار الغد / ⏭ تخطي مشوار الغد.
///
/// - iPhone: the push is an ordinary alert with the APNs category RECURRING_TOMORROW. The buttons are
///   registered and answered natively (ios/Runner/AppDelegate.swift), so they work on the lock screen
///   and while another app is open, without starting Flutter.
/// - Android: the server sends this app version a data-only message (it said it draws buttons:
///   [recurringPushFeatures]); the background handler shows it here with two notification actions,
///   and [recurringNotificationAction] answers in a background isolate, without opening the app.
///
/// The day's token travels in the notification; the server checks it and the day's latest state, and
/// the answer shown in place of the question is always the server's own (never an assumed success).
class RecurringPush {
  static const category = 'RECURRING_TOMORROW';
  static const confirmAction = 'RECURRING_CONFIRM';
  static const skipAction = 'RECURRING_SKIP';
  static const channelId = 'recurring_reminders';

  /// the open app refreshes «رحلاتي المتكررة» / the home card after an answer (same isolate only)
  static final ValueNotifier<RecurringAnswer?> lastAnswer = ValueNotifier<RecurringAnswer?>(null);

  /// what this app version can do, told to the server with the push token
  static const features = ['notification_actions'];

  static bool handles(Map? data) => data?['category']?.toString() == category && (data?['occurrence_id']?.toString() ?? '').isNotEmpty;

  /// one notification per day: the question, and then its answer in the same place
  static int notificationId(Map data) => 880000 + ((int.tryParse('${data['occurrence_id']}') ?? 0) % 100000);

  /// only what the buttons need (the day, its token, the time it showed); no address
  static String payload(Map data) => jsonEncode({
        'category': category,
        'occurrence_id': '${data['occurrence_id'] ?? ''}',
        'recurring_id': '${data['recurring_id'] ?? ''}',
        'day_token': '${data['day_token'] ?? ''}',
        'seen_at': '${data['seen_at'] ?? ''}',
        'expires_at': '${data['expires_at'] ?? ''}',
        'date': '${data['date'] ?? ''}',
        'title': '${data['title'] ?? ''}',
        'message': '${data['message'] ?? ''}',
      });

  static Map<String, dynamic>? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final m = jsonDecode(payload);
      if (m is Map && m['category'] == category) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return null;
  }

  /// the native iPhone handler reads the API address the app uses (a test build may use another)
  static Future<void> rememberApiBase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taxista_api_base', apiBaseUrl);
    } catch (_) {}
  }

  static AndroidNotificationChannel get channel => const AndroidNotificationChannel(
        channelId,
        'تذكير الرحلات المتكررة',
        description: 'تذكير الليلة بمشوار الغد، بزرين: تأكيد أو تخطي',
        importance: Importance.high,
      );

  /// Shows the question with its two buttons (Android, any state; iPhone while the app is open).
  static Future<void> show(FlutterLocalNotificationsPlugin plugin, Map data, {String? note}) async {
    final expires = int.tryParse('${data['expires_at'] ?? ''}');
    final left = expires == null ? null : expires * 1000 - DateTime.now().millisecondsSinceEpoch;
    if (left != null && left <= 0) return; // its deadline passed while the phone was off
    final title = '${data['title'] ?? '🚕 مشوارك غدًا!'}';
    final body = note == null ? '${data['message'] ?? ''}' : '$note\n${data['message'] ?? ''}';
    await plugin.show(
      notificationId(data),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'تذكير الرحلات المتكررة',
          channelDescription: 'تذكير الليلة بمشوار الغد، بزرين: تأكيد أو تخطي',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public, // the text names البيت / العمل only, never an address
          styleInformation: BigTextStyleInformation(body),
          timeoutAfter: left,
          autoCancel: true,
          actions: const [
            AndroidNotificationAction(confirmAction, '✅ تأكيد مشوار الغد', showsUserInterface: false, cancelNotification: false),
            AndroidNotificationAction(skipAction, '⏭ تخطي مشوار الغد', showsUserInterface: false, cancelNotification: false),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          categoryIdentifier: category,
          threadIdentifier: 'recurring',
        ),
      ),
      payload: payload(data),
    );
  }

  /// The answer, in place of the question (no buttons, except to try again after a failure).
  static Future<void> showResult(FlutterLocalNotificationsPlugin plugin, Map data, RecurringAnswer a) async {
    if (a.retry) {
      await show(plugin, data, note: '⚠️ ${a.message}');
      return;
    }
    await plugin.show(
      notificationId(data),
      a.title,
      a.message,
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, 'تذكير الرحلات المتكررة',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(a.message),
            onlyAlertOnce: true,
            timeoutAfter: 6 * 3600 * 1000),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentList: true, presentSound: false, threadIdentifier: 'recurring'),
      ),
      payload: jsonEncode({'category': 'RECURRING_RESULT', 'recurring_id': '${data['recurring_id'] ?? ''}', 'occurrence_id': '${data['occurrence_id'] ?? ''}'}),
    );
  }

  /// POST api/v1/recurring-day/{id}/{attend|skip} with the day's token; one retry on a weak line.
  static Future<RecurringAnswer> answer(Map data, String answer, {http.Client? client}) async {
    final id = '${data['occurrence_id'] ?? ''}';
    final uri = Uri.parse('${apiBaseUrl}api/v1/recurring-day/$id/$answer');
    final body = jsonEncode({'t': '${data['day_token'] ?? ''}', 'seen_at': '${data['seen_at'] ?? ''}', 'platform': Platform.isIOS ? 'ios' : 'android'});
    final c = client ?? http.Client();
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final r = await c
              .post(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: body)
              .timeout(const Duration(seconds: 15));
          final j = jsonDecode(r.body);
          if (j is Map && j['title'] != null) {
            return RecurringAnswer(ok: j['success'] == true, state: '${j['state'] ?? ''}', title: '${j['title']}', message: '${j['message'] ?? ''}');
          }
          if (r.statusCode >= 500 && attempt == 0) {
            await Future<void>.delayed(const Duration(seconds: 3));
            continue;
          }
          return RecurringAnswer.failed('ما وصلناش رد واضح من تاكسيستا (${r.statusCode}). ردك ما تسجلش؛ جرب مرة ثانية.');
        } on TimeoutException {
          if (attempt == 0) continue;
        } on SocketException {
          if (attempt == 0) {
            await Future<void>.delayed(const Duration(seconds: 3));
            continue;
          }
        } on FormatException {
          return RecurringAnswer.failed('ما وصلناش رد واضح من تاكسيستا. ردك ما تسجلش؛ جرب مرة ثانية.');
        }
      }
      return RecurringAnswer.failed('ما فيش اتصال بالإنترنت. ردك ما تسجلش؛ جرب الزر مرة ثانية لما يرجع الاتصال.');
    } finally {
      if (client == null) c.close();
    }
  }
}

class RecurringAnswer {
  const RecurringAnswer({required this.ok, required this.state, required this.title, required this.message});

  factory RecurringAnswer.failed(String message) => RecurringAnswer(ok: false, state: 'network', title: 'ما تسجلش ردك', message: message);

  final bool ok;
  final String state;
  final String title;
  final String message;

  /// nothing reached the server: the buttons stay, so he can press again
  bool get retry => state == 'network';
}

/// A tap on a button of the reminder (Android; a background isolate, the app may be closed), or on
/// any other notification this app showed. Must stay a top-level entry point.
@pragma('vm:entry-point')
Future<void> recurringNotificationAction(NotificationResponse response) async {
  final data = RecurringPush.fromPayload(response.payload);
  final action = response.actionId;
  if (data == null || (action != RecurringPush.confirmAction && action != RecurringPush.skipAction)) return;
  WidgetsFlutterBindingShim.ensure();
  final plugin = FlutterLocalNotificationsPlugin();
  try {
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
        onDidReceiveBackgroundNotificationResponse: recurringNotificationAction);
  } catch (_) {}
  final a = await RecurringPush.answer(data, action == RecurringPush.confirmAction ? 'attend' : 'skip');
  await RecurringPush.showResult(plugin, data, a);
  RecurringPush.lastAnswer.value = a;
}

class WidgetsFlutterBindingShim {
  static void ensure() {
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {}
  }
}
