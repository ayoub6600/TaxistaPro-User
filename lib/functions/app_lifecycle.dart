import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The one owner of app-wide foreground/background work.
///
/// Pages keep their own light reconcile (they know what to refresh), but
/// everything that must happen exactly once per background/foreground trip
/// happens here:
///  * going to the background closes every shared Firebase listener, so no
///    snapshot is delivered - or exported on the main thread - while the app
///    is away;
///  * coming back reopens them ONCE, after the first frame, however many
///    lifecycle events iOS delivers (inactive -> hidden -> paused ->
///    inactive -> resumed is normal, and flaky networks add more).
class AppLifecycleCoordinator with WidgetsBindingObserver {
  AppLifecycleCoordinator({
    this.resumeDelay = const Duration(milliseconds: 250),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static final AppLifecycleCoordinator instance = AppLifecycleCoordinator();

  /// Runs once per trip to the background.
  final List<VoidCallback> onBackground = <VoidCallback>[];

  /// Runs once per return to the foreground, after the first frame + delay.
  final List<VoidCallback> onForeground = <VoidCallback>[];

  final Duration resumeDelay;
  final DateTime Function() _clock;

  bool _attached = false;
  bool _inBackground = false;
  Timer? _resumeTimer;
  DateTime? _backgroundedAt;

  /// Most recent transitions, newest last (diagnostics; no personal data).
  final List<String> trace = <String>[];
  int backgroundRuns = 0;
  int foregroundRuns = 0;

  bool get inBackground => _inBackground;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => handle(state);

  @visibleForTesting
  void handle(AppLifecycleState state) {
    _note(state.name);
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _goBackground();
        break;
      case AppLifecycleState.resumed:
        _goForeground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Control Centre, an incoming call, the app switcher: the app is still
        // on screen, so nothing is torn down.
        break;
    }
  }

  void _goBackground() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
    if (_inBackground) return;
    _inBackground = true;
    _backgroundedAt = _clock();
    backgroundRuns++;
    _run(onBackground);
  }

  void _goForeground() {
    if (!_inBackground) return;
    // One pending resume, however many "resumed" events arrive.
    if (_resumeTimer != null) return;
    _resumeTimer = Timer(resumeDelay, () {
      _resumeTimer = null;
      if (!_inBackground) return;
      _inBackground = false;
      foregroundRuns++;
      final away = _backgroundedAt == null
          ? null
          : _clock().difference(_backgroundedAt!).inSeconds;
      _note('foreground after ${away ?? '?'}s: listeners reopened');
      _run(onForeground);
    });
  }

  void _run(List<VoidCallback> callbacks) {
    for (final callback in List<VoidCallback>.of(callbacks)) {
      try {
        callback();
      } catch (error) {
        _note('callback failed: ${error.runtimeType}');
      }
    }
  }

  void _note(String entry) {
    trace.add('${_clock().toIso8601String()} $entry');
    if (trace.length > 60) trace.removeRange(0, trace.length - 60);
    if (kDebugMode) debugPrint('[lifecycle] $entry');
  }
}
