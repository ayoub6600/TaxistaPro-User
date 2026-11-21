// The live card scanner's pure parts: parser, row builder, multi-frame voting,
// brands, and a real Apple Vision frame. Shared with the Otlop customer app's
// scanner (test cases ported from there, plus Numo / Meeza).
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/payments/moamalat/card_brand.dart';
import 'package:taxista/payments/moamalat/card_ocr.dart';
import 'package:taxista/payments/moamalat/card_scan_session.dart';
import 'package:taxista/payments/moamalat/card_text_parser.dart';
import 'package:taxista/payments/moamalat/saved_card.dart';

final _now = DateTime(2026, 11, 21);

void main() {
  visionFixture();
  group('parseCardText', () {
    test('reads a typical Visa front', () {
      final card = parseCardText([
        'BANK OF COMMERCE',
        '4111 1111 1111 1111',
        'VALID THRU 08/29',
        'AHMED ALI SALEM',
        'VISA',
      ], now: _now);
      expect(card.number, '4111111111111111');
      expect(card.expiryText, '08/29');
      expect(card.holder, 'AHMED ALI SALEM');
      expect(card.review, isEmpty);
    });

    test('fixes look-alike letters only when the checksum agrees', () {
      final card = parseCardText(['4111 1111 1111 111l', 'O8/29', 'SARA OMAR'], now: _now);
      expect(card.number, '4111111111111111');
      expect(card.needsReview(CardField.number), isTrue, reason: 'corrected readings are flagged');
      expect(card.expiryText, '08/29');
    });

    test('never assembles a number from two different rows', () {
      final card = parseCardText(['4111 1111', '1111 1111'], now: _now);
      expect(card.number, isNull);
    });

    test('prefers the expiry over the start date', () {
      final card = parseCardText(['5555 5555 5555 4444', 'VALID FROM 01/24  VALID THRU 01/28', 'MONA KHALED'], now: _now);
      expect(card.expiryText, '01/28');
      expect(card.number, '5555555555554444');
    });

    test('Arabic-Indic digits', () {
      final card = parseCardText(['٤١١١ ١١١١ ١١١١ ١١١١', '٠٨/٢٩', 'ALI HASSAN'], now: _now);
      expect(card.number, '4111111111111111');
      expect(card.expiryText, '08/29');
    });

    test('bank and network words are never the holder', () {
      final card = parseCardText(['JUMHOURIA BANK', '4111 1111 1111 1111', 'DEBIT CARD', '12/30', 'KHALIL IBRAHIM MANSOUR'], now: _now);
      expect(card.holder, 'KHALIL IBRAHIM MANSOUR');
    });

    test('an expired date is flagged', () {
      final card = parseCardText(['4111 1111 1111 1111', '08/24', 'ALI HASSAN'], now: _now);
      expect(card.needsReview(CardField.expiry), isTrue);
    });

    test('a local card without a check digit is offered but flagged', () {
      final card = parseCardText(['6900 1234 5678 9012', '10/28', 'OMAR SAEED'], now: _now);
      expect(card.number, '6900123456789012');
      expect(card.needsReview(CardField.number), isTrue);
    });

    test('alternative readings rescue the number', () {
      final card = parseCardText(['4111 1111 1111 1112', 'ALI HASSAN'], alternativeRows: ['4111 1111 1111 1111'], now: _now);
      expect(card.number, '4111111111111111');
    });

    test('Amex length and grouping', () {
      final card = parseCardText(['3782 822463 10005', '07/30', 'JOHN SMITH'], now: _now);
      expect(card.number, '378282246310005');
      expect(groupCardNumber('378282246310005'), '3782 822463 10005');
      expect(cardBrandOf('378282246310005'), CardBrand.amex);
    });
  });

  group('cardReadingRows', () {
    test('joins number groups on one row and ignores text outside the card frame', () {
      const roi = Rect.fromLTWH(0.06, 0.3, 0.88, 0.35);
      final rows = cardReadingRows([
        const OcrLine(text: '4111', box: Rect.fromLTWH(0.10, 0.45, 0.15, 0.04)),
        const OcrLine(text: '1111', box: Rect.fromLTWH(0.30, 0.452, 0.15, 0.04)),
        const OcrLine(text: '1111', box: Rect.fromLTWH(0.50, 0.449, 0.15, 0.04)),
        const OcrLine(text: '1111', box: Rect.fromLTWH(0.70, 0.451, 0.15, 0.04)),
        const OcrLine(text: '9999 9999 9999 9995', box: Rect.fromLTWH(0.1, 0.9, 0.8, 0.04)), // outside
      ], roi: roi);
      expect(rows.rows.first, '4111 1111 1111 1111');
      expect(rows.rows.any((r) => r.contains('9999')), isFalse);
    });
  });

  group('CardScanSession', () {
    late DateTime t;
    CardScanSession session() {
      t = DateTime(2026, 11, 21, 10);
      return CardScanSession(clock: () => t);
    }

    const full = ScannedCard(number: '4111111111111111', holder: 'ALI HASSAN', expiryMonth: 8, expiryYear: 2029);

    test('locks after two identical clean frames', () {
      final s = session();
      expect(s.observe(full).done, isFalse);
      final p = s.observe(full);
      expect(p.done, isTrue);
      expect(p.result!.number, '4111111111111111');
      expect(p.result!.review, isEmpty);
    });

    test('a card without a printed name finishes shortly after number and expiry', () {
      final s = session();
      const noName = ScannedCard(number: '4111111111111111', expiryMonth: 8, expiryYear: 2029);
      s.observe(noName);
      s.observe(noName);
      expect(s.progress.done, isFalse);
      t = t.add(const Duration(milliseconds: 1500));
      final p = s.observe(noName);
      expect(p.done, isTrue);
      expect(p.result!.holder, isNull);
      expect(p.result!.needsReview(CardField.holder), isTrue);
    });

    test('per-position voting repairs one flickering digit', () {
      final s = session();
      // Each frame misreads a different digit, so its checksum fails and no
      // frame alone is accepted - but every position agrees across frames.
      const frames = ['4121111111111111', '4111111311111111', '4111111111411111', '4111111111111191'];
      var p = s.progress;
      for (final n in frames) {
        expect(parseCardText([groupCardNumber(n)], now: _now).rawNumber, n);
        p = s.observe(ScannedCard(rawNumber: n));
      }
      expect(p.number, '4111111111111111');
      expect(p.numberState, FieldState.locked);
    });

    test('a wrong but checksum-valid flicker never wins on its own', () {
      final s = session();
      s.observe(const ScannedCard(number: '4111111111111111'));
      s.observe(const ScannedCard(number: '4012888888881881'));
      expect(s.progress.numberState, isNot(FieldState.locked));
    });

    test('finishNow hands over the best guesses for review', () {
      final s = session();
      s.observe(const ScannedCard(number: '4111111111111111', holder: 'ALI HASSAN'));
      final card = s.finishNow();
      expect(card.number, '4111111111111111');
      expect(card.review, containsAll([CardField.number, CardField.holder, CardField.expiry]));
    });
  });

  group('brands (Libya and Egypt included)', () {
    test('Visa, Mastercard (both series), Amex, Numo, Meeza, other local', () {
      expect(cardBrandOf('4111111111111111'), CardBrand.visa);
      expect(cardBrandOf('5555555555554444'), CardBrand.mastercard);
      expect(cardBrandOf('2223003122003222'), CardBrand.mastercard);
      expect(cardBrandOf('378282246310005'), CardBrand.amex);
      expect(cardBrandOf('6390001234561234'), CardBrand.numo);
      expect(cardBrandOf('8000123456789012'), CardBrand.numo);
      expect(cardBrandOf('5078031234567890'), CardBrand.meeza);
      expect(cardBrandOf('6273001234561234'), CardBrand.local);
    });

    test('a Numo card has no CVV; every other card types it on the bank page', () {
      expect(CardBrand.numo.hasCvv, isFalse);
      for (final b in CardBrand.values.where((b) => b != CardBrand.numo)) {
        expect(b.hasCvv, isTrue, reason: '$b');
      }
    });

    test('Numo and Meeza are never rejected by a checksum that may not apply to them', () {
      expect(CardRules.isNumberValid('6390 0012 3456 1234'), isTrue);
      expect(CardRules.isNumberValid('8000 1234 5678 9012'), isTrue);
      expect(CardRules.isNumberValid('5078 0312 3456 7890'), isTrue);
      expect(CardRules.isNumberValid('5555 5555 5555 4440'), isFalse, reason: 'Mastercard still needs Luhn');
    });

    test('a Numo card read by the camera is offered, flagged, and needs more agreeing frames', () {
      final card = parseCardText(['NUMO', '6390 0012 3456 1234', '01/30', 'MOHAMED ALI'], now: _now);
      expect(card.number, '6390001234561234');
      expect(card.needsReview(CardField.number), isTrue);
      expect(card.holder, 'MOHAMED ALI', reason: 'the network word is not part of the name');
      var t = DateTime(2026, 11, 21, 10);
      final s = CardScanSession(clock: () => t);
      for (var i = 0; i < 3; i++) {
        expect(s.observe(card).numberState, isNot(FieldState.locked));
      }
      final p = s.observe(card);
      expect(p.numberState, FieldState.locked);
      t = t.add(const Duration(seconds: 3));
      expect(s.observe(card).result!.needsReview(CardField.number), isTrue, reason: 'no check digit to vouch for it');
    });

    test('grouping: 4-4-4-4, Amex 4-6-5, long local cards keep every digit', () {
      expect(groupCardNumber('6390001234561234'), '6390 0012 3456 1234');
      expect(groupCardNumber('6390001234561234567'), '6390 0012 3456 1234 567');
      expect(CardRules.groupNumber('٤١١١١١١١١١١١١١١١'), '4111 1111 1111 1111');
    });
  });

  group('CardRules', () {
    test('validates international numbers strictly and local ones by length', () {
      expect(CardRules.isNumberValid('4111 1111 1111 1111'), isTrue);
      expect(CardRules.isNumberValid('4111 1111 1111 1112'), isFalse);
      expect(CardRules.isNumberValid('6900 1234 5678 9012'), isTrue);
    });

    test('redacted copies keep the brand and the last four digits only', () {
      const card = SavedCard(id: 'a', holderName: 'X Y', number: '5555555555554444', expMonth: 1, expYear: 2030);
      final r = card.redacted();
      expect(r.number.contains('5555'), isFalse);
      expect(r.last4, '4444');
      expect(r.brand, CardBrand.mastercard);
    });
  });
}

// A real Apple Vision result (macOS, same request as AppDelegate.swift) for a
// synthetic card in a rotated 1280x720 camera frame, with a decoy number
// printed outside the card frame.
void visionFixture() {
  test('Apple Vision frame -> rows -> parser -> scan session', () {
    final raw = jsonDecode(File('test/fixtures/vision_visa_frame.json').readAsStringSync()) as List;
    final lines = raw.map(OcrLine.fromMap).whereType<OcrLine>().toList();
    const roi = Rect.fromLTWH(0.139, 0.212, 0.7215, 0.256);
    final rows = cardReadingRows(lines, roi: roi);
    final card = parseCardText(rows.rows, alternativeRows: rows.alternatives, now: _now);
    expect(card.number, '4111111111111111');
    expect(card.expiryText, '08/29');
    expect(card.holder, 'AHMED ALI SALEM');
    final session = CardScanSession();
    session.observe(card);
    expect(session.observe(card).result?.number, '4111111111111111');
  });
}
