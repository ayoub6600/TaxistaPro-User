import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/functions/errand_api.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/functions/parcel_api.dart';
import 'package:taxista/pages/parcels/errand/errand_draft.dart';
import 'package:taxista/pages/parcels/errand/errand_ride_card.dart';
import 'package:taxista/pages/parcels/parcel_code_card.dart';
import 'package:taxista/pages/parcels/parcel_page.dart';

Map<String, Object?> _errand({bool enabled = true, bool allowed = true, bool buy = true, int max = 3}) => {
      'enabled': enabled, 'name': 'مشوار بوقفات', 'max_stops': max, 'stop_fee': 2, 'free_wait': 5, 'wait_per_min': 0.5,
      'buy': {'enabled': buy, 'max': 200, 'receipt_required': true, 'allowed': allowed, 'min_rides': 3},
    };

ParcelHome _home(Map<String, Object?>? errand) => ParcelHome({
      'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'banned': 'فلوس كاش، ذهب',
      'sizes': [
        {'size': 'small', 'base': 5, 'per_km': 0.5},
        {'size': 'medium', 'base': 7, 'per_km': 0.6},
        {'size': 'large', 'base': 10, 'per_km': 0.8},
      ],
      if (errand != null) 'errand': errand,
    });

const _here = IcPlace(32.35, 15.1, 'شارع طرابلس');
const _shops = [IcPlace(32.36, 15.11, 'محل قطع غيار'), IcPlace(32.37, 15.12, 'صيدلية النور'), IcPlace(32.38, 15.13, 'مخبز')];

class _Calls {
  final quotes = <(List<IcPlace>, IcPlace)>[];
  List<ErrandStopData>? sentStops;
  IcPlace? sentDrop;
  int placeAsks = 0;
}

Widget _page(_Calls c, {Map<String, Object?>? errand, IcPlace? newDrop}) => MaterialApp(
      home: ParcelPage(
        home: _home(errand ?? _errand()),
        pick: _here,
        map: (_, __) => const SizedBox.expand(),
        pickDrop: (role) async => (_here, const IcPlace(32.39, 15.13, 'الزروق')),
        quote: (p, d, s) async => IntercityResult(true, '', {'price': 10, 'km': 3}),
        balance: () => null,
        errandPlace: (i) async => i == null ? newDrop : _shops[(c.placeAsks++) % _shops.length],
        errandQuote: (stops, drop) async {
          c.quotes.add((stops, drop));
          return IntercityResult(true, '', {'km': 6.4, 'route_price': 12, 'stops': stops.length, 'stop_fees': 2 * stops.length, 'price': 12 + 2 * stops.length, 'currency': 'LYD'});
        },
        errandSend: (stops, drop) async {
          c.sentStops = stops;
          c.sentDrop = drop;
          return IntercityResult(true, 'طلبنا كابتن للمشوار');
        },
      ),
    );

