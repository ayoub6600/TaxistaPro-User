import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/api_guard.dart';

/// A page shaped like the Rider search/home pages: it restores itself the
/// moment the app returns, then reconciles once under a deadline, and resets
/// itself if reconciling keeps failing.
class ResumeHarness extends StatefulWidget {
  const ResumeHarness({super.key, required this.reconcile, required this.log});

  final Future<void> Function() reconcile;
  final List<String> log;

  @override
  State<ResumeHarness> createState() => _ResumeHarnessState();
}

class _ResumeHarnessState extends State<ResumeHarness> with WidgetsBindingObserver {
  final ResumeReconciler _resume = ResumeReconciler(timeout: const Duration(seconds: 15));
  int taps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) widget.log.add('paused');
    if (state == AppLifecycleState.resumed) unawaited(_onResumed());
  }

  Future<void> _onResumed() async {
    widget.log.add('restore'); // instant, network-free
    final outcome = await _resume.run(widget.reconcile);
    if (!mounted) return;
    widget.log.add(outcome.name);
    if (outcome == ResumeOutcome.needsReset) widget.log.add('controlled-reset');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextButton(
            key: const Key('tap'),
            onPressed: () => setState(() => taps++),
            child: Text('taps $taps'),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('SingleFlight with a deadline', () {
    test('a run that never finishes is abandoned and the next call starts fresh', () {
      fakeAsync((async) {
        final flight = SingleFlight<int>();
        var starts = 0;
        Object? firstError;

        flight.run(() {
          starts++;
          return Completer<int>().future; // never completes: a dead socket
        }, timeout: const Duration(seconds: 10)).catchError((Object e) {
          firstError = e;
          return -1;
        });

        // while it hangs, others join it instead of piling up
        flight.run(() async => 99, timeout: const Duration(seconds: 10));
        expect(starts, 1);
        expect(flight.busy, isTrue);

        async.elapse(const Duration(seconds: 11));
        expect(firstError, isA<TimeoutException>());
        expect(flight.busy, isFalse, reason: 'the lock is released after the deadline');

        int? second;
        flight.run(() async {
          starts++;
          return 7;
        }, timeout: const Duration(seconds: 10)).then((v) => second = v);
        async.flushMicrotasks();
        expect(second, 7);
        expect(starts, 2);
      });
    });

    test('an abandoned run finishing late cannot release a newer run\'s lock', () {
      fakeAsync((async) {
        final flight = SingleFlight<int>();
        final late = Completer<int>();
        flight.run(() => late.future, timeout: const Duration(seconds: 5)).catchError((Object _) => -1);
        async.elapse(const Duration(seconds: 6));

        final newer = Completer<int>();
        flight.run(() => newer.future, timeout: const Duration(seconds: 30));
        expect(flight.busy, isTrue);

        late.complete(1); // the old socket finally answers
        async.flushMicrotasks();
        expect(flight.busy, isTrue, reason: 'the newer run still owns the lock');
      });
    });
  });

  group('ResumeReconciler', () {
    test('a healthy reconcile reports reconciled and clears the failure count', () async {
      final r = ResumeReconciler(timeout: const Duration(seconds: 5));
      expect(await r.run(() async {}), ResumeOutcome.reconciled);
      expect(r.consecutiveFailures, 0);
    });

    test('a hanging reconcile times out softly first, then asks for a controlled reset', () {
      fakeAsync((async) {
        final r = ResumeReconciler(timeout: const Duration(seconds: 15));
        final outcomes = <ResumeOutcome>[];

        r.run(() => Completer<void>().future).then(outcomes.add);
        async.elapse(const Duration(seconds: 16));
        expect(outcomes, [ResumeOutcome.softFailure]);

        r.run(() => Completer<void>().future).then(outcomes.add);
        async.elapse(const Duration(seconds: 16));
        expect(outcomes, [ResumeOutcome.softFailure, ResumeOutcome.needsReset]);
        expect(r.consecutiveFailures, 0, reason: 'the counter restarts after a reset');
      });
    });

    test('an error counts as a failure and one success in between clears the streak', () async {
      final r = ResumeReconciler(timeout: const Duration(seconds: 5));
      expect(await r.run(() async => throw Exception('boom')), ResumeOutcome.softFailure);
      expect(await r.run(() async {}), ResumeOutcome.reconciled);
      expect(await r.run(() async => throw Exception('boom')), ResumeOutcome.softFailure);
    });

    test('rapid resumes share ONE reconcile', () async {
      final r = ResumeReconciler(timeout: const Duration(seconds: 5));
      final gate = Completer<void>();
      var runs = 0;
      final all = [
        for (var i = 0; i < 5; i++)
          r.run(() {
            runs++;
            return gate.future;
          })
      ];
      gate.complete();
      final outcomes = await Future.wait(all);
      expect(runs, 1);
      expect(outcomes.every((o) => o == ResumeOutcome.reconciled), isTrue);
    });
  });

  group('page lifecycle (real WidgetsBindingObserver events)', () {
    testWidgets('repeated Rider <-> Driver switching: every return restores at once and reconciles once', (tester) async {
      final log = <String>[];
      var reconciles = 0;
      await tester.pumpWidget(ResumeHarness(reconcile: () async => reconciles++, log: log));

      for (var i = 0; i < 5; i++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        // the screen answers touches straight after every return
        await tester.tap(find.byKey(const Key('tap')));
        await tester.pump();
      }

      expect(reconciles, 5);
      expect(log.where((e) => e == 'restore').length, 5);
      expect(log.where((e) => e == 'reconciled').length, 5);
      expect(find.text('taps 5'), findsOneWidget);
    });

    testWidgets('a reconcile stuck on a dead connection never blocks touches, and the page resets itself after two failures', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(ResumeHarness(reconcile: () => Completer<void>().future, log: log));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Immediately after the return - long before any deadline - it is usable.
      expect(log, contains('restore'));
      await tester.tap(find.byKey(const Key('tap')));
      await tester.pump();
      expect(find.text('taps 1'), findsOneWidget);

      await tester.pump(const Duration(seconds: 16));
      expect(log.last, 'softFailure');
      await tester.tap(find.byKey(const Key('tap')));
      await tester.pump();
      expect(find.text('taps 2'), findsOneWidget);

      // The next return also hangs: second consecutive failure -> reset.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 16));
      expect(log.takeLast(2), ['needsReset', 'controlled-reset']);
    });

    testWidgets('a page that is gone when the reconcile ends does nothing', (tester) async {
      final log = <String>[];
      final gate = Completer<void>();
      await tester.pumpWidget(ResumeHarness(reconcile: () => gate.future, log: log));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pump();

      expect(log, ['restore']);
      expect(tester.takeException(), isNull);
    });
  });
}

extension on List<String> {
  List<String> takeLast(int n) => sublist(length - n);
}
