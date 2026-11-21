/// Reads the text an on-device OCR pass found on the FRONT of a bank card and
/// pulls out the number, the cardholder and the expiry.
///
/// Scanning is an input convenience only: whatever this returns lands in the
/// Add Card form for the customer to read, correct and confirm. (Shared with
/// the Otlop customer app's scanner, which proved it on real camera frames.) It is cautious
/// by design:
///  * it never invents a digit - an OCR look-alike ("O" for "0") is swapped
///    only when the Luhn checksum then validates;
///  * a field it is not sure about is flagged in [ScannedCard.review];
///  * the security code is never read: only the front is scanned and there is
///    no field for it.
///
/// Pure Dart (no camera, no plugin, no storage) so it is tested with plain text.
library;

import 'card_brand.dart';
import 'saved_card.dart';

enum CardField { number, holder, expiry }

class ScannedCard {
  const ScannedCard({this.number, this.holder, this.expiryMonth, this.expiryYear, this.review = const <CardField>{}, this.rawNumber});

  /// Digits only, 12-19 of them.
  final String? number;
  final String? holder;
  final int? expiryMonth;

  /// Four digits.
  final int? expiryYear;

  /// Fields the customer must double-check before saving.
  final Set<CardField> review;

  /// The most plausible digit run of this one frame even when its checksum
  /// fails (one misread digit). Never shown or saved: the scanner votes over
  /// many frames' raw runs to repair a digit that flickers.
  final String? rawNumber;

  static const ScannedCard empty = ScannedCard();

  bool get isEmpty => number == null && holder == null && expiryMonth == null;

  /// `MM/YY`, the form the Add Card field takes.
  String? get expiryText => (expiryMonth == null || expiryYear == null)
      ? null
      : '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear! % 100).toString().padLeft(2, '0')}';

  bool needsReview(CardField field) => review.contains(field);

  ScannedCard copyWith({Set<CardField>? review}) =>
      ScannedCard(number: number, holder: holder, expiryMonth: expiryMonth, expiryYear: expiryYear, review: review ?? this.review);
}

bool luhnValid(String digits) => CardRules.luhnValid(digits);

/// What an OCR engine commonly reads a digit as.
const Map<String, String> kDigitLookalikes = {
  'O': '0', 'o': '0', 'D': '0', 'Q': '0', 'U': '0',
  'I': '1', 'l': '1', '|': '1', 'i': '1', 'L': '1', '!': '1',
  'Z': '2', 'z': '2',
  'S': '5', 's': '5',
  'B': '8',
  'G': '6', 'b': '6',
  'T': '7',
  'g': '9', 'q': '9',
};

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 48 && c <= 57;
}

bool _digitLike(String ch) => _isDigit(ch) || kDigitLookalikes.containsKey(ch);

String _fix(String token) => token.split('').map((c) => kDigitLookalikes[c] ?? c).join();

