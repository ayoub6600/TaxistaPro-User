import 'dart:async';

import 'moamalat_api.dart';

/// How a top-up ended, from the server's point of view.
enum TopUpOutcome {
  /// The server credited the wallet.
  paid,

  /// The payment failed or was cancelled; nothing was credited.
  notPaid,

  /// The server has not confirmed yet (pending / under review / unreachable).
  /// The wallet was NOT credited as far as the app knows.
  unconfirmed,
}

/// Waits for the server's verdict after the payment page reports something.
///
/// Polling backs off (1s, 2s, 3s, 3s ...), is bounded by [maxWait] - so there
/// is never an endless spinner - and treats network errors as "try again"
/// until time runs out. The app never claims success unless the server says
/// the wallet was credited.
class TopUpFlow {
  TopUpFlow(
    this.api, {
    this.maxWait = const Duration(seconds: 30),
    this.delay = _realDelay,
  });

  final MoamalatApi api;
  final Duration maxWait;
  final Future<void> Function(Duration) delay;

  static Future<void> _realDelay(Duration d) => Future<void>.delayed(d);

  static const List<int> _backoffSeconds = [1, 2, 3];

  /// [expectFinal] is true when the page said the payment completed, so a
  /// still-pending status is worth waiting on. Otherwise one check is enough.
  Future<TopUpOutcome> settle(String topUpId, {required bool expectFinal}) async {
    var waited = Duration.zero;
    var attempt = 0;
    while (true) {
      try {
        final status = await api.status(topUpId);
        if (status.credited) return TopUpOutcome.paid;
        if (status.status == 'failed' || status.status == 'cancelled') return TopUpOutcome.notPaid;
        if (!expectFinal) {
          return status.status == 'needs_review' ? TopUpOutcome.unconfirmed : TopUpOutcome.notPaid;
        }
        // pending / needs_review while a completed payment is expected: wait.
      } on MoamalatException catch (e) {
        if (e.kind == MoamalatErrorKind.unauthorized) rethrow;
        // network / server hiccup: keep trying until the time is up.
      }
      final step = Duration(seconds: _backoffSeconds[attempt < _backoffSeconds.length ? attempt : _backoffSeconds.length - 1]);
      if (waited + step > maxWait) return TopUpOutcome.unconfirmed;
      await delay(step);
      waited += step;
      attempt++;
    }
  }
}
