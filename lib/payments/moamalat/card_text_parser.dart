/// Reads the text an on-device OCR pass found on the FRONT of a bank card and
/// pulls out the number, the cardholder and the expiry.
///
/// Scanning is only an input convenience: whatever this returns is placed in the
/// Add Card form for the user to read, correct and confirm. It is deliberately
/// cautious:
///  * it never invents a digit - an OCR look-alike ("O" for "0") is only
///    swapped when the Luhn checksum then validates;
///  * a field it is not sure about is flagged in [ScannedCard.review] and left
///    editable, never silently trusted;
///  * the security code is never read: only the front is scanned and no field
///    for it exists here.
///
/// Pure Dart: no camera, no plugin, no storage - easy to test with plain text.
library;

enum CardField { number, holder, expiry }

class ScannedCard {
  const ScannedCard({
    this.number,
    this.holder,
    this.expiryMonth,
    this.expiryYear,
    this.review = const <CardField>{},
  });

  /// Digits only, 13-19 of them.
  final String? number;
  final String? holder;
  final int? expiryMonth;

  /// Four digits.
  final int? expiryYear;

  /// Fields the user must double-check before saving.
  final Set<CardField> review;

  static const ScannedCard empty = ScannedCard();

  bool get isEmpty => number == null && holder == null && expiryMonth == null;

  /// `MM/YY`, the form the Add Card field takes.
  String? get expiryText => (expiryMonth == null || expiryYear == null)
      ? null
      : '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear! % 100).toString().padLeft(2, '0')}';

  bool needsReview(CardField field) => review.contains(field);
}

bool luhnValid(String digits) {
  if (digits.isEmpty) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = digits.codeUnitAt(i) - 48;
    if (n < 0 || n > 9) return false;
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

/// Arabic-Indic and Persian digits -> Latin.
String _latinDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    out.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
  }
  return out.toString();
}

/// What an OCR engine commonly reads a digit as.
const Map<String, String> _lookalikes = {
  'O': '0', 'o': '0', 'D': '0', 'Q': '0',
  'I': '1', 'l': '1', '|': '1', 'i': '1',
  'Z': '2', 'z': '2',
  'S': '5', 's': '5',
  'B': '8',
  'G': '6',
};

