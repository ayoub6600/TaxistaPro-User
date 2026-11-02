import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// How the line sounds right now, from WebRTC's own statistics every 2 s.
enum NetQuality { good, weak, poor }

/// One reading of the audio connection.
class QualitySample {
  const QualitySample({this.rttMs, this.received = 0, this.lost = 0, this.jitterMs});

  final double? rttMs;
  final int received;
  final int lost;
  final double? jitterMs;

  /// From getStats(): the active candidate pair's round trip and the incoming audio's packets.
  factory QualitySample.fromReports(List<StatsReport> reports) {
    double? rtt;
    var received = 0;
    var lost = 0;
    double? jitter;
    double? num0(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
    for (final r in reports) {
      final v = r.values;
      if (r.type == 'candidate-pair' && (v['state'] == 'succeeded' || v['nominated'] == true)) {
        final s = num0(v['currentRoundTripTime']);
        if (s != null) rtt = s * 1000;
      } else if (r.type == 'inbound-rtp' && (v['kind'] ?? v['mediaType']) == 'audio') {
        received += (num0(v['packetsReceived']) ?? 0).toInt();
        lost += (num0(v['packetsLost']) ?? 0).toInt();
        final j = num0(v['jitter']);
        if (j != null) jitter = j * 1000;
      }
    }
    return QualitySample(rttMs: rtt, received: received, lost: lost, jitterMs: jitter);
  }
}

class CallQuality {
  /// The line between two readings: lost packets, delay, jitter, or no sound arriving at all.
  static NetQuality between(QualitySample before, QualitySample now) {
    final received = now.received - before.received;
    final lost = (now.lost - before.lost).clamp(0, 1 << 30);
    final loss = received + lost == 0 ? 0.0 : lost * 100 / (received + lost);
    return rate(rttMs: now.rttMs, lossPercent: loss, jitterMs: now.jitterMs, silent: received <= 0);
  }

  static NetQuality rate({double? rttMs, double lossPercent = 0, double? jitterMs, bool silent = false}) {
    if (silent || lossPercent >= 15 || (rttMs ?? 0) >= 800) return NetQuality.poor;
    if (lossPercent >= 4 || (rttMs ?? 0) >= 350 || (jitterMs ?? 0) >= 60) return NetQuality.weak;
    return NetQuality.good;
  }
}

/// Reads the connection every [every] and reports a change only once two readings in a row agree
/// (one bad moment does not flash a warning).
class CallQualityMonitor {
  CallQualityMonitor({this.every = const Duration(seconds: 2)});

  final Duration every;
  Timer? _timer;
  QualitySample? _last;
  NetQuality quality = NetQuality.good;
  NetQuality? _pending;

  void start(RTCPeerConnection pc, void Function(NetQuality) onChange) {
    stop();
    _timer = Timer.periodic(every, (_) async {
      try {
        final sample = QualitySample.fromReports(await pc.getStats());
        final last = _last;
        _last = sample;
        if (last == null) return;
        final q = CallQuality.between(last, sample);
        if (q == quality) {
          _pending = null;
        } else if (_pending == q) {
          _pending = null;
          quality = q;
          onChange(q);
        } else {
          _pending = q;
        }
      } catch (_) {}
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _last = null;
    _pending = null;
    quality = NetQuality.good;
  }
}
