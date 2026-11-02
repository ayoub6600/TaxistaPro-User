import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../pages/NavigatorPages/adminchatpage.dart';
import '../pages/NavigatorPages/walletpage.dart';
import '../pages/callPage/call_log_page.dart';
import 'calls/admin_call_controller.dart';
import 'functions.dart';

/// Opening the chat with the administration from a notification, whatever state the app was in
/// (open, in the background, closed, phone locked): a message from the administration
/// (push_type admin_chat_message) or a missed call from it (admin_call_missed). The same path opens
/// the wallet for change a driver returned to it (change_return) and for a top-up paid in cash to a
/// driver (wallet_topup, "تم شحن محفظتك").
///
/// The tap is kept until the app can act on it: a signed-in session with the home screen up
/// (after a cold start that is when the home screen mounts, see [appReady]). The conversation is
/// opened only after the server confirms the push names this account's own chat; a push meant
/// for another account that used this phone opens nothing.
class SupportChatLink {
  static const chatPush = 'admin_chat_message';
  static const missedCallPush = 'admin_call_missed';
  static const changeReturnPush = 'change_return';
  static const walletTopUpPush = 'wallet_topup';

  /// The message to show in the chat page already on screen (set when a tap arrives while it is open).
  static final ValueNotifier<int?> focus = ValueNotifier<int?>(null);

  static Map<String, dynamic>? _pending;
  static bool _busy = false;

  /// A push this link opens. A missed call between a driver and a rider opens the call log instead.
  static bool handles(Map data) {
    final type = data['push_type']?.toString();
    return type == chatPush || type == missedCallPush || type == changeReturnPush || type == walletTopUpPush;
  }

  static bool _isTripCall(Map data) => data['call_kind']?.toString() == 'driver_rider';

  /// What a local notification carries, to be routed the same way when tapped.
  static String payload(Map data) => jsonEncode({
        'push_type': data['push_type']?.toString(),
        'chat_id': data['chat_id']?.toString(),
        'message_id': data['message_id']?.toString(),
        'call_kind': data['call_kind']?.toString(),
      });

  static Map<String, dynamic>? fromPayload(String? payload) {
    if (payload == null || !payload.startsWith('{')) return null;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      return handles(data) ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// A notification was tapped.
  static void open(Map data) {
    _pending = Map<String, dynamic>.from(data);
    unawaited(_flush());
  }

  /// The home screen is up (a signed-in session): act on a tap that arrived before.
  static void appReady() => unawaited(_flush());

  static Future<void> _flush() async {
    final data = _pending;
    final nav = appNavigatorKey.currentState;
    if (data == null || _busy || nav == null) return;
    if (bearerToken.isEmpty || userDetails.isEmpty) return; // signed out, or the session is still loading
    _pending = null;
    _busy = true;
    try {
      if (data['push_type'] == changeReturnPush || data['push_type'] == walletTopUpPush) {
        nav.push(MaterialPageRoute(builder: (_) => const WalletPage()));
        return;
      }
      if (data['push_type'] == missedCallPush && _isTripCall(data)) {
        nav.push(MaterialPageRoute(builder: (_) => const CallLogPage()));
        return;
      }
      final loaded = await getadminCurrentMessages(markRead: AdminChatPage.isOpen);
      final pushedChat = data['chat_id']?.toString() ?? '';
      if (loaded == 'success' && pushedChat.isNotEmpty && chatid?.toString() != pushedChat) {
        return; // not this account's conversation
      }
      final messageId = int.tryParse(data['message_id']?.toString() ?? '');
      if (AdminChatPage.isOpen) {
        focus.value = null; // the same message tapped twice still scrolls to it
        focus.value = messageId;
        return;
      }
      nav.push(MaterialPageRoute(builder: (_) => AdminChatPage(focusMessageId: messageId)));
    } finally {
      _busy = false;
    }
  }
}