bool _digitLike(String ch) => (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || _lookalikes.containsKey(ch);

String _fix(String token) => token.split('').map((c) => _lookalikes[c] ?? c).join();

const Set<String> _noiseWords = {
  'VISA', 'MASTERCARD', 'MASTER', 'CARD', 'DEBIT', 'CREDIT', 'PREPAID', 'BANK', 'VALID', 'THRU', 'THROUGH',
  'FROM', 'MEMBER', 'SINCE', 'GOOD', 'EXPIRES', 'EXPIRY', 'END', 'PLATINUM', 'GOLD', 'CLASSIC', 'INTERNATIONAL',
  'WORLD', 'ELECTRON', 'MAESTRO', 'CIRRUS', 'PLUS', 'CONTACTLESS', 'BUSINESS', 'SIGNATURE', 'INFINITE',
  'TITANIUM', 'LIBYA', 'LIBYAN', 'COMMERCIAL', 'NATIONAL', 'ISLAMIC', 'ARAB', 'AMERICAN', 'EXPRESS', 'CUSTOMER',
  'SERVICE', 'WWW', 'AUTHORIZED', 'ONLY', 'NOT', 'TRANSFERABLE', 'PAY', 'TAP', 'ELECTRONIC', 'USE', 'MONTH', 'YEAR',
  'DATE', 'ACCOUNT', 'NUMBER', 'PAYMENT', 'DEBITCARD', 'CREDITCARD', 'SAVINGS', 'CHECKING',
  'بنك', 'مصرف', 'بطاقة', 'فيزا', 'ماستر', 'كارد', 'صالحة', 'حتى', 'الى', 'من', 'تاريخ', 'الانتهاء', 'رقم', 'الحساب',
};

/// Parses OCR [lines] (in reading order) from the front of a card.
ScannedCard parseCardText(List<String> lines, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final cleaned = lines.map((l) => _latinDigits(l).trim()).where((l) => l.isNotEmpty).toList();
  if (cleaned.isEmpty) return ScannedCard.empty;

  final review = <CardField>{};

  final numberResult = _findNumber(cleaned);
  if (numberResult.number == null) {
    review.add(CardField.number);
  } else if (numberResult.needsReview) {
    review.add(CardField.number);
  }

  final expiry = _findExpiry(cleaned, today);
  if (expiry == null) {
    review.add(CardField.expiry);
  } else if (expiry.needsReview) {
    review.add(CardField.expiry);
  }

  final holder = _findHolder(cleaned, numberResult.lineIndex);
  if (holder.name == null || holder.ambiguous) review.add(CardField.holder);

  return ScannedCard(
    number: numberResult.number,
    holder: holder.name,
    expiryMonth: expiry?.month,
    expiryYear: expiry?.year,
    review: review,
  );
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
  final int score; // 3 exact + Luhn, 2 OCR-corrected + Luhn, 1 plausible length only
  final int line;
}

_NumberHit _findNumber(List<String> lines) {
  // Digit-like tokens with the line they sit on, in reading order.
  final tokens = <MapEntry<int, String>>[];
  for (var i = 0; i < lines.length; i++) {
    for (final raw in lines[i].split(RegExp(r'[\s\-]+'))) {
      if (raw.isEmpty) continue;
      if (raw.length <= 6 && raw.split('').every(_digitLike) && raw.split('').any((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
        tokens.add(MapEntry(i, raw));
      } else if (raw.length > 6 && raw.length <= 23 && raw.split('').every(_digitLike)) {
        tokens.add(MapEntry(i, raw)); // an unbroken run
      } else {
        tokens.add(MapEntry(i, '')); // a separator: breaks a run
      }
    }
  }

  final candidates = <_Candidate>[];
  var run = <MapEntry<int, String>>[];
  void flush() {
    if (run.isEmpty) return;
    // Every window of adjacent tokens is a possible number (a run may hold a
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
    // Prefer the usual 16 digits, then the longer one.
    final aSixteen = a.digits.length == 16 ? 1 : 0;
    final bSixteen = b.digits.length == 16 ? 1 : 0;
    if (aSixteen != bSixteen) return bSixteen.compareTo(aSixteen);
    return b.digits.length.compareTo(a.digits.length);
  });
  final best = candidates.first;
  final rivals = candidates.where((c) => c.score == best.score && c.digits != best.digits && !best.digits.contains(c.digits) && !c.digits.contains(best.digits));
  final ambiguous = rivals.isNotEmpty;
  return _NumberHit(best.digits, best.score < 3 || ambiguous, best.line);
}

void _addCandidate(List<_Candidate> out, String raw, int line) {
  final exact = raw.split('').every((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57);
  final fixed = _fix(raw);
  if (fixed.length < 13 || fixed.length > 19) return;
  if (exact && luhnValid(raw)) {
    out.add(_Candidate(raw, 3, line));
  } else if (!exact && luhnValid(fixed)) {
    out.add(_Candidate(fixed, 2, line)); // the checksum arbitrates the look-alikes
  } else if (exact && (fixed.length == 15 || fixed.length == 16)) {
    // Local cards need not pass Luhn: offer it, but the user must verify.
    out.add(_Candidate(raw, 1, line));
  }
}

// ---- expiry -------------------------------------------------------------------

class _Expiry {
  const _Expiry(this.month, this.year, this.needsReview);
  final int month;
  final int year;
  final bool needsReview;
}

_Expiry? _findExpiry(List<String> lines, DateTime today) {
  final pattern = RegExp(r'(?<![\d])(0?[1-9]|1[0-2])\s*[/\-.]\s*(\d{4}|\d{2})(?![\d])');
  final found = <_Expiry>[];
  for (final line in lines) {
    // A card number is not a date: skip any line that is mostly digits.
    if (RegExp(r'\d').allMatches(line).length >= 13) continue;
    for (final match in pattern.allMatches(line)) {
      final month = int.parse(match.group(1)!);
      var year = int.parse(match.group(2)!);
      if (match.group(2)!.length == 2) year += 2000;
      if (year < today.year - 12 || year > today.year + 20) continue;
      found.add(_Expiry(month, year, false));
    }
  }
  if (found.isEmpty) return null;
  // "VALID FROM 01/22  VALID THRU 01/27": the expiry is the latest date.
  found.sort((a, b) => (a.year * 12 + a.month).compareTo(b.year * 12 + b.month));
  final latest = found.last;
  final past = latest.year < today.year || (latest.year == today.year && latest.month < today.month);
  return _Expiry(latest.month, latest.year, past);
}

// ---- holder -------------------------------------------------------------------

class _Holder {
  const _Holder(this.name, this.ambiguous);
  final String? name;
  final bool ambiguous;
}

_Holder _findHolder(List<String> lines, int numberLine) {
  final candidates = <MapEntry<int, String>>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.length < 4 || line.length > 28) continue;
    if (RegExp(r'\d').hasMatch(line)) continue;
    if (!RegExp(r'^[A-Za-z؀-ۿ .\-]+$').hasMatch(line)) continue;
    final words = line.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2) continue;
    if (words.any((w) => _noiseWords.contains(w.toUpperCase()) || _noiseWords.contains(w))) continue;
    // A name needs at least two real words; a single-letter initial is fine.
    if (words.where((w) => w.replaceAll(RegExp(r'[^A-Za-z\u0600-\u06FF]'), '').length >= 2).length < 2) continue;
    candidates.add(MapEntry(i, line));
  }
  if (candidates.isEmpty) return const _Holder(null, false);
  // The name is printed below the number, so prefer the first candidate after it.
  final after = numberLine >= 0 ? candidates.where((c) => c.key > numberLine).toList() : <MapEntry<int, String>>[];
  final pool = after.isNotEmpty ? after : candidates;
  return _Holder(pool.first.value, pool.length > 1);
}
