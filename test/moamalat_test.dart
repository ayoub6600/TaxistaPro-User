import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/payments/moamalat/card_helper_panel.dart';
import 'package:taxista/payments/moamalat/card_vault.dart';
import 'package:taxista/payments/moamalat/moamalat_api.dart';
import 'package:taxista/payments/moamalat/moamalat_checkout_page.dart';
import 'package:taxista/payments/moamalat/moamalat_env.dart';
import 'package:taxista/payments/moamalat/moamalat_topup_page.dart';
import 'package:taxista/payments/moamalat/saved_card.dart';
import 'package:taxista/payments/moamalat/saved_cards_page.dart';
import 'package:taxista/payments/moamalat/secure_clipboard.dart';
import 'package:taxista/payments/moamalat/topup_flow.dart';

const visa = '4111111111111111';
const localCard = '6273001234561234';

class FakeApi implements MoamalatApi {
  FakeApi({this.available = true, List<MoamalatStatus>? statuses}) : statuses = statuses ?? [const MoamalatStatus(status: 'pending', credited: false)];

  bool available;
  List<MoamalatStatus> statuses;
  final List<double> initiated = [];
  int statusCalls = 0;
  bool failStatusWithNetwork = false;
  bool cardOnFile = false;

  List<PaymentMethodOption> methodList = const [
    PaymentMethodOption(key: 'qareeb_card', labelAr: 'كروت شحن قريب', labelEn: 'Qareeb recharge cards'),
    PaymentMethodOption(key: 'bank_card', labelAr: 'البطاقة البنكية', labelEn: 'Bank card'),
  ];
  bool failMethods = false;

  @override
  Future<List<PaymentMethodOption>> methods() async {
    if (failMethods) throw const MoamalatException(MoamalatErrorKind.network);
    return methodList;
  }

  @override
  Future<MoamalatOptions> options() async => MoamalatOptions(available: available, currency: 'LYD', minAmount: 5, maxAmount: 2000, cardOnFile: cardOnFile);

  @override
  Future<MoamalatTopUp> initiate(double amount) async {
    initiated.add(amount);
    return MoamalatTopUp(id: 'T1', reference: 'TXPRABC123', amount: amount, currency: 'LYD', paymentUrl: 'https://pay.example/T1');
  }

  @override
  Future<MoamalatStatus> status(String topUpId) async {
    statusCalls++;
    if (failStatusWithNetwork) throw const MoamalatException(MoamalatErrorKind.network);
    final index = (statusCalls - 1).clamp(0, statuses.length - 1);
    return statuses[index];
  }
}

MoamalatEnv makeEnv({FakeApi? api, MemorySecretStore? store, List<String>? clipboardLog, VoidCallback? onWalletChanged}) {
  return MoamalatEnv(
    api: api ?? FakeApi(),
    vault: CardVault(store: store ?? MemorySecretStore(), ownerId: '27'),
    clipboard: SecureClipboard(writer: (text) async => clipboardLog?.add(text)),
    isRtl: true,
    onWalletChanged: onWalletChanged,
  );
}

