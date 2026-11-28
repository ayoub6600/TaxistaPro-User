import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/ambassadors/ambassador_home_card.dart';
import 'package:taxista/ambassadors/ambassadors_api.dart';
import 'package:taxista/ambassadors/ambassadors_pages.dart';
import 'package:taxista/ambassadors/ambassadors_sheets.dart';
import 'package:taxista/functions/functions.dart' as app;
import 'package:taxista/functions/invite_link.dart';
import 'package:taxista/pages/referralcode/invite_welcome_page.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json; charset=utf-8'});

http.Response _ok(Map<String, dynamic> data) => _json({'success': true, 'data': data});

const _share = 'جرّب تاكسيستا وسجّل من رابطي وتاخذ خصم 2 د.ل على أول مشوار: https://taxista.aljidartech.com/i/67084';

Map<String, dynamic> _none({bool canJoin = true, String? note}) => {
      'enabled': true,
      'status': 'none',
      'can_join': canJoin,
      'join_note': note,
      'rules': {'pct': 1.0, 'share_of_profit': 10, 'months': 6, 'invitee_lyd': 2.0},
      'gold': {'enabled': true, 'price_lyd': 250.0, 'pct': 2.0, 'share_of_profit': 20, 'months': 6, 'active': false, 'until_label': null, 'wallet_lyd': 5.6, 'short_lyd': 244.4},
      'code': null,
      'links': null,
      'share_text': null,
      'jar': null,
      'friends': [],
      'withdraw': {'allowed': false, 'min_lyd': 20.0, 'available_lyd': 0.0, 'note': 'السحب للسفير الذهبي', 'requests': []},
      'home_card': {'show': true, 'title': 'ولّي سفير تاكسيستا', 'sub': 'جيب صحابك واكسب من مشاويرهم'},
    };

Map<String, dynamic> _active({
  bool goldActive = false,
  double wallet = 5.6,
  double short = 244.4,
  bool withdrawAllowed = false,
  double available = 0,
  List<Map<String, dynamic>> requests = const [],
}) =>
    {
      ..._none(),
      'status': 'active',
      'can_join': false,
      'gold': {
        'enabled': true,
        'price_lyd': 250.0,
        'pct': 2.0,
        'share_of_profit': 20,
        'months': 6,
        'active': goldActive,
        'until_label': goldActive ? '28 مايو 2027' : null,
        'wallet_lyd': wallet,
        'short_lyd': short,
      },
      'code': '67084',
      'links': {'rider': 'https://taxista.aljidartech.com/i/67084', 'captain': 'https://taxista.aljidartech.com/captain/join/67084'},
      'share_text': _share,
      'jar': {'total_lyd': 9.6, 'week_lyd': 1.8, 'friends': 7, 'rides': 64},
      'friends': [
        {'name': 'سالم', 'kind': 'rider', 'rides': 6, 'earned_lyd': 0.9, 'state_text': 'باقي 5 شهور'},
        {'name': 'مريم', 'kind': 'rider', 'rides': 0, 'earned_lyd': 0, 'state_text': 'سجّلت، تستنى أول مشوار'},
        {'name': 'عبدالله', 'kind': 'driver', 'rides': 41, 'earned_lyd': 6.15, 'state_text': 'كابتن · باقي 4 شهور'},
      ],
      'withdraw': {'allowed': withdrawAllowed, 'min_lyd': 20.0, 'available_lyd': available, 'note': withdrawAllowed ? null : 'السحب للسفير الذهبي', 'requests': requests},
      'home_card': {'show': true, 'title': 'جيب صحابك واكسب', 'sub': 'كودك 67084 · كسبت 9.60 د.ل'},
    };

