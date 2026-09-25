import 'dart:async';

/// Coalesces identical concurrent requests: while one run is in flight, every
/// other caller gets that same run's result instead of starting another.
/// A double tap on Cancel, or two screens asking for the same status at the
/// same moment, therefore become ONE request.
class SingleFlight<T> {
  Future<T>? _inflight;

  bool get busy => _inflight != null;

  Future<T> run(Future<T> Function() task) {
    final running = _inflight;
    if (running != null) return running;
    final started = task();
    _inflight = started;
    return started.whenComplete(() => _inflight = null);
  }
}

/// Rate discipline for a polled endpoint: at most one in flight, at least
/// [minInterval] between runs, and a hard pause after the server said
/// "too many requests" (respecting its Retry-After). A caller that has just
/// learned something changed (a push notification) can [force] past the
/// minimum interval, but never past a server-imposed pause.
class PollGate {
  PollGate({required this.minInterval, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Duration minInterval;
  final DateTime Function() _clock;
  Future<Object?>? _inflight;
  DateTime? _lastStarted;
  DateTime? _pausedUntil;

  bool get paused {
    final until = _pausedUntil;
    return until != null && _clock().isBefore(until);
  }

  /// Pause every run (forced or not) for [duration].
  void backOff(Duration duration) => _pausedUntil = _clock().add(duration);

  /// Runs [task] unless one is in flight, the endpoint is paused, or it ran
  /// too recently. Returns null when it was skipped (or shares a run in flight).
  Future<T?> run<T>(Future<T> Function() task, {bool force = false}) async {
    if (paused) return null;
    final running = _inflight;
    if (running != null) return await running as T?;
    final last = _lastStarted;
    if (!force && last != null && _clock().difference(last) < minInterval) {
      return null;
    }
    _lastStarted = _clock();
    final started = task();
    _inflight = started;
    try {
      return await started;
    } finally {
      _inflight = null;
    }
  }
}

/// The server's requested wait from a Retry-After header: delta-seconds, or
/// an HTTP date. Clamped to a sensible range; null when absent or unusable.
Duration? retryAfterOf(Map<String, String> headers, {DateTime? now}) {
  String? raw;
  headers.forEach((key, value) {
    if (key.toLowerCase() == 'retry-after') raw = value.trim();
  });
  if (raw == null || raw!.isEmpty) return null;
  final seconds = int.tryParse(raw!);
  Duration? wait;
  if (seconds != null) {
    wait = Duration(seconds: seconds);
  } else {
    try {
      wait = _parseHttpDate(raw!).difference(now ?? DateTime.now());
    } catch (_) {
      return null;
    }
  }
  if (wait.isNegative) return const Duration(seconds: 1);
  if (wait > const Duration(minutes: 2)) return const Duration(minutes: 2);
  return wait < const Duration(seconds: 1) ? const Duration(seconds: 1) : wait;
}

DateTime _parseHttpDate(String value) {
  // RFC 1123: "Wed, 21 Oct 2026 07:28:00 GMT"
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  final match = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})')
      .firstMatch(value);
  if (match == null) throw const FormatException('not an HTTP date');
  return DateTime.utc(
    int.parse(match.group(3)!),
    months[match.group(2)]!,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

/// The one shape every ride-lifecycle answer is read through, so the apps
/// react to what the backend decided instead of to a generic failure.
enum RideAnswer {
  ok,

  /// 410 / 409 with code ride_no_longer_available: the ride was cancelled,
  /// finished or taken. Never retried; the card / search screen is dropped.
  gone,

  /// 429: back off and try once more later, never in a loop.
  throttled,
  unauthorized,
  failed,
}

RideAnswer rideAnswerOf(int status, [String body = '']) {
  if (status >= 200 && status < 300) return RideAnswer.ok;
  if (status == 401) return RideAnswer.unauthorized;
  if (status == 429) return RideAnswer.throttled;
  if (status == 410 || status == 404) return RideAnswer.gone;
  if (status == 409 && body.contains('ride_no_longer_available')) {
    return RideAnswer.gone;
  }
  return RideAnswer.failed;
}
