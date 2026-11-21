// Renders the card screens to PNG for review (not a regression test). Skipped
// unless SHOTS_OUT is set:
//   SHOTS_OUT=/path/to/dir flutter test test/card_scan_shots_test.dart --tags shots
@Tags(['shots'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/payments/moamalat/card_brand.dart';
import 'package:taxista/payments/moamalat/card_scan_session.dart';
import 'package:taxista/payments/moamalat/card_scanner_page.dart';
import 'package:taxista/payments/moamalat/card_text_parser.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/card_visual.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/saved_cards_page.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';

final String? _out = Platform.environment['SHOTS_OUT'];

/// The Rider app's look (lib/payments/moamalat/moamalat_app_env.dart): white page, Taxista-blue buttons.
const Color _blue = Color(0xff0873FF);

Future<void> _fonts() async {
  Future<void> load(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/Caskroom/flutter/3.32.4/flutter';
  await load('MaterialIcons', '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    await load('Roboto', '$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
  }
  // GoogleFonts.cairo falls back to the family "Cairo": a system face with Arabic AND Latin
  // (CVV, dashes, brackets) stands in for it here, so the shots show no missing glyphs.
  const both = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
  // (the exact names GoogleFonts asks for: "Cairo_700" etc.; an unknown name would fall to the test font)
  for (final name in ['Cairo', 'Cairo_regular', 'Cairo_500', 'Cairo_600', 'Cairo_700', 'Cairo_800', 'Cairo_900']) {
    await load(name, both);
  }
  await load('SFArabic', both);
  await load('Courier', '/System/Library/Fonts/Supplemental/Courier New Bold.ttf');
}

class _Api implements MoamalatApi {
  @override
  Future<List<PaymentMethodOption>> methods() async => const [];
  @override
  Future<MoamalatOptions> options() async => const MoamalatOptions(available: true, currency: 'LYD', minAmount: 5, maxAmount: 1000);
  @override
  Future<MoamalatTopUp> initiate(double amount) async => MoamalatTopUp(id: '1', reference: 'TX-1', amount: amount, currency: 'LYD', paymentUrl: 'https://x');
  @override
  Future<MoamalatStatus> status(String topUpId) async => const MoamalatStatus(status: 'pending', credited: false);
}

MoamalatEnv _env(CardVault vault) => MoamalatEnv(
      api: _Api(),
      vault: vault,
      clipboard: SecureClipboard(writer: (_) async {}),
      isRtl: true,
      accent: _blue,
      background: Colors.white,
      surface: Colors.white,
      text: const Color(0xff12121D),
      muted: const Color(0xff808080),
      border: const Color(0xffE5E5E5),
    );

final GlobalKey _frame = GlobalKey();

Widget _app(Widget home) => RepaintBoundary(
      key: _frame,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', fontFamilyFallback: const ['SFArabic'], useMaterial3: true),
        home: home,
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _shot(WidgetTester tester, Widget home, String name, {Future<void> Function()? then}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home));
  await _settle(tester);
  if (then != null) await then();
  await _settle(tester);
  await tester.runAsync(() async {
    final boundary = _frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Stand-in for the camera: a card held over a desk, inside the frame.
class _MockCameraScene extends StatelessWidget {
  const _MockCameraScene();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth * 0.84;
      return Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.2, colors: [Color(0xFF6B5B4B), Color(0xFF3B3129), Color(0xFF1E1914)]),
          ),
        ),
        Positioned(
          left: (c.maxWidth - w) / 2,
          top: c.maxHeight * 0.34 - (w / CardVisual.aspect) / 2,
          width: w,
          child: Transform.rotate(
            angle: -2.2 * math.pi / 180,
            child: const CardVisual(
              brand: CardBrand.visa,
              numberText: '4111 1111 1111 1111',
              holderText: 'AHMED ALI SALEM',
              expiryText: '08/29',
              title: 'JUMHOURIA BANK',
            ),
          ),
        ),
      ]);
    });
  }
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _fonts();
  });
  setUp(() => SharedPreferences.setMockInitialValues({'taxista.card_scan_explained.v1': true}));

  final skip = _out == null ? 'set SHOTS_OUT to render the screens' : null;

  testWidgets('01 add card, empty', (tester) async {
    await _shot(tester, CardFormPage(env: _env(CardVault(store: MemorySecretStore(), ownerId: 'u'))), '01_add_card_empty');
  }, skip: skip != null);

  testWidgets('02 live scanner viewfinder (mock camera)', (tester) async {
    const progress = ScanProgress(
      number: '4111111111111111',
      numberState: FieldState.locked,
      holder: null,
      holderState: FieldState.reading,
      expiryMonth: 8,
      expiryYear: 2029,
      expiryState: FieldState.locked,
      result: null,
      textSeen: true,
    );
    await _shot(tester, const CardScannerPage(isRtl: true, debugPreview: _MockCameraScene(), debugProgress: progress), '02_scanner_viewfinder');
  }, skip: skip != null);

  testWidgets('03 scan result filled', (tester) async {
    await _shot(
      tester,
      CardFormPage(
        env: _env(CardVault(store: MemorySecretStore(), ownerId: 'u')),
        openScanner: (_) async => const CardScanResult.scanned(
            ScannedCard(number: '4111111111111111', expiryMonth: 8, expiryYear: 2029, holder: 'AHMED ALI SALEM', review: {CardField.holder})),
      ),
      '03_scan_result_filled',
      then: () async {
        await tester.tap(find.byKey(const Key('scan-card')));
        await _settle(tester);
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }, skip: skip != null);

  testWidgets('04 saved cards list', (tester) async {
    final vault = CardVault(store: MemorySecretStore(), ownerId: 'u');
    await tester.runAsync(() async {
      await vault.add(holderName: 'AHMED ALI SALEM', number: '4111111111111111', expMonth: 8, expYear: 2029, nickname: 'بطاقة المرتب');
      await vault.add(holderName: 'AHMED ALI SALEM', number: '5555555555554444', expMonth: 3, expYear: 2028);
      await vault.add(holderName: 'AHMED ALI SALEM', number: '6390001234561234', expMonth: 1, expYear: 2030, nickname: 'نومو');
    });
    await _shot(tester, SavedCardsPage(env: _env(vault)), '04_saved_cards_list');
  }, skip: skip != null);

  testWidgets('05 saved cards, empty', (tester) async {
    await _shot(tester, SavedCardsPage(env: _env(CardVault(store: MemorySecretStore(), ownerId: 'u'))), '05_saved_cards_empty');
  }, skip: skip != null);

  testWidgets('06 camera off: photo or typing', (tester) async {
    await _shot(tester, const CardScannerPage(isRtl: true, debugCameraProblem: false), '06_camera_off_fallback');
  }, skip: skip != null);

  testWidgets('07 Numo card typed', (tester) async {
    await _shot(
      tester,
      CardFormPage(env: _env(CardVault(store: MemorySecretStore(), ownerId: 'u'))),
      '07_numo_typed',
      then: () async {
        await tester.enterText(find.byKey(const Key('card-number')), '6390001234561234');
        await tester.enterText(find.byKey(const Key('card-expiry')), '0130');
        await tester.enterText(find.byKey(const Key('card-holder')), 'MOHAMED ALI');
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }, skip: skip != null);
}
