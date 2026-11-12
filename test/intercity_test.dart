import 'package:taxista/pages/intercity/intercity_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/pages/intercity/intercity_again.dart';
import 'package:taxista/pages/intercity/intercity_fare_page.dart';
import 'package:taxista/pages/intercity/intercity_flow.dart';
import 'package:taxista/pages/intercity/intercity_seats.dart';
import 'package:taxista/pages/intercity/intercity_wait_page.dart';
import 'package:taxista/pages/onTripPage/home_services_row.dart';

IntercityHome _home({List shared = const [], bool enabled = true}) => IntercityHome({
      'enabled': enabled,
      'from': 'مصراتة',
      'zone_type_id': 'zt-1',
      'routes': [
        {'route_id': 1, 'to': 'زليتن', 'suggested': 60, 'min': 45, 'max': 90, 'seat_price': 15, 'to_lat': 32.46, 'to_lng': 14.56},
        {'route_id': 3, 'to': 'طرابلس', 'suggested': 180, 'min': 145, 'max': 270, 'seat_price': 40, 'to_lat': 32.88, 'to_lng': 13.19, 'accepted_from': 175},
      ],
      'shared': shared,
      'rules': {'horizon_days': 7, 'max_passengers': 4},
    });

const _trip = {
  'id': 7, 'to': 'طرابلس', 'depart_at': '2099-01-01 07:00', 'seat_price': 40, 'seats_left': 2, 'seats_total': 4, 'meeting_point': 'دوران الدفنية',
  'driver': {'name': 'محمد', 'rating': 4.9, 'completed': 210, 'car': 'هيونداي أكسنت'},
};

