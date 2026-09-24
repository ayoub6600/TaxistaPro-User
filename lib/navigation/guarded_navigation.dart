import 'package:flutter/material.dart';

DateTime? _lastGuardedPush;
const _pushLock = Duration(milliseconds: 450);

/// Same as [Navigator.push], but a second push requested right after the
/// first (a double tap, or a repeated tap while the first handler is still
/// starting its route) is ignored instead of stacking the same page twice.
///
/// An ignored push completes immediately with `null` (the same result as a
/// route dismissed without a value), so a caller that awaits the result is
/// never left hanging - and callers that guard with an [ExclusiveRunner] can
/// never deadlock on a push that was skipped.
Future<T?> guardedPush<T extends Object?>(
    BuildContext context, Route<T> route) {
  final now = DateTime.now();
  final last = _lastGuardedPush;
  if (last != null && now.difference(last) < _pushLock) {
    return Future<T?>.value(null);
  }
  _lastGuardedPush = now;
  return Navigator.push<T>(context, route);
}

/// Accepts one call per [window]; a second call inside the window is refused.
/// Shared by [Button] so a double tap (or a tap while the first handler is
/// still starting its route/request) cannot run the same action twice.
class TapLock {
  TapLock([this.window = const Duration(milliseconds: 700)]);

  final Duration window;
  DateTime? _last;

  bool tryAcquire([DateTime? now]) {
    final at = now ?? DateTime.now();
    final last = _last;
    if (last != null && at.difference(last) < window) return false;
    _last = at;
    return true;
  }
}

/// Runs one action at a time: while an action is still running (resolving a
/// location, navigating, waiting for a page to return), further calls are
/// ignored. Used for the home "where to / home / work / recent" taps so a
/// burst of taps cannot start the same work - or push the same page - twice.
class ExclusiveRunner {
  bool _busy = false;

  bool get busy => _busy;

  Future<void> run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }
}
