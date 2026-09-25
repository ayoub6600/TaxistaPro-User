import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/app_lifecycle.dart';
import 'package:taxista/functions/live_queries.dart';
import 'package:taxista/navigation/guarded_navigation.dart';

/// Regression tests for the Rider "frozen after coming back to the app" bug.
///
/// Root cause (from the device's own crash report, 0x8BADF00D scene-update
/// watchdog): the main thread - which on iOS also runs Dart and touch
/// handling - spent >10 s inside Firebase's `-[FIRDataSnapshot value]` for a
/// child-event listener on `requests/<id>`, while listeners created in build()
/// were being torn down and reopened on every rebuild.

/// A stand-in for one native Firebase listener: counts opens and closes.
class FakeNative {
  int opened = 0;
  int closed = 0;
  final List<StreamController<int>> controllers = [];

  Stream<int> open() {
    late StreamController<int> c;
    c = StreamController<int>(
      onListen: () => opened++,
      onCancel: () => closed++,
    );
    controllers.add(c);
    return c.stream;
  }

  int get live => opened - closed;
  void emit(int v) {
    for (final c in controllers) {
      if (c.hasListener) c.add(v);
    }
  }
}

class RebuildingPage extends StatefulWidget {
  const RebuildingPage({super.key, required this.streams, required this.native});
  final SharedStreams<int> streams;
  final FakeNative native;

  @override
  State<RebuildingPage> createState() => RebuildingPageState();
}

class RebuildingPageState extends State<RebuildingPage> {
  int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    // Exactly what Home / booking did: ask for the stream INSIDE build().
    return Column(children: [
      for (var i = 0; i < 4; i++)
        StreamBuilder<int>(
          stream: widget.streams.watch('drivers-near:a:b', widget.native.open),
          builder: (context, snap) => Text('card$i:${snap.data ?? '-'}'),
        ),
    ]);
  }
}

