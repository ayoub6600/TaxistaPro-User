import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/payments/moamalat/add_money_sheet.dart';
import 'package:taxista/payments/moamalat/card_scanner.dart';
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

class FakeRecognizer implements CardTextRecognizer {
  FakeRecognizer(this.lines, {this.fail = false});
  final List<String> lines;
  final bool fail;

  @override
  Future<List<String>> recognize(String imagePath) async {
    if (fail) throw StateError('ocr crashed');
    return lines;
  }
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

    test('digits split across lines are joined; Arabic-Indic digits are read', () {
      expect(parseCardText(['4111', '1111', '1111', '1111', '12/28', 'ALI BEN OMAR'], now: now).number, testPan);
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

  group('the scanner keeps the photo private', () {
    test('success: the text is read on the device and the photo is deleted', () async {
      final deleted = <String>[];
      final scanner = CardScanner(
        source: FakeSource('/tmp/card.jpg'),
        recognizer: FakeRecognizer([testPan, '12/28', 'ALI BEN OMAR']),
        clock: () => now,
        deleter: (p) async => deleted.add(p),
      );
      final outcome = await scanner.scan();
      expect(outcome.status, CardScanStatus.success);
      expect(outcome.card.number, testPan);
      expect(deleted, ['/tmp/card.jpg']);
    });

    test('an OCR crash, an unreadable photo and a failing delete never keep or expose the image', () async {
      final deleted = <String>[];
      final crashed = await CardScanner(
        source: FakeSource('/tmp/a.jpg'),
        recognizer: FakeRecognizer(const [], fail: true),
        deleter: (p) async => deleted.add(p),
      ).scan();
      expect(crashed.status, CardScanStatus.failed);

      final blank = await CardScanner(
        source: FakeSource('/tmp/b.jpg'),
        recognizer: FakeRecognizer(const ['   ']),
        deleter: (p) async => deleted.add(p),
      ).scan();
      expect(blank.status, CardScanStatus.unreadable);
      expect(deleted, ['/tmp/a.jpg', '/tmp/b.jpg']);

      final stubborn = await CardScanner(
        source: FakeSource('/tmp/c.jpg'),
        recognizer: FakeRecognizer([testPan, '12/28']),
        clock: () => now,
        deleter: (p) async => throw const FileSystemException('locked'),
      ).scan();
      expect(stubborn.status, CardScanStatus.success, reason: 'a delete error never turns into a scan error');
    });

    test('cancelling takes no photo and deletes nothing; a refused camera is a clean outcome', () async {
      final deleted = <String>[];
      final cancelled = await CardScanner(source: FakeSource(null), recognizer: FakeRecognizer(const []), deleter: (p) async => deleted.add(p)).scan();
      expect(cancelled.status, CardScanStatus.cancelled);
      final denied = await CardScanner(source: FakeSource(null, denied: true), recognizer: FakeRecognizer(const []), deleter: (p) async => deleted.add(p)).scan();
      expect(denied.status, CardScanStatus.denied);
      expect(deleted, isEmpty);
    });

    test('the scanner code has no network, gallery, analytics or logging of card data', () {
      final source = File('lib/payments/moamalat/card_scanner.dart').readAsStringSync();
      final parser = File('lib/payments/moamalat/card_text_parser.dart').readAsStringSync();
      final code = (source + parser).replaceAll(RegExp(r'///.*'), '').replaceAll(RegExp(r'//.*'), '');
      for (final banned in ['package:http', 'dio', 'HttpClient', 'upload', 'multipart', 'debugPrint', 'print(', 'log(', 'saveImage', 'ImageGallerySaver', 'gallery', 'analytics', 'Firebase', 'cvv', 'CVV']) {
        expect(code.contains(banned), isFalse, reason: 'scanner must not contain "$banned"');
      }
      expect(source.contains('requestFullMetadata: false'), isTrue, reason: 'no photo-library permission is requested');
      expect(source.contains('ImageSource.camera'), isTrue);
      expect(source.contains("'taxista/card_ocr'"), isTrue, reason: 'recognition runs in the app, through the native channel');
      expect(source.contains('google_mlkit'), isFalse, reason: 'no cloud-capable plugin, no heavy pods');
      expect(source.contains('finally'), isTrue, reason: 'deletion is unconditional');
    });
  });

  group('on-device recognition channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('taxista/card_ocr');

    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('the path goes to the native side and the recognised lines come back as text', () async {
      MethodCall? seen;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        seen = call;
        return <Object?>['4111 1111 1111 1111', '12/28', 42];
      });
      final lines = await NativeCardTextRecognizer().recognize('/tmp/card.jpg');
      expect(seen!.method, 'recognize');
      expect(seen!.arguments, {'path': '/tmp/card.jpg'});
      expect(lines, ['4111 1111 1111 1111', '12/28', '42']);
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
      expect(swift.contains('URLSession'), isFalse);
      expect(swift.contains('taxista/card_ocr'), isTrue);

      final gradle = File('android/app/build.gradle').readAsStringSync();
      expect(gradle.contains('com.google.mlkit:text-recognition:'), isTrue, reason: 'the bundled model, not the Play-services download variant');
      expect(gradle.contains('play-services-mlkit'), isFalse);
      final kotlin = Directory('android/app/src/main/kotlin').listSync(recursive: true).whereType<File>().firstWhere((f) => f.path.endsWith('MainActivity.kt')).readAsStringSync();
      expect(kotlin.contains('taxista/card_ocr'), isTrue);
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
      expect(find.text('كروت شحن قريب'), findsOneWidget);
      expect(find.text('البطاقة البنكية'), findsOneWidget);
      expect(find.byKey(const Key('method-qareeb_card')), findsOneWidget);
      expect(find.byKey(const Key('method-bank_card')), findsOneWidget);
      expect(find.textContaining('معاملات'), findsNothing);
      expect(find.textContaining('Moamalat'), findsNothing);
      expect(find.textContaining('Maamalat'), findsNothing);
    });

    testWidgets('english labels', (tester) async {
      await openSheet(tester, makeEnv(FakeApi(), rtl: false));
      expect(find.text('Qareeb recharge cards'), findsOneWidget);
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
      expect(find.text('البطاقات المحفوظة'), findsOneWidget);
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
    Future<(FakeApi, MemorySecretStore)> pumpForm(WidgetTester tester, CardScanner scanner) async {
      final api = FakeApi();
      final store = MemorySecretStore();
      final env = makeEnv(api, store: store);
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: CardForm(env: env, scanner: scanner))));
      return (api, store);
    }

