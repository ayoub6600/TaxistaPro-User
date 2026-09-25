import 'dart:async';

import 'package:flutter/services.dart';

typedef ClipboardWriter = Future<void> Function(String text);

/// Copies a card detail to the clipboard for pasting into the payment page and
/// removes it again shortly after.
///
/// The clipboard cannot be made private from Flutter, so this is best effort:
/// the value is cleared after [clearAfter], when the payment screen closes and
/// (via [clearNow]) whenever the app decides the payment is over. It never
/// reads the clipboard back (that would trigger the iOS paste notice) and it
/// is only ever given a card number or an expiry - never a CVV.
class SecureClipboard {
  SecureClipboard({
    ClipboardWriter? writer,
    this.clearAfter = const Duration(seconds: 60),
  }) : _writer = writer ?? _systemWriter;

  final Duration clearAfter;
  final ClipboardWriter _writer;
  Timer? _timer;
  bool _holdsSecret = false;

  static Future<void> _systemWriter(String text) => Clipboard.setData(ClipboardData(text: text));

  bool get holdsSecret => _holdsSecret;

  Future<void> copy(String value) async {
    _timer?.cancel();
    await _writer(value);
    _holdsSecret = true;
    _timer = Timer(clearAfter, () {
      clearNow();
    });
  }

  Future<void> clearNow() async {
    _timer?.cancel();
    _timer = null;
    if (!_holdsSecret) return;
    _holdsSecret = false;
    try {
      await _writer('');
    } catch (_) {}
  }
}
