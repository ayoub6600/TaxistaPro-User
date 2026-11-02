import 'package:flutter/services.dart';

/// What the caller hears (native telephone tones, see CallTones in MainActivity / AppDelegate).
enum CallTone {
  /// The call is on its way to the other phone: a short pip every 2 s.
  connecting,

  /// The other phone really rings: the long ring, 1 s on, 4 s off.
  ringback,

  /// Declined, or nobody answered.
  busy,

  /// The other side hung up.
  ended,

  /// The network dropped the call.
  failed,
}

class CallTones {
  static const _channel = MethodChannel('taxista/call_tones');

  /// Replaced in tests.
  static Future<void> Function(String method, Map<String, dynamic>? args) invoke =
      (method, args) => _channel.invokeMethod(method, args);

  static CallTone? _current;
  static CallTone? get current => _current;

  static bool _loops(CallTone t) => t == CallTone.connecting || t == CallTone.ringback;

  static Future<void> play(CallTone tone) async {
    if (_current == tone && _loops(tone)) return; // already sounding
    _current = _loops(tone) ? tone : null;
    try {
      await invoke('play', {'tone': tone.name});
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (_current == null) return;
    _current = null;
    try {
      await invoke('stop', null);
    } catch (_) {}
  }

  /// The caller's tone while the call rings: [reach] is the server's connecting | ringing |
  /// unreached (an older server sends none: then [alerted] decides).
  static CallTone ringingTone({String? reach, bool alerted = false}) =>
      (reach == 'ringing' || (reach == null && alerted)) ? CallTone.ringback : CallTone.connecting;

  /// How a call that ended without this person hanging up sounds: [status] is the server's final
  /// status, [connected] whether the two had been talking, [iAmCaller] who started it.
  static CallTone? endTone({required String status, required bool connected, required bool iAmCaller}) {
    if (connected) return status == 'failed' ? CallTone.failed : CallTone.ended;
    if (!iAmCaller) return null; // a call that stopped ringing here just goes quiet
    switch (status) {
      case 'declined':
      case 'missed':
        return CallTone.busy;
      case 'failed':
        return CallTone.failed;
      default:
        return CallTone.ended;
    }
  }
}