/// Words printed on cards that are never part of the holder's name.
const Set<String> kCardNoiseWords = {
  'VISA', 'MASTERCARD', 'MASTER', 'CARD', 'DEBIT', 'CREDIT', 'PREPAID', 'BANK', 'VALID', 'THRU', 'THROUGH', 'FROM',
  'MEMBER', 'SINCE', 'GOOD', 'EXPIRES', 'EXPIRY', 'EXP', 'END', 'PLATINUM', 'GOLD', 'CLASSIC', 'STANDARD', 'INTERNATIONAL',
  'WORLD', 'ELITE', 'ELECTRON', 'MAESTRO', 'CIRRUS', 'PLUS', 'CONTACTLESS', 'BUSINESS', 'CORPORATE', 'SIGNATURE', 'INFINITE',
  'TITANIUM', 'PREMIUM', 'REWARDS', 'LIBYA', 'LIBYAN', 'COMMERCIAL', 'NATIONAL', 'ISLAMIC', 'ARAB', 'AMERICAN', 'EXPRESS',
  'CUSTOMER', 'SERVICE', 'WWW', 'COM', 'LY', 'AUTHORIZED', 'ONLY', 'NOT', 'TRANSFERABLE', 'PAY', 'TAP', 'ELECTRONIC', 'USE',
  'MONTH', 'YEAR', 'DATE', 'ACCOUNT', 'NUMBER', 'PAYMENT', 'DEBITCARD', 'CREDITCARD', 'SAVINGS', 'CHECKING', 'UNIONPAY',
  'MOAMALAT', 'NUMO', 'LYPAY', 'TADAWUL', 'SADAD', 'EDFALI', 'MOBICASH', 'JUMHOURIA', 'JUMHOURIYA', 'SAHARA', 'WAHDA',
  'TADAMON', 'AMAN', 'YAQEEN', 'ATIB', 'NORTH', 'AFRICA', 'MEDITERRANEAN', 'ALWAHDA', 'ALJUMHOURIA', 'ALSAHARA', 'NAB', 'LIB',
  'COMMERCE', 'DEVELOPMENT', 'UNITED', 'FIRST', 'GULF', 'ALAMAN', 'ANDALUS', 'BRANCH', 'CHIP', 'VIRTUAL', 'GIFT', 'TRAVEL',
  'MEEZA', 'MISR', 'BANQUE', 'EGYPT', 'EGYPTIAN', 'CIB', 'NBE', 'QNB', 'AHLY', 'ALAHLY', 'TAXISTA',
  'بنك', 'مصرف', 'بطاقة', 'فيزا', 'ماستر', 'كارد', 'صالحة', 'حتى', 'الى', 'إلى', 'من', 'تاريخ', 'الانتهاء', 'رقم', 'الحساب',
  'مسبقة', 'الدفع', 'الجمهورية', 'الصحاري', 'الوحدة', 'التجارة', 'والتنمية', 'الأمان', 'معاملات', 'تداول', 'سداد',
  'نومو', 'ميزة', 'مصر', 'الأهلي', 'الاهلي',
};

/// Words that mark the expiry date on the card.
final RegExp _expiryKeyword = RegExp(r'(VALID|THRU|THROUGH|EXP|EXPIRY|EXPIRES|GOOD|END|UNTIL|انتهاء|الانتهاء|صالحة|حتى)', caseSensitive: false);

/// Words that mark a start date ("VALID FROM 01/22", "MEMBER SINCE 19").
final RegExp _startKeyword = RegExp(r'(FROM|SINCE|ISSUE|إصدار|اصدار|منذ)', caseSensitive: false);

/// Parses OCR [rows] (reading order) from the front of a card. [alternativeRows]
/// are the engine's second guesses for the same text; they are consulted for
/// the number only when the main reading has no checksum-valid candidate.
ScannedCard parseCardText(List<String> rows, {List<String> alternativeRows = const [], DateTime? now}) {
  final today = now ?? DateTime.now();
  final cleaned = rows.map((l) => normalizeDigits(l).trim()).where((l) => l.isNotEmpty).toList();
  if (cleaned.isEmpty) return ScannedCard.empty;

  final review = <CardField>{};

  var numberResult = _findNumber(cleaned);
  if ((numberResult.number == null || numberResult.needsReview) && alternativeRows.isNotEmpty) {
    final alts = alternativeRows.map((l) => normalizeDigits(l).trim()).where((l) => l.isNotEmpty).toList();
    final fromAlts = _findNumber(alts);
    if (fromAlts.number != null && !fromAlts.needsReview) numberResult = _NumberHit(fromAlts.number, false, -1);
  }
  if (numberResult.number == null || numberResult.needsReview) review.add(CardField.number);

  final expiry = _findExpiry(cleaned, today);
  if (expiry == null || expiry.needsReview) review.add(CardField.expiry);

  final raw = _plausibleRun(cleaned);
  final holder = _findHolder(cleaned, numberResult.lineIndex);
  if (holder.name == null || holder.ambiguous) review.add(CardField.holder);

  return ScannedCard(
    number: numberResult.number,
    holder: holder.name,
    expiryMonth: expiry?.month,
    expiryYear: expiry?.year,
    review: review,
    rawNumber: numberResult.number ?? raw,
  );
}

/// The longest digit run of a card-number length on one row, look-alikes fixed.
String? _plausibleRun(List<String> lines) {
  String? best;
  for (final line in lines) {
    final compact = line.replaceAll(RegExp(r'[\s\-–—]'), '');
    for (final m in RegExp(r'[0-9OoDQIl|iZzSsBG]{13,19}').allMatches(compact)) {
      final fixed = _fix(m.group(0)!);
      if (!RegExp(r'^\d+$').hasMatch(fixed)) continue;
      if (fixed.split('').where(_isDigit).length < 12) continue;
      final fits = cardBrandOf(fixed).lengths.contains(fixed.length);
      if (best == null || (fits && !cardBrandOf(best).lengths.contains(best.length)) || (fixed.length == 16 && best.length != 16)) best = fixed;
    }
  }
  return best;
}

