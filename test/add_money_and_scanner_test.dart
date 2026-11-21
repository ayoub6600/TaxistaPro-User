import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/payments/moamalat/add_money_sheet.dart';
import 'package:taxista/payments/moamalat/card_ocr.dart';
import 'package:taxista/payments/moamalat/card_scan_session.dart';
import 'package:taxista/payments/moamalat/card_scanner.dart';
import 'package:taxista/payments/moamalat/card_scanner_page.dart';
import 'package:taxista/payments/moamalat/card_text_parser.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/moamalat_topup_page.dart';
import 'package:taxista/payments/moamalat/saved_cards_page.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';

/// A TEST card number (the well-known Visa test PAN) - never a real one.
const testPan = '4111111111111111';
final now = DateTime(2026, 9, 26);

class FakeApi implements MoamalatApi {
  List<PaymentMethodOption> methodList = const [
    PaymentMethodOption(key: 'qareeb_card', labelAr: 'كروت شحن قريب', labelEn: 'Qareeb recharge cards'),
    PaymentMethodOption(key: 'bank_card', labelAr: 'البطاقة البنكية', labelEn: 'Bank card'),
  ];
  bool failMethods = false;
  final List<double> initiated = [];

  @override
  Future<List<PaymentMethodOption>> methods() async {
    if (failMethods) throw const MoamalatException(MoamalatErrorKind.network);
    return methodList;
  }

  @override
  Future<MoamalatOptions> options() async => const MoamalatOptions(available: true, currency: 'LYD', minAmount: 5, maxAmount: 2000);

  @override
  Future<MoamalatTopUp> initiate(double amount) async {
    initiated.add(amount);
    return MoamalatTopUp(id: 'T', reference: 'R', amount: amount, currency: 'LYD', paymentUrl: 'https://pay.example');
  }

  @override
  Future<MoamalatStatus> status(String topUpId) async => const MoamalatStatus(status: 'pending', credited: false);
}

MoamalatEnv makeEnv(FakeApi api, {MemorySecretStore? store, bool rtl = true}) => MoamalatEnv(
      api: api,
      vault: CardVault(store: store ?? MemorySecretStore(), ownerId: '27'),
      clipboard: SecureClipboard(writer: (_) async {}),
      isRtl: rtl,
    );

/// Fakes for the scanner: no camera, no OCR engine.
class FakeSource implements CardImageSource {
  FakeSource(this.path, {this.denied = false});
  final String? path;
  final bool denied;
  int calls = 0;

  @override
  Future<String?> capture() async {
    calls++;
    if (denied) throw const CardCameraDenied();
    return path;
  }
}

/// The on-device recogniser, faked: each line on its own row, top to bottom.
class FakeRecognizer implements CardOcr {
  FakeRecognizer(this.lines, {this.fail = false});
  final List<String> lines;
  final bool fail;
  final List<String> files = [];

  @override
  Future<OcrFrame> recognizeFile(String path) async {
    files.add(path);
    if (fail) throw StateError('ocr crashed');
    return OcrFrame(lines: [
      for (var i = 0; i < lines.length; i++) OcrLine(text: lines[i], box: Rect.fromLTWH(0.1, 0.1 + i * 0.08, 0.6, 0.04)),
    ]);
  }

  @override
  Future<OcrFrame> recognizeFrame(OcrFrameInput input) async => OcrFrame.empty;
}