Widget _app(Widget w) => MaterialApp(home: w);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  HomeService svc(String l, {bool soon = false, VoidCallback? tap}) => HomeService(
      label: l, icon: Icons.circle, background: Colors.white, foreground: Colors.black, iconBackground: Colors.blue, iconColor: Colors.white, soon: soon, onTap: tap ?? () {});

  testWidgets('the home bar shows every service with its label and «قريبًا» only near the focus', (t) async {
    HomeServicesRow.introPlayed = true;
    var travel = 0;
    await t.pumpWidget(_app(Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: HomeServicesRow(services: [svc('بدون وجهة'), svc('سفر', tap: () => travel++), svc('الشحن', soon: true), svc('توصيل', soon: true), svc('ونش', soon: true)])),
      ),
    )));
    await t.pumpAndSettle();
    for (final l in ['بدون وجهة', 'سفر', 'الشحن', 'توصيل', 'ونش']) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    await t.tap(find.text('سفر'));
    expect(travel, 1);
    expect(HomeServicesRow.scaleFor(0), 1);
    expect(HomeServicesRow.scaleFor(200), closeTo(.55, .01));
    expect(HomeServicesRow.scaleFor(-120), lessThan(1));
  });

  testWidgets('كيف تحب تسافر: a city and a whole car or a seat', (t) async {
    await t.pumpWidget(_app(IntercityTypePage(home: _home(shared: [_trip]), pick: const IcPlace(32.35, 15.1, ''), routeId: 3)));
    expect(find.text('كيف تحب تسافر؟'), findsOneWidget);
    expect(find.text('أنت ومن معاك بس · من LYD 180'), findsOneWidget);
    expect(find.text('تدفع كرسيك بس · 1 رحلة متاحة'), findsOneWidget);
    await t.tap(find.text('زليتن'));
    await t.pump();
    expect(find.text('أنت ومن معاك بس · من LYD 60'), findsOneWidget);
  });

  testWidgets('the price stays in the admin range and the booking carries riders, bag and price', (t) async {
    Map<String, Object?>? sent;
    final home = _home();
    await t.pumpWidget(_app(IntercityFarePage(
      home: home,
      pick: const IcPlace(32.35, 15.1, 'شارع عبدالرحمن عزام'),
      route: home.routes[1],
      send: (b) async {
        sent = b;
        return IntercityResult(false, 'السعر للمشوار هذا لازم يكون بين 145 و270 دينار.');
      },
    )));
    expect(find.text('LYD 180'), findsOneWidget);
    expect(find.text('أغلب الطلبات تنقبل من LYD 175 وفوق 👍'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('نقص'));
    await t.pump();
    expect(find.textContaining('سعرك أقل من اللي تنقبل بيه'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('زيادة'));
    await t.pump();
    for (var i = 0; i < 12; i++) {
      await t.tap(find.bySemanticsLabel('زيادة'));
      await t.pump();
    }
    expect(find.text('LYD 270'), findsOneWidget, reason: 'steps of 10, never past 270');
    await t.tap(find.text('2'));
    await t.scrollUntilVisible(find.text('شنطة كبيرة'), 80, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('شنطة كبيرة'));
    await t.pump();
    await t.tap(find.text('اطلب عروض السائقين'));
    await t.pumpAndSettle();
    expect(sent!['fare'], 270);
    expect(sent!['passengers'], 2);
    expect(sent!['big_bag'], true);
    expect((sent!['drop'] as IcPlace).address, 'طرابلس · وسط المدينة');
    expect(find.text('السعر للمشوار هذا لازم يكون بين 145 و270 دينار.'), findsOneWidget, reason: 'the server refusal shows');
  });

  testWidgets('the offers arrive with the driver time, and raising shows its button', (t) async {
    await t.pumpWidget(_app(IntercityWaitPage(
      rideId: 'r1', from: 'مصراتة', to: 'طرابلس', fare: 180, max: 270, step: 10, summary: 'بكرة 7:00 الصبح · 2 ركاب',
      pickAddress: 'شارع عبدالرحمن عزام', dropAddress: 'طرابلس · وسط المدينة',
      load: () async => {
        'scheduled_offers': [
          {'offer_id': 5, 'proposed_fare': 180, 'driver_name': 'محمد', 'driver_rating': 4.9, 'driver_completed': 210},
          {'offer_id': 6, 'proposed_fare': 200, 'driver_name': 'علي', 'proposed_time': '2099-01-02 07:30:00'},
        ],
      },
    )));
    await t.pump();
    expect(find.text('العروض (2)'), findsOneWidget);
    expect(find.text('محمد · 4.9 · 210 رحلة'), findsOneWidget);
    expect(find.textContaining('يقترح'), findsOneWidget);
    expect(find.text('ارفع سعرك تجيك عروض أكثر'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('زيادة'));
    await t.pump();
    expect(find.text('ارفع السعر إلى 190'), findsOneWidget);
    await t.pumpWidget(const SizedBox()); // stops the polling timer
  });

  testWidgets('seats: one booking, never more than what is left', (t) async {
    final calls = <List<int>>[];
    await t.pumpWidget(_app(IntercitySeatsPage(
      home: _home(shared: [_trip]),
      pickAddress: '',
      book: (id, n) async {
        calls.add([id, n]);
        return IntercityResult(true, 'تم حجز $n كرسي ✅');
      },
    )));
    expect(find.text('LYD 40'), findsOneWidget);
    await t.tap(find.text('+'));
    await t.pump();
    await t.tap(find.text('+'));
    await t.pump();
    expect(find.text('احجز · LYD 80'), findsOneWidget, reason: 'two left, so two at most');
    await t.tap(find.text('احجز · LYD 80'));
    await t.pumpAndSettle();
    expect(calls, [
      [7, 2]
    ]);
    expect(find.textContaining('محجوز'), findsOneWidget);
  });

  test('day labels and the wall clock', () {
    final now = DateTime(2026, 11, 12, 10);
    expect(IntercityApi.dayLabel('2026-11-13 07:30:00', now: now), 'بكرة 7:30 الصبح');
    expect(IntercityApi.dayLabel('2026-11-12 19:00', now: now), 'اليوم 7:00 بالليل');
    expect(IntercityApi.wallClock(DateTime(2026, 11, 13, 7, 5)), '2026-11-13 07:05:00');
  });

  test('a travel push or card opens its own page with the server\'s numbers', () {
    expect(IntercityLink.handles({'push_type': 'intercity_no_offers', 'request_id': 'r9'}), isTrue);
    expect(IntercityLink.handles({'push_type': 'intercity_no_offers'}), isFalse, reason: 'no request to open');
    expect(IntercityLink.handles({'push_type': 'general', 'request_id': 'r9'}), isFalse);
    final page = IntercityLink.pageFor({
      'id': 'r9', 'rider_proposed_fare': '160.00', 'trip_start_time_raw': '2099-01-02T07:00:00', 'pick_address': 'السكت', 'drop_address': 'طرابلس',
      'intercity': {'from': 'مصراتة', 'to': 'طرابلس', 'passengers': 2, 'max_offer': 240, 'note': 'شنطة كبيرة'},
    });
    expect([page.rideId, page.from, page.to, page.fare, page.max, page.step, page.note], ['r9', 'مصراتة', 'طرابلس', 160, 240, 5, 'شنطة كبيرة']);
    expect(page.summary, endsWith('2 ركاب'));
    expect(IntercityLink.isIntercity({'is_out_station': 1}), isTrue);
    expect(IntercityLink.isIntercity({'is_out_station': 0}), isFalse);
  });

  group('round trip, the same trip again, seat stars', () {
    IntercityHome home({Map? last, Map? rate}) => IntercityHome({
          'enabled': true,
          'from': 'مصراتة',
          'zone_type_id': 'zt-1',
          'routes': [
            {
              'route_id': 3, 'to': 'طرابلس', 'suggested': 180, 'min': 145, 'max': 270, 'seat_price': 40, 'to_lat': 32.88, 'to_lng': 13.19, 'travel_minutes': 120,
              'round_trip': {'suggested': 324, 'min': 261, 'max': 486, 'max_wait_hours': 8},
            },
          ],
          'shared': const [],
          'rules': {'horizon_days': 7, 'max_passengers': 4, 'round_trip': true, 'max_wait_hours': 8},
          if (last != null) 'last_trip': last,
          if (rate != null) 'to_rate': rate,
        });

    testWidgets('«ذهاب ورجوع»: the admin round-trip price, the hours he waits, and the time back', (t) async {
      await t.binding.setSurfaceSize(const Size(430, 1800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      Map<String, Object?>? sent;
      final h = home();
      await t.pumpWidget(_app(IntercityFarePage(
        home: h,
        pick: const IcPlace(32.35, 15.1, 'السكت'),
        route: h.routes.first,
        send: (b) async {
          sent = b;
          return IntercityResult(false, 'x');
        },
      )));
      expect(find.text('LYD 180'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('ذهاب ورجوع ⇄'));
      await t.pump();
      expect(find.text('LYD 324'), findsOneWidget, reason: 'the round-trip price from the admin');
      expect(find.text('نفس اليوم · الكابتن يستناك'), findsOneWidget);
      expect(find.text('8 س'), findsOneWidget, reason: 'up to the admin\'s longest wait');
      await t.tap(find.text('6 س'));
      await t.pump();
      expect(find.byKey(const ValueKey('ic-back')), findsOneWidget);
      await t.ensureVisible(find.text('اطلب عروض السائقين'));
      await t.tap(find.text('اطلب عروض السائقين'));
      await t.pump();
      expect(sent!['wait_hours'], 6);
      expect(sent!['fare'], 324);
      await t.tap(find.bySemanticsLabel('ذهاب بس'));
      await t.pump();
      expect(find.text('LYD 180'), findsOneWidget);
    });

    testWidgets('«نفس السفرة مرة ثانية»: one tap fills it, and a changed price is said plainly', (t) async {
      await t.binding.setSurfaceSize(const Size(430, 1800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final h = home(last: {
        'kind': 'car', 'route_id': 3, 'to': 'طرابلس', 'date': '2026-11-03', 'passengers': 2, 'big_bag': true, 'round_trip': true, 'wait_hours': 4,
        'drop': {'lat': 32.88, 'lng': 13.19, 'address': 'طرابلس · سوق الجمعة'}, 'paid': 300, 'price': 330, 'price_changed': true,
      });
      await t.pumpWidget(_app(IntercityTypePage(home: h, pick: const IcPlace(32.35, 15.1, 'السكت'))));
      await t.pump();
      expect(find.text('سفرتك الأخيرة · 3 نوفمبر'), findsOneWidget);
      expect(find.text('مصراتة ⇄ طرابلس'), findsOneWidget);
      expect(find.text('راكبين · ذهاب ورجوع · LYD 330'), findsOneWidget);
      expect(find.byKey(const ValueKey('ic-price-changed')), findsOneWidget);
      await t.tap(find.text('اطلبها مرة ثانية'));
      await t.pumpAndSettle();
      expect(find.text('نفس سفرتك مرة ثانية'), findsOneWidget);
      expect(find.text('LYD 330'), findsOneWidget);
      expect(find.text('2 ركاب'), findsOneWidget);
      expect(find.text('نفس اليوم · الكابتن يستناك'), findsOneWidget);
    });

    testWidgets('a seat: «شوف الكراسي», and the stars sheet once', (t) async {
      int? stars;
      List<String>? tags;
      final h = home(last: {'kind': 'seat', 'route_id': 3, 'to': 'طرابلس', 'date': '2026-11-03', 'seats': 2, 'paid': 80, 'open_trips': 2, 'cheapest_seat': 35});
      await t.pumpWidget(_app(IntercityTypePage(home: h, pick: const IcPlace(32.35, 15.1, 'السكت'))));
      await t.pump();
      expect(find.text('كرسيين · LYD 80'), findsOneWidget);
      expect(find.text('2 رحلات متاحة · من LYD 35'), findsOneWidget);
      expect(find.text('شوف الكراسي إلى طرابلس'), findsOneWidget);

      await t.pumpWidget(_app(Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: IntercityRateSheet(
            toRate: IntercityToRate(const {'booking_id': 9, 'to': 'طرابلس', 'driver': 'محمد', 'seats': 2, 'price': 80}),
            send: (s, tg) async {
              stars = s;
              tags = tg;
              return IntercityResult(true, 'شكرًا');
            },
          ),
        ),
      )));
      expect(find.text('كيف كانت السفرة مع محمد؟'), findsOneWidget);
      await t.tap(find.text('أرسل التقييم'));
      await t.pump();
      expect(find.text('اختار عدد النجوم.'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('4 نجوم'));
      await t.tap(find.text('في الموعد'));
      await t.pump();
      await t.tap(find.text('أرسل التقييم'));
      await t.pump();
      expect(stars, 4);
      expect(tags, ['on_time']);
    });
  });
}
