import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:taxista/functions/calls/call_quality.dart';
import 'package:taxista/functions/calls/call_tones.dart';

/// What a call sounds like and how the line is judged - and the one background push handler that
/// makes a call ring when the app is not on screen.
void main() {
  group('tones', () {
    late List<String> sent;
    setUp(() {
      sent = [];
      CallTones.invoke = (method, args) async => sent.add(args == null ? method : '$method:${args['tone']}');
    });
    tearDown(() async => CallTones.stop());

    test('the caller hears a pip while the call is on its way, the long ring once the phone rings', () {
      expect(CallTones.ringingTone(reach: 'connecting'), CallTone.connecting);
      expect(CallTones.ringingTone(reach: 'unreached'), CallTone.connecting);
      expect(CallTones.ringingTone(reach: 'ringing'), CallTone.ringback);
      // an older server sends no "reach": the confirmation decides
      expect(CallTones.ringingTone(alerted: true), CallTone.ringback);
      expect(CallTones.ringingTone(alerted: false), CallTone.connecting);
    });

    test('how a call that the other side closed sounds', () {
      expect(CallTones.endTone(status: 'ended', connected: true, iAmCaller: false), CallTone.ended, reason: 'they hung up on me');
      expect(CallTones.endTone(status: 'failed', connected: true, iAmCaller: true), CallTone.failed);
      expect(CallTones.endTone(status: 'declined', connected: false, iAmCaller: true), CallTone.busy);
      expect(CallTones.endTone(status: 'missed', connected: false, iAmCaller: true), CallTone.busy, reason: 'nobody answered');
      expect(CallTones.endTone(status: 'cancelled', connected: false, iAmCaller: false), isNull, reason: 'a ring that stopped goes quiet');
    });

    test('a looping tone is started once, a new one replaces it, stop silences it', () async {
      await CallTones.play(CallTone.connecting);
      await CallTones.play(CallTone.connecting);
      await CallTones.play(CallTone.ringback);
      await CallTones.stop();
      await CallTones.stop();
      expect(sent, ['play:connecting', 'play:ringback', 'stop']);
      await CallTones.play(CallTone.ended);
      await CallTones.stop();
      expect(sent.last, 'play:ended', reason: 'a one-shot tone is never cut by a later stop');
    });
  });

  group('the line', () {
    test('lost packets, delay and silence make it weak or poor', () {
      expect(CallQuality.rate(rttMs: 120, lossPercent: 0.5, jitterMs: 10), NetQuality.good);
      expect(CallQuality.rate(rttMs: 420), NetQuality.weak);
      expect(CallQuality.rate(lossPercent: 6), NetQuality.weak);
      expect(CallQuality.rate(jitterMs: 80), NetQuality.weak);
      expect(CallQuality.rate(lossPercent: 20), NetQuality.poor);
      expect(CallQuality.rate(rttMs: 900), NetQuality.poor);
      expect(CallQuality.rate(silent: true), NetQuality.poor);
    });

    test('two readings give the loss in between; no sound arriving is poor', () {
      const a = QualitySample(rttMs: 100, received: 1000, lost: 10);
      expect(CallQuality.between(a, const QualitySample(rttMs: 100, received: 1100, lost: 10)), NetQuality.good);
      expect(CallQuality.between(a, const QualitySample(rttMs: 100, received: 1090, lost: 20)), NetQuality.weak);
      expect(CallQuality.between(a, const QualitySample(rttMs: 100, received: 1000, lost: 10)), NetQuality.poor);
    });

    test('WebRTC statistics are read from the active pair and the incoming audio', () {
      final s = QualitySample.fromReports([
        StatsReport('p1', 'candidate-pair', 0, {'state': 'succeeded', 'currentRoundTripTime': 0.25}),
        StatsReport('in', 'inbound-rtp', 0, {'kind': 'audio', 'packetsReceived': 500, 'packetsLost': 7, 'jitter': 0.02}),
        StatsReport('v', 'inbound-rtp', 0, {'kind': 'video', 'packetsReceived': 9999, 'packetsLost': 999}),
      ]);
      expect(s.rttMs, 250);
      expect(s.received, 500);
      expect(s.lost, 7);
      expect(s.jitterMs, 20);
    });
  });

  test('one background push handler, and a call rings before anything else in it', () {
    // Android honours only the FIRST FirebaseMessaging.onBackgroundMessage(...): a second one is
    // ignored. A handler that did not know calls once made them ring only with the app on screen.
    final sources = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    final registrations = <String>[];
    String? handler;
    for (final f in sources) {
      for (final m in RegExp(r'FirebaseMessaging\.onBackgroundMessage\((\w+)\)').allMatches(f.readAsStringSync())) {
        registrations.add(f.path);
        handler = m.group(1);
      }
    }
    expect(registrations, hasLength(1), reason: 'registered in: $registrations');
    final all = sources.map((f) => f.readAsStringSync()).join('\n');
    final start = all.indexOf(RegExp('Future<void> $handler\\('));
    expect(start, greaterThan(0));
    expect(all.substring(start - 40, start), contains("@pragma('vm:entry-point')"), reason: 'kept in a release build');
    final body = all.substring(start, all.indexOf('\n}\n', start));
    final call = body.contains("'admin_call'") ? body.indexOf("'admin_call'") : body.indexOf('handleCallPush');
    expect(call, greaterThan(0), reason: 'the handler rings calls');
    final init = body.indexOf('Firebase.initializeApp');
    expect(init == -1 || call < init, isTrue, reason: 'the ring comes before Firebase starts');
  });
}