void main() {
  group('SharedStreams', () {
    test('one stable stream object per key; native listener opens once', () {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      final a = streams.watch('k', native.open);
      final b = streams.watch('k', native.open);
      expect(identical(a, b), isTrue);

      final subs = [a.listen((_) {}), b.listen((_) {}), a.listen((_) {})];
      expect(native.opened, 1);
      expect(streams.nativeListeners, 1);
      expect(streams.listeners, 3);
      for (final s in subs) {
        s.cancel();
      }
    });

    testWidgets('100 rebuilds with 4 listening cards keep ONE native listener',
        (tester) async {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      await tester.pumpWidget(MaterialApp(
        home: RebuildingPage(streams: streams, native: native),
      ));
      final state = tester.state<RebuildingPageState>(find.byType(RebuildingPage));
      for (var i = 0; i < 100; i++) {
        // ignore: invalid_use_of_protected_member
        state.setState(() {});
        await tester.pump();
      }
      expect(state.builds, greaterThan(100));
      expect(native.opened, 1, reason: 'a rebuild must never re-open a listener');
      expect(native.closed, 0);

      native.emit(7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('card0:7'), findsOneWidget);
      expect(find.text('card3:7'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(native.live, 0, reason: 'last listener leaving closes the native one');
      expect(streams.nativeListeners, 0);
    });

    test('a late listener gets the newest value immediately', () async {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      final first = <int>[];
      final second = <int>[];
      final s1 = streams.watch('k', native.open).listen(first.add);
      native.emit(1);
      native.emit(2);
      await pumpEventQueue();
      final s2 = streams.watch('k', native.open).listen(second.add);
      await pumpEventQueue();
      expect(first, [1, 2]);
      expect(second, [2], reason: 'no waiting for the next server change');
      expect(native.opened, 1);
      await s1.cancel();
      await s2.cancel();
    });

    test('pauseAll closes native listeners; resumeAll reopens once', () async {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      final got = <int>[];
      final sub = streams.watch('k', native.open).listen(got.add);
      expect(native.live, 1);

      streams.pauseAll();
      streams.pauseAll();
      expect(native.live, 0);
      expect(streams.nativeListeners, 0);
      expect(streams.listeners, 1, reason: 'the widget is still listening');

      streams.resumeAll();
      streams.resumeAll();
      streams.resumeAll();
      expect(native.opened, 2, reason: 'repeated resumes reopen exactly once');
      expect(native.live, 1);

      native.emit(9);
      await pumpEventQueue();
      expect(got, [9]);
      await sub.cancel();
      expect(native.live, 0);
    });

    test('nobody listening while paused: resume opens nothing', () {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      final sub = streams.watch('k', native.open).listen((_) {});
      streams.pauseAll();
      sub.cancel();
      streams.resumeAll();
      expect(native.opened, 1);
      expect(native.live, 0);
    });

    test('a listener added while paused waits for resume', () {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      streams.pauseAll();
      final sub = streams.watch('k', native.open).listen((_) {});
      expect(native.opened, 0, reason: 'nothing opens while the app is away');
      streams.resumeAll();
      expect(native.opened, 1);
      sub.cancel();
    });

    test('reset drops everything for a controlled recovery', () {
      final streams = SharedStreams<int>();
      final native = FakeNative();
      streams.watch('a', native.open).listen((_) {});
      streams.watch('b', native.open).listen((_) {});
      expect(native.live, 2);
      streams.reset();
      expect(native.live, 0);
      expect(streams.listeners, 0);
      // and it works again afterwards
      final sub = streams.watch('a', native.open).listen((_) {});
      expect(native.live, 1);
      sub.cancel();
    });

    test('a burst is coalesced to leading + trailing', () {
      fakeAsync((async) {
        final streams = SharedStreams<int>(
            now: () => DateTime(2026).add(async.elapsed));
        final native = FakeNative();
        final got = <int>[];
        streams
            .watch('k', native.open, coalesce: const Duration(milliseconds: 800))
            .listen(got.add);
        for (var i = 1; i <= 200; i++) {
          native.emit(i);
          async.elapse(const Duration(milliseconds: 3));
        }
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(got.first, 1);
        expect(got.last, 200, reason: 'the newest state is never lost');
        expect(got.length, lessThanOrEqualTo(3));
      });
    });
  });

  group('watchRideLeaves', () {
    Stream<Object?> Function(String) opener(
        Map<String, StreamController<Object?>> byPath, List<String> opened) {
      return (path) {
        opened.add(path);
        return (byPath[path] = StreamController<Object?>()).stream;
      };
    }

    test('listens to exactly the requested leaves, never the whole node',
        () async {
      final byPath = <String, StreamController<Object?>>{};
      final opened = <String>[];
      final sub = watchRideLeaves('r1', const ['is_accept', 'is_trip_start'],
          openLeaf: opener(byPath, opened)).listen((_) {});
      expect(opened, ['requests/r1/is_accept', 'requests/r1/is_trip_start']);
      expect(opened.any((p) => p.endsWith('lat_lng_array')), isFalse);
      expect(opened.contains('requests/r1'), isFalse);
      await sub.cancel();
    });

    test('reports an existing flag once at start, then only real changes',
        () async {
      final byPath = <String, StreamController<Object?>>{};
      final got = <String>[];
      final sub = watchRideLeaves('r1', const ['is_trip_start', 'cancelled_by_driver'],
          openLeaf: opener(byPath, [])).listen((l) => got.add('${l.key}=${l.value}'));

      byPath['requests/r1/is_trip_start']!.add(null); // not there yet
      byPath['requests/r1/cancelled_by_driver']!.add(1); // already set before we attached
      await pumpEventQueue();
      expect(got, ['cancelled_by_driver=1']);

      byPath['requests/r1/is_trip_start']!.add('1');
      byPath['requests/r1/is_trip_start']!.add('1'); // unchanged
      byPath['requests/r1/is_trip_start']!.add(null); // removed: ignored
      byPath['requests/r1/is_trip_start']!.add('1'); // back: a change again
      await pumpEventQueue();
      expect(got, [
        'cancelled_by_driver=1',
        'is_trip_start=1',
        'is_trip_start=1',
      ]);
      await sub.cancel();
    });

    test('cancelling closes every leaf listener', () async {
      final byPath = <String, StreamController<Object?>>{};
      final sub = watchRideLeaves('r9', const ['a', 'b', 'c'],
          openLeaf: opener(byPath, [])).listen((_) {});
      expect(byPath.values.every((c) => c.hasListener), isTrue);
      await sub.cancel();
      expect(byPath.values.any((c) => c.hasListener), isFalse);
    });
  });

  group('AppLifecycleCoordinator', () {
    test('background once, foreground once, however many events arrive', () {
      fakeAsync((async) {
        final coordinator = AppLifecycleCoordinator(
            clock: () => DateTime(2026).add(async.elapsed));
        var background = 0;
        var foreground = 0;
        coordinator.onBackground.add(() => background++);
        coordinator.onForeground.add(() => foreground++);

        // inactive -> hidden -> paused, the real iOS order
        coordinator.handle(AppLifecycleState.inactive);
        coordinator.handle(AppLifecycleState.hidden);
        coordinator.handle(AppLifecycleState.paused);
        coordinator.handle(AppLifecycleState.paused);
        expect(background, 1);
        expect(coordinator.inBackground, isTrue);

        // a burst of resumes (radio flaps) -> ONE reconcile after the delay
        coordinator.handle(AppLifecycleState.inactive);
        coordinator.handle(AppLifecycleState.resumed);
        coordinator.handle(AppLifecycleState.resumed);
        coordinator.handle(AppLifecycleState.resumed);
        expect(foreground, 0, reason: 'never synchronously on the resume event');
        async.elapse(const Duration(seconds: 1));
        expect(foreground, 1);
        expect(coordinator.inBackground, isFalse);
      });
    });

    test('resume without a preceding background does nothing', () {
      fakeAsync((async) {
        final coordinator = AppLifecycleCoordinator();
        var foreground = 0;
        coordinator.onForeground.add(() => foreground++);
        coordinator.handle(AppLifecycleState.inactive);
        coordinator.handle(AppLifecycleState.resumed);
        async.elapse(const Duration(seconds: 1));
        expect(foreground, 0);
      });
    });

    test('a quick bounce back to background cancels the pending resume', () {
      fakeAsync((async) {
        final coordinator = AppLifecycleCoordinator();
        var background = 0;
        var foreground = 0;
        coordinator.onBackground.add(() => background++);
        coordinator.onForeground.add(() => foreground++);
        coordinator.handle(AppLifecycleState.paused);
        coordinator.handle(AppLifecycleState.resumed);
        coordinator.handle(AppLifecycleState.paused); // switched away again
        async.elapse(const Duration(seconds: 1));
        expect(foreground, 0, reason: 'never reopen listeners for an app that left');
        expect(background, 1);
        coordinator.handle(AppLifecycleState.resumed);
        async.elapse(const Duration(seconds: 1));
        expect(foreground, 1);
      });
    });

    test('ten switch-aways: exactly ten closes and ten reopens, no leftovers', () {
      fakeAsync((async) {
        final streams = SharedStreams<int>();
        final native = FakeNative();
        final coordinator = AppLifecycleCoordinator();
        coordinator.onBackground.add(streams.pauseAll);
        coordinator.onForeground.add(streams.resumeAll);
        final sub = streams.watch('drivers', native.open).listen((_) {});

        for (var i = 0; i < 10; i++) {
          coordinator.handle(AppLifecycleState.inactive);
          coordinator.handle(AppLifecycleState.hidden);
          coordinator.handle(AppLifecycleState.paused);
          expect(native.live, 0, reason: 'nothing delivered while away');
          async.elapse(Duration(seconds: 1 + i));
          coordinator.handle(AppLifecycleState.inactive);
          coordinator.handle(AppLifecycleState.resumed);
          coordinator.handle(AppLifecycleState.resumed);
          async.elapse(const Duration(seconds: 1));
          expect(native.live, 1, reason: 'exactly one listener after resume $i');
        }
        expect(native.opened, 11);
        expect(coordinator.backgroundRuns, 10);
        expect(coordinator.foregroundRuns, 10);
        sub.cancel();
        expect(native.live, 0);
      });
    });

    test('a failing callback never blocks the others', () {
      fakeAsync((async) {
        final coordinator = AppLifecycleCoordinator();
        var ran = false;
        coordinator.onBackground
          ..add(() => throw StateError('boom'))
          ..add(() => ran = true);
        coordinator.handle(AppLifecycleState.paused);
        expect(ran, isTrue);
      });
    });
  });

  group('ExclusiveRunner never keeps a lock forever', () {
    test('a normal action releases the lock when it finishes; a second tap during it is ignored', () async {
      final runner = ExclusiveRunner();
      final gate = Completer<void>();
      var runs = 0;
      final first = runner.run(() async {
        runs++;
        await gate.future;
      });
      expect(runner.busy, isTrue);
      await runner.run(() async => runs++); // ignored
      expect(runs, 1);
      gate.complete();
      await first;
      expect(runner.busy, isFalse);
      await runner.run(() async => runs++);
      expect(runs, 2);
    });

    test('an action that never answers is abandoned after the deadline', () {
      fakeAsync((async) {
        final runner = ExclusiveRunner(maxDuration: const Duration(seconds: 25));
        var second = 0;
        runner.run(() => Completer<void>().future); // never completes
        async.elapse(const Duration(seconds: 10));
        runner.run(() async => second++);
        expect(runner.busy, isTrue);
        expect(second, 0, reason: 'still inside the deadline: taps are ignored');
        async.elapse(const Duration(seconds: 20));
        expect(runner.busy, isFalse, reason: 'the lock came off by itself');
        runner.run(() async => second++);
        async.flushMicrotasks();
        expect(second, 1);
      });
    });

    test('reset (returning from the background) frees the lock at once and the old run cannot re-lock', () {
      fakeAsync((async) {
        final runner = ExclusiveRunner();
        final never = Completer<void>();
        runner.run(() => never.future);
        expect(runner.busy, isTrue);
        runner.reset();
        expect(runner.busy, isFalse);
        var ran = 0;
        final gate = Completer<void>();
        runner.run(() async {
          ran++;
          await gate.future;
        });
        // the abandoned first run finishing late must not free the NEW run's lock
        never.complete();
        async.flushMicrotasks();
        expect(runner.busy, isTrue);
        gate.complete();
        async.flushMicrotasks();
        expect(runner.busy, isFalse);
        expect(ran, 1);
      });
    });

    test('Home resets it on every resume', () {
      final home = File('lib/pages/onTripPage/map_page.dart').readAsStringSync();
      expect(home.contains('_destinationEntry.reset()'), isTrue);
    });
  });

  group('source rules that keep the freeze from coming back', () {
    String read(String path) => File(path).readAsStringSync();

    test('no page builds a Firebase stream inside build()', () {
      final offenders = <String>[];
      for (final entity
          in Directory('lib/pages/onTripPage').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        if (RegExp(r'FirebaseDatabase\.instance[\s\S]{0,300}?\.onValue')
            .hasMatch(text)) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'use LiveQueries.watchQuery(key, ...) so rebuilds reuse one listener');
    });

    test('the ride node is never watched with child events', () {
      final text = read('lib/functions/parts/payments_profile.dart');
      expect(text.contains('.onChildAdded'), isFalse);
      expect(text.contains('.onChildChanged'), isFalse);
      expect(text.contains('watchRideLeaves('), isTrue);
    });

    test('every page that registers a lifecycle observer removes it', () {
      for (final file in [
        'lib/pages/onTripPage/map_page.dart',
        'lib/pages/onTripPage/booking_confirmation/booking_confirmation_controller.dart',
        'lib/pages/onTripPage/pick_loc_select.dart',
      ]) {
        final text = read(file);
        expect('addObserver'.allMatches(text).length,
            lessThanOrEqualTo('removeObserver'.allMatches(text).length),
            reason: '$file leaks a State on every visit');
      }
    });

    test('connectivity reads the list and only notifies on change', () {
      final text = read('lib/functions/parts/bootstrap_auth.dart');
      expect(text.contains('results.any((r) => r != ConnectivityResult.none)'), isTrue);
      expect(text.contains('if (internet == online) return;'), isTrue);
    });

    test('the coordinator is wired once in main()', () {
      final text = read('lib/main.dart');
      expect(text.contains('AppLifecycleCoordinator.instance'), isTrue);
      expect(text.contains('LiveQueries.instance.pauseAll'), isTrue);
      expect(text.contains('detachRideStreams'), isTrue);
    });
  });
}
