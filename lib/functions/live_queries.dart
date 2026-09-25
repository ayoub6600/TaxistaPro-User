import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// One native listener per distinct query, however many widgets read it and
/// however often they rebuild.
///
/// Why this exists: Flutter runs Dart, platform channels and touch handling on
/// ONE thread on iOS, and the Firebase iOS plugin turns every snapshot into a
/// dictionary on that same thread. Listeners that were created inside
/// `build()` were torn down and re-created on every rebuild, and every
/// vehicle card opened its own copy of the same query - so a resume (which
/// rebuilds Home several times) meant dozens of full snapshot exports on the
/// thread that also delivers touches. On a device that was already thermally
/// throttled this ran past iOS's 10 second scene-update watchdog (crash
/// report 0x8BADF00D, main thread inside `-[FIRDataSnapshot value]`).
///
/// Rules of this layer:
///  * the stream object for a key is created once and never changes, so a
///    `StreamBuilder` keeps its subscription across rebuilds;
///  * the native listener is opened when the first widget listens and closed
///    when the last one leaves;
///  * [pauseAll] closes every native listener (app going to the background)
///    without disturbing the widgets listening; [resumeAll] reopens them once;
///  * a late listener is handed the newest snapshot straight away, so a second
///    consumer never waits for the next server change;
///  * bursts are coalesced to at most one event per [SharedStreams.coalesce].
class SharedStreams<T> {
  SharedStreams({this.now});

  /// Test hook.
  final DateTime Function()? now;

  final Map<String, _Entry<T>> _entries = {};
  bool _paused = false;

  bool get paused => _paused;

  /// Native listeners currently open (diagnostics and tests).
  int get nativeListeners =>
      _entries.values.where((entry) => entry.attached).length;

  /// Widgets/streams currently listening across every key.
  int get listeners =>
      _entries.values.fold<int>(0, (sum, entry) => sum + entry.listeners);

  /// The one stable stream for [key]. [open] is only called when a native
  /// listener actually has to be created.
  Stream<T> watch(
    String key,
    Stream<T> Function() open, {
    Duration coalesce = Duration.zero,
  }) {
    return (_entries[key] ??= _Entry<T>(
      key: key,
      open: open,
      coalesce: coalesce,
      owner: this,
      now: now ?? DateTime.now,
    ))
        .stream;
  }

  /// App going to the background: stop every native listener. Listening
  /// widgets are untouched; nothing is delivered until [resumeAll].
  void pauseAll() {
    _paused = true;
    for (final entry in _entries.values) {
      entry.detach();
    }
  }

  /// App back in the foreground: reopen the native listeners that still have
  /// somebody listening - once, no matter how many resume events arrive.
  void resumeAll() {
    if (!_paused) return;
    _paused = false;
    for (final entry in _entries.values.toList()) {
      if (entry.listeners > 0) entry.attach();
    }
  }

  /// Drop every listener and forget every key (sign-out, or a controlled
  /// recovery that rebuilds Home from scratch).
  void reset() {
    for (final entry in _entries.values.toList()) {
      entry.dispose();
    }
    _entries.clear();
    _paused = false;
  }

  void _forget(String key, _Entry<T> entry) {
    if (identical(_entries[key], entry)) _entries.remove(key);
  }
}

class _Entry<T> {
  _Entry({
    required this.key,
    required this.open,
    required this.coalesce,
    required this.owner,
    required this.now,
  });

  final String key;
  final Stream<T> Function() open;
  final Duration coalesce;
  final SharedStreams<T> owner;
  final DateTime Function() now;

  final StreamController<T> _fanOut = StreamController<T>.broadcast();
  StreamSubscription<T>? _native;
  Timer? _trailing;
  DateTime? _lastEmit;
  T? _pending;
  bool _hasPending = false;
  T? _last;
  bool _hasLast = false;
  int listeners = 0;

  bool get attached => _native != null;