void main() {
  late List<http.Request> requests;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    requests = [];
    AmbassadorsApi.resetForTest();
    SharedPreferences.setMockInitialValues({});
    app.bearerToken = [app.BearerClass(type: 'Bearer', token: 'test-token')];
    app.languageDirection = 'rtl';
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// the app's Button ignores a second tap within 700 ms (real time)
  Future<void> waitTapLock(WidgetTester tester) => tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 750)));

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // ------------------------------------------------------------------ parsing

  group('parsing', () {
    test('not yet an ambassador: no code, no links, no jar, no friends', () {
      final s = AmbassadorState.fromJson(_none())!;
      expect(s.enabled, isTrue);
      expect(s.active, isFalse);
      expect(s.canJoin, isTrue);
      expect(s.code, isNull);
      expect(s.riderLink, isNull);
      expect(s.captainLink, isNull);
      expect(s.shareText, isNull);
      expect(s.jar, isNull);
      expect(s.friends, isEmpty);
      expect(s.rules.pct, 1.0);
      expect(s.rules.shareOfProfit, 10);
      expect(s.rules.months, 6);
      expect(s.rules.inviteeLyd, 2.0);
      expect(s.gold.short, isTrue);
      expect(s.withdraw.allowed, isFalse);
      expect(s.withdraw.canAsk, isFalse);
      expect(s.homeCard.show, isTrue);
      expect(s.sharePct, 10);
    });

    test('an ambassador: code, links, the share text as is, jar, friends, requests', () {
      final s = AmbassadorState.fromJson(_active(goldActive: true, withdrawAllowed: true, available: 64, requests: [
        {'id': 3, 'amount_lyd': 50.0, 'status': 'pending', 'status_text': 'تحت التحويل', 'at': '2026-11-28T10:00:00+02:00', 'bank': 'مصرف الجمهورية'},
      ]))!;
      expect(s.active, isTrue);
      expect(s.code, '67084');
      expect(s.riderLink, 'https://taxista.aljidartech.com/i/67084');
      expect(s.captainLink, 'https://taxista.aljidartech.com/captain/join/67084');
      expect(s.shareText, _share);
      expect(s.jar!.totalLyd, 9.6);
      expect(s.jar!.friends, 7);
      expect(s.friends.map((f) => f.captain), [false, false, true]);
      expect(s.friends.last.stateText, 'كابتن · باقي 4 شهور');
      expect(s.sharePct, 20);
      expect(s.withdraw.canAsk, isTrue);
      final r = s.withdraw.requests.single;
      expect(r.status, 'pending');
      expect(r.at!.toUtc(), DateTime.utc(2026, 11, 28, 8));
      expect(r.bank, 'مصرف الجمهورية');
    });

    test('numbers as strings, missing blocks and nulls do not break it', () {
      final s = AmbassadorState.fromJson({
        'enabled': 1,
        'status': 'active',
        'rules': {'pct': '1.0', 'share_of_profit': '10', 'months': '6', 'invitee_lyd': '2'},
        'gold': null,
        'code': 67084,
        'links': {'rider': null},
        'jar': {'total_lyd': '9.60', 'friends': '7'},
        'friends': [null, {'name': 'سالم', 'rides': '6'}],
        'withdraw': null,
        'home_card': {'show': true, 'title': ''},
      })!;
      expect(s.enabled, isTrue);
      expect(s.rules.pct, 1.0);
      expect(s.code, '67084');
      expect(s.riderLink, isNull);
      expect(s.jar!.totalLyd, 9.6);
      expect(s.friends.single.rides, 6);
      expect(s.friends.single.kind, 'rider');
      expect(s.gold.enabled, isFalse);
      expect(s.withdraw.requests, isEmpty);
      expect(s.homeCard.show, isFalse, reason: 'a card without a title is not shown');
      expect(AmbassadorState.fromJson(null), isNull);
    });

    test('words: percents, months, rides, the friend\'s discount', () {
      expect(ambNum(1.0), '1');
      expect(ambNum(1.5), '1.5');
      expect(ambNum(20), '20');
      expect(ambMonths(6), '6 شهور');
      expect(ambMonths(2), 'شهرين');
      expect(ambRides(6), '6 مشاوير');
      expect(ambRides(41), '41 مشوار');
      expect(ambRides(1), 'مشوار واحد');
      expect(inviteeDiscount('2 دينار'), '2 د.ل');
      expect(inviteeDiscount('2.5 دينار'), '2.50 د.ل');
      expect(inviteeDiscount('٣ دينار'), '3 د.ل');
      expect(inviteeDiscount(null), isNull, reason: 'the admin turned it off: nothing promised');
      expect(inviteeDiscount('20 جنيه'), '20 جنيه');
    });

    test('the server\'s words on 422, a plain «try again» otherwise, «الشبكة ضعيفة» offline', () async {
      var reply = http.Response('', 200);
      Object? thrown;
      await http.runWithClient(() async {
        reply = _json({'message': 'لازم تكمّل مشوار واحد على الأقل باش تولّي سفير.'}, 422);
        var r = await AmbassadorsApi.join();
        expect(r.ok, isFalse);
        expect(r.status, 422);
        expect(r.error, 'لازم تكمّل مشوار واحد على الأقل باش تولّي سفير.');

        reply = _json({'message': 'Server Error'}, 500);
        r = await AmbassadorsApi.me();
        expect(r.error, AmbassadorsApi.failed);

        thrown = Exception('offline');
        r = await AmbassadorsApi.me();
        expect(r.status, 0);
        expect(r.error, AmbassadorsApi.offline);
        thrown = null;

        reply = _ok(_active());
        r = await AmbassadorsApi.me();
        expect(r.ok, isTrue);
        expect(AmbassadorsApi.state.value!.code, '67084', reason: 'every good answer feeds the menu and the home card');
      }, () => MockClient((request) async {
            requests.add(request);
            if (thrown != null) throw thrown!;
            return reply;
          }));
      expect(requests.first.url.path, endsWith('api/v1/ambassadors/join'));
      expect(requests.first.method, 'POST');
      expect(requests.first.headers['Authorization'], 'Bearer test-token');
      expect(requests[1].url.path, endsWith('api/v1/ambassadors/me'));
    });

    test('another account on this phone never sees the last one\'s code', () async {
      await http.runWithClient(() async {
        await AmbassadorsApi.me();
        expect(AmbassadorsApi.state.value!.code, '67084');
        app.bearerToken = [app.BearerClass(type: 'Bearer', token: 'other-account')];
        final r = await AmbassadorsApi.me();
        expect(r.ok, isFalse);
        expect(AmbassadorsApi.state.value, isNull);
        expect(AmbassadorsApi.homeCard.value, isNull);
      }, () => MockClient((request) async => request.headers['Authorization'] == 'Bearer test-token' ? _ok(_active()) : http.Response('', 500)));
    });

    test('a key per purchase: 8-64 of [A-Za-z0-9_-], never the same twice', () {
      final a = AmbassadorsApi.newKey(), b = AmbassadorsApi.newKey();
      expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(a), isTrue);
      expect(a == b, isFalse);
    });

    test('withdraw form: the first thing to fix', () {
      String? check({String amount = '50', String bank = 'مصرف الجمهورية', String name = 'سالم علي', String number = '0912345678'}) =>
          AmbassadorWithdrawSheet.check(amount: amount, bank: bank, name: name, number: number, min: 20, available: 64);
      expect(check(), isNull);
      expect(check(amount: ''), 'اكتب المبلغ اللي تبي تسحبه.');
      expect(check(amount: 'abc'), 'اكتب المبلغ اللي تبي تسحبه.');
      expect(check(amount: '10'), 'أقل سحب 20 د.ل.');
      expect(check(amount: '64.5'), 'تقدر تسحب لين 64 د.ل بس.');
      expect(check(amount: '٦٤'), isNull);
      expect(check(amount: '20,5'), isNull);
      expect(check(bank: ' '), 'اكتب اسم المصرف (أو LYPay).');
      expect(check(name: 'س'), 'اكتب اسم صاحب الحساب كامل.');
      expect(check(number: '12'), 'اكتب رقم الحساب أو رقم LYPay صح.');
      expect(check(number: '0912 345 678'), isNull);
      expect(check(number: 'LY83 0020 4800 0020 1012 0145'), isNull);
      expect(check(number: '091234567#'), 'اكتب رقم الحساب أو رقم LYPay صح.');
    });
  });

  // ------------------------------------------------------------------ the page

  testWidgets('not yet: the rules in profit words and «ولّي سفير» joins, then his code', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
      await settle(tester);
      expect(find.text('جيب صحابك، واكسب من كل مشوار'), findsOneWidget);
      expect(find.textContaining('10% من ربح تاكسيستا'), findsWidgets);
      expect(find.textContaining('1% من سعر المشوار'), findsWidgets);
      expect(find.textContaining('خصم 2 د.ل على أول مشوار'), findsOneWidget);
      expect(find.textContaining('مثال: صاحبك دار مشوار بـ20 د.ل ← تاخذ منه 0.20 د.ل'), findsOneWidget);
      expect(find.text('67084'), findsNothing);

      await tester.tap(find.text('ولّي سفير'));
      await settle(tester);
      expect(find.text('67084'), findsOneWidget);
      expect(find.text('شارك في واتساب'), findsOneWidget);
      expect(find.text('انسخ الرابط'), findsOneWidget);
      expect(find.textContaining('مبروك، ولّيت سفير تاكسيستا'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async {
          requests.add(request);
          return _ok(request.url.path.endsWith('join') ? _active() : _none());
        }));
    expect(requests.where((r) => r.method == 'POST').single.url.path, endsWith('ambassadors/join'));
  });

  testWidgets('not yet and cannot join: the server\'s note instead of the button', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
      await settle(tester);
      expect(find.text('كمّل أول مشوار مع تاكسيستا وبعدها تولّي سفير.'), findsOneWidget);
      expect(find.text('ولّي سفير'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok(_none(canJoin: false, note: 'كمّل أول مشوار مع تاكسيستا وبعدها تولّي سفير.'))));
  });

  testWidgets('revoked with gold earnings left: the note, and the way to withdraw stays', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
      await settle(tester);
      expect(find.text('وقفنا حساب السفير متاعك.'), findsOneWidget);
      expect(find.text('ولّي سفير'), findsNothing);
      expect(find.text('عندك 30 د.ل تقدر تسحبها'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok({
          ..._none(canJoin: false, note: 'وقفنا حساب السفير متاعك.'),
          'status': 'revoked',
          'withdraw': {'allowed': true, 'min_lyd': 20.0, 'available_lyd': 30.0, 'note': null, 'requests': []},
        })));
  });

  testWidgets('switched off on the server: nothing to do here', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
      await settle(tester);
      expect(find.textContaining('سفراء تاكسيستا مش متاحة توا'), findsOneWidget);
      expect(find.text('ولّي سفير'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok({..._none(), 'enabled': false})));
  });

  testWidgets('active: code, QR, stats, friends, gold card; share sends share_text as is, copy the link', (tester) async {
    bigScreen(tester);
    MethodCall? shared;
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (c) async {
      shared = c;
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
      await settle(tester);
      expect(find.text('67084'), findsOneWidget);
      expect(find.byKey(const ValueKey('amb-qr')), findsOneWidget);
      expect(find.text('taxista.aljidartech.com/i/67084'), findsOneWidget);
      expect(find.textContaining('10% من ربح تاكسيستا، لمدة 6 شهور'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('9.60'), findsOneWidget);
      expect(find.text('هذا الأسبوع: +1.80 د.ل · تنزل في محفظتك كل أسبوع'), findsOneWidget);
      expect(find.text('سالم'), findsOneWidget);
      expect(find.text('6 مشاوير · باقي 5 شهور'), findsOneWidget);
      expect(find.text('+0.90'), findsOneWidget);
      expect(find.text('سجّلت، تستنى أول مشوار'), findsOneWidget);
      expect(find.text('كابتن عبدالله'), findsOneWidget);
      expect(find.text('41 مشوار · باقي 4 شهور'), findsOneWidget, reason: 'the name says كابتن once');
      expect(find.text('+6.15'), findsOneWidget);
      expect(find.text('20% من ربح تاكسيستا، وتقدر تسحب فلوسك'), findsOneWidget);
      expect(find.textContaining('السحب للسفير الذهبي بس'), findsOneWidget);

      await tester.tap(find.text('شارك في واتساب'));
      await settle(tester);
      final args = Map<String, dynamic>.from(shared!.arguments as Map);
      expect(args['text'], _share);
      expect(args['originX'], greaterThanOrEqualTo(0));
      expect(args['originY'], greaterThanOrEqualTo(0));
      expect(args['originWidth'], greaterThan(0));

      await tester.tap(find.text('انسخ الرابط'));
      await settle(tester);
      expect(copied, 'https://taxista.aljidartech.com/i/67084');
      expect(find.text('تم نسخ الرابط ✓'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('amb-gold-card')));
      await settle(tester);
      expect(find.text('السفير الذهبي'), findsOneWidget);
      expect(find.text('العادي · ببلاش'), findsOneWidget);
      expect(find.text('الذهبي · 250 د.ل'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok(_active())));
  });

  // ------------------------------------------------------------------ gold

  testWidgets('gold, wallet short: the note and «اشحن واشترك» opens the wallet, then asks again', (tester) async {
    bigScreen(tester);
    var wallets = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: AmbassadorGoldPage(openWallet: (_) async => wallets++)));
      await settle(tester);
      expect(find.text('ينخصم من محفظتك. محفظتك فيها 5.60، تحتاج تشحن 244.40 الأول.'), findsOneWidget);
      expect(find.text('اشترك في الذهبي'), findsNothing);
      await tester.tap(find.text('اشحن واشترك في الذهبي'));
      await settle(tester);
      expect(wallets, 1);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async {
          requests.add(request);
          return _ok(_active());
        }));
    expect(requests.where((r) => r.url.path.endsWith('ambassadors/me')).length, 2, reason: 'on opening, and back from the wallet');
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('gold, enough in the wallet: confirm, one key, then «انت سفير ذهبي»', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorGoldPage()));
      await settle(tester);
      expect(find.text('ينخصم 250 د.ل من محفظتك. محفظتك فيها 300 د.ل.'), findsOneWidget);
      await tester.tap(find.text('اشترك في الذهبي'));
      await settle(tester);
      expect(find.text('تشترك في السفير الذهبي؟'), findsOneWidget);
      await tester.tap(find.text('اشترك بـ250 د.ل'));
      await settle(tester);
      expect(find.text('تشترك في السفير الذهبي؟'), findsNothing);
      expect(find.text('انت سفير ذهبي ✓'), findsOneWidget);
      expect(find.text('اشتراكك ماشي لين 28 مايو 2027'), findsOneWidget);
      expect(find.text('مبروك! ولّيت سفير ذهبي ✓'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') return _ok(_active(goldActive: true, wallet: 50, short: 0, withdrawAllowed: true));
          return _ok(_active(wallet: 300, short: 0));
        }));
    final post = requests.singleWhere((r) => r.method == 'POST');
    expect(post.url.path, endsWith('ambassadors/gold'));
    expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch((jsonDecode(post.body) as Map)['key'] as String), isTrue);
  });

  testWidgets('gold refused because the wallet is short: the server\'s words and «اشحن محفظتك»', (tester) async {
    bigScreen(tester);
    var wallets = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: AmbassadorGoldPage(openWallet: (_) async => wallets++)));
      await settle(tester);
      await tester.tap(find.text('اشترك في الذهبي'));
      await settle(tester);
      await tester.tap(find.text('اشترك بـ250 د.ل'));
      await settle(tester);
      expect(find.text('محفظتك فيها 5.60 د.ل، اشحن 244.40 الأول'), findsOneWidget);
      await tester.tap(find.text('اشحن محفظتك'));
      await settle(tester);
      expect(wallets, 1);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async {
          if (request.method == 'POST') return _json({'message': 'محفظتك فيها 5.60 د.ل، اشحن 244.40 الأول'}, 422);
          return _ok(_active(wallet: 300, short: 0));
        }));
  });

  testWidgets('withdraw sheet: checks each field, then sends the request with its key', (tester) async {
    bigScreen(tester);
    final last = {'id': 3, 'amount_lyd': 50.0, 'status': 'paid', 'status_text': 'اتحوّلت ✓', 'at': '2026-11-20T10:00:00+02:00', 'bank': 'مصرف الجمهورية'};
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorGoldPage()));
      await settle(tester);
      expect(find.text('64 د.ل'), findsOneWidget);
      expect(find.text('اتحوّلت ✓'), findsOneWidget);
      await tester.tap(find.text('اسحب أرباحك'));
      await settle(tester);
      expect(find.text('تقدر تسحب لين 64 د.ل · أقل سحب 20 د.ل'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'مصرف الجمهورية'), findsOneWidget, reason: 'the bank of his last request');

      Future<void> send() async {
        await tester.tap(find.text('ابعت طلب السحب'));
        await settle(tester);
        await waitTapLock(tester);
      }

      await send();
      expect(find.text('اكتب المبلغ اللي تبي تسحبه.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('amb-w-amount')), '10');
      await send();
      expect(find.text('أقل سحب 20 د.ل.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('amb-w-amount')), '100');
      await send();
      expect(find.text('تقدر تسحب لين 64 د.ل بس.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('amb-w-amount')), '50');
      await send();
      expect(find.text('اكتب اسم صاحب الحساب كامل.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('amb-w-name')), 'سالم علي');
      await tester.enterText(find.byKey(const ValueKey('amb-w-number')), '12');
      await send();
      expect(find.text('اكتب رقم الحساب أو رقم LYPay صح.'), findsOneWidget);
      expect(requests.where((r) => r.method == 'POST'), isEmpty, reason: 'nothing leaves the phone while a field is wrong');

      await tester.enterText(find.byKey(const ValueKey('amb-w-number')), '0912 345 678');
      await send();
      expect(find.text('ابعت طلب السحب'), findsNothing, reason: 'the sheet closes');
      expect(find.text('وصلنا طلب السحب ✓ نحوّلولك الفلوس ويوصلك إشعار.'), findsOneWidget);
      expect(find.text('تحت التحويل'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return _ok(_active(goldActive: true, withdrawAllowed: true, available: 14, requests: [
              {'id': 4, 'amount_lyd': 50.0, 'status': 'pending', 'status_text': 'تحت التحويل', 'at': '2026-11-28T10:00:00+02:00', 'bank': 'مصرف الجمهورية'},
              last,
            ]));
          }
          return _ok(_active(goldActive: true, withdrawAllowed: true, available: 64, requests: [last]));
        }));
    final post = requests.singleWhere((r) => r.method == 'POST');
    expect(post.url.path, endsWith('ambassadors/withdraw'));
    final body = jsonDecode(post.body) as Map;
    expect(body['amount'], 50);
    expect(body['bank_name'], 'مصرف الجمهورية');
    expect(body['account_name'], 'سالم علي');
    expect(body['account_number'], '0912345678');
    expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(body['key'] as String), isTrue);
  });

  testWidgets('gold earnings after gold ended: he can still withdraw (withdraw.allowed decides)', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorGoldPage()));
      await settle(tester);
      expect(find.text('السفير الذهبي'), findsOneWidget);
      expect(find.text('30 د.ل'), findsOneWidget);
      await tester.tap(find.text('اسحب أرباحك'));
      await settle(tester);
      expect(find.text('ابعت طلب السحب'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok(_active(withdrawAllowed: true, available: 30))));
  });

  testWidgets('withdraw below the smallest amount: the button waits, the reason is said', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AmbassadorGoldPage()));
      await settle(tester);
      expect(find.text('أقل سحب 20 د.ل، وعندك توا 5.60 د.ل.'), findsOneWidget);
      await tester.tap(find.text('اسحب أرباحك'));
      await settle(tester);
      expect(find.text('ابعت طلب السحب'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async => _ok(_active(goldActive: true, withdrawAllowed: true, available: 5.6))));
  });

  // ------------------------------------------------------------------ home card

  testWidgets('home card: «شوف» opens, × hides it on this phone for 7 days, then it comes back', (tester) async {
    var now = DateTime(2026, 11, 28, 12);
    AmbassadorsApi.clock = () => now;
    var opened = 0;
    AmbassadorsApi.publish(AmbassadorState.fromJson(_active())!);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<AmbassadorHomeCardData?>(
          valueListenable: AmbassadorsApi.homeCard,
          builder: (_, card, __) => card == null ? const SizedBox() : AmbassadorHomeCard(card: card, onOpen: () => opened++),
        ),
      ),
    ));
    expect(find.text('جيب صحابك واكسب'), findsOneWidget);
    expect(find.text('كودك 67084 · كسبت 9.60 د.ل'), findsOneWidget);
    await tester.tap(find.text('شوف'));
    expect(opened, 1);

    await tester.tap(find.byKey(const ValueKey('amb-home-close')));
    await tester.pump();
    expect(find.text('جيب صحابك واكسب'), findsNothing);
    expect(opened, 1, reason: 'the × does not open the page');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AmbassadorsApi.hideKey), DateTime(2026, 12, 5, 12).millisecondsSinceEpoch);

    // the next answers from the server, and the app opened again on this phone: still hidden
    AmbassadorsApi.publish(AmbassadorState.fromJson(_active())!);
    await AmbassadorsApi.reloadHiddenForTest();
    await tester.pump();
    expect(find.text('جيب صحابك واكسب'), findsNothing);

    now = DateTime(2026, 12, 5, 12, 1);
    AmbassadorsApi.publish(AmbassadorState.fromJson(_active())!);
    await tester.pump();
    expect(find.text('جيب صحابك واكسب'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('home card: off when the server says so or the feature is off; the pause is read from the phone', () async {
    AmbassadorsApi.publish(AmbassadorState.fromJson({..._active(), 'home_card': {'show': false, 'title': 'x', 'sub': ''}})!);
    expect(AmbassadorsApi.homeCard.value, isNull);
    AmbassadorsApi.publish(AmbassadorState.fromJson({..._active(), 'enabled': false})!);
    expect(AmbassadorsApi.homeCard.value, isNull);

    AmbassadorsApi.resetForTest();
    SharedPreferences.setMockInitialValues({AmbassadorsApi.hideKey: DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch});
    await http.runWithClient(() => AmbassadorsApi.refresh(), () => MockClient((_) async => _ok(_active())));
    expect(AmbassadorsApi.state.value!.active, isTrue);
    expect(AmbassadorsApi.homeCard.value, isNull);
  });

  testWidgets('small phones (320×568, 390×844): every screen fits without overflow', (tester) async {
    addTearDown(tester.view.reset);
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final data in [
        _none(),
        _active(),
        _active(goldActive: true, withdrawAllowed: true, available: 64, requests: [
          {'id': 3, 'amount_lyd': 1250.5, 'status': 'refused', 'status_text': 'مرفوض: الرقم ناقص', 'at': '2026-11-28T10:00:00+02:00', 'bank': 'مصرف التجارة والتنمية'},
        ]),
      ]) {
        // the lists build lazily: scroll to the end so every part is laid out at this width
        Future<void> scrollAll() async {
          for (var i = 0; i < 8; i++) {
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -300), warnIfMissed: false);
            await tester.pump();
          }
        }

        await http.runWithClient(() async {
          await tester.pumpWidget(const MaterialApp(home: AmbassadorsPage()));
          await settle(tester);
          await scrollAll();
          await tester.pumpWidget(const MaterialApp(home: AmbassadorGoldPage()));
          await settle(tester);
          await scrollAll();
          if (data['status'] == 'active' && (data['withdraw'] as Map)['allowed'] == true) {
            await tester.scrollUntilVisible(find.text('اسحب أرباحك'), 200, scrollable: find.byType(Scrollable).first);
            await tester.ensureVisible(find.text('اسحب أرباحك'));
            await settle(tester);
            await tester.tap(find.text('اسحب أرباحك'));
            await settle(tester);
            expect(find.text('ابعت طلب السحب'), findsOneWidget);
          }
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: AmbassadorHomeCard(card: AmbassadorState.fromJson(data)!.homeCard, onOpen: () {})),
              ),
            ),
          ));
          await tester.pump();
          await tester.pumpWidget(MaterialApp(
            home: InviteWelcomePage(match: const InviteMatch(code: '67084', name: 'عبدالرحمن', reward: '2 دينار'), onAccept: () async {}, onOtherCode: () {}),
          ));
          await tester.pump();
          await tester.pumpWidget(const SizedBox());
        }, () => MockClient((request) async => _ok(data)));
      }
    }
  });

  // ------------------------------------------------------------------ the friend

  testWidgets('the friend: «دعاك X», the first-ride discount said plainly, «مش هو؟ اكتب الكود»', (tester) async {
    var other = 0, accepted = 0;
    await tester.pumpWidget(MaterialApp(
      home: InviteWelcomePage(
        match: const InviteMatch(code: '67084', name: 'ريان', reward: '2 دينار'),
        onAccept: () async => accepted++,
        onOtherCode: () => other++,
      ),
    ));
    await tester.pump();
    expect(find.text('دعاك ريان لتاكسيستا'), findsOneWidget);
    expect(find.text('عندك خصم 2 د.ل على أول مشوار'), findsOneWidget);
    expect(find.text('ينحسب وحده، ما تكتب حتى حاجة'), findsOneWidget);
    await tester.tap(find.text('مش هو؟ اكتب الكود'));
    expect(other, 1);
    await tester.tap(find.text('تمام، يلا نطلب'));
    await tester.pump();
    expect(accepted, 1);

    await tester.pumpWidget(MaterialApp(
      home: InviteWelcomePage(match: const InviteMatch(code: '67084', name: ''), onAccept: () async {}, onOtherCode: () {}),
    ));
    await tester.pump();
    expect(find.text('دعاك صاحبك لتاكسيستا'), findsOneWidget);
    expect(find.byKey(const ValueKey('invite-discount')), findsNothing, reason: 'no reward from the server: no discount promised');
  });
}
