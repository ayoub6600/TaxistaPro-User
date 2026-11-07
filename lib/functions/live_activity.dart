import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// «🚕 مشوارك غدًا» as a card on the iPhone lock screen (Live Activity, iOS 17.2+) with its two buttons
/// in view. The native side holds Apple's push-to-start token; this only tells the server what the
/// phone can do (with the device token) and lets the TestFlight build try the card and the notification.
class LiveActivity {
  static const _channel = MethodChannel('taxista/live_activity');
  static const feature = 'live_activity';

  /// called when Apple gives a new push-to-start token (resync the device token) or a day was answered
  static void listen({required void Function() onToken, void Function(String id)? onAnswered}) {
    if (!Platform.isIOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'tokenChanged') onToken();
      if (call.method == 'answered' && onAnswered != null) onAnswered('${(call.arguments as Map?)?['id'] ?? ''}');
      return null;
    });
  }

  static Future<Map<String, dynamic>> info() async {
    if (!Platform.isIOS) return const {};
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('info');
      return r ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// what goes with the device token: the feature and the token only while the card can really show
  static Future<Map<String, dynamic>> deviceFields() async {
    final i = await info();
    final token = '${i['token'] ?? ''}';
    if (i['supported'] == true && i['enabled'] == true && token.isNotEmpty) {
      return {'live_activity': true, 'live_activity_token': token};
    }
    return const {};
  }

  static Future<bool> isTryoutBuild() async => (await info())['tryout'] == true;

  /// the TestFlight tryout: a card on the lock screen now ('ok' or why not)
  static Future<String> demoCard() async {
    try {
      return '${await _channel.invokeMethod('demoCard')}';
    } catch (e) {
      return 'ما قدرناش نبدأ البطاقة: $e';
    }
  }

  /// the TestFlight tryout: the plain notification in 5 seconds (lock the phone meanwhile)
  static Future<void> demoNotification() async {
    try {
      await _channel.invokeMethod('demoNotification');
    } catch (_) {}
  }

  /// answered inside the app: its card leaves the lock screen
  static Future<void> endDay(String occurrenceId) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('endDay', {'id': occurrenceId});
    } catch (_) {}
  }
}
