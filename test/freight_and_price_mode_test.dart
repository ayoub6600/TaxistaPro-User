import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/freight_api.dart';
import 'package:taxista/functions/functions.dart' show languageDirection;
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/functions/tow_api.dart';
import 'package:taxista/pages/freight/freight_page.dart';
import 'package:taxista/pages/freight/freight_ride_card.dart';
import 'package:taxista/pages/tow/tow_page.dart';

FreightHome _freight() => FreightHome({
      'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'worker_price': 25, 'floor_price': 10, 'max_workers': 4,
      'free_loading_minutes': 20, 'horizon_days': 7, 'max_photos': 3,
      'categories': [
        {'key': 'furniture', 'label': 'عفش'},
        {'key': 'appliances', 'label': 'أجهزة'},
      ],
      'classes': [
        {'key': 'pickup', 'zone_type_id': 'zt-pickup', 'label': 'بيك أب', 'load': 'حتى 1 طن', 'base': 40},
        {'key': 'van', 'zone_type_id': 'zt-van', 'label': 'فان مقفول', 'load': 'حتى 1.5 طن', 'base': 60},
      ],
    });

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    languageDirection = 'rtl';
  });

  Future<void> tall(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(430, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
  }

  testWidgets('freight: what, which vehicle, workers, floors, where to; the suggested price line by line; his price in the range', (t) async {
    await tall(t);
    Map<String, Object?>? sent;
    final asked = <String>[];
    await t.pumpWidget(MaterialApp(
      home: FreightPage(
        home: _freight(),
        pick: const IcPlace(32.35, 15.1, 'شارع طرابلس'),
        pickPlace: (role) async => const IcPlace(32.39, 15.13, 'الزروق'),
        quote: (cls, workers, floors) async {
          asked.add('$cls/$workers/$floors');
          final s = 60 + 20 + workers * 25 + floors * 10;
          return FreightQuote({'suggested': s, 'min': (s * .8).floor(), 'max': (s * 2.5).ceil(), 'km': 5, 'base': 60, 'distance': 20, 'workers': workers * 25, 'floors': floors * 10});
        },
        send: (body) async {
          sent = body;
          return IntercityResult(true, 'تم');
        },
      ),
    ));

    await t.tap(find.textContaining('اطلب عروض'));
    await t.pump();
    expect(find.text('اختار شن تنقل.'), findsOneWidget);

    await t.tap(find.text('عفش'));
    await t.tap(find.text('فان مقفول'));
    await t.tap(find.byKey(const ValueKey('freight-drop-place')));
    await t.pumpAndSettle();
    expect(asked.last, 'van/0/0');
    expect(find.text('LYD 80'), findsWidgets);

    // two workers, the third floor without a lift at the pick-up: the price follows
    await t.tap(find.bySemanticsLabel('عمال تحميل زيادة'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('عمال تحميل زيادة'));
    await t.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await t.tap(find.descendant(of: find.byKey(const ValueKey('freight-pick-floor')), matching: find.bySemanticsLabel('الدور زيادة')));
      await t.pumpAndSettle();
    }
    expect(asked.last, 'van/2/3');
    expect(find.text('LYD 160'), findsWidgets, reason: '60 + 20 + 2×25 + 3×10');
    // a lift there: the floors cost nothing
    await t.tap(find.byKey(const ValueKey('freight-pick-lift')));
    await t.pumpAndSettle();
    expect(asked.last, 'van/2/0');

    await t.tap(find.textContaining('اطلب عروض'));
    await t.pumpAndSettle();
    expect(sent!['vehicle_type'], 'zt-van', reason: 'the class service, so the right owners are asked');
    expect([sent!['freight_class'], sent!['freight_category'], sent!['workers'], sent!['pick_floor'], sent!['pick_lift'], sent!['rider_proposed_fare']],
        ['van', 'furniture', 2, 3, 1, 130]);
    expect(sent!['is_later'], 0);
  });

  testWidgets('the freight card on the ride says what moves and what happens now', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FreightRideCard.of({
          'is_driver_arrived': 1,
          'freight': {'class': 'van', 'class_label': 'فان مقفول', 'category_label': 'عفش', 'items': 'غرفة نوم', 'workers': 2,
            'pick_floor_label': 'الدور 3 · بدون مصعد', 'drop_floor_label': 'أرضي', 'photos': const [], 'free_loading_minutes': 20},
        })!,
      ),
    ));
    expect(find.text('شحن · عفش · فان مقفول'), findsOneWidget);
    expect(find.text('«غرفة نوم»'), findsOneWidget);
    expect(find.textContaining('أول 20 دقيقة تحميل مجانية'), findsOneWidget);
  });

  testWidgets('a tow by offers when the admin lets him choose: his price goes, inside the range', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 2000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Map<String, Object?>? sent;
    await t.pumpWidget(MaterialApp(
      home: TowPage(
        home: TowHome({
          'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'trucks_online': 1, 'price_mode': 'choice', 'offer_min_percent': 80, 'offer_max_percent': 150,
          'conditions': [{'key': 'not_starting', 'label': 'ما تشتغلش', 'flatbed': false}],
          'cars': [{'key': 'sedan', 'label': 'صالون', 'flatbed': false}],
          'workshops': [{'id': 3, 'name': 'ورشة', 'address': '', 'lat': 32.37, 'lng': 15.12}],
        }),
        pick: const IcPlace(32.35, 15.1, 'طريق الكورنيش'),
        quote: (c, car, d) async => TowQuote({'total': 102, 'km': 13, 'lift': 50, 'distance': 52, 'flatbed': 0, 'night': 0, 'needs_flatbed': false}),
        send: (tow) async {
          sent = tow;
          return IntercityResult(true, 'تم');
        },
      ),
    ));
    await t.tap(find.text('ما تشتغلش'));
    await t.tap(find.text('صالون'));
    await t.tap(find.byKey(const ValueKey('tow-ws-3')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('price-mode')), findsOneWidget);
    expect(find.textContaining('اطلب ساحبة · LYD 102'), findsOneWidget, reason: 'fixed until he asks for offers');

    await t.tap(find.text('اطلب عروض'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('نقص'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('tow-owner')));
    await t.pump();
    await t.tap(find.textContaining('اطلب عروض · LYD'));
    await t.pumpAndSettle();
    expect(sent!['fare'], 97, reason: 'from 102 down one step of 5 (a price over 100)');
  });

  testWidgets('in English the freight page is English, left to right', (t) async {
    await tall(t);
    languageDirection = 'ltr';
    addTearDown(() => languageDirection = 'rtl');
    await t.pumpWidget(MaterialApp(home: FreightPage(home: _freight(), pick: const IcPlace(32.35, 15.1, ''))));
    expect(find.text('What are you moving? 🚚'), findsOneWidget);
    expect(find.text('Furniture'), findsOneWidget);
    expect(find.text('Closed van'), findsOneWidget);
    expect(find.text('up to 1.5 t'), findsOneWidget);
    expect(find.text('Loading workers'), findsOneWidget);
    expect(find.text('Ask for offers'), findsOneWidget);
    expect(Directionality.of(t.element(find.text('Loading workers'))), TextDirection.ltr);
  });
}
