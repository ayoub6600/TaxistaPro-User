import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/pages/intercity/intercity_car_form.dart';
import 'package:taxista/pages/intercity/intercity_page.dart';
import 'package:taxista/pages/intercity/intercity_seats.dart';

IntercityHome _home({List shared = const [], bool enabled = true}) => IntercityHome({
      'enabled': enabled,
      'from': 'مصراتة',
      'zone_type_id': 'zt-1',
      'routes': [
        {'route_id': 1, 'to': 'زليتن', 'suggested': 60, 'min': 45, 'max': 90, 'seat_price': 20, 'to_lat': 32.46, 'to_lng': 14.56},
        {'route_id': 2, 'to': 'طرابلس', 'suggested': 150, 'min': 120, 'max': 225, 'to_lat': 32.88, 'to_lng': 13.19},
      ],
      'shared': shared,
      'rules': {'horizon_days': 7, 'max_passengers': 4},
    });

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: SingleChildScrollView(child: w))));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the card shows the cities and hides where there are none', (t) async {
    int? opened;
    await t.pumpWidget(_wrap(IntercityEntryCard(home: _home(), onOpen: (id, _) => opened = id)));
    expect(find.text('سفر لمدينة ثانية'), findsOneWidget);
    await t.tap(find.text('طرابلس'));
    expect(opened, 2);

    await t.pumpWidget(_wrap(IntercityEntryCard(home: _home(enabled: false), onOpen: (_, __) {})));
    expect(find.text('سفر لمدينة ثانية'), findsNothing);
  });

  testWidgets('the price moves inside the admin range and the booking carries it', (t) async {
    Map<String, Object?>? sent;
    String? done;
    await t.pumpWidget(_wrap(IntercityCarForm(
      home: _home(),
      pick: const IcPlace(32.35, 15.1, 'شارع عبدالرحمن عزام'),
      routeId: 2,
      onBooked: (m) => done = m,
      send: (b) async {
        sent = b;
        return IntercityResult(true, 'تم');
      },
    )));
    expect(find.text('اطلب عروض السائقين · LYD 150'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await t.tap(find.text('+').last);
      await t.pump();
    }
    expect(find.text('اطلب عروض السائقين · LYD 220'), findsOneWidget, reason: 'steps of 10 up to 225');
    await t.tap(find.text('+').first); // passengers
    await t.pump();
    await t.tap(find.text('شنطة كبيرة'));
    await t.pump();
    await t.ensureVisible(find.textContaining('اطلب عروض السائقين'));
    await t.tap(find.textContaining('اطلب عروض السائقين'));
    await t.pumpAndSettle();
    expect(sent!['fare'], 220);
    expect(sent!['passengers'], 2);
    expect(sent!['big_bag'], true);
    expect((sent!['drop'] as IcPlace).address, 'طرابلس');
    expect(done, contains('الرحلات القادمة'));
  });

  testWidgets('a refusal from the server is shown and the form stays', (t) async {
    await t.pumpWidget(_wrap(IntercityCarForm(
      home: _home(),
      pick: const IcPlace(32.35, 15.1, ''),
      onBooked: (_) {},
      send: (_) async => IntercityResult(false, 'السعر للمشوار هذا لازم يكون بين 45 و90 دينار.'),
    )));
    await t.ensureVisible(find.textContaining('اطلب عروض السائقين'));
    await t.tap(find.textContaining('اطلب عروض السائقين'));
    await t.pumpAndSettle();
    expect(find.text('السعر للمشوار هذا لازم يكون بين 45 و90 دينار.'), findsOneWidget);
  });

  testWidgets('seats: one booking per trip, at most what is left', (t) async {
    final calls = <List<int>>[];
    await t.pumpWidget(_wrap(IntercitySeats(
      home: _home(shared: [
        {'id': 7, 'to': 'زليتن', 'depart_at': '2099-01-01 08:00', 'seat_price': 20, 'seats_left': 2, 'seats_total': 3, 'meeting_point': 'دوران الدفنية',
          'driver': {'name': 'محمد', 'rating': 4.9, 'completed': 210, 'car': 'هيونداي أكسنت'}},
      ]),
      pickAddress: '',
      onWholeCar: () {},
      book: (id, n) async {
        calls.add([id, n]);
        return IntercityResult(true, 'تم حجز $n كرسي ✅');
      },
    )));
    expect(find.text('باقي 2 من 3'), findsOneWidget);
    await t.tap(find.text('+'));
    await t.pump();
    await t.tap(find.text('+'));
    await t.pump();
    expect(find.text('احجز · LYD 40'), findsOneWidget, reason: 'never more than the 2 left');
    await t.tap(find.text('احجز · LYD 40'));
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
}
