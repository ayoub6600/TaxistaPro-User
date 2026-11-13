import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/functions/tow_api.dart';
import 'package:taxista/pages/onTripPage/home_quick_actions.dart';
import 'package:taxista/pages/tow/tow_page.dart';
import 'package:taxista/pages/tow/tow_ride_card.dart';

TowHome _home({int trucks = 2}) => TowHome({
      'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'trucks_online': trucks, 'lift_fee': 50,
      'emergency_text': 'لو فيه إصابات، اتصل بالإسعاف.',
      'conditions': [
        {'key': 'not_starting', 'label': 'ما تشتغلش', 'flatbed': false},
        {'key': 'accident', 'label': 'حادث', 'flatbed': true},
      ],
      'cars': [
        {'key': 'sedan', 'label': 'صالون', 'flatbed': false},
        {'key': 'motorcycle', 'label': 'موتو', 'flatbed': true},
      ],
      'workshops': [
        {'id': 3, 'name': 'ورشة الحاج سالم', 'address': 'شارع طرابلس', 'lat': 32.37, 'lng': 15.12},
      ],
    });

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> tall(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => t.binding.setSurfaceSize(null));
  }

  testWidgets('«شن صار للسيارة؟»: nothing goes until every answer is there, and the price shows line by line', (t) async {
    await tall(t);
    Map<String, Object?>? sent;
    final quotes = <String>[];
    await t.pumpWidget(MaterialApp(
      home: TowPage(
        home: _home(),
        pick: const IcPlace(32.35, 15.1, 'طريق الكورنيش'),
        quote: (c, car, d) async {
          quotes.add('$c/$car/${d.address}');
          return TowQuote({'total': 102, 'km': 13, 'lift': 50, 'distance': 52, 'flatbed': 0, 'night': 0, 'needs_flatbed': false});
        },
        send: (tow) async {
          sent = tow;
          return IntercityResult(true, 'طلبنا لك أقرب ساحبة 🛻');
        },
      ),
    ));
    expect(find.text('شن صار للسيارة؟ 🛻'), findsOneWidget);
    expect(find.text('2 ساحبات متاحة في مصراتة الآن'), findsOneWidget);

    await t.tap(find.text('اطلب ساحبة'));
    await t.pump();
    expect(find.text('اختار شن صار للسيارة.'), findsOneWidget);

    await t.tap(find.text('ما تشتغلش'));
    await t.tap(find.text('صالون'));
    await t.tap(find.byKey(const ValueKey('tow-ws-3')));
    await t.pumpAndSettle();
    expect(quotes.last, 'not_starting/sedan/ورشة الحاج سالم');
    expect(find.byKey(const ValueKey('tow-flatbed')), findsNothing);
    expect(find.text('رفع السيارة (يشمل مشوار الساحبة لعندك)'), findsOneWidget);
    expect(find.text('LYD 102'), findsWidgets);

    await t.tap(find.textContaining('اطلب ساحبة'));
    await t.pump();
    expect(find.text('أكّد إن السيارة متاعك أو عندك إذن تحركها.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tow-owner')));
    await t.pump();
    await t.tap(find.textContaining('اطلب ساحبة'));
    await t.pumpAndSettle();
    expect(sent!['condition'], 'not_starting');
    expect(sent!['workshop_id'], 3);
  });

  testWidgets('an accident: the emergency note, the flatbed, and «ما فيش إصابات» before anything', (t) async {
    await tall(t);
    Map<String, Object?>? sent;
    await t.pumpWidget(MaterialApp(
      home: TowPage(
        home: _home(trucks: 0),
        pick: const IcPlace(32.35, 15.1, ''),
        quote: (c, car, d) async => TowQuote({'total': 147, 'km': 13, 'lift': 50, 'distance': 52, 'flatbed': 20, 'night': 24.4, 'needs_flatbed': true}),
        pickPlace: (role) async => const IcPlace(32.39, 15.13, 'البيت'),
        send: (tow) async {
          sent = tow;
          return IntercityResult(true, 'تم');
        },
      ),
    ));
    expect(find.text('كل الساحبات مشغولة الآن. نطلبها وتوصلك أول ما تتوفر وحدة.'), findsOneWidget);
    await t.tap(find.text('حادث'));
    await t.tap(find.text('صالون'));
    await t.pump();
    expect(find.byKey(const ValueKey('tow-accident')), findsOneWidget);
    expect(find.byKey(const ValueKey('tow-flatbed')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tow-other')));
    await t.pumpAndSettle();
    expect(find.text('البيت'), findsOneWidget);
    expect(find.text('سطحة'), findsOneWidget, reason: 'the flatbed line');
    expect(find.text('زيادة الليل'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tow-owner')));
    await t.pump();
    await t.tap(find.textContaining('اطلب ساحبة'));
    await t.pump();
    expect(find.text('في الحادث: أكّد إن ما فيش إصابات أو إن الشرطة سمحت.'), findsOneWidget);
    expect(sent, isNull);
    await t.tap(find.byKey(const ValueKey('tow-injuries')));
    await t.pump();
    await t.tap(find.textContaining('اطلب ساحبة'));
    await t.pumpAndSettle();
    expect(sent!['injuries_cleared'], isTrue);
    expect(sent!['workshop_id'], isNull);
  });

  testWidgets('the ride card says what to do now, and the home button opens the tow', (t) async {
    final card = TowRideCard.of({
      'is_driver_arrived': 1, 'is_trip_start': 0,
      'tow': {'kind_label': 'سطحة', 'condition_label': 'حادث', 'car_label': 'صالون', 'before_sides': ['front', 'back'], 'emergency_text': 'اتصل بالإسعاف', 'workshop': {'name': 'ورشة الحاج سالم'}},
    })!;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: card))));
    expect(find.text('ساحبة · سطحة'), findsOneWidget);
    expect(find.text('الكابتن عند السيارة يصوّرها قبل الرفع (2 من 4).'), findsOneWidget);
    expect(find.text('⚠️ اتصل بالإسعاف'), findsOneWidget);
    expect(TowRideCard.of({'id': 'x'}), isNull);

    var opened = 0;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeQuickActions(
          rtl: true, onChooseDestination: () {}, onRideWithoutDestination: () {}, showRideWithoutDestination: true, destinations: const [],
          onTow: () => opened++, onSoon: (_) {},
        ),
      ),
    ));
    await t.pumpAndSettle();
    await t.tap(find.text('ساحبة'));
    expect(opened, 1);
  });
}
