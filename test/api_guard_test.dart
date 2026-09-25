import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/api_guard.dart';

void main() {
  group('SingleFlight', () {
    test('concurrent callers share one run', () async {
      var runs = 0;
      final gate = Completer<int>();
      final flight = SingleFlight<int>();

      final a = flight.run(() {
        runs++;
        return gate.future;
      });
      final b = flight.run(() {
        runs++;
        return gate.future;
      });
      expect(flight.busy, isTrue);
      gate.complete(7);

      expect(await a, 7);
      expect(await b, 7);
      expect(runs, 1);
      expect(flight.busy, isFalse);
    });

    test('a failed run releases the flight so the next call can retry', () async {
      final flight = SingleFlight<int>();
      await expectLater(flight.run(() async => throw StateError('x')), throwsStateError);
      expect(await flight.run(() async => 3), 3);
    });
  });

  group('PollGate', () {
    test('runs at most once per interval and coalesces in-flight calls', () async {
      var now = DateTime(2026, 1, 1, 10);
      final gate = PollGate(minInterval: const Duration(seconds: 5), clock: () => now);
      var runs = 0;
      Future<int> task() async => ++runs;

      expect(await gate.run(task), 1);
      expect(await gate.run(task), isNull, reason: 'too soon');
      now = now.add(const Duration(seconds: 6));
      expect(await gate.run(task), 2);
      expect(runs, 2);
    });

    test('force passes the minimum interval but never a server pause', () async {
      var now = DateTime(2026, 1, 1, 10);
      final gate = PollGate(minInterval: const Duration(seconds: 30), clock: () => now);
      var runs = 0;
      Future<int> task() async => ++runs;

      await gate.run(task);
      expect(await gate.run(task, force: true), 2);

      gate.backOff(const Duration(seconds: 20));
      expect(gate.paused, isTrue);
      expect(await gate.run(task, force: true), isNull, reason: 'server said slow down');
      now = now.add(const Duration(seconds: 21));
      expect(gate.paused, isFalse);
      expect(await gate.run(task, force: true), 3);
    });

    test('a burst of callers during one run produces one request', () async {
      final gate = PollGate(minInterval: Duration.zero);
      var runs = 0;
      final release = Completer<int>();
      final results = [
        gate.run(() {
          runs++;
          return release.future;
        }),
        gate.run(() {
          runs++;
          return release.future;
        }),
        gate.run(() {
          runs++;
          return release.future;
        }),
      ];
      release.complete(1);
      expect(await Future.wait(results), [1, 1, 1]);
      expect(runs, 1);
    });
  });

  group('retryAfterOf', () {
    test('reads seconds, is case-insensitive, and clamps', () {
      expect(retryAfterOf({'Retry-After': '12'}), const Duration(seconds: 12));
      expect(retryAfterOf({'retry-after': '0'}), const Duration(seconds: 1));
      expect(retryAfterOf({'retry-after': '99999'}), const Duration(minutes: 2));
      expect(retryAfterOf({}), isNull);
      expect(retryAfterOf({'retry-after': 'soon'}), isNull);
    });

    test('reads an HTTP date', () {
      final now = DateTime.utc(2026, 10, 21, 7, 27, 30);
      expect(retryAfterOf({'retry-after': 'Wed, 21 Oct 2026 07:28:00 GMT'}, now: now),
          const Duration(seconds: 30));
    });
  });

  group('rideAnswerOf', () {
    test('a gone ride is never a retryable failure', () {
      expect(rideAnswerOf(200), RideAnswer.ok);
      expect(rideAnswerOf(410), RideAnswer.gone);
      expect(rideAnswerOf(409, '{"code":"ride_no_longer_available"}'), RideAnswer.gone);
      expect(rideAnswerOf(409, '{"message":"other conflict"}'), RideAnswer.failed);
      expect(rideAnswerOf(429), RideAnswer.throttled);
      expect(rideAnswerOf(401), RideAnswer.unauthorized);
      expect(rideAnswerOf(500), RideAnswer.failed);
    });
  });
}