void main() {
  group('reading the text of a card', () {
    test('a clean card: number, expiry and cardholder, nothing flagged', () {
      final card = parseCardText(['VISA', 'DEBIT', testPan.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim(), 'VALID THRU 12/28', 'JOHN A SMITH'], now: now);
      expect(card.number, testPan);
      expect(card.expiryMonth, 12);
      expect(card.expiryYear, 2028);
      expect(card.expiryText, '12/28');
      expect(card.holder, 'JOHN A SMITH');
      expect(card.review, isEmpty);
    });

    test('the exact lines Apple Vision returned for a synthetic test card parse cleanly', () {
      // Captured from a real Vision run on a generated test image (test number, fictional name).
      final card = parseCardText(['NATIONAL COMMERCIAL BANK', '4111 1111 1111 1111', 'VALID THRU 12/28', 'TEST CARDHOLDER', 'VISA'], now: now);
      expect(card.number, testPan);
      expect(card.expiryText, '12/28');
      expect(card.holder, 'TEST CARDHOLDER');
      expect(card.review, isEmpty);
    });

    test('digit groups recognised separately on one row are joined; Arabic-Indic digits are read', () {
      final rows = cardReadingRows([
        for (var i = 0; i < 4; i++) OcrLine(text: '1111'.replaceRange(0, 1, i == 0 ? '4' : '1'), box: Rect.fromLTWH(0.1 + i * 0.2, 0.40 + (i.isEven ? 0.002 : 0), 0.15, 0.04)),
        const OcrLine(text: '12/28', box: Rect.fromLTWH(0.4, 0.5, 0.15, 0.03)),
        const OcrLine(text: 'ALI BEN OMAR', box: Rect.fromLTWH(0.1, 0.58, 0.4, 0.03)),
      ]);
      expect(parseCardText(rows.rows, now: now).number, testPan);
      // ... but text on different rows is never glued into a number.
      expect(parseCardText(['4111', '1111', '1111', '1111'], now: now).number, isNull);
      final arabic = parseCardText(['٤١١١ ١١١١ ١١١١ ١١١١', '١٢/٢٨', 'ALI BEN OMAR'], now: now);
      expect(arabic.number, testPan);
      expect(arabic.expiryText, '12/28');
    });

    test('MM/YY, MM/YYYY and MM-YY all read; the latest date is the expiry', () {
      expect(parseCardText([testPan, '09/2029'], now: now).expiryText, '09/29');
      expect(parseCardText([testPan, 'EXP 03-30'], now: now).expiryText, '03/30');
      final both = parseCardText(['VALID FROM 01/22', testPan, 'VALID THRU 01/29'], now: now);
      expect(both.expiryText, '01/29');
      expect(parseCardText(['MEMBER SINCE 05/19', testPan, '11/27'], now: now).expiryText, '11/27');
    });

    test('an impossible month is never accepted; an expired card is flagged', () {
      expect(parseCardText([testPan, '13/28'], now: now).expiryText, isNull);
      expect(parseCardText([testPan, '13/28'], now: now).needsReview(CardField.expiry), isTrue);
      final past = parseCardText([testPan, '08/26'], now: now);
      expect(past.expiryText, '08/26');
      expect(past.needsReview(CardField.expiry), isTrue, reason: 'the user is told to check an expired date');
      expect(parseCardText([testPan, '09/26'], now: now).needsReview(CardField.expiry), isFalse, reason: 'the current month is still valid');
    });

    test('an OCR look-alike is only corrected when the checksum then validates', () {
      final corrected = parseCardText(['4111 1111 1111 111l', '12/28'], now: now); // "l" read for "1"
      expect(corrected.number, testPan);
      expect(corrected.needsReview(CardField.number), isTrue, reason: 'a corrected reading is still shown for checking');

      // "O" for "0" would give 4111111111111110, which fails Luhn: NOT accepted, no digit is invented.
      final unresolved = parseCardText(['4111 1111 1111 111O', '12/28'], now: now);
      expect(unresolved.number, isNull);
      expect(unresolved.needsReview(CardField.number), isTrue);
    });

    test('a local card that does not pass Luhn is offered but flagged for checking', () {
      final card = parseCardText(['6273 0012 3456 1234', '01/30', 'MOHAMED ALI'], now: now);
      expect(card.number, '6273001234561234');
      expect(card.needsReview(CardField.number), isTrue);
    });

    test('a missing field is left empty and flagged - never guessed', () {
      final card = parseCardText(['VISA', testPan], now: now);
      expect(card.number, testPan);
      expect(card.holder, isNull);
      expect(card.expiryText, isNull);
      expect(card.review, containsAll(<CardField>[CardField.holder, CardField.expiry]));
      expect(parseCardText(const [], now: now).isEmpty, isTrue);
      expect(parseCardText(['hello world'], now: now).number, isNull);
    });

    test('brand and bank words are not mistaken for the cardholder; the name after the number wins', () {
      final card = parseCardText(['NATIONAL COMMERCIAL BANK', 'PLATINUM DEBIT CARD', testPan, '12/28', 'SALEM HUSSEIN'], now: now);
      expect(card.holder, 'SALEM HUSSEIN');
      expect(card.needsReview(CardField.holder), isFalse);
    });

    test('several name-like lines: the first one after the number, flagged', () {
      final card = parseCardText([testPan, '12/28', 'SALEM HUSSEIN', 'OMAR KHALIL'], now: now);
      expect(card.holder, 'SALEM HUSSEIN');
      expect(card.needsReview(CardField.holder), isTrue);
    });

    test('the security code is never read: a lone 3-digit number changes nothing', () {
      final card = parseCardText([testPan, '12/28', 'ALI OMAR', '123'], now: now);
      expect(card.number, testPan);
      expect(card.toString().contains('123'), isFalse);
      // the parser has no field for a CVV at all
      expect(ScannedCard.empty.review, isEmpty);
    });

    test('two different valid numbers on the card: the user is asked to check', () {
      final card = parseCardText([testPan, '5555 5555 5555 4444', '12/28'], now: now);
      expect(card.number, isNotNull);
      expect(card.needsReview(CardField.number), isTrue);
    });
  });

  group('the photo fallback keeps the photo private', () {
    test('success: the text is read on the device, the number is shown for checking, the photo is deleted', () async {
      final deleted = <String>[];
      final ocr = FakeRecognizer([testPan, '12/28', 'ALI BEN OMAR']);
      final scanner = CardScanner(
        source: FakeSource('/tmp/card.jpg'),
        ocr: ocr,
        clock: () => now,
        deleter: (p) async => deleted.add(p),
      );
      final outcome = await scanner.scan();
      expect(outcome.status, CardScanStatus.success);
      expect(outcome.card.number, testPan);
      expect(outcome.card.holder, 'ALI BEN OMAR');
      expect(outcome.card.needsReview(CardField.number), isTrue, reason: 'one photo is one reading');
      expect(ocr.files, ['/tmp/card.jpg']);
      expect(deleted, ['/tmp/card.jpg']);
    });

    test('an OCR crash, an unreadable photo and a failing delete never keep or expose the image', () async {
      final deleted = <String>[];
      final crashed = await CardScanner(
        source: FakeSource('/tmp/a.jpg'),
        ocr: FakeRecognizer(const [], fail: true),
        deleter: (p) async => deleted.add(p),
      ).scan();
      expect(crashed.status, CardScanStatus.failed);

      final blank = await CardScanner(
        source: FakeSource('/tmp/b.jpg'),
        ocr: FakeRecognizer(const ['   ']),
        deleter: (p) async => deleted.add(p),
      ).scan();
      expect(blank.status, CardScanStatus.unreadable);
      expect(deleted, ['/tmp/a.jpg', '/tmp/b.jpg']);

      final stubborn = await CardScanner(
        source: FakeSource('/tmp/c.jpg'),
        ocr: FakeRecognizer([testPan, '12/28']),
        clock: () => now,
        deleter: (p) async => throw const FileSystemException('locked'),
      ).scan();
      expect(stubborn.status, CardScanStatus.success, reason: 'a delete error never turns into a scan error');
    });

    test('cancelling takes no photo and deletes nothing; a refused camera is a clean outcome', () async {
      final deleted = <String>[];
      final cancelled = await CardScanner(source: FakeSource(null), ocr: FakeRecognizer(const []), deleter: (p) async => deleted.add(p)).scan();
      expect(cancelled.status, CardScanStatus.cancelled);
      final denied = await CardScanner(source: FakeSource(null, denied: true), ocr: FakeRecognizer(const []), deleter: (p) async => deleted.add(p)).scan();
      expect(denied.status, CardScanStatus.denied);
      expect(deleted, isEmpty);
    });

    test('the scanner code has no network, photo saving, analytics or logging of card data', () {
      String read(String name) => File('lib/payments/moamalat/$name').readAsStringSync();
      final files = {
        for (final f in ['card_scanner.dart', 'card_scanner_page.dart', 'card_ocr.dart', 'card_scan_session.dart', 'card_text_parser.dart']) f: read(f),
      };
      for (final entry in files.entries) {
        final code = entry.value.replaceAll(RegExp(r'///.*'), '').replaceAll(RegExp(r'//.*'), '');
        for (final banned in ['package:http', 'package:dio', 'HttpClient', 'upload', 'multipart', 'debugPrint', 'print(', 'log(', 'saveImage', 'ImageGallerySaver', 'gallery_saver', 'writeAsBytes', 'path_provider', 'analytics', 'Firebase', 'cvv', 'CVV']) {
          expect(code.contains(banned), isFalse, reason: '${entry.key} must not contain "$banned"');
        }
      }
      final photo = files['card_scanner.dart']!.replaceAll(RegExp(r'//.*'), '');
      expect('requestFullMetadata: false'.allMatches(photo).length, 2, reason: 'no photo-library permission is requested, for the camera or a picked photo');
      expect(photo.contains('ImageSource.camera'), isTrue, reason: 'the one-photo path stays as the fallback');
      expect(photo.contains('finally'), isTrue, reason: 'deletion is unconditional');
      expect(files['card_ocr.dart']!.contains("'taxista/card_ocr'"), isTrue, reason: 'recognition runs in the app, through the native channel');
      expect(files.values.any((c) => c.contains('google_mlkit')), isFalse, reason: 'no cloud-capable plugin, no heavy pods');
      expect(files['card_scanner_page.dart']!.contains('startImageStream'), isTrue, reason: 'live frames are read from memory');
      expect(files['card_scanner_page.dart']!.contains('takePicture'), isFalse, reason: 'the live scanner never writes a picture');
    });
  });

  group('on-device recognition channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('taxista/card_ocr');

    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('a photo path goes to the native side and the lines come back with their place on the card', () async {
      MethodCall? seen;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        seen = call;
        return {
          'lines': [
            {'text': '4111 1111 1111 1111', 'box': [0.1, 0.4, 0.6, 0.05], 'alts': <String>[], 'conf': 0.9},
            {'text': 'broken'},
            42,
          ],
        };
      });
      final frame = await const ChannelCardOcr().recognizeFile('/tmp/card.jpg');
      expect(seen!.method, 'recognizeFile');
      expect(seen!.arguments, {'path': '/tmp/card.jpg'});
      expect(frame.lines.map((l) => l.text), ['4111 1111 1111 1111'], reason: 'malformed entries are dropped');
      expect(frame.lines.single.box, const Rect.fromLTWH(0.1, 0.4, 0.6, 0.05));
    });

    test('a live frame is handed over in memory with its rotation and the card area', () async {
      MethodCall? seen;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        seen = call;
        return {'lines': <Object>[], 'luma': 120};
      });
      final frame = await const ChannelCardOcr().recognizeFrame(OcrFrameInput(
        bytes: Uint8List(16),
        width: 4,
        height: 1,
        bytesPerRow: 16,
        format: 'bgra8888',
        rotation: 90,
        roi: const Rect.fromLTWH(0.1, 0.2, 0.8, 0.3),
      ));
      expect(seen!.method, 'recognizeFrame');
      final args = seen!.arguments as Map;
      expect(args['rotation'], 90);
      expect(args['format'], 'bgra8888');
      expect(args['roi'], [0.1, 0.2, 0.8, 0.3]);
      expect(args.containsKey('path'), isFalse, reason: 'a live frame never touches the disk');
      expect(frame.luma, 120);
    });

    test('a native failure becomes a clean failed scan and the photo is still deleted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ocr_failed', message: 'Text recognition failed');
      });
      final deleted = <String>[];
      final outcome = await CardScanner(source: FakeSource('/tmp/z.jpg'), deleter: (p) async => deleted.add(p)).scan();
      expect(outcome.status, CardScanStatus.failed);
      expect(deleted, ['/tmp/z.jpg']);
    });

    test('iOS reads the card with Apple Vision and Android with the bundled ML Kit model - both on the device', () {
      final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(swift.contains('import Vision'), isTrue);
      expect(swift.contains('VNRecognizeTextRequest'), isTrue);
      expect(swift.contains('usesLanguageCorrection = false'), isTrue, reason: 'digits are never "corrected"');
      expect(swift.contains('regionOfInterest'), isTrue, reason: 'only the card frame is read');
      expect(swift.contains('"recognizeFrame"') && swift.contains('"recognizeFile"'), isTrue);
      expect(swift.contains('"recognize"'), isFalse, reason: 'one recognition path, not two');
      final ocr = swift.substring(swift.indexOf('final class CardOcr'), swift.indexOf('/// Smart Fill: puts one saved card'));
      expect(ocr.contains('URLSession'), isFalse, reason: 'the card is read on the device');
      expect(ocr.contains('write('), isFalse, reason: 'a frame is never written to disk');
      // the app delegate's only requests go to the signed link of a VoIP push ("this call is shown",
      // then "does it still ring" every 2 s)
      // the evening reminder's buttons (enum RecurringReminderButtons) post only the day's answer
      final reminder = swift.substring(swift.indexOf('enum RecurringReminderButtons'));
      expect(reminder.contains('api/v1/recurring-day/'), isTrue);
      expect('URLSession'.allMatches(reminder).length, 1);
      final rest = swift.substring(0, swift.indexOf('enum RecurringReminderButtons'));
      expect('URLSession'.allMatches(rest).length, 2);
      expect(RegExp(r'URLSession\.shared\.dataTask\(with: (url|link)\)').allMatches(rest).length, 2);
      expect(swift.contains('p["alerted_url"]'), isTrue);
      expect(swift.contains('taxista/card_ocr'), isTrue);

      final gradle = File('android/app/build.gradle').readAsStringSync();
      expect(gradle.contains('com.google.mlkit:text-recognition:'), isTrue, reason: 'the bundled model, not the Play-services download variant');
      expect(gradle.contains('play-services-mlkit'), isFalse);
      final kotlinFiles = Directory('android/app/src/main/kotlin').listSync(recursive: true).whereType<File>().toList();
      final cardOcr = kotlinFiles.firstWhere((f) => f.path.endsWith('CardOcr.kt')).readAsStringSync();
      expect(cardOcr.contains('taxista/card_ocr'), isTrue);
      expect(cardOcr.contains('"recognizeFrame"') && cardOcr.contains('"recognizeFile"'), isTrue);
      expect(cardOcr.contains('FileOutputStream') || cardOcr.contains('writeBytes'), isFalse);
      final main = kotlinFiles.firstWhere((f) => f.path.endsWith('MainActivity.kt')).readAsStringSync();
      expect(main.contains('CardOcr.register('), isTrue);
      expect(main.contains('TextRecognition'), isFalse, reason: 'one recognition path, not two');
    });
  });

  group('Add money', () {
    Future<void> openSheet(WidgetTester tester, MoamalatEnv env, {VoidCallback? onQareeb}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('add-money'),
              onPressed: () => showAddMoneySheet(context, env: env, onQareeb: onQareeb ?? () {}),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('add-money')));
      await tester.pumpAndSettle();
    }

    testWidgets('offers exactly the two methods, named for the customer', (tester) async {
      await openSheet(tester, makeEnv(FakeApi()));
      expect(find.text('إضافة فلوس'), findsOneWidget);
      expect(find.text('كروت الشحن'), findsOneWidget); // the customer sees no provider name
      expect(find.text('البطاقة البنكية'), findsOneWidget);
      expect(find.byKey(const Key('method-qareeb_card')), findsOneWidget);
      expect(find.byKey(const Key('method-bank_card')), findsOneWidget);
      expect(find.textContaining('معاملات'), findsNothing);
      expect(find.textContaining('Moamalat'), findsNothing);
      expect(find.textContaining('Maamalat'), findsNothing);
    });

    testWidgets('english labels', (tester) async {
      await openSheet(tester, makeEnv(FakeApi(), rtl: false));
      expect(find.text('Recharge cards'), findsOneWidget);
      expect(find.text('Bank card'), findsOneWidget);
    });

    testWidgets('Qareeb recharge cards still opens the existing code entry', (tester) async {
      var opened = 0;
      await openSheet(tester, makeEnv(FakeApi()), onQareeb: () => opened++);
      await tester.tap(find.byKey(const Key('method-qareeb_card')));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('Bank card opens the top-up flow, with saved cards listed first', (tester) async {
      final env = makeEnv(FakeApi());
      await env.vault.add(holderName: 'Ali', number: testPan, expMonth: 12, expYear: 2028);
      await openSheet(tester, env);
      await tester.tap(find.byKey(const Key('method-bank_card')));
      await tester.pumpAndSettle();
      expect(find.byType(MoamalatTopUpPage), findsOneWidget);
      expect(find.text('بطاقاتي'), findsOneWidget);
      expect(find.text('**** **** **** 1111'), findsOneWidget);
    });

    testWidgets('a market without the bank card sees only Qareeb (e.g. Qena)', (tester) async {
      final api = FakeApi()..methodList = const [PaymentMethodOption(key: 'qareeb_card', labelAr: 'كروت شحن قريب', labelEn: 'Qareeb recharge cards')];
      await openSheet(tester, makeEnv(api));
      expect(find.byKey(const Key('method-qareeb_card')), findsOneWidget);
      expect(find.byKey(const Key('method-bank_card')), findsNothing);
    });

    testWidgets('a market with nothing configured says so instead of showing a dead end', (tester) async {
      final api = FakeApi()..methodList = const [];
      await openSheet(tester, makeEnv(api));
      expect(find.byKey(const Key('no-methods')), findsOneWidget);
    });

    testWidgets('an unreachable server still leaves the manual recharge-card entry available', (tester) async {
      final api = FakeApi()..failMethods = true;
      await openSheet(tester, makeEnv(api));
      expect(find.byKey(const Key('method-qareeb_card')), findsOneWidget);
      expect(find.byKey(const Key('method-bank_card')), findsNothing);
    });
  });

  group('adding a card by scanning', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<(FakeApi, MemorySecretStore, List<int>)> pumpForm(WidgetTester tester, CardScanResult? result) async {
      final api = FakeApi();
      final store = MemorySecretStore();
      final env = makeEnv(api, store: store);
      final opened = <int>[];
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: CardFormPage(
          env: env,
          openScanner: (_) async {
            opened.add(1);
            return result;
          },
        ),
      ));
      return (api, store, opened);
    }

    Future<void> scan(WidgetTester tester, {bool explained = false}) async {
      await tester.tap(find.byKey(const Key('scan-card')));
      await tester.pumpAndSettle();
      if (!explained) {
        expect(find.byKey(const Key('scan-explainer')), findsOneWidget, reason: 'the customer is told what the camera is for first');
        await tester.tap(find.byKey(const Key('scan-continue')));
        await tester.pumpAndSettle();
      }
    }

    String field(WidgetTester tester, String key) => (tester.widget<TextField>(find.byKey(Key(key))).controller!).text;

    testWidgets('a doubtful scan fills the form and must be confirmed before it is saved', (tester) async {
      final (api, store, _) = await pumpForm(
          tester, const CardScanResult.scanned(ScannedCard(number: testPan, expiryMonth: 12, expiryYear: 2028, holder: 'ALI BEN OMAR', review: {CardField.holder})));
      await scan(tester);

      expect(field(tester, 'card-number'), '4111 1111 1111 1111');
      expect(field(tester, 'card-expiry'), '12/28');
      expect(field(tester, 'card-holder'), 'ALI BEN OMAR');
      expect(find.textContaining('تحقق من هذا الحقل'), findsOneWidget, reason: 'only the doubtful field is marked');

      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('save-error')), findsOneWidget, reason: 'a doubtful scan cannot be saved unchecked');
      expect(await CardVault(store: store, ownerId: '27').load(), isEmpty);

      await tester.tap(find.byKey(const Key('confirm-scan')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      final saved = await CardVault(store: store, ownerId: '27').load();
      expect(saved, hasLength(1));
      expect(saved.single.expMonth, 12);
      expect(api.initiated, isEmpty, reason: 'scanning or saving a card never starts a payment');
      expect(store.data.values.join().toLowerCase(), isNot(contains('cvv')));
    });

    testWidgets('a scan where number, expiry and name all agreed saves without an extra tick', (tester) async {
      final (_, store, _) = await pumpForm(
          tester, const CardScanResult.scanned(ScannedCard(number: testPan, expiryMonth: 12, expiryYear: 2028, holder: 'ALI BEN OMAR')));
      await scan(tester);
      expect(find.byKey(const Key('confirm-scan')), findsNothing);
      expect(find.text('انقرت البطاقة كاملة'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect((await CardVault(store: store, ownerId: '27').load()).single.holderName, 'ALI BEN OMAR');
    });

    testWidgets('the user can correct what was read before saving', (tester) async {
      final (_, store, _) = await pumpForm(
          tester, const CardScanResult.scanned(ScannedCard(number: testPan, expiryMonth: 12, expiryYear: 2028, holder: 'ALY BEN OMAR', review: {CardField.holder})));
      await scan(tester);
      await tester.enterText(find.byKey(const Key('card-holder')), 'ALI BEN OMAR');
      await tester.tap(find.byKey(const Key('confirm-scan')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect((await CardVault(store: store, ownerId: '27').load()).single.holderName, 'ALI BEN OMAR');
    });

    testWidgets('a Numo card: no CVV note, a doubtful number is marked, missing fields are left for the user', (tester) async {
      await pumpForm(tester, const CardScanResult.scanned(ScannedCard(number: '6390001234561234', expiryMonth: 1, expiryYear: 2030, review: {CardField.number})));
      await scan(tester);
      expect(find.textContaining('تحقق من هذا الحقل'), findsNWidgets(2), reason: 'the number (no check digit) and the missing name');
      expect(find.text('بطاقة نومو ما عندهاش رمز CVV'), findsOneWidget);
      expect(find.text('NUMO'), findsOneWidget, reason: 'the card picture shows the Numo mark');
    });

    testWidgets('choosing to type: nothing filled, nothing to confirm, typing the card by hand saves', (tester) async {
      final (_, store, _) = await pumpForm(tester, const CardScanResult.manual());
      await scan(tester);
      expect(find.byKey(const Key('confirm-scan')), findsNothing, reason: 'nothing was scanned, so nothing needs confirming');
      expect(field(tester, 'card-number'), '');

      await tester.enterText(find.byKey(const Key('card-holder')), 'Ali Omar');
      await tester.enterText(find.byKey(const Key('card-number')), testPan);
      await tester.enterText(find.byKey(const Key('card-expiry')), '1228');
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect(await CardVault(store: store, ownerId: '27').load(), hasLength(1));
    });

    testWidgets('declining the explanation never opens the camera; accepting it is asked once', (tester) async {
      final (_, _, opened) = await pumpForm(tester, null);
      await tester.tap(find.byKey(const Key('scan-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);

      await scan(tester);
      expect(opened, hasLength(1));
      await scan(tester, explained: true);
      expect(opened, hasLength(2), reason: 'the explanation is shown until it is accepted, then not again');
    });
  });

  group('live scanner page', () {
    Future<void> pumpScanner(WidgetTester tester, Widget page, List<Object?> popped) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () async => popped.add(await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page))),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('reading: the fields lock one by one and only a masked number is drawn', (tester) async {
      const progress = ScanProgress(
        number: testPan,
        numberState: FieldState.locked,
        holder: null,
        holderState: FieldState.reading,
        expiryMonth: 12,
        expiryYear: 2028,
        expiryState: FieldState.locked,
        result: null,
        textSeen: true,
      );
      await pumpScanner(tester, const CardScannerPage(isRtl: true, debugPreview: ColoredBox(color: Colors.black), debugProgress: progress), []);
      expect(find.textContaining('4111 11•• •••• 1111'), findsWidgets);
      expect(find.textContaining('4111 1111 1111 1111'), findsNothing, reason: 'the full number is never on screen');
      expect(find.byKey(const Key('scan-use')), findsOneWidget);
      expect(find.byKey(const Key('scan-torch')), findsOneWidget);
      expect(find.text('ثبّت البطاقة شوية… جاري القراءة'), findsOneWidget);
    });

    testWidgets('camera off: settings, a photo or typing - and a photo that reads well comes back for checking', (tester) async {
      final popped = <Object?>[];
      final deleted = <String>[];
      await pumpScanner(
          tester,
          CardScannerPage(
            isRtl: true,
            debugCameraProblem: false,
            photoScanner: (source) => CardScanner(
              source: FakeSource('/tmp/p.jpg'),
              ocr: FakeRecognizer([testPan, 'VALID THRU 12/28', 'ALI BEN OMAR']),
              clock: () => now,
              deleter: (p) async => deleted.add(p),
            ),
          ),
          popped);
      expect(find.byKey(const Key('scan-camera-problem')), findsOneWidget);
      expect(find.byKey(const Key('scan-take-photo')), findsOneWidget, reason: 'the one-photo path is the fallback');
      expect(find.byKey(const Key('scan-manual-fallback')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scan-take-photo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(deleted, ['/tmp/p.jpg']);
      final result = popped.single as CardScanResult;
      expect(result.card!.number, testPan);
      expect(result.card!.needsReview(CardField.number), isTrue);
    });

    testWidgets('camera refused: the settings button is offered, and typing closes the scanner', (tester) async {
      final popped = <Object?>[];
      await pumpScanner(tester, const CardScannerPage(isRtl: true, debugCameraProblem: true), popped);
      expect(find.byKey(const Key('scan-settings')), findsOneWidget);
      expect(find.text('الكاميرا مقفولة على التطبيق'), findsOneWidget);
      await tester.tap(find.byKey(const Key('scan-manual-fallback')));
      await tester.pumpAndSettle();
      expect((popped.single as CardScanResult).manual, isTrue);
    });
  });

  group('wallet page', () {
    test('Add Money goes through the two-method sheet; the old standalone row is gone', () {
      final page = File('lib/pages/NavigatorPages/walletpage.dart').readAsStringSync();
      expect(page.contains('showAddMoneySheet('), isTrue);
      expect(page.contains('MoamalatWalletEntry'), isFalse);
      expect(page.contains('_openQareebRecharge'), isTrue, reason: 'the recharge-card entry is kept, unchanged');
      expect(page.contains('addBalance('), isTrue);
    });

    test('the camera permission text tells the customer what it is for', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final match = RegExp(r'<key>NSCameraUsageDescription</key>\s*<string>([^<]*)</string>').firstMatch(plist)!;
      expect(match.group(1)!.toLowerCase(), allOf(contains('card'), contains('device')));
    });
  });
}