// ---- number -------------------------------------------------------------------

class _NumberHit {
  const _NumberHit(this.number, this.needsReview, this.lineIndex);
  final String? number;
  final bool needsReview;
  final int lineIndex;
}

class _Candidate {
  _Candidate(this.digits, this.score, this.line);
  final String digits;

  /// 3 exact + Luhn, 2 OCR-corrected + Luhn, 1 plausible local card (no Luhn).
  final int score;
  final int line;
}

_NumberHit _findNumber(List<String> lines) {
  // Digit-like tokens with the line they sit on, in reading order.
  final tokens = <MapEntry<int, String>>[];
  for (var i = 0; i < lines.length; i++) {
    for (final raw in lines[i].split(RegExp(r'[\s\-–—]+'))) {
      if (raw.isEmpty) continue;
      final chars = raw.split('');
      final digitCount = chars.where(_isDigit).length;
      if (raw.length <= 6 && chars.every(_digitLike) && digitCount > 0) {
        tokens.add(MapEntry(i, raw));
      } else if (raw.length > 6 && raw.length <= 23 && chars.every(_digitLike) && digitCount >= raw.length - 3) {
        tokens.add(MapEntry(i, raw)); // an unbroken run
      } else {
        tokens.add(MapEntry(i, '')); // a separator: breaks a run
      }
    }
    // Never assemble a number from text on different OCR rows: groups from one
    // visual row are already joined by the row builder.
    tokens.add(MapEntry(i, ''));
  }

  final candidates = <_Candidate>[];
  var run = <MapEntry<int, String>>[];
  void flush() {
    if (run.isEmpty) return;
    // Every window of adjacent tokens is a possible number (a row may hold a
    // date or a bank code beside the number).
    for (var start = 0; start < run.length; start++) {
      final buffer = StringBuffer();
      for (var end = start; end < run.length; end++) {
        buffer.write(run[end].value);
        final raw = buffer.toString();
        if (raw.length > 23) break;
        _addCandidate(candidates, raw, run[start].key);
      }
    }
    run = <MapEntry<int, String>>[];
  }

  for (final token in tokens) {
    if (token.value.isEmpty) {
      flush();
    } else {
      run.add(token);
    }
  }
  flush();

  if (candidates.isEmpty) return const _NumberHit(null, true, -1);

  candidates.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    // Prefer a length the brand really uses, then the usual 16, then the longer.
    final aFit = cardBrandOf(a.digits).lengths.contains(a.digits.length) ? 1 : 0;
    final bFit = cardBrandOf(b.digits).lengths.contains(b.digits.length) ? 1 : 0;
    if (aFit != bFit) return bFit.compareTo(aFit);
    final aSixteen = a.digits.length == 16 ? 1 : 0;
    final bSixteen = b.digits.length == 16 ? 1 : 0;
    if (aSixteen != bSixteen) return bSixteen.compareTo(aSixteen);
    return b.digits.length.compareTo(a.digits.length);
  });
  final best = candidates.first;
  final rivals = candidates.where((c) =>
      c.score == best.score && c.digits != best.digits && !best.digits.contains(c.digits) && !c.digits.contains(best.digits));
  return _NumberHit(best.digits, best.score < 3 || rivals.isNotEmpty, best.line);
}

void _addCandidate(List<_Candidate> out, String raw, int line) {
  final exact = raw.split('').every(_isDigit);
  final fixed = _fix(raw);
  if (fixed.length < 12 || fixed.length > 19) return;
  if (!fixed.split('').every(_isDigit)) return;
  final brand = cardBrandOf(fixed);
  if (!brand.usesLuhn) {
    // A local card need not pass Luhn - and a short window that happens to pass
    // it proves nothing. Offer full-length runs only, for the customer to verify.
    if (exact && (fixed.length == 16 || fixed.length == 15 || fixed.length == 19)) out.add(_Candidate(raw, 1, line));
    return;
  }
  if (exact && luhnValid(raw) && brand.lengths.contains(raw.length)) {
    out.add(_Candidate(raw, 3, line));
  } else if (!exact && luhnValid(fixed) && brand.lengths.contains(fixed.length)) {
    out.add(_Candidate(fixed, 2, line)); // the checksum arbitrates the look-alikes
  }
}

