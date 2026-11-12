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

  testWidgets('«شن تبعت؟»: size, where, the receiver, the rules — nothing is sent until all is there', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Map<String, Object?>? sent;
    await t.pumpWidget(MaterialApp(
      home: ParcelPage(
        home: _home(),
        pick: const IcPlace(32.35, 15.1, 'شارع طرابلس'),
        pickDrop: () async => const IcPlace(32.39, 15.13, 'الزروق'),
        send: (p) async {
          sent = p;
          return IntercityResult(true, 'طلبنا كابتن');
        },
      ),
    ));
    expect(find.text('شن تبعت؟ 📦'), findsOneWidget);
    expect(find.text('من LYD 7'), findsOneWidget);
    await t.tap(find.text('اطلب توصيل'));
    await t.pump();
    expect(find.text('اختار وين يوصل الطرد.'), findsOneWidget);
    expect(sent, isNull);

    await t.tap(find.byKey(const ValueKey('parcel-drop')));
    await t.pumpAndSettle();
    expect(find.text('الزروق'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('parcel-name')), 'أحمد');
    await t.enterText(find.byKey(const ValueKey('parcel-phone')), '0912345678');
    await t.tap(find.bySemanticsLabel('كبير'));
    await t.tap(find.text('المستلم (نقدًا)'));
    await t.pump();
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

  testWidgets('the home bar: «توصيل» opens where parcels are open, else «قريبًا»', (t) async {
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
    await t.tap(find.text('توصيل'));
    expect(opened, 1);
  });
}
