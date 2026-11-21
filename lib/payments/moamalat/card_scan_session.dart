import 'card_brand.dart';
import 'card_text_parser.dart';

enum FieldState { searching, reading, locked }

/// What the scanner screen shows after each frame.
class ScanProgress {
  const ScanProgress({
    required this.number,
    required this.numberState,
    required this.holder,
    required this.holderState,
    required this.expiryMonth,
    required this.expiryYear,
    required this.expiryState,
    required this.result,
    required this.textSeen,
  });

  /// The best reading so far (locked or not).
  final String? number;
  final FieldState numberState;
  final String? holder;
  final FieldState holderState;
  final int? expiryMonth;
  final int? expiryYear;
  final FieldState expiryState;

  /// Non-null once the scan is complete.
  final ScannedCard? result;

  /// The last frame had text inside the card frame (a card is probably there).
  final bool textSeen;

  bool get done => result != null;

  String? get expiryText => (expiryMonth == null || expiryYear == null)
      ? null
      : '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear! % 100).toString().padLeft(2, '0')}';

  static const ScanProgress initial = ScanProgress(
    number: null,
    numberState: FieldState.searching,
    holder: null,
    holderState: FieldState.searching,
    expiryMonth: null,
    expiryYear: null,
    expiryState: FieldState.searching,
    result: null,
    textSeen: false,
  );
}