    Future<void> scan(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('scan-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scan-explainer')), findsOneWidget, reason: 'the customer is told what the camera is for first');
      await tester.tap(find.byKey(const Key('scan-continue')));
      await tester.pumpAndSettle();
    }

    String field(WidgetTester tester, String key) => (tester.widget<TextField>(find.byKey(Key(key))).controller!).text;

    testWidgets('the scan fills the form, asks for confirmation, and only then can it be saved', (tester) async {
      final scanner = CardScanner(
        source: FakeSource('/tmp/x.jpg'),
        recognizer: FakeRecognizer([testPan, 'VALID THRU 12/28', 'ALI BEN OMAR']),
        clock: () => now,
        deleter: (_) async {},
      );
      final (api, store) = await pumpForm(tester, scanner);
      await scan(tester);

      expect(field(tester, 'card-number'), '4111 1111 1111 1111');
      expect(field(tester, 'card-expiry'), '12/28');
      expect(field(tester, 'card-holder'), 'ALI BEN OMAR');

      final save = find.byKey(const Key('save-card'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull, reason: 'a scanned card cannot be saved unchecked');
      await tester.tap(find.byKey(const Key('confirm-scan')));
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.pumpAndSettle();
      final saved = await CardVault(store: store, ownerId: '27').load();
      expect(saved, hasLength(1));
      expect(saved.single.expMonth, 12);
      expect(api.initiated, isEmpty, reason: 'scanning or saving a card never starts a payment');
      expect(store.data.values.join().toLowerCase(), isNot(contains('cvv')));
    });

    testWidgets('the user can correct what was read before saving', (tester) async {
      final scanner = CardScanner(
        source: FakeSource('/tmp/x.jpg'),
        recognizer: FakeRecognizer([testPan, '12/28', 'ALY BEN OMAR']),
        clock: () => now,
        deleter: (_) async {},
      );
      final (_, store) = await pumpForm(tester, scanner);
      await scan(tester);
      await tester.enterText(find.byKey(const Key('card-holder')), 'ALI BEN OMAR');
      await tester.tap(find.byKey(const Key('confirm-scan')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect((await CardVault(store: store, ownerId: '27').load()).single.holderName, 'ALI BEN OMAR');
    });

    testWidgets('a doubtful field is marked so the user looks at it', (tester) async {
      final scanner = CardScanner(
        source: FakeSource('/tmp/x.jpg'),
        recognizer: FakeRecognizer(['6273 0012 3456 1234', '01/30']), // local card, no name read
        clock: () => now,
        deleter: (_) async {},
      );
      await pumpForm(tester, scanner);
      await scan(tester);
      expect(find.textContaining('تحقق من هذا الحقل'), findsWidgets);
    });

    testWidgets('camera denied: a clear message, and typing the card by hand still saves', (tester) async {
      final scanner = CardScanner(source: FakeSource(null, denied: true), recognizer: FakeRecognizer(const []), deleter: (_) async {});
      final (_, store) = await pumpForm(tester, scanner);
      await scan(tester);
      expect(find.byKey(const Key('scan-denied')), findsOneWidget);
      expect(find.byKey(const Key('confirm-scan')), findsNothing, reason: 'nothing was scanned, so nothing needs confirming');

      await tester.enterText(find.byKey(const Key('card-holder')), 'Ali Omar');
      await tester.enterText(find.byKey(const Key('card-number')), testPan);
      await tester.enterText(find.byKey(const Key('card-expiry')), '1228');
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();
      expect(await CardVault(store: store, ownerId: '27').load(), hasLength(1));
    });

    testWidgets('an unreadable photo changes nothing and the form stays usable', (tester) async {
      final scanner = CardScanner(source: FakeSource('/tmp/x.jpg'), recognizer: FakeRecognizer(const ['blur']), deleter: (_) async {});
      await pumpForm(tester, scanner);
      await scan(tester);
      expect(find.byKey(const Key('scan-failed')), findsOneWidget);
      expect(field(tester, 'card-number'), '');
    });

    testWidgets('declining the explanation never opens the camera', (tester) async {
      final source = FakeSource('/tmp/x.jpg');
      final scanner = CardScanner(source: source, recognizer: FakeRecognizer(const []), deleter: (_) async {});
      await pumpForm(tester, scanner);
      await tester.tap(find.byKey(const Key('scan-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(source.calls, 0);
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
