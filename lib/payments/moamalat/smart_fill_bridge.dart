import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Android's frame-scoped injection (androidx.webkit 1.16, isolated world) is implemented and compiles,
/// but has not been run on a device yet, so Android keeps the classic copy helper until it has been
/// tested there. iOS is on.
const bool kSmartFillOnAndroid = false;

/// What the native side reports about the payment page's card form.
enum SmartFillFrameState { ready, gone }

class SmartFillFrameEvent {
  const SmartFillFrameEvent(this.webViewId, this.state);

  final int webViewId;
  final SmartFillFrameState state;
}

/// The outcome of one Smart Fill attempt. Labels only - never a card value.
class SmartFillResult {
  const SmartFillResult({required this.ok, this.pan = 'failed', this.exp = 'failed', this.name = 'absent', this.terms = 'skipped', this.reason});

  /// Every intended operation succeeded (and the page did not flag a value as invalid).
  final bool ok;
  final String pan; // filled | failed
  final String exp; // filled | failed
  final String name; // filled | absent | failed
  final String terms; // checked | absent | failed | skipped
  final String? reason; // unknown_form | not_accepted | no_ready_frame | ...

  bool get formNotRecognised => reason == 'unknown_form' || reason == 'no_ready_frame';

  static const SmartFillResult error = SmartFillResult(ok: false, reason: 'error');

  factory SmartFillResult.fromMap(Object? raw) {
    if (raw is! Map) return error;
    String s(String k, String fallback) => raw[k] is String ? raw[k] as String : fallback;
    return SmartFillResult(
      ok: raw['ok'] == true,
      pan: s('pan', 'failed'),
      exp: s('exp', 'failed'),
      name: s('name', 'absent'),
      terms: s('terms', 'skipped'),
      reason: raw['reason'] is String ? raw['reason'] as String : null,
    );
  }
}

/// The native half of Smart Fill: it installs the fill script in the payment
/// web view's frames (exact origin allow-list) and delivers a card to the ONE
/// verified Moamalat frame, only when asked. Dart never sees the page.
abstract class SmartFillBridge {
  /// Installs the script into the web view identified by [webViewId]. Must run
  /// BEFORE the payment page is loaded. False when this platform / web view
  /// cannot do frame-scoped injection (the caller then keeps the classic helper).
  Future<bool> install({required int webViewId, required String script, required List<String> origins});

  /// `ready` / `gone` for the verified frame of a web view.
  Stream<SmartFillFrameEvent> get events;

  /// Hands the card to the verified frame and reports what happened. The values
  /// are passed once as call arguments; nothing is kept by the bridge.
  Future<SmartFillResult> fill({required int webViewId, required String pan, required String exp, required String name, required bool acceptTerms});

  Future<void> dispose(int webViewId);
}

/// The real bridge: a method channel to the app's native code (`AppDelegate.swift`
/// on iOS, `MainActivity.kt` on Android).
class ChannelSmartFillBridge implements SmartFillBridge {
  ChannelSmartFillBridge._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'state') return null;
      final args = call.arguments;
      if (args is! Map) return null;
      final id = args['webViewId'];
      final state = args['state'];
      if (id is! int) return null;
      if (state == 'ready') _events.add(SmartFillFrameEvent(id, SmartFillFrameState.ready));
      if (state == 'gone') _events.add(SmartFillFrameEvent(id, SmartFillFrameState.gone));
      return null;
    });
  }

  static final ChannelSmartFillBridge instance = ChannelSmartFillBridge._();

  final MethodChannel _channel = const MethodChannel('taxista/card_fill');
  final StreamController<SmartFillFrameEvent> _events = StreamController<SmartFillFrameEvent>.broadcast();

  @override
  Stream<SmartFillFrameEvent> get events => _events.stream;

  @override
  Future<bool> install({required int webViewId, required String script, required List<String> origins}) async {
    if (Platform.isAndroid && !kSmartFillOnAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('install', {'webViewId': webViewId, 'script': script, 'origins': origins});
      return ok == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<SmartFillResult> fill({required int webViewId, required String pan, required String exp, required String name, required bool acceptTerms}) async {
    try {
      final raw = await _channel.invokeMethod<Object?>('fill', {'webViewId': webViewId, 'pan': pan, 'exp': exp, 'name': name, 'terms': acceptTerms});
      return SmartFillResult.fromMap(raw);
    } on MissingPluginException {
      return SmartFillResult.error;
    } on PlatformException {
      return SmartFillResult.error;
    }
  }

  @override
  Future<void> dispose(int webViewId) async {
    try {
      await _channel.invokeMethod<void>('dispose', {'webViewId': webViewId});
    } catch (_) {}
  }
}
