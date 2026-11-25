import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/functions.dart' show languageDirection;
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/pages/intercity/intercity_fare_page.dart';
import 'package:taxista/pages/intercity/intercity_flow.dart';
import 'package:taxista/pages/intercity/intercity_seats.dart';
import 'package:taxista/pages/intercity/intercity_style.dart';
import 'package:taxista/pages/intercity/intercity_type_widgets.dart';

/// Misrata → Zliten (50 min, round trip), Khoms (80 min), Tripoli (the server did not say how long)
IntercityHome _home({List shared = const [], bool roundTrip = true}) => IntercityHome({
      'enabled': true,
      'from': 'مصراتة',
      'zone_type_id': 'zt-1',
      'routes': [
        {
          'route_id': 1, 'to': 'زليتن', 'suggested': 80, 'min': 60, 'max': 120, 'seat_price': 20, 'to_lat': 32.46, 'to_lng': 14.56, 'travel_minutes': 50,
          'round_trip': {'suggested': 150, 'min': 110, 'max': 220, 'max_wait_hours': 8},
        },
        {'route_id': 2, 'to': 'الخمس', 'suggested': 120, 'min': 90, 'max': 180, 'seat_price': 25, 'to_lat': 32.65, 'to_lng': 14.26, 'travel_minutes': 80},
        {'route_id': 3, 'to': 'طرابلس', 'suggested': 220, 'min': 145, 'max': 270, 'seat_price': 40, 'to_lat': 32.88, 'to_lng': 13.19},
      ],
      'shared': shared,
      'rules': {'horizon_days': 7, 'max_passengers': 4, 'round_trip': roundTrip, 'max_wait_hours': 8},
    });

Map _trip(int id, num price) => {
      'id': id, 'to': 'طرابلس', 'depart_at': '2099-01-01 07:00', 'seat_price': price, 'seats_left': 2, 'seats_total': 4, 'meeting_point': 'دوران الدفنية',
      'driver': {'name': 'محمد', 'rating': 4.9, 'completed': 210, 'car': 'هيونداي أكسنت'},
    };

Widget _page(IntercityHome home, {int? routeId}) => MaterialApp(
      home: IntercityTypePage(home: home, pick: const IcPlace(32.37, 15.09, 'السكت'), routeId: routeId, map: (_, __) => const SizedBox.expand()),
    );

/// a phone the size of the design's
Future<void> _phone(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
}

