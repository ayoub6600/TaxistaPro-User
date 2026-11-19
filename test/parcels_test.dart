import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/functions/parcel_api.dart';
import 'package:taxista/pages/onTripPage/home_quick_actions.dart';
import 'package:taxista/pages/parcels/parcel_code_card.dart';
import 'package:taxista/pages/parcels/parcel_page.dart';

ParcelHome _home() => ParcelHome({
      'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'banned': 'فلوس كاش، ذهب',
      'sizes': [
        {'size': 'small', 'base': 5, 'per_km': 0.5},
        {'size': 'medium', 'base': 7, 'per_km': 0.6},
        {'size': 'large', 'base': 10, 'per_km': 0.8},
      ],
    });

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('«نوصلولك»: both places, every size priced for the distance, the receiver, the rules — nothing is sent until all is there', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Map<String, Object?>? sent;
    final asked = <String>[];
    await t.pumpWidget(MaterialApp(
      home: ParcelPage(
        home: _home(),
        pick: const IcPlace(32.35, 15.1, 'شارع طرابلس'),
        map: (_, __) => const SizedBox.expand(),
        // he moves the pickup to his shop and picks where it goes
        pickDrop: (role) async => (const IcPlace(32.36, 15.11, 'محلي'), const IcPlace(32.39, 15.13, 'الزروق')),
        quote: (p, d, size) async {
          asked.add('${p.address}>${d.address}:$size');
          return IntercityResult(true, '', {'price': {'small': 8.5, 'medium': 10.5, 'large': 14}[size], 'km': 4.2});
        },
        send: (p) async {
          sent = p;
          return IntercityResult(true, 'طلبنا كابتن');
        },
      ),
    ));
    expect(find.text('من وين ياخذها الكابتن'), findsOneWidget);
    expect(find.text('لوين توصل'), findsOneWidget);
    expect(find.text('مكانك الآن · شارع طرابلس'), findsOneWidget);
    expect(find.text('من LYD 7'), findsOneWidget, reason: 'before the places: the size\'s own start');
    expect(find.text('اختار لوين توصل 👇'), findsOneWidget);
    await t.tap(find.text('اطلب توصيل'));
    await t.pump();
    expect(find.text('اختار وين يوصل الطرد.'), findsOneWidget);
    expect(sent, isNull);

    await t.tap(find.byKey(const ValueKey('parcel-drop')));
    await t.pumpAndSettle();
    expect(find.text('الزروق'), findsOneWidget);
    expect(find.text('محلي'), findsOneWidget);
    expect(asked, ['محلي>الزروق:small', 'محلي>الزروق:medium', 'محلي>الزروق:large']);
    for (final p in ['LYD 8.5', 'LYD 10.5', 'LYD 14']) {
      expect(find.text(p), findsWidgets, reason: 'each size shows its price for 4.2 km');
    }
    expect(find.text('4.2 كم · LYD 10.5'), findsOneWidget, reason: 'the chip on the map');
    await t.enterText(find.byKey(const ValueKey('parcel-name')), 'أحمد');
    await t.enterText(find.byKey(const ValueKey('parcel-phone')), '0912345678');
    await t.tap(find.bySemanticsLabel('كبير'));
    await t.tap(find.text('المستلم (نقدًا)'));
    await t.pump();
    expect(find.text('4.2 كم · LYD 14'), findsOneWidget, reason: 'another size: no new question to the server');
    expect(asked.length, 3);
    await t.tap(find.textContaining('اطلب توصيل'));
    await t.pump();
    expect(find.text('أكّد إن الطرد مش من الممنوعات.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('parcel-rules')));
    await t.pump();
    await t.tap(find.textContaining('اطلب توصيل'));
    await t.pumpAndSettle();
    expect(sent!['size'], 'large');
    expect(sent!['payer'], 'receiver');
    expect(sent!['receiver_phone'], '0912345678');
    expect((sent!['pick'] as IcPlace).address, 'محلي');
  });

  testWidgets('the title takes the admin\'s words in turn', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: ParcelPage(
        home: ParcelHome({..._home().raw, 'home_names': ['طرود', 'أمانات', 'توصيل']}),
        pick: const IcPlace(32.35, 15.1, ''),
        map: (_, __) => const SizedBox.expand(),
      ),
    ));
    expect(find.text('طرود'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 2500));
    await t.pumpAndSettle();
    expect(find.text('أمانات'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 2500));
    await t.pumpAndSettle();
    expect(find.text('توصيل'), findsOneWidget);
  });

  testWidgets('the sender sees the delivery code and can send it; nothing once delivered', (t) async {
    final card = ParcelCodeCard.of({
      'parcel': {'code': '4827', 'receiver_name': 'أحمد', 'size_label': 'متوسط', 'picked_up': true},
    })!;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: card))));
    expect(find.text('الطرد مع الكابتن، في الطريق لـأحمد'), findsOneWidget);
    for (final d in ['4', '8', '2', '7']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.text('ابعت الكود لـأحمد'), findsOneWidget);
    expect(ParcelCodeCard.of({'parcel': {'code': null}}), isNull, reason: 'a driver never gets the code');
    expect(ParcelCodeCard.of({'parcel': {'code': '4827', 'delivered': true}}), isNull);
    expect(ParcelCodeCard.of({}), isNull);
  });

  testWidgets('the home bar: «طرود» (the admin can rename it) opens where parcels are open', (t) async {
    var opened = 0;
    Widget bar(VoidCallback? onDelivery) => MaterialApp(
          home: Scaffold(
            body: HomeQuickActions(
              rtl: true,
              onChooseDestination: () {},
              onRideWithoutDestination: () {},
              showRideWithoutDestination: true,
              destinations: const [],
              onDelivery: onDelivery,
              onSoon: (_) {},
            ),
          ),
        );
    await t.pumpWidget(bar(() => opened++));
    await t.pumpAndSettle();
    await t.tap(find.text('طرود'));
    expect(opened, 1);
    // the admin's own name wins over the default
    ParcelApi.notifier.value = ParcelHome({'enabled': true, 'home_name': 'مشاوير طرود'});
    await t.pumpWidget(bar(() => opened++));
    await t.pumpAndSettle();
    await t.tap(find.text('مشاوير طرود'));
    expect(opened, 2);
    ParcelApi.notifier.value = null;
  });
}