void main() {
  group('card rules', () {
    test('visa and mastercard must pass the Luhn check, local cards are length-checked only', () {
      expect(CardRules.isNumberValid(visa), isTrue);
      expect(CardRules.isNumberValid('4111 1111 1111 1112'), isFalse);
      expect(CardRules.isNumberValid('5555 5555 5555 4444'), isTrue);
      expect(CardRules.isNumberValid(localCard), isTrue);
      expect(CardRules.isNumberValid('62730012'), isFalse);
      expect(CardRules.isNumberValid('62730012345612341234'), isFalse);
    });

    test('expiry parses MM/YY, rejects nonsense and past months, allows the current month', () {
      final now = DateTime(2026, 9, 26);
      expect(CardRules.parseExpiry('12/28'), (month: 12, year: 2028));
      expect(CardRules.parseExpiry('1228'), (month: 12, year: 2028));
      expect(CardRules.parseExpiry('13/28'), isNull);
      expect(CardRules.isExpiryValid('09/26', now: now), isTrue);
      expect(CardRules.isExpiryValid('08/26', now: now), isFalse);
      expect(CardRules.isExpiryValid('12/60', now: now), isFalse);
    });

    test('a saved card never prints its number', () {
      final card = SavedCard(id: 'a', holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);
      expect(card.toString(), isNot(contains(visa)));
      expect(card.toString(), contains('1111'));
      expect(card.masked, '**** **** **** 1111');
      expect(card.expiryText, '12/28');
    });
  });

  group('card vault', () {
    test('first card becomes the default; the stored value holds no security code', () async {
      final store = MemorySecretStore();
      final vault = CardVault(store: store, ownerId: '27');

      final a = await vault.add(holderName: 'Ali Ben', number: '4111 1111 1111 1111', expMonth: 12, expYear: 2028);
      final b = await vault.add(holderName: 'Ali Ben', number: localCard, expMonth: 1, expYear: 2030, nickname: 'Work');

      final cards = await vault.load();
      expect(cards.map((c) => c.id), [a.id, b.id]);
      expect(cards.first.isDefault, isTrue);
      expect(cards.last.isDefault, isFalse);
      expect(cards.last.title, 'Work');

      final raw = store.data.values.join();
      expect(raw.toLowerCase(), isNot(contains('cvv')));
      expect(raw.toLowerCase(), isNot(contains('cvc')));
      expect(jsonDecode(store.data.values.single).first.keys, isNot(contains('cvv')));
    });

    test('cards are private to the signed-in account', () async {
      final store = MemorySecretStore();
      await CardVault(store: store, ownerId: '27').add(holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);

      expect(await CardVault(store: store, ownerId: '28').load(), isEmpty);
      expect(await CardVault(store: store, ownerId: '27').load(), hasLength(1));
    });

    test('edit, make default and delete behave, and deleting the default hands the role on', () async {
      final vault = CardVault(store: MemorySecretStore(), ownerId: '27');
      final a = await vault.add(holderName: 'A', number: visa, expMonth: 12, expYear: 2028);
      final b = await vault.add(holderName: 'B', number: localCard, expMonth: 12, expYear: 2029);

      await vault.update(b.id, holderName: 'Bee', nickname: 'Spare', expMonth: 6, expYear: 2031);
      var cards = await vault.load();
      final edited = cards.firstWhere((c) => c.id == b.id);
      expect(edited.holderName, 'Bee');
      expect(edited.number, localCard, reason: 'number kept when not replaced');
      expect(edited.expiryText, '06/31');

      await vault.setDefault(b.id);
      cards = await vault.load();
      expect(cards.first.id, b.id);
      expect(cards.where((c) => c.isDefault), hasLength(1));

      await vault.delete(b.id);
      cards = await vault.load();
      expect(cards.single.id, a.id);
      expect(cards.single.isDefault, isTrue);

      await vault.delete(a.id);
      expect(await vault.load(), isEmpty);
    });

    test('quick successive adds are serialised and none is lost', () async {
      final vault = CardVault(store: MemorySecretStore(), ownerId: '27');
      await Future.wait([
        for (var i = 0; i < 5; i++) vault.add(holderName: 'Card $i', number: visa, expMonth: 12, expYear: 2028),
      ]);
      expect(await vault.load(), hasLength(5));
    });

    test('an unreadable blob is treated as no cards, not a crash', () async {
      final store = MemorySecretStore();
      final vault = CardVault(store: store, ownerId: '27');
      await store.write('taxista.moamalat.cards.v1.27', '{not json');
      expect(await vault.load(), isEmpty);
    });
  });

  group('secure clipboard', () {
    test('copied text is cleared after the timeout and by clearNow', () {
      fakeAsync((async) {
        final log = <String>[];
        final clipboard = SecureClipboard(writer: (t) async => log.add(t), clearAfter: const Duration(seconds: 60));

        clipboard.copy(visa);
        async.flushMicrotasks();
        expect(log, [visa]);
        expect(clipboard.holdsSecret, isTrue);

        async.elapse(const Duration(seconds: 59));
        expect(log, [visa]);
        async.elapse(const Duration(seconds: 2));
        expect(log, [visa, '']);
        expect(clipboard.holdsSecret, isFalse);

        clipboard.copy('12/28');
        async.flushMicrotasks();
        clipboard.clearNow();
        async.flushMicrotasks();
        expect(log.last, '');
        // nothing left to clear: no extra write
        final count = log.length;
        clipboard.clearNow();
        async.elapse(const Duration(minutes: 5));
        expect(log.length, count);
      });
    });
  });

  group('top-up flow', () {
    Future<void> noDelay(Duration _) async {}

    test('waits through pending until the server says paid', () async {
      final api = FakeApi(statuses: const [
        MoamalatStatus(status: 'pending', credited: false),
        MoamalatStatus(status: 'pending', credited: false),
        MoamalatStatus(status: 'paid', credited: true),
      ]);
      final outcome = await TopUpFlow(api, delay: noDelay).settle('T1', expectFinal: true);
      expect(outcome, TopUpOutcome.paid);
      expect(api.statusCalls, 3);
    });

    test('failed and cancelled are not paid', () async {
      for (final status in ['failed', 'cancelled']) {
        final api = FakeApi(statuses: [MoamalatStatus(status: status, credited: false)]);
        expect(await TopUpFlow(api, delay: noDelay).settle('T1', expectFinal: true), TopUpOutcome.notPaid);
      }
    });

    test('the server never confirming ends as unconfirmed - bounded, no endless spinner', () async {
      final api = FakeApi();
      final outcome = await TopUpFlow(api, maxWait: const Duration(seconds: 10), delay: noDelay).settle('T1', expectFinal: true);
      expect(outcome, TopUpOutcome.unconfirmed);
      expect(api.statusCalls, lessThan(12));
    });

    test('a flaky network is retried, then gives up as unconfirmed', () async {
      final api = FakeApi()..failStatusWithNetwork = true;
      final outcome = await TopUpFlow(api, maxWait: const Duration(seconds: 8), delay: noDelay).settle('T1', expectFinal: true);
      expect(outcome, TopUpOutcome.unconfirmed);
      expect(api.statusCalls, greaterThan(1));
    });

    test('one quick check is enough when the page said cancel', () async {
      final api = FakeApi();
      expect(await TopUpFlow(api, delay: noDelay).settle('T1', expectFinal: false), TopUpOutcome.notPaid);
      expect(api.statusCalls, 1);
    });
  });

  group('http api', () {
    HttpMoamalatApi apiWith(MockClient client) => HttpMoamalatApi(baseUrl: 'https://api.example/', token: () => 'tok', client: client);

    test('options carry the server\'s card-on-file switch, off unless the server says true', () async {
      Future<MoamalatOptions> read(String body) => apiWith(MockClient((_) async => http.Response(body, 200))).options();
      expect((await read('{"data":{"available":true,"currency":"LYD","min_amount":5,"max_amount":2000,"card_on_file":true}}')).cardOnFile, isTrue);
      expect((await read('{"data":{"available":true,"currency":"LYD","card_on_file":false}}')).cardOnFile, isFalse);
      expect((await read('{"data":{"available":true,"currency":"LYD"}}')).cardOnFile, isFalse, reason: 'an older server says nothing');
      expect((await read('{"data":{"available":true,"card_on_file":"true"}}')).cardOnFile, isFalse, reason: 'only a real true counts');
    });

    test('reads options and sends the bearer token', () async {
      late http.Request seen;
      final api = apiWith(MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode({'success': true, 'data': {'available': true, 'currency': 'LYD', 'min_amount': 5, 'max_amount': 2000}}), 200);
      }));

      final options = await api.options();
      expect(options.available, isTrue);
      expect(options.currency, 'LYD');
      expect(options.maxAmount, 2000);
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(seen.url.path, '/api/v1/payment/moamalat/options');
    });

    test('initiate maps refusals to clear errors and network loss to network', () async {
      Future<MoamalatErrorKind> kindFor(MockClient client) async {
        try {
          await apiWith(client).initiate(50);
        } on MoamalatException catch (e) {
          return e.kind;
        }
        fail('expected an exception');
      }

      expect(await kindFor(MockClient((_) async => http.Response('{}', 403))), MoamalatErrorKind.unavailable);
      expect(await kindFor(MockClient((_) async => http.Response('{}', 400))), MoamalatErrorKind.invalidAmount);
      expect(await kindFor(MockClient((_) async => http.Response('{}', 401))), MoamalatErrorKind.unauthorized);
      expect(await kindFor(MockClient((_) async => http.Response('oops', 500))), MoamalatErrorKind.server);
      expect(await kindFor(MockClient((_) async => throw const SocketException('down'))), MoamalatErrorKind.network);
    });

    test('initiate returns the payment url and reference; status reports credited only when the server does', () async {
      final api = apiWith(MockClient((request) async {
        if (request.url.path.endsWith('/initiate')) {
          expect(jsonDecode(request.body), {'amount': 50.0});
          return http.Response(jsonEncode({'data': {'topup_id': 'T9', 'reference': 'TXPR1', 'amount': 50, 'currency': 'LYD', 'payment_url': 'https://x/pay'}}), 200);
        }
        return http.Response(jsonEncode({'data': {'status': 'paid', 'credited': true}}), 200);
      }));

      final start = await api.initiate(50);
      expect(start.id, 'T9');
      expect(start.paymentUrl, 'https://x/pay');
      final status = await api.status('T9');
      expect(status.credited, isTrue);
    });
  });

  group('saved cards screen', () {
    testWidgets('add a card once: shown masked, stored locally, no security code field', (tester) async {
      final store = MemorySecretStore();
      final env = makeEnv(store: store);
      await tester.pumpWidget(MaterialApp(home: SavedCardsPage(env: env)));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد بطاقات محفوظة'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-card')));
      await tester.pumpAndSettle();
      expect(find.textContaining('CVV'), findsWidgets); // only the "we never store it" note
      expect(find.byKey(const Key('card-cvv')), findsNothing);

      await tester.enterText(find.byKey(const Key('card-holder')), 'Ali Ben Salem');
      await tester.enterText(find.byKey(const Key('card-number')), visa);
      await tester.enterText(find.byKey(const Key('card-expiry')), '1228');
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();

      expect(find.text('**** **** **** 1111'), findsOneWidget);
      expect(find.textContaining('4111 1111'), findsNothing);
      expect(find.textContaining(visa), findsNothing);
      expect(find.text('افتراضية'), findsOneWidget);
      expect(find.textContaining('Ali Ben Salem'), findsOneWidget);
      expect(find.textContaining('12/28'), findsOneWidget);

      final cards = await env.vault.load();
      expect(cards.single.number, visa);
    });

    testWidgets('invalid input is refused with inline errors and nothing is saved', (tester) async {
      final env = makeEnv();
      await tester.pumpWidget(MaterialApp(home: SavedCardsPage(env: env)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-card')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('card-holder')), 'A');
      await tester.enterText(find.byKey(const Key('card-number')), '4111111111111112');
      await tester.enterText(find.byKey(const Key('card-expiry')), '0120');
      await tester.tap(find.byKey(const Key('save-card')));
      await tester.pumpAndSettle();

      expect(find.text('أدخل اسم حامل البطاقة'), findsOneWidget);
      expect(find.text('رقم البطاقة غير صحيح'), findsOneWidget);
      expect(find.text('تاريخ الانتهاء غير صحيح أو منتهٍ'), findsOneWidget);
      expect(await env.vault.load(), isEmpty);
    });

    testWidgets('an existing card can be made default, edited and deleted', (tester) async {
      final env = makeEnv();
      final a = await env.vault.add(holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);
      final b = await env.vault.add(holderName: 'Sara', number: localCard, expMonth: 11, expYear: 2029);
      await tester.pumpWidget(MaterialApp(home: SavedCardsPage(env: env)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('card-menu-${b.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعيين كافتراضية'));
      await tester.pumpAndSettle();
      expect((await env.vault.load()).first.id, b.id);

      await tester.tap(find.byKey(Key('card-menu-${a.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
      expect((await env.vault.load()).map((c) => c.id), [b.id]);
    });
  });

  group('card helper panel', () {
    const card = SavedCard(id: 'a', holderName: 'Ali Ben', number: visa, expMonth: 12, expYear: 2028);

    Future<void> pumpPanel(WidgetTester tester, MoamalatEnv env, {SavedCard c = card}) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: CardHelperPanel(env: env, card: c))));

    testWidgets('shows only the masked number and copies the real values on request', (tester) async {
      final log = <String>[];
      final env = makeEnv(clipboardLog: log);
      await pumpPanel(tester, env);

      expect(find.text('بطاقتك المحفوظة'), findsOneWidget);
      expect(find.text('**** **** **** 1111'), findsWidgets);
      expect(find.textContaining(visa), findsNothing);

      await tester.tap(find.byKey(const Key('copy-number')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('copy-expiry')));
      await tester.pump();

      expect(log, [visa, '12/28']);
      expect(find.textContaining(visa), findsNothing, reason: 'the full number is never drawn on screen');
      expect(env.clipboard.holdsSecret, isTrue);
      await env.clipboard.clearNow();
      expect(log.last, '');
    });

    testWidgets('is one slim bar by default and shows the masked details only when opened', (tester) async {
      final env = makeEnv();
      await pumpPanel(tester, env);

      expect(find.text('12/28'), findsNothing);
      expect(find.byKey(const Key('copy-number')), findsOneWidget);
      expect(find.byKey(const Key('copy-expiry')), findsOneWidget);
      expect(find.byKey(const Key('copy-name')), findsOneWidget);

      await tester.tap(find.byKey(const Key('helper-toggle')));
      await tester.pump();
      expect(find.text('12/28'), findsOneWidget);
      expect(find.text('Ali Ben'), findsWidgets);
      expect(find.textContaining(visa), findsNothing);
    });

    testWidgets('one tap copies each detail and the next one is offered: number, expiry, name', (tester) async {
      final log = <String>[];
      final env = makeEnv(clipboardLog: log);
      await pumpPanel(tester, env);

      Widget button(String key) => tester.widget(find.byKey(Key(key)));
      expect(button('copy-number'), isA<FilledButton>());
      expect(button('copy-expiry'), isA<OutlinedButton>());

      await tester.tap(find.byKey(const Key('copy-number')));
      await tester.pump();
      expect(button('copy-expiry'), isA<FilledButton>());
      expect(button('copy-number'), isA<OutlinedButton>());

      await tester.tap(find.byKey(const Key('copy-expiry')));
      await tester.pump();
      expect(button('copy-name'), isA<FilledButton>());

      await tester.tap(find.byKey(const Key('copy-name')));
      await tester.pump();
      expect(log, [visa, '12/28', 'Ali Ben']);
      for (final key in ['copy-number', 'copy-expiry', 'copy-name']) {
        expect(button(key), isA<OutlinedButton>(), reason: 'nothing left to suggest');
      }
      await env.clipboard.clearNow();
    });

    testWidgets('fits a narrow phone in both languages, with and without the details open', (tester) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      addTearDown(tester.view.reset);
      for (final rtl in [true, false]) {
        final env = MoamalatEnv(
          api: FakeApi(),
          vault: CardVault(store: MemorySecretStore(), ownerId: '27'),
          clipboard: SecureClipboard(writer: (_) async {}),
          isRtl: rtl,
        );
        await pumpPanel(tester, env);
        await tester.tap(find.byKey(const Key('copy-number')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('helper-toggle')));
        await tester.pump();
        final problem = tester.takeException();
        expect(problem, isNull, reason: 'no overflow at 320 dp (rtl=$rtl): ${problem is FlutterError ? problem.toStringDeep() : problem}');
        expect(tester.getSize(find.byType(CardHelperPanel)).width, lessThanOrEqualTo(320));
        await env.clipboard.clearNow(); // cancels the auto-clear timer
      }
    });

    testWidgets('a card with no holder name offers no name button', (tester) async {
      final env = makeEnv();
      await pumpPanel(tester, env, c: const SavedCard(id: 'b', holderName: '', number: visa, expMonth: 12, expYear: 2028));
      expect(find.byKey(const Key('copy-name')), findsNothing);
      expect(find.byKey(const Key('copy-number')), findsOneWidget);
    });
  });

  group('top-up flow', () {
    testWidgets('an amount outside the server limits is refused before any request', (tester) async {
      final api = FakeApi();
      final env = makeEnv(api: api);
      await tester.pumpWidget(MaterialApp(home: MoamalatTopUpPage(env: env, options: await api.options())));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('topup-amount')), '1');
      await tester.tap(find.byKey(const Key('topup-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topup-error')), findsOneWidget);
      expect(api.initiated, isEmpty);
    });

    testWidgets('Arabic-Indic digits are accepted and the amount reaches the server once', (tester) async {
      final api = FakeApi();
      final env = makeEnv(api: api);
      await tester.pumpWidget(MaterialApp(
        home: MoamalatTopUpPage(
          env: env,
          options: await api.options(),
          checkoutViewBuilder: (context, {required url, required onMessage, required onLoaded, required onLoadError}) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
            return Text(url, key: const Key('payment-view'));
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('topup-amount')), '٥٠');
      await tester.tap(find.byKey(const Key('topup-continue')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('topup-continue')), warnIfMissed: false); // double tap
      await tester.pumpAndSettle();

      expect(api.initiated, [50.0]);
      expect(find.byKey(const Key('payment-view')), findsOneWidget); // checkout opened on the server's payment url
      expect(find.text('https://pay.example/T1'), findsOneWidget);
    });
  });

  group('checkout page', () {
    late void Function(String) send;

    PaymentViewBuilder fakeView({bool loads = true}) => (context, {required url, required onMessage, required onLoaded, required onLoadError}) {
          send = onMessage;
          if (loads) WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
          return Container(key: const Key('payment-view'), color: Colors.grey);
        };

    Future<TopUpOutcome?> open(WidgetTester tester, {required MoamalatEnv env, SavedCard? card, bool loads = true, Duration? settle, bool cardOnFile = false, Duration? autoClose}) async {
      TopUpOutcome? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () async {
                result = await Navigator.of(context).push<TopUpOutcome>(MaterialPageRoute(
                  builder: (_) => MoamalatCheckoutPage(
                    env: env,
                    card: card,
                    cardOnFile: cardOnFile,
                    autoCloseAfter: autoClose ?? const Duration(hours: 1),
                    viewBuilder: fakeView(loads: loads),
                    settleTimeout: settle ?? Duration.zero,
                    loadTimeout: const Duration(seconds: 2),
                    topUp: const MoamalatTopUp(id: 'T1', reference: 'TXPRABC123', amount: 50, currency: 'LYD', paymentUrl: 'https://pay.example/T1'),
                  ),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('shows the saved card helper above the payment page', (tester) async {
      final env = makeEnv();
      const card = SavedCard(id: 'a', holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);
      await open(tester, env: env, card: card);

      expect(find.byType(CardHelperPanel), findsOneWidget);
      expect(find.byKey(const Key('payment-view')), findsOneWidget);
    });

    testWidgets('success is reported only after the server confirms it, then the wallet reloads', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'paid', credited: true)]);
      final env = makeEnv(api: api);
      await open(tester, env: env);

      send('done');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result-title')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('result-title'))).data, 'تمت إضافة الرصيد');
      expect(tester.widget<Text>(find.byKey(const Key('result-body'))).data, contains('50 LYD'));
    });

    testWidgets('a page that says "done" while the server says nothing was credited is NOT shown as success', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'needs_review', credited: false)]);
      final env = makeEnv(api: api);
      await open(tester, env: env);

      send('done');
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('result-title'))).data, 'لم نتمكن من تأكيد الدفع بعد');
      expect(tester.widget<Text>(find.byKey(const Key('result-body'))).data, contains('TXPRABC123'));
      expect(find.byKey(const Key('recheck')), findsOneWidget);
    });

    testWidgets('cancel and error credit nothing and read as not completed', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'cancelled', credited: false)]);
      final env = makeEnv(api: api);
      await open(tester, env: env);

      send('cancel');
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('result-title'))).data, 'لم تكتمل عملية الدفع');
    });

    testWidgets('a second message from the page does not start a second confirmation', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'paid', credited: true)]);
      final env = makeEnv(api: api);
      await open(tester, env: env);

      send('done');
      send('done');
      send('cancel');
      await tester.pumpAndSettle();

      expect(api.statusCalls, 1);
    });

    testWidgets('a payment page that never loads shows a retry state instead of a blank screen', (tester) async {
      final env = makeEnv();
      await open(tester, env: env, loads: false);
      await tester.pump(const Duration(seconds: 3));

      expect(find.byKey(const Key('retry-load')), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry-load')));
      await tester.pump();
      expect(find.byKey(const Key('retry-load')), findsNothing);
    });

    testWidgets('closing the page after paying but before the message still asks the server', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'paid', credited: true)]);
      final env = makeEnv(api: api);
      await open(tester, env: env);

      await tester.tap(find.byKey(const Key('checkout-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إغلاق').last);
      await tester.pumpAndSettle();

      expect(api.statusCalls, 1);
      expect(find.byKey(const Key('open')), findsOneWidget, reason: 'returned to the previous screen');
    });

    testWidgets('after a confirmed payment the customer is returned to the wallet on their own', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'paid', credited: true)]);
      final env = makeEnv(api: api);
      await open(tester, env: env, autoClose: const Duration(seconds: 2));

      send('done');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result-title')), findsOneWidget);
      expect(find.byKey(const Key('auto-return-note')), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result-title')), findsNothing);
      expect(find.byKey(const Key('open')), findsOneWidget, reason: 'back on the previous screen');
    });

    testWidgets('a payment that is not confirmed stays on screen until the customer decides', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'needs_review', credited: false)]);
      final env = makeEnv(api: api);
      await open(tester, env: env, autoClose: const Duration(seconds: 1));

      send('done');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      expect(find.byKey(const Key('result-title')), findsOneWidget);
      expect(find.byKey(const Key('auto-return-note')), findsNothing);
      expect(find.byKey(const Key('recheck')), findsOneWidget);
    });

    testWidgets('the Done button still returns immediately and the timer does not pop twice', (tester) async {
      final api = FakeApi(statuses: const [MoamalatStatus(status: 'paid', credited: true)]);
      final env = makeEnv(api: api);
      await open(tester, env: env, autoClose: const Duration(seconds: 2));

      send('done');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('result-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open')), findsOneWidget);

      await tester.pump(const Duration(seconds: 5)); // a late timer must not pop the screen underneath
      expect(find.byKey(const Key('open')), findsOneWidget);
    });

    testWidgets('when the bank keeps cards, a customer with no saved card is told to pick theirs on the page', (tester) async {
      final env = makeEnv();
      await open(tester, env: env, cardOnFile: true);
      expect(find.byKey(const Key('card-on-file-hint')), findsOneWidget);
      expect(find.byType(CardHelperPanel), findsNothing);
    });

    testWidgets('no hint when the bank does not keep cards, and no hint next to the device helper', (tester) async {
      await open(tester, env: makeEnv(), cardOnFile: false);
      expect(find.byKey(const Key('card-on-file-hint')), findsNothing);
    });

    testWidgets('a device-saved card keeps its helper even when the bank keeps cards', (tester) async {
      const card = SavedCard(id: 'a', holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);
      await open(tester, env: makeEnv(), card: card, cardOnFile: true);
      expect(find.byType(CardHelperPanel), findsOneWidget);
      expect(find.byKey(const Key('card-on-file-hint')), findsNothing);
    });

    testWidgets('leaving the payment screen clears a copied card number from the clipboard', (tester) async {
      final log = <String>[];
      final env = makeEnv(clipboardLog: log);
      // The checkout only keeps a redacted copy; the real number is read from the vault on the tap.
      final saved = await env.vault.add(holderName: 'Ali', number: visa, expMonth: 12, expYear: 2028);
      await open(tester, env: env, card: saved.redacted());

      await tester.tap(find.byKey(const Key('copy-number')));
      await tester.pump();
      expect(log, [visa]);

      await tester.tap(find.byKey(const Key('checkout-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إغلاق').last);
      await tester.pumpAndSettle();

      expect(log.last, '');
    });
  });
}