Future<void> _big(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(430, 2200));
  addTearDown(() => t.binding.setSurfaceSize(null));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('no errand from the admin: the parcels page has no switch', (t) async {
    await _big(t);
    await t.pumpWidget(_page(_Calls(), errand: _errand(enabled: false)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mode-errand')), findsNothing);
    expect(find.text('شن تبعت؟'), findsOneWidget);
  });

  testWidgets('«مشوار بوقفات»: a stop, what to take, priced road + stops, summary, then sent with his place as the last one', (t) async {
    await _big(t);
    final c = _Calls();
    await t.pumpWidget(_page(c));
    await t.pumpAndSettle();
    expect(find.text('طرد من مكان لمكان'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('mode-errand')));
    await t.pumpAndSettle();
    expect(find.text('الوقفة 1'), findsOneWidget, reason: 'one empty stop to start');
    expect(find.text('مكانك الآن · شارع طرابلس'), findsOneWidget, reason: '«لوين يجيبهم» starts where he is');
    expect(find.text('⏱️ أول 5 دقايق في كل وقفة مجانية، بعدها 0.5 LYD للدقيقة'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('errand-request')));
    await t.pump();
    expect(find.text('اختار مكان الوقفة 1.'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('errand-place-0')));
    await t.pumpAndSettle();
    expect(find.text('محل قطع غيار'), findsOneWidget);
    expect(c.quotes.single.$1.single.address, 'محل قطع غيار');
    expect(c.quotes.single.$2.address, 'شارع طرابلس');
    expect(find.text('LYD 14'), findsOneWidget);
    expect(find.text('+ 1 وقفات × 2'), findsOneWidget);
    expect(find.text('6.4 كم · LYD 14'), findsOneWidget, reason: 'the chip on the map');

    await t.tap(find.byKey(const ValueKey('errand-request')));
    await t.pump();
    expect(find.text('اكتب شن ياخذ الكابتن من الوقفة 1.'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('errand-item-0')), 'فلتر زيت تويوتا');
    await t.enterText(find.byKey(const ValueKey('errand-phone-0')), '0911111111');
    expect(find.text('الكابتن يدفع عنك لين 200 LYD، ويصوّر الفاتورة، وأنت تأكد المبلغ.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('errand-captain-0')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('errand-request')));
    await t.pump();
    expect(find.text('أكّد إن الحاجات مش من الممنوعات.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('errand-rules')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('errand-request')));
    await t.pumpAndSettle();
    expect(c.sentStops, isNull, reason: 'the summary first');
    expect(find.text('راجع مشوارك 🛍️'), findsOneWidget);
    expect(find.text('الكابتن يدفع عنك (لين 200 LYD) وتأكد المبلغ'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('errand-confirm')));
    await t.pumpAndSettle();
    final s = c.sentStops!.single;
    expect(s.item, 'فلتر زيت تويوتا');
    expect(s.pays, 'captain');
    expect(s.toJson()['contact_phone'], '0911111111');
    expect(s.toJson().containsKey('contact_name'), isFalse);
    expect(c.sentDrop!.address, 'شارع طرابلس');
  });

  testWidgets('stops: up to the admin\'s most, moved up and down, removed; «لوين يجيبهم» can change', (t) async {
    await _big(t);
    final c = _Calls();
    await t.pumpWidget(_page(c, errand: _errand(max: 3), newDrop: const IcPlace(32.4, 15.2, 'بيت خالي')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('mode-errand')));
    await t.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byKey(const ValueKey('errand-add')));
      await t.pump();
    }
    expect(find.text('وصلت لأقصى عدد (3 وقفات)'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(ValueKey('errand-place-$i')));
      await t.pumpAndSettle();
    }
    expect(c.quotes.last.$1.map((e) => e.address), ['محل قطع غيار', 'صيدلية النور', 'مخبز']);
    expect(find.text('+ 3 وقفات × 2'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('errand-down-0')));
    await t.pumpAndSettle();
    expect(c.quotes.last.$1.map((e) => e.address), ['صيدلية النور', 'محل قطع غيار', 'مخبز']);
    await t.tap(find.byKey(const ValueKey('errand-up-2')));
    await t.pumpAndSettle();
    expect(c.quotes.last.$1.map((e) => e.address), ['صيدلية النور', 'مخبز', 'محل قطع غيار']);
    await t.tap(find.byKey(const ValueKey('errand-remove-1')));
    await t.pumpAndSettle();
    expect(c.quotes.last.$1.map((e) => e.address), ['صيدلية النور', 'محل قطع غيار']);
    expect(find.text('زيد وقفة (لين 3)'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('errand-drop')));
    await t.pumpAndSettle();
    expect(find.text('بيت خالي'), findsOneWidget);
    expect(c.quotes.last.$2.address, 'بيت خالي');

    // back to the parcel and again: the stops are kept
    await t.tap(find.byKey(const ValueKey('mode-parcel')));
    await t.pumpAndSettle();
    expect(find.text('شن تبعت؟'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('mode-errand')));
    await t.pumpAndSettle();
    expect(find.text('صيدلية النور'), findsOneWidget);
    expect(find.text('الوقفة 2'), findsOneWidget);
  });

  testWidgets('buying on, not yet allowed: no «الكابتن يدفع عني», the rides he still needs', (t) async {
    await _big(t);
    await t.pumpWidget(_page(_Calls(), errand: _errand(allowed: false)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('mode-errand')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('errand-captain-0')), findsNothing);
    expect(find.text('الكابتن يشتري عنك بعد 3 رحلات كاملة.'), findsOneWidget);
  });

  testWidgets('buying off: only «مدفوعة», no note', (t) async {
    await _big(t);
    await t.pumpWidget(_page(_Calls(), errand: _errand(buy: false, allowed: false)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('mode-errand')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('errand-paid-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('errand-captain-0')), findsNothing);
    expect(find.byKey(const ValueKey('errand-buy-note-0')), findsNothing);
  });

  test('the draft says what is missing in order; a stop the captain pays needs buying allowed', () {
    final d = ErrandDraft();
    expect(d.missing(buyAllowed: true), 'زيد وقفة وحدة على الأقل.');
    d.add();
    d.stops[0].place = _shops[0];
    d.stops[0].item.text = 'دوا';
    d.stops[0].pays = 'captain';
    expect(d.missing(buyAllowed: false), 'الكابتن ما يقدرش يدفع عنك حاليًا.');
    d.stops[0].contactPhone.text = '091';
    expect(d.missing(buyAllowed: true), 'رقم التواصل في الوقفة 1 ناقص.');
    d.stops[0].contactPhone.text = '';
    expect(d.missing(buyAllowed: true), 'أكّد إن الحاجات مش من الممنوعات.');
    d.rules = true;
    expect(d.missing(buyAllowed: true), isNull);
    d.dispose();
  });

  Map<String, Object?> ride({String? answer}) => {
        'id': 'r-77',
        'requested_currency_symbol': 'LYD',
        'service_kind': 'parcel',
        'parcel': {'needs_code': true, 'code': '1234'},
        'errand': {
          'name': 'مشوار بوقفات',
          'purchases_line': 'تدفع للكابتن 35 LYD قيمة المشتريات مع الرحلة',
          'stops': [
            {'position': 1, 'address': 'محل قطع غيار', 'item': 'فلتر زيت', 'pays': 'captain', 'arrived': true, 'picked': true, 'purchase_amount': 35, 'receipt': 'https://x/r.jpg', 'rider_answer': answer},
            {'position': 2, 'address': 'صيدلية النور', 'item': 'دوا', 'pays': 'paid', 'arrived': true, 'picked': false},
            {'position': 3, 'address': 'مخبز', 'item': 'خبز', 'pays': 'paid', 'arrived': false, 'picked': false},
          ],
        },
      };

  testWidgets('on the ride: each stop\'s state, what the captain paid, and his answer sent once and shown', (t) async {
    final answers = <(int, bool)>[];
    final r = ride();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ErrandRideCard(
            rideId: r['id']!,
            errand: r['errand'] as Map,
            currency: 'LYD',
            answer: (p, ok) async {
              answers.add((p, ok));
              return IntercityResult(true, 'تم');
            },
          ),
        ),
      ),
    ));
    expect(find.text('استلم ✓'), findsOneWidget);
    expect(find.text('الكابتن وصل'), findsOneWidget);
    expect(find.text('لسه'), findsOneWidget);
    expect(find.text('الكابتن دفع 35 LYD عن «فلتر زيت»'), findsOneWidget);
    expect(find.byKey(const ValueKey('errand-receipt-1')), findsOneWidget);
    expect(find.text('💵 تدفع للكابتن 35 LYD قيمة المشتريات مع الرحلة'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('errand-yes-1')));
    await t.pumpAndSettle();
    expect(answers, [(1, true)]);
    expect(find.text('أكدت المبلغ ✓'), findsOneWidget);
    expect(find.byKey(const ValueKey('errand-yes-1')), findsNothing);
  });

  testWidgets('an answer already given (the ride JSON) shows without buttons', (t) async {
    final r = ride(answer: 'disputed');
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ErrandRideCard.of(r)!))));
    expect(find.text('قلت إن المبلغ مش صحيح، نراجعوه مع الكابتن.'), findsOneWidget);
    expect(find.byKey(const ValueKey('errand-no-1')), findsNothing);
  });

  test('an errand ride shows its own card, not the parcel code; the push is matched to the ride on screen', () {
    final r = ride();
    expect(ParcelCodeCard.of(r), isNull);
    expect(ErrandRideCard.of(r), isNotNull);
    expect(ErrandRideCard.of({'id': 1, 'parcel': {}}), isNull);
    expect(ErrandPush.isCurrent({'push_type': 'errand_purchase', 'request_id': 'r-77'}, r), isTrue);
    expect(ErrandPush.isCurrent({'push_type': 'errand_purchase', 'request_id': 'r-78'}, r), isFalse);
    expect(ErrandPush.isCurrent({'push_type': 'general', 'request_id': 'r-77'}, r), isFalse);
    expect(ErrandPush.isCurrent({'push_type': 'errand_purchase', 'request_id': 'r-77'}, {}), isFalse);
  });

  test('the admin\'s settings with safe defaults', () {
    final c = ErrandConfig.of(_home(_errand(allowed: false)))!;
    expect(c.enabled, isTrue);
    expect(c.maxStops, 3);
    expect(c.buyEnabled, isTrue);
    expect(c.buyAllowed, isFalse);
    expect(c.minRides, 3);
    expect(c.currency, 'LYD');
    expect(ErrandConfig.of(_home(null)), isNull);
    final bare = ErrandConfig({'enabled': true});
    expect(bare.name, 'مشوار بوقفات');
    expect(bare.buyAllowed, isFalse);
  });
}
