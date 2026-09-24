import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/navigation/guarded_navigation.dart';
import 'package:taxista/pages/loadingPage/loading.dart';
import 'package:taxista/pages/onTripPage/widgets/smooth_page_route.dart';

class _CountingObserver extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route route, Route? previousRoute) => pushes++;
}

void main() {
  testWidgets('guardedPush ignores a repeated push, then allows the next one',
      (tester) async {
    final observer = _CountingObserver();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [observer],
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => guardedPush(
                context, MaterialPageRoute(builder: (_) => const Text('next'))),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    final initial = observer.pushes; // the home route

    // Double tap: both taps land before the first route has even settled.
    await tester.tap(find.text('go'));
    await tester.tap(find.text('go'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(observer.pushes - initial, 1);

    // After the lock window a new push is allowed again.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)));
    Navigator.of(tester.element(find.text('next'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(observer.pushes - initial, 2);
  });

  test('ExclusiveRunner runs one action at a time and always releases',
      () async {
    final runner = ExclusiveRunner();
    var runs = 0;
    final gate = Completer<void>();

    // Burst of taps while the first action is still in flight.
    final first = runner.run(() async {
      runs++;
      await gate.future;
    });
    await runner.run(() async => runs++);
    await runner.run(() async => runs++);
    expect(runner.busy, isTrue);
    expect(runs, 1);

    gate.complete();
    await first;
    expect(runner.busy, isFalse);

    // Released: the next tap works again.
    await runner.run(() async => runs++);
    expect(runs, 2);

    // A failing action must not leave the runner locked.
    await expectLater(
        runner.run(() async => throw StateError('boom')), throwsStateError);
    expect(runner.busy, isFalse);
    await runner.run(() async => runs++);
    expect(runs, 3);
  });

  testWidgets('an ignored guardedPush completes at once with null',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => const Scaffold(body: Text('home'))),
    ));
    final context = tester.element(find.text('home'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));

    final first = guardedPush<bool>(
        context, MaterialPageRoute(builder: (_) => const Text('a')));
    final ignored = guardedPush<bool>(
        context, MaterialPageRoute(builder: (_) => const Text('b')));

    // The skipped push resolves immediately - a caller awaiting it never hangs.
    expect(await ignored, isNull);
    await tester.pumpAndSettle();
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsNothing);
    Navigator.of(tester.element(find.text('a'))).pop(true);
    expect(await first, isTrue);
  });

  test('TapLock accepts one call per window', () {
    final lock = TapLock(const Duration(milliseconds: 700));
    final t0 = DateTime(2026, 1, 1, 12);

    expect(lock.tryAcquire(t0), isTrue);
    expect(lock.tryAcquire(t0.add(const Duration(milliseconds: 100))), isFalse);
    expect(lock.tryAcquire(t0.add(const Duration(milliseconds: 699))), isFalse);
    expect(lock.tryAcquire(t0.add(const Duration(milliseconds: 701))), isTrue);
  });

  testWidgets('Loading overlay stays invisible at first, then fades in',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Loading())));

    double opacity() => tester
        .widget<Opacity>(find
            .descendant(
                of: find.byType(Loading), matching: find.byType(Opacity))
            .first)
        .opacity;

    expect(opacity(), 0); // blocks taps immediately, but nothing flashes
    await tester.pump(const Duration(milliseconds: 120));
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), 1);
  });

  test('smoothPageRoute uses the app-wide MaterialPageRoute transition', () {
    expect(smoothPageRoute<void>(builder: (_) => const SizedBox()),
        isA<MaterialPageRoute<void>>());
  });
}