/// the test font is wider than Cairo, so the sheet scrolls: bring the thing into view first
Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the drive to a city, as an Arabic reader says it', () {
    expect(IcStyle.travelTime(50), '≈ 50 دقيقة');
    expect(IcStyle.travelTime(80), '≈ ساعة و20 دقيقة');
    expect(IcStyle.travelTime(150), '≈ ساعتين و30 دقيقة');
    expect(IcStyle.travelTime(60), '≈ ساعة');
    expect(IcStyle.travelTime(120), '≈ ساعتين');
    expect(IcStyle.travelTime(185), '≈ 3 ساعات و5 دقائق');
    expect(IcStyle.travelTime(660), '≈ 11 ساعة');
    expect(IcStyle.travelTime(52), '≈ 50 دقيقة', reason: '«≈»: to the nearest five minutes');
    expect(IcStyle.travelTime(58), '≈ ساعة');
    expect(IcStyle.travelTime(3), '≈ 5 دقائق');
    expect(IcStyle.travelTime(null), isNull, reason: 'the server did not say: nothing is shown');
    expect(IcStyle.travelTime(0), isNull);
    // under a city's name there is little room
    expect(IcStyle.travelTime(50, short: true), '≈ 50 د');
    expect(IcStyle.travelTime(80, short: true), '≈ 1 س 20 د');
    expect(IcStyle.travelTime(120, short: true), '≈ 2 س');
    expect(IcStyle.travelTime(null, short: true), isNull);
  });

  test('the drive and the money in English', () {
    languageDirection = 'ltr';
    addTearDown(() => languageDirection = 'rtl');
    expect(IcStyle.travelTime(80), '≈ 1 h 20 min');
    expect(IcStyle.travelTime(50, short: true), '≈ 50 min');
    expect(IcStyle.lyd(80), 'LYD 80');
  });

  test('«د.ل» after the number, and «لـ» before a city', () {
    expect(IcStyle.lyd(80), '80 د.ل');
    expect(IcStyle.lyd(12.5), '12.5 د.ل');
    expect(icToCity('زليتن'), 'لـزليتن');
    expect(icToCity('الخمس'), 'للخمس');
  });

  testWidgets('the design: the drive on top and under each city, prices in «د.ل», tags, and a button that names the choice', (t) async {
    await _phone(t);
    await t.pumpWidget(_page(_home()));
    expect(find.text('مصراتة ← زليتن'), findsOneWidget);
    expect(find.text('≈ 50 دقيقة'), findsOneWidget, reason: 'beside the trip on top');
    expect(find.text('وين مسافر؟'), findsOneWidget);
    expect(find.text('كيف تحب تسافر؟'), findsOneWidget);
    expect(find.text('≈ 50 د'), findsOneWidget);
    expect(find.text('≈ 1 س 20 د'), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(IcDestCard, 'طرابلس'), matching: find.textContaining('≈')), findsNothing, reason: 'no time from the server: only the name');

    expect(find.text('أنت ومن معاك بس، من الباب للباب'), findsOneWidget);
    expect(find.text('تدفع كرسيك بس، مع ركاب آخرين'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('من'), findsNWidgets(2));
    expect(find.text('د.ل'), findsNWidgets(2));
    for (final tag in ['لين 4 ركاب', 'تحدد سعرك', 'ذهاب ورجوع 150 د.ل', 'أرخص', 'رحلات بمواعيد محددة']) {
      expect(find.text(tag), findsWidgets, reason: tag);
    }
    expect(find.textContaining('LYD'), findsNothing, reason: 'Arabic never reads «LYD» here');
    expect(find.text('الكباتن يبعثوا عروضهم'), findsOneWidget);
    expect(find.text('التالي: سيارة كاملة لـزليتن'), findsOneWidget);

    await _tap(t, find.text('الخمس'));
    expect(find.text('مصراتة ← الخمس'), findsOneWidget);
    expect(find.text('≈ ساعة و20 دقيقة'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.textContaining('ذهاب ورجوع'), findsNothing, reason: 'no round trip to this city');
    expect(find.text('التالي: سيارة كاملة للخمس'), findsOneWidget);

    await _tap(t, find.text('طرابلس'));
    expect(find.text('مصراتة ← طرابلس'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing, reason: 'no time: the trip stands alone on top');
  });

  testWidgets('«ذهاب ورجوع» is not promised where the next page does not offer it', (t) async {
    await _phone(t);
    await t.pumpWidget(_page(_home(roundTrip: false)));
    expect(find.textContaining('ذهاب ورجوع'), findsNothing);
  });

  testWidgets('a seat where captains posted trips: how many, the cheapest, and on to the seats', (t) async {
    await _phone(t);
    await t.pumpWidget(_page(_home(shared: [_trip(7, 45), _trip(8, 35)]), routeId: 3));
    expect(find.text('2 رحلات متاحة'), findsOneWidget);
    expect(find.text('35'), findsOneWidget, reason: '«من»: the cheapest seat posted, not the admin price (40)');
    await _tap(t, find.text('كرسي في رحلة'));
    expect(find.byKey(const ValueKey('ic-no-trip')), findsNothing);
    expect(find.text('تحجز كرسيك'), findsOneWidget, reason: 'the steps of a seat, not of an offer');
    await t.tap(find.text('التالي: كرسي لـطرابلس'));
    await t.pumpAndSettle();
    expect(find.byType(IntercitySeatsPage), findsOneWidget);
  });

  testWidgets('a seat with no trip to the city: said in the card, and the button offers the whole car', (t) async {
    await _phone(t);
    await t.pumpWidget(_page(_home()));
    await _tap(t, find.text('كرسي في رحلة'));
    expect(find.byKey(const ValueKey('ic-no-trip')), findsOneWidget);
    expect(find.text('ما فيش رحلة لـزليتن توّا'), findsOneWidget);
    expect(find.text('من 80 د.ل'), findsOneWidget, reason: 'the whole car shrinks to one row');
    expect(find.text('أرخص'), findsNothing, reason: 'the notice takes the place of the tags');
    expect(find.textContaining('نبّهني'), findsNothing, reason: 'no such call on the server yet: nothing is promised');
    expect(find.textContaining('التالي'), findsNothing);

    await _tap(t, find.text('اطلب سيارة كاملة بدلها'));
    expect(find.byKey(const ValueKey('ic-no-trip')), findsNothing);
    expect(find.byType(IntercitySeatsPage), findsNothing, reason: 'it only picks the whole car');
    await t.tap(find.text('التالي: سيارة كاملة لـزليتن'));
    await t.pumpAndSettle();
    expect(find.byType(IntercityFarePage), findsOneWidget);
  });

  testWidgets('the sheet ends at its button, and a short phone scrolls it without an overflow', (t) async {
    await _phone(t);
    await t.pumpWidget(_page(_home()));
    final button = t.getRect(find.widgetWithText(FilledButton, 'التالي: سيارة كاملة لـزليتن'));
    expect(844 - button.bottom, 18, reason: 'nothing under the button but its margin');
    final sheetTop = t.getRect(find.text('وين مسافر؟')).top;
    expect(sheetTop, greaterThan(200), reason: 'the map keeps the rest of the screen');

    await t.binding.setSurfaceSize(const Size(320, 480));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('التالي: سيارة كاملة لـزليتن').hitTestable(), findsOneWidget, reason: 'the button stays in reach');
  });
}