  late final Stream<T> stream = Stream<T>.multi((controller) {
    listeners++;
    if (_hasLast) controller.add(_last as T);
    final sub = _fanOut.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    if (!owner.paused) attach();
    controller.onCancel = () {
      sub.cancel();
      listeners--;
      if (listeners <= 0) {
        listeners = 0;
        detach();
        _hasLast = false;
        _last = null;
        owner._forget(key, this);
      }
    };
  }, isBroadcast: true);

  void attach() {
    if (_native != null) return;
    _native = open().listen(
      _onEvent,
      onError: (Object error, StackTrace stack) {
        if (!_fanOut.isClosed) _fanOut.addError(error, stack);
      },
    );
  }

  void detach() {
    _trailing?.cancel();
    _trailing = null;
    _hasPending = false;
    _pending = null;
    final sub = _native;
    _native = null;
    sub?.cancel();
  }

  void dispose() {
    detach();
    listeners = 0;
    if (!_fanOut.isClosed) _fanOut.close();
  }

  void _onEvent(T event) {
    if (coalesce == Duration.zero) return _emit(event);
    final last = _lastEmit;
    final elapsed = last == null ? coalesce : now().difference(last);
    if (elapsed >= coalesce) {
      _trailing?.cancel();
      _trailing = null;
      _emit(event);
      return;
    }
    // Inside the window: keep only the newest, deliver it when the window ends.
    _pending = event;
    _hasPending = true;
    _trailing ??= Timer(coalesce - elapsed, () {
      _trailing = null;
      if (!_hasPending) return;
      final value = _pending as T;
      _hasPending = false;
      _pending = null;
      _emit(value);
    });
  }

  void _emit(T event) {
    _lastEmit = now();
    _last = event;
    _hasLast = true;
    if (!_fanOut.isClosed) _fanOut.add(event);
  }
}

/// The app-wide registry of Firebase queries.
class LiveQueries {
  LiveQueries._();

  static final SharedStreams<DatabaseEvent> instance =
      SharedStreams<DatabaseEvent>();

  /// The single shared `onValue` stream for [key] (see [SharedStreams]).
  static Stream<DatabaseEvent> watchQuery(
    String key,
    Query Function() make, {
    Duration coalesce = Duration.zero,
  }) =>
      instance.watch(key, () => make().onValue, coalesce: coalesce);
}

/// A change of one leaf of a ride's Firebase node.
@immutable
class RideLeaf {
  const RideLeaf(this.key, this.value);
  final String key;
  final Object? value;
}

/// Watches individual fields of `requests/<id>` instead of the whole node.
///
/// The node also carries `lat_lng_array` (up to ~280 GPS points, about 14 KB,
/// rewritten by the Driver on every location tick) plus lat / lng / bearing /
/// distance. Listening with child events on the node delivered - and
/// exported on the main thread - every one of those changes, thousands of them
/// while the app sat in the background. The rider only reacts to a handful of
/// state flags, so listen to exactly those leaves.
///
/// Semantics match the old child listeners: a leaf that already exists is
/// reported when the listener starts (a state change made before we attached is
/// never missed), and after that only real changes are reported; a leaf that
/// disappears is ignored.
Stream<RideLeaf> watchRideLeaves(
  String requestId,
  List<String> keys, {
  Stream<Object?> Function(String path)? openLeaf,
}) {
  final open = openLeaf ??
      (String path) => FirebaseDatabase.instance
          .ref(path)
          .onValue
          .map<Object?>((event) => event.snapshot.value);
  late final StreamController<RideLeaf> controller;
  final subs = <StreamSubscription<Object?>>[];
  controller = StreamController<RideLeaf>(
    onListen: () {
      for (final key in keys) {
        Object? previous;
        var seen = false;
        subs.add(open('requests/$requestId/$key').listen(
          (value) {
            final changed = !seen || value != previous;
            seen = true;
            previous = value;
            if (value != null && changed && !controller.isClosed) {
              controller.add(RideLeaf(key, value));
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          },
        ));
      }
    },
    onCancel: () async {
      final all = List<StreamSubscription<Object?>>.of(subs);
      subs.clear();
      for (final sub in all) {
        await sub.cancel();
      }
    },
  );
  return controller.stream;
}
