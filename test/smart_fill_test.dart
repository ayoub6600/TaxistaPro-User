import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/payments/moamalat/card_fill_script.dart';
import 'package:taxista/payments/moamalat/card_helper_panel.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_checkout_page.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/saved_card.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';
import 'package:taxista/payments/moamalat/smart_fill_assistant.dart';
import 'package:taxista/payments/moamalat/smart_fill_bridge.dart';
import 'package:taxista/payments/moamalat/smart_fill_controller.dart';

const String pan = '4111111111111111';

class FakeBridge implements SmartFillBridge {
  bool installOk = true;
  final List<Map<String, Object?>> installs = [];
  final List<Map<String, Object?>> fills = [];
  final List<int> disposed = [];
  SmartFillResult next = const SmartFillResult(ok: true, pan: 'filled', exp: 'filled', name: 'filled', terms: 'checked');
  Completer<void>? gate;
  final StreamController<SmartFillFrameEvent> _events = StreamController<SmartFillFrameEvent>.broadcast(sync: true);

  void emit(int id, SmartFillFrameState s) => _events.add(SmartFillFrameEvent(id, s));

  @override
  Stream<SmartFillFrameEvent> get events => _events.stream;

  @override
  Future<bool> install({required int webViewId, required String script, required List<String> origins}) async {
    installs.add({'id': webViewId, 'script': script, 'origins': origins});
    return installOk;
  }

  @override
  Future<SmartFillResult> fill({required int webViewId, required String pan, required String exp, required String name, required bool acceptTerms}) async {
    fills.add({'id': webViewId, 'pan': pan, 'exp': exp, 'name': name, 'terms': acceptTerms});
    if (gate != null) await gate!.future;
    return next;
  }

  @override
  Future<void> dispose(int webViewId) async => disposed.add(webViewId);
}

MoamalatEnv makeEnv(FakeBridge bridge, {List<String>? clipboardLog, bool rtl = true, CardVault? vault}) => MoamalatEnv(
      api: _Api(),
      vault: vault ?? CardVault(store: MemorySecretStore(), ownerId: '1'),
      clipboard: SecureClipboard(writer: (t) async => clipboardLog?.add(t)),
      isRtl: rtl,
      smartFill: SmartFillSupport(bridge: bridge, assistantAsset: 'assets/images/rider_mascot.png'),
    );

class _Api implements MoamalatApi {
  @override
  Future<List<PaymentMethodOption>> methods() async => PaymentMethodOption.offlineFallback;
  @override
  Future<MoamalatOptions> options() async => const MoamalatOptions(available: true, currency: 'LYD', minAmount: 5, maxAmount: 2000);
  @override
  Future<MoamalatTopUp> initiate(double amount) async => MoamalatTopUp(id: 'T', reference: 'R', amount: amount, currency: 'LYD', paymentUrl: 'https://pay.example');
  @override
  Future<MoamalatStatus> status(String id) async => const MoamalatStatus(status: 'pending', credited: false);
}

const SavedCard card = SavedCard(id: 'c1', holderName: 'Ali Ben', number: pan, expMonth: 12, expYear: 2030);

SmartFillController controllerFor(FakeBridge bridge, {Future<SavedCard?> Function()? fetch, Duration collapse = const Duration(seconds: 3), Duration timeout = const Duration(seconds: 20)}) =>
    SmartFillController(
      support: SmartFillSupport(bridge: bridge, assistantAsset: 'assets/images/rider_mascot.png'),
      fetchCard: fetch ?? () async => card,
      collapseAfterSuccess: collapse,
      formTimeout: timeout,
    );