// ---- expiry -------------------------------------------------------------------

class _Expiry {
  const _Expiry(this.month, this.year, this.needsReview, this.weight);
  final int month;
  final int year;
  final bool needsReview;

  /// 2 next to an expiry word, 1 plain, 0 next to a start-date word.
  final int weight;
}

final RegExp _datePattern = RegExp(r'(?<![0-9A-Za-z])([0-9OoIlSB]{1,2})\s*[/\\\-.]\s*([0-9OoIlSBZ]{4}|[0-9OoIlSBZ]{2})(?![0-9])');

_Expiry? _findExpiry(List<String> lines, DateTime today) {
  final found = <_Expiry>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // A card number is not a date: skip any line that is mostly digits.
    if (RegExp(r'\d').allMatches(line).length >= 12) continue;
    final previous = i > 0 ? lines[i - 1] : '';
    for (final match in _datePattern.allMatches(line)) {
      final m = _fix(match.group(1)!);
      final y = _fix(match.group(2)!);
      // A look-alike is accepted only around a real separator, never in a bare run.
      if (!RegExp(r'^\d+$').hasMatch(m) || !RegExp(r'^\d+$').hasMatch(y)) continue;
      final month = int.parse(m);
      if (month < 1 || month > 12) continue;
      var year = int.parse(y);
      if (y.length == 2) year += 2000;
      if (year < today.year - 12 || year > today.year + 20) continue;
      final before = line.substring(0, match.start);
      var weight = 1;
      if (_expiryKeyword.hasMatch(before) || (before.trim().isEmpty && _expiryKeyword.hasMatch(previous))) weight = 2;
      if (_startKeyword.hasMatch(before) && !_expiryKeyword.hasMatch(before.split(_startKeyword).last)) weight = 0;
      found.add(_Expiry(month, year, false, weight));
    }
  }
  if (found.isEmpty) return null;
  // "VALID FROM 01/22  VALID THRU 01/27": prefer the expiry word, then the latest date.
  found.sort((a, b) {
    final byWeight = a.weight.compareTo(b.weight);
    if (byWeight != 0) return byWeight;
    return (a.year * 12 + a.month).compareTo(b.year * 12 + b.month);
  });
  final best = found.last;
  final past = CardRules.isExpired(best.month, best.year, now: today);
  final rivals = found.where((e) => e.weight == best.weight && (e.month != best.month || e.year != best.year)).length;
  return _Expiry(best.month, best.year, past || (best.weight < 2 && rivals > 0), best.weight);
}

// ---- holder -------------------------------------------------------------------

class _Holder {
  const _Holder(this.name, this.ambiguous);
  final String? name;
  final bool ambiguous;
}

_Holder _findHolder(List<String> lines, int numberLine) {
  final candidates = <({int line, String name, int score})>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.length < 4 || line.length > 30) continue;
    if (RegExp(r'\d').hasMatch(line)) continue;
    if (!RegExp(r"^[A-Za-z؀-ۿ .'\-]+$").hasMatch(line)) continue;
    if (_expiryKeyword.hasMatch(line) && line.split(' ').length <= 3) continue;
    final words = line.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2 || words.length > 5) continue;
    if (words.any((w) => kCardNoiseWords.contains(w.toUpperCase()) || kCardNoiseWords.contains(w))) continue;
    // A name needs at least two real words; a one-letter initial is fine.
    if (words.where((w) => w.replaceAll(RegExp(r'[^A-Za-z؀-ۿ]'), '').length >= 2).length < 2) continue;
    var score = 1;
    // Embossed names are printed in capitals.
    if (line == line.toUpperCase() && RegExp(r'[A-Z]').hasMatch(line)) score += 2;
    if (numberLine >= 0 && i > numberLine) score += 1;
    candidates.add((line: i, name: line.toUpperCase() == line ? line : line, score: score));
  }
  if (candidates.isEmpty) return const _Holder(null, false);
  candidates.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    // The name is printed below the number: the first candidate after it.
    return a.line.compareTo(b.line);
  });
  final best = candidates.first;
  final rivals = candidates.where((c) => c.score == best.score && c.name != best.name).length;
  return _Holder(best.name, rivals > 0);
}