/// Turns a stream of noisy per-frame readings into one trustworthy card.
///
///  * A number is accepted only when the same checksum-valid value is read in
///    several frames - or, when one digit flickers between frames, when the
///    per-position majority of many same-length readings is checksum-valid.
///  * Numo, Meeza and other cards without a known check digit need more
///    identical frames and are always handed over for review.
///  * Name and expiry lock on their own; a card that has no printed name (or
///    an unreadable one) does not stall the scan: shortly after the number
///    locks the scan finishes with what it has, and the missing field is
///    left for the customer.
class CardScanSession {
  CardScanSession({
    DateTime Function()? clock,
    this.numberVotes = 2.0,
    this.localNumberVotes = 4,
    this.fieldVotes = 2,
    this.consensusMinReadings = 4,
    this.nameGrace = const Duration(milliseconds: 1400),
    this.partialGrace = const Duration(milliseconds: 2600),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final double numberVotes;
  final int localNumberVotes;
  final int fieldVotes;
  final int consensusMinReadings;

  /// Number and expiry are locked: how long to keep looking for the name.
  final Duration nameGrace;

  /// Only the number is locked: how long to keep looking for the rest.
  final Duration partialGrace;

  final Map<String, double> _numbers = {};
  final Map<String, int> _localNumbers = {};
  final List<String> _recentNumbers = [];
  final Map<String, int> _holders = {};
  final Map<String, int> _expiries = {};

  String? _lockedNumber;
  bool _numberByConsensus = false;
  String? _lockedHolder;
  String? _lockedExpiry;
  DateTime? _numberLockedAt;
  DateTime? _numberAndExpiryLockedAt;
  ScannedCard? _result;
  ScanProgress _progress = ScanProgress.initial;

  ScanProgress get progress => _progress;

  ScanProgress observe(ScannedCard reading, {bool textSeen = true}) {
    if (_result != null) return _progress;
    final now = _clock();

    // ---- number
    final number = reading.number;
    final raw = reading.rawNumber ?? number;
    if (_lockedNumber == null && raw != null) {
      _recentNumbers.add(raw);
      if (_recentNumbers.length > 10) _recentNumbers.removeAt(0);
    }
    if (_lockedNumber == null && number != null) {
      final brand = cardBrandOf(number);
      if (brand.usesLuhn && luhnValid(number)) {
        // A reading the parser had to correct (look-alikes) counts for less.
        final weight = reading.needsReview(CardField.number) ? 0.67 : 1.0;
        _numbers[number] = (_numbers[number] ?? 0) + weight;
        if (_numbers[number]! >= numberVotes - 1e-9) _lockNumber(number, now);
      } else if (!brand.usesLuhn) {
        _localNumbers[number] = (_localNumbers[number] ?? 0) + 1;
        if (_localNumbers[number]! >= localNumberVotes) _lockNumber(number, now);
      }
    }
    if (_lockedNumber == null && raw != null) {
      final agreed = _consensus();
      if (agreed != null) {
        _lockNumber(agreed, now);
        _numberByConsensus = true;
      }
    }

    // ---- expiry
    if (_lockedExpiry == null && reading.expiryMonth != null && reading.expiryYear != null) {
      final key = '${reading.expiryMonth}:${reading.expiryYear}';
      _expiries[key] = (_expiries[key] ?? 0) + 1;
      if (_expiries[key]! >= fieldVotes && !reading.needsReview(CardField.expiry)) _lockedExpiry = key;
      if (_expiries[key]! >= fieldVotes + 1) _lockedExpiry = key; // even "maybe" dates settle when they persist
    }

    // ---- holder
    final holder = reading.holder?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (_lockedHolder == null && holder != null && holder.length >= 3) {
      _holders[holder] = (_holders[holder] ?? 0) + 1;
      if (_holders[holder]! >= fieldVotes) _lockedHolder = holder;
    }

    if (_lockedNumber != null && _lockedExpiry != null) _numberAndExpiryLockedAt ??= now;

    // ---- finish?
    final complete = _lockedNumber != null && _lockedExpiry != null && _lockedHolder != null;
    final nameWaitOver = _numberAndExpiryLockedAt != null && now.difference(_numberAndExpiryLockedAt!) >= nameGrace;
    final partialWaitOver = _numberLockedAt != null && now.difference(_numberLockedAt!) >= partialGrace;
    if (complete || nameWaitOver || partialWaitOver) _result = _finish();

    _progress = _snapshot(textSeen: textSeen);
    return _progress;
  }

  /// The customer pressed "use what you have": finish with the best guesses.
  ScannedCard finishNow() {
    _result ??= _finish();
    _progress = _snapshot(textSeen: _progress.textSeen);
    return _result!;
  }

  bool get hasAnything => _numbers.isNotEmpty || _localNumbers.isNotEmpty || _holders.isNotEmpty || _expiries.isNotEmpty;

  void _lockNumber(String number, DateTime now) {
    _lockedNumber = number;
    _numberLockedAt = now;
  }

  /// The per-position majority of recent readings of the most common length,
  /// when every position agrees clearly and the result is checksum-valid.
  String? _consensus() {
    if (_recentNumbers.length < consensusMinReadings) return null;
    final byLength = <int, List<String>>{};
    for (final n in _recentNumbers) {
      byLength.putIfAbsent(n.length, () => []).add(n);
    }
    final pool = byLength.values.reduce((a, b) => a.length >= b.length ? a : b);
    if (pool.length < consensusMinReadings) return null;
    final length = pool.first.length;
    final out = StringBuffer();
    for (var i = 0; i < length; i++) {
      final counts = <String, int>{};
      for (final n in pool) {
        counts[n[i]] = (counts[n[i]] ?? 0) + 1;
      }
      final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value / pool.length < 0.6) return null;
      out.write(top.key);
    }
    final agreed = out.toString();
    final brand = cardBrandOf(agreed);
    if (!brand.usesLuhn || !luhnValid(agreed) || !brand.lengths.contains(agreed.length)) return null;
    return agreed;
  }

  String? _best<T>(Map<String, T> votes) {
    if (votes.isEmpty) return null;
    return votes.entries.reduce((a, b) => (a.value as num) >= (b.value as num) ? a : b).key;
  }

  ScannedCard _finish() {
    final review = <CardField>{};
    var number = _lockedNumber;
    if (number == null) {
      number = _best(_numbers) ?? _best(_localNumbers) ?? (_recentNumbers.isEmpty ? null : _recentNumbers.last);
      review.add(CardField.number);
    } else if (!cardBrandOf(number).usesLuhn) {
      review.add(CardField.number); // no check digit to vouch for it
    } else if (_numberByConsensus) {
      // Built from several partly differing frames: correct, but worth a glance.
      review.add(CardField.number);
    }
    var expiry = _lockedExpiry;
    if (expiry == null) {
      expiry = _best(_expiries);
      review.add(CardField.expiry);
    }
    var holder = _lockedHolder;
    if (holder == null) {
      holder = _best(_holders);
      review.add(CardField.holder);
    }
    final parts = expiry?.split(':');
    return ScannedCard(
      number: number,
      holder: holder,
      expiryMonth: parts == null ? null : int.parse(parts[0]),
      expiryYear: parts == null ? null : int.parse(parts[1]),
      review: review,
    );
  }

  ScanProgress _snapshot({required bool textSeen}) {
    FieldState state(bool locked, bool seen) => locked ? FieldState.locked : (seen ? FieldState.reading : FieldState.searching);
    final number = _lockedNumber ?? _best(_numbers) ?? _best(_localNumbers) ?? (_recentNumbers.isEmpty ? null : _recentNumbers.last);
    final expiry = _lockedExpiry ?? _best(_expiries);
    final parts = expiry?.split(':');
    return ScanProgress(
      number: number,
      numberState: state(_lockedNumber != null, number != null),
      holder: _lockedHolder ?? _best(_holders),
      holderState: state(_lockedHolder != null, _holders.isNotEmpty),
      expiryMonth: parts == null ? null : int.parse(parts[0]),
      expiryYear: parts == null ? null : int.parse(parts[1]),
      expiryState: state(_lockedExpiry != null, _expiries.isNotEmpty),
      result: _result,
      textSeen: textSeen,
    );
  }
}