void main() {
  group('the script that goes into the payment frames', () {
    test('carries the exact origin allow-list, no wildcard', () {
      final s = buildCardFillScript(kMoamalatGatewayOrigins);
      expect(kMoamalatGatewayOrigins, ['https://npg.moamalat.net:6006']);
      expect(s, contains('var ORIGINS = ["https://npg.moamalat.net:6006"];'));
      expect(s, isNot(contains('"*"')));
      expect(s, contains('ORIGINS.indexOf(W.location.origin) < 0) return;'));
    });

    test('tells native the moment its frame is leaving, so the offer never outlives the form', () {
      expect(buildCardFillScript(kMoamalatGatewayOrigins), contains("addEventListener('pagehide'"));
    });

    test('never handles the CVV, never submits, never sends or stores anything', () {
      final s = buildCardFillScript(kMoamalatGatewayOrigins);
      // The CVV field is only ever used to recognise the form, never written to.
      expect(s, isNot(contains('typeInto(f.cvv')));
      expect(s, isNot(contains('f.cvv.value')));
      for (final forbidden in ['fetch(', 'XMLHttpRequest', 'sendBeacon', 'localStorage', 'sessionStorage', 'document.cookie', 'console.', 'WebSocket', '.submit(', 'requestSubmit', 'type=submit', 'button[']) {
        expect(s, isNot(contains(forbidden)), reason: 'the script must not use $forbidden');
      }
      // The only click it can ever make is on the terms checkbox it found.
      expect('.click()'.allMatches(s).length, 1);
      expect(s, contains('box.click()'));
    });

    test('an empty allow-list means the script never runs anywhere', () {
      expect(buildCardFillScript(const []), contains('var ORIGINS = [];'));
    });
  });

  group('controller', () {
    test('installs the script before anything else and starts waiting', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge);
      await c.attach(7);
      expect(bridge.installs.single['id'], 7);
      expect(bridge.installs.single['origins'], kMoamalatGatewayOrigins);
      expect(c.phase, SmartFillPhase.waiting);
      c.dispose();
    });

    test('offers the fill only when the form is ready; other web views are ignored', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge);
      await c.attach(7);
      bridge.emit(99, SmartFillFrameState.ready);
      expect(c.phase, SmartFillPhase.waiting);
      bridge.emit(7, SmartFillFrameState.ready);
      expect(c.phase, SmartFillPhase.ready);
      bridge.emit(7, SmartFillFrameState.gone);
      expect(c.phase, SmartFillPhase.waiting);
      c.dispose();
    });

    test('the card is read from the vault only when the customer taps, and handed over once', () async {
      final bridge = FakeBridge();
      var reads = 0;
      final c = controllerFor(bridge, fetch: () async {
        reads++;
        return card;
      });
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      expect(reads, 0, reason: 'nothing is read while the assistant is only offering');
      await c.fill();
      expect(reads, 1);
      expect(bridge.fills.single, {'id': 7, 'pan': pan, 'exp': '12/30', 'name': 'Ali Ben', 'terms': true});
      expect(c.phase, SmartFillPhase.success);
      c.dispose();
    });

    test('success needs EVERY operation: a page that did not take the terms box is a failure, never a success', () async {
      final bridge = FakeBridge()..next = const SmartFillResult(ok: false, pan: 'filled', exp: 'filled', name: 'filled', terms: 'failed', reason: 'not_accepted');
      final c = controllerFor(bridge);
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      await c.fill();
      expect(c.phase, SmartFillPhase.failed);
      expect(c.phase, isNot(SmartFillPhase.success));
      expect(c.showFallbackHelper, isFalse, reason: 'a partial failure is retried, not abandoned');
      // retry works and can then succeed
      bridge.next = const SmartFillResult(ok: true, pan: 'filled', exp: 'filled', name: 'filled', terms: 'checked');
      await c.fill();
      expect(c.phase, SmartFillPhase.success);
      expect(bridge.fills.length, 2);
      c.dispose();
    });

    test('a form it does not recognise fails closed and brings the classic helper back', () async {
      final bridge = FakeBridge()..next = const SmartFillResult(ok: false, reason: 'unknown_form');
      final c = controllerFor(bridge);
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      await c.fill();
      expect(c.phase, SmartFillPhase.failed);
      expect(c.showFallbackHelper, isTrue);
      c.dispose();
    });

    test('a platform that cannot inject into frames keeps the classic helper', () async {
      final c = controllerFor(FakeBridge()..installOk = false);
      await c.attach(7);
      expect(c.phase, SmartFillPhase.unsupported);
      expect(c.showFallbackHelper, isTrue);
      c.dispose();
    });

    test('a missing card (deleted meanwhile) fails without touching the page', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge, fetch: () async => null);
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      await c.fill();
      expect(c.phase, SmartFillPhase.failed);
      expect(bridge.fills, isEmpty);
      c.dispose();
    });

    test('after success the panel collapses; a reloaded (empty) form offers the fill again, never a stale success', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge, collapse: const Duration(milliseconds: 10));
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      await c.fill();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.collapsed, isTrue);
      bridge.emit(7, SmartFillFrameState.gone); // the page reloads
      bridge.emit(7, SmartFillFrameState.ready);
      expect(c.phase, SmartFillPhase.ready);
      expect(c.collapsed, isFalse);
      expect(c.lastResult, isNull);
      c.dispose();
    });

    test('the page repainting while the fill runs cannot flip the state or trigger a second fill', () async {
      final bridge = FakeBridge()..gate = Completer<void>();
      final c = controllerFor(bridge);
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      final running = c.fill();
      await Future<void>.delayed(Duration.zero);
      expect(c.phase, SmartFillPhase.filling);
      bridge.emit(7, SmartFillFrameState.gone);
      bridge.emit(7, SmartFillFrameState.ready);
      unawaited(c.fill()); // a double tap
      expect(c.phase, SmartFillPhase.filling);
      bridge.gate!.complete();
      await running;
      expect(bridge.fills.length, 1);
      expect(c.phase, SmartFillPhase.success);
      c.dispose();
    });

    test('no recognisable form for a while: the classic helper is offered, and withdrawn when the form appears', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge, timeout: const Duration(milliseconds: 20));
      await c.attach(7);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.showFallbackHelper, isTrue);
      bridge.emit(7, SmartFillFrameState.ready);
      expect(c.showFallbackHelper, isFalse);
      c.dispose();
    });

    test('a page that never answers ends as a retryable failure, not an endless spinner', () async {
      final bridge = FakeBridge()..gate = Completer<void>();
      final c = SmartFillController(
        support: SmartFillSupport(bridge: bridge, assistantAsset: 'assets/images/rider_mascot.png'),
        fetchCard: () async => card,
        fillTimeout: const Duration(milliseconds: 30),
      );
      await c.attach(7);
      bridge.emit(7, SmartFillFrameState.ready);
      await c.fill();
      expect(c.phase, SmartFillPhase.failed);
      expect(c.showFallbackHelper, isFalse);
      c.dispose();
    });

    test('disposing releases the native side', () async {
      final bridge = FakeBridge();
      final c = controllerFor(bridge);
      await c.attach(7);
      c.dispose();
      expect(bridge.disposed, [7]);
    });
  });

  group('assistant', () {
    Future<void> finish(WidgetTester tester, SmartFillController c) async {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }

    Future<SmartFillController> pump(WidgetTester tester, FakeBridge bridge, {bool rtl = true, Size? size, EdgeInsets keyboard = EdgeInsets.zero}) async {
      final c = controllerFor(bridge);
      await c.attach(7);
      final env = makeEnv(bridge, rtl: rtl);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size ?? const Size(390, 844), viewInsets: keyboard),
          child: Scaffold(body: SmartFillAssistant(env: env, controller: c)),
        ),
      ));
      return c;
    }

    testWidgets('shows nothing until the form is ready', (tester) async {
      final bridge = FakeBridge();
      final c = await pump(tester, bridge);
      expect(find.byKey(const Key('smart-fill-card')), findsNothing);
      expect(find.byKey(const Key('smart-fill-button')), findsNothing);
      await finish(tester, c);
    });

    testWidgets('once: friendly text, the consent sentence BEFORE the tap, one prominent button', (tester) async {
      final bridge = FakeBridge();
      final c = await pump(tester, bridge);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('smart-fill-card')), findsOneWidget);
      expect(find.text('نقدر نعبّيلك بيانات البطاقة تلقائياً 👌'), findsOneWidget);
      expect(find.text('بالضغط على تعبئة ذكية، سيتم تعبئة بيانات بطاقتك والموافقة على شروط الدفع.'), findsOneWidget);
      expect(find.byKey(const Key('smart-fill-button')), findsOneWidget);
      expect(find.text('تعبئة ذكية'), findsOneWidget);
      await finish(tester, c);
    });

    testWidgets('customer-facing text has no technical words', (tester) async {
      final bridge = FakeBridge();
      final c = await pump(tester, bridge);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => (t.data ?? '').toLowerCase()).join(' ');
      for (final word in ['webview', 'javascript', 'iframe', 'pan', 'script', 'inject']) {
        expect(texts.contains(word), isFalse, reason: 'no "$word" in the UI');
      }
      await finish(tester, c);
    });

    testWidgets('tap fills; success turns the button into the green "filled" state and it is not offered again', (tester) async {
      final bridge = FakeBridge();
      final c = await pump(tester, bridge);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('smart-fill-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('✓ تمت التعبئة بنجاح'), findsOneWidget);
      expect(find.text('تمام 👌 بيانات البطاقة جاهزة، كمّل عملية الدفع.'), findsOneWidget);
      expect(find.text('تعبئة ذكية'), findsNothing);
      final button = tester.widget<FilledButton>(find.byKey(const Key('smart-fill-button')));
      expect(button.onPressed, isNull, reason: 'the fill button is never offered again after success');
      expect(bridge.fills.length, 1);
      await finish(tester, c);
    });

    testWidgets('success then collapses to a slim chip that can be opened again', (tester) async {
      final bridge = FakeBridge();
      final c = await pump(tester, bridge);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await c.fill();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('smart-fill-chip')), findsOneWidget);
      expect(find.byKey(const Key('smart-fill-card')), findsNothing);
      await tester.tap(find.text('✓ تمت التعبئة'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('smart-fill-card')), findsOneWidget);
      await finish(tester, c);
    });

    testWidgets('a partial failure never says success; it offers a retry', (tester) async {
      final bridge = FakeBridge()..next = const SmartFillResult(ok: false, pan: 'filled', exp: 'filled', name: 'filled', terms: 'failed', reason: 'not_accepted');
      final c = await pump(tester, bridge);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('smart-fill-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تعذر إكمال التعبئة، حاول مرة أخرى'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.textContaining('تمت التعبئة'), findsNothing);
      expect(find.textContaining('✓'), findsNothing);
      await finish(tester, c);
    });

    testWidgets('fits a 320 dp phone, in both languages, normal and keyboard-open, every state', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      addTearDown(tester.view.reset);
      for (final rtl in [true, false]) {
        for (final keyboard in [EdgeInsets.zero, const EdgeInsets.only(bottom: 300)]) {
          final bridge = FakeBridge();
          final c = await pump(tester, bridge, rtl: rtl, size: const Size(320, 640), keyboard: keyboard);
          bridge.emit(7, SmartFillFrameState.ready);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: 'ready rtl=$rtl keyboard=${keyboard.bottom}');
          // consent is visible in both layouts
          expect(find.textContaining(rtl ? 'الموافقة على شروط الدفع' : 'accept the payment terms'), findsOneWidget);
          await tester.tap(find.byKey(const Key('smart-fill-button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: 'success rtl=$rtl keyboard=${keyboard.bottom}');
          await finish(tester, c);
        }
      }
    });
  });

  group('checkout page', () {
    Future<void> open(WidgetTester tester, {required MoamalatEnv env, SavedCard? selected, SmartFillController? smart}) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MoamalatCheckoutPage(
                  env: env,
                  card: selected,
                  smartFill: smart,
                  viewBuilder: (context, {required url, required onMessage, required onLoaded, required onLoadError}) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
                    return Container(key: const Key('payment-view'), color: Colors.grey);
                  },
                  loadTimeout: const Duration(seconds: 2),
                  topUp: const MoamalatTopUp(id: 'T1', reference: 'TXPRABC123', amount: 50, currency: 'LYD', paymentUrl: 'https://pay.example/T1'),
                ),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
    }

    testWidgets('with a selected card: the assistant appears once the form is ready, above the page, and no classic helper', (tester) async {
      final bridge = FakeBridge();
      final smart = controllerFor(bridge);
      await smart.attach(7);
      final env = makeEnv(bridge);
      await open(tester, env: env, selected: card.redacted(), smart: smart);
      expect(find.byKey(const Key('smart-fill-card')), findsNothing);

      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('smart-fill-card')), findsOneWidget);
      expect(find.byType(CardHelperPanel), findsNothing);
      // the assistant is above the payment page and does not overlap it
      final assistantBottom = tester.getBottomLeft(find.byKey(const Key('smart-fill-card'))).dy;
      final pageTop = tester.getTopLeft(find.byKey(const Key('payment-view'))).dy;
      expect(assistantBottom, lessThanOrEqualTo(pageTop + 1));
    });

    testWidgets('no selected card: no assistant at all', (tester) async {
      final bridge = FakeBridge();
      final env = makeEnv(bridge);
      await open(tester, env: env, selected: null);
      bridge.emit(7, SmartFillFrameState.ready);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SmartFillAssistant), findsNothing);
      expect(find.byKey(const Key('smart-fill-button')), findsNothing);
    });

    testWidgets('when smart fill cannot work, the classic helper takes over - and copies the REAL card from the vault, not the redacted one', (tester) async {
      final log = <String>[];
      final bridge = FakeBridge()..installOk = false;
      final vault = CardVault(store: MemorySecretStore(), ownerId: '1');
      final saved = await vault.add(holderName: 'Ali Ben', number: pan, expMonth: 12, expYear: 2030);
      final smart = controllerFor(bridge, fetch: () => vault.byId(saved.id));
      await smart.attach(7);
      final env = makeEnv(bridge, clipboardLog: log, vault: vault);
      await open(tester, env: env, selected: saved.redacted(), smart: smart);

      expect(find.byType(CardHelperPanel), findsOneWidget);
      expect(saved.redacted().number, isNot(contains('4111')));
      await tester.tap(find.byKey(const Key('copy-number')));
      await tester.pump();
      expect(log, [pan], reason: 'the number comes from the vault on the tap');
      await env.clipboard.clearNow();
    });

    testWidgets('a redacted card keeps only its last four digits', (tester) async {
      final r = card.redacted();
      expect(r.number, '************1111');
      expect(r.last4, '1111');
      expect(r.masked, '**** **** **** 1111');
      expect(r.toString(), isNot(contains('4111')));
    });
  });
}
