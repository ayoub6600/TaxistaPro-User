import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/functions/intercity_api.dart';
import 'package:taxista/functions/parcel_api.dart';
import 'package:taxista/functions/parcel_saved.dart';
import 'package:taxista/pages/onTripPage/home_sheet/home_services.dart';
import 'package:taxista/pages/onTripPage/home_sheet/rider_home_sheet.dart';
import 'package:taxista/pages/parcels/parcel_code_card.dart';
import 'package:taxista/pages/parcels/parcel_confirm_sheet.dart';
import 'package:taxista/pages/parcels/parcel_options.dart';
import 'package:taxista/pages/parcels/parcel_page.dart';
import 'package:taxista/pages/parcels/parcel_pins.dart';
import 'package:taxista/pages/parcels/parcel_places.dart';

ParcelHome _home() => ParcelHome({
      'enabled': true, 'city': 'مصراتة', 'currency': 'LYD', 'banned': 'فلوس كاش، ذهب',
      'sizes': [
        {'size': 'small', 'base': 5, 'per_km': 0.5},
        {'size': 'medium', 'base': 7, 'per_km': 0.6},
        {'size': 'large', 'base': 10, 'per_km': 0.8},
      ],
    });

IntercityResult _priced(IcPlace p, IcPlace d, String size) => IntercityResult(true, '', {'price': {'small': 8.5, 'medium': 10.5, 'large': 14}[size], 'km': 4.2});

/// the page with both places chosen and the receiver written, ready to ask
Future<void> _ready(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('parcel-drop')));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const ValueKey('parcel-name')), 'أحمد');
  await t.enterText(find.byKey(const ValueKey('parcel-phone')), '0912345678');
  await t.tap(find.byKey(const ValueKey('parcel-rules')));
  await t.pump();
}

Widget _page({ParcelHome? home, num? balance, Future<IntercityResult> Function(Map<String, Object?>)? send, IcPlace? drop, String? name, String? phone, String? size, List<String>? asked}) => MaterialApp(
      home: ParcelPage(
        home: home ?? _home(),
        pick: const IcPlace(32.35, 15.1, 'شارع طرابلس'),
        pickIsHere: drop == null,
        drop: drop,
        receiverName: name,
        receiverPhone: phone,
        size: size,
        map: (_, __) => const SizedBox.expand(),
        pickDrop: (role) async => (const IcPlace(32.36, 15.11, 'محلي'), const IcPlace(32.39, 15.13, 'الزروق')),
        quote: (p, d, s) async {
          asked?.add(s);
          return _priced(p, d, s);
        },
        balance: () => balance,
        send: send ?? (p) async => IntercityResult(true, 'طلبنا كابتن'),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    await t.tap(find.byKey(const ValueKey('parcel-payer-receiver')));
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
    expect(sent, isNull, reason: 'the summary first: nothing leaves before «أكّد الطلب»');
    expect(find.text('راجع طلبك 📦'), findsOneWidget);
    expect(find.text('المستلم · كاش للكابتن وقت التسليم'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('parcel-confirm')));
    await t.pumpAndSettle();
    expect(sent!['size'], 'large');
    expect(sent!['payer'], 'receiver');
    expect(sent!['payment'], 'auto');
    expect(sent!['needs_code'], true);
    expect(sent!['receiver_phone'], '0912345678');
    expect((sent!['pick'] as IcPlace).address, 'محلي');
    // the receiver and the place are new: he is asked once whether to keep them
    expect(find.text('نحفظ المستلم للمرات الجاية؟'), findsOneWidget);
    expect(find.text('نحفظ مكان الاستلام؟'), findsOneWidget);
    await t.tap(find.text('لا، شكرًا'));
    await t.pumpAndSettle();
    expect(await ParcelSaved.receivers(), isEmpty, reason: '«لا، شكرًا» saves nothing');
  });

  testWidgets('a tap on «أنا» (or anything but the request) never sends; the summary says how he pays and «رجوع للتعديل» sends nothing', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    var sends = 0;
    await t.pumpWidget(_page(balance: 50, send: (p) async {
      sends++;
      return IntercityResult(true, 'تم');
    }));
    await _ready(t);
    await t.tap(find.byKey(const ValueKey('parcel-payer-receiver')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('parcel-payer-sender')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parcel-code-switch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parcel-code-switch')));
    await t.pumpAndSettle();
    expect(sends, 0);
    expect(find.text('راجع طلبك 📦'), findsNothing);
    await t.tap(find.byKey(const ValueKey('parcel-request')));
    await t.pumpAndSettle();
    for (final line in ['محلي', 'الزروق', '👜 متوسط', 'LYD 10.5', 'أنا · من محفظتك (رصيدك LYD 50)']) {
      expect(find.descendant(of: find.byType(ParcelConfirmSheet), matching: find.text(line)), findsOneWidget, reason: line);
    }
    expect(find.textContaining('أحمد · '), findsOneWidget);
    expect(find.text('بكود: الكابتن ما يسلّمش إلا للي عنده الكود'), findsOneWidget);
    await t.tap(find.text('رجوع للتعديل'));
    await t.pumpAndSettle();
    expect(sends, 0);
  });

  test('«أنا»: from the wallet when it holds the price, else cash at pickup; offers are cash', () {
    expect(ParcelPay.senderWallet(price: 10, balance: 12, offers: false), isTrue);
    expect(ParcelPay.senderWallet(price: 10, balance: 9.5, offers: false), isFalse);
    expect(ParcelPay.senderWallet(price: 10, balance: 50, offers: true), isFalse);
    expect(ParcelPay.senderWallet(price: null, balance: 50, offers: false), isNull);
    expect(ParcelPay.senderLine(price: 10, balance: 9.5, offers: false, currency: 'LYD'), 'كاش للكابتن لما ياخذ الطرد');
    expect(ParcelPay.senderLine(price: 10, balance: 12, offers: false, currency: 'LYD'), 'من محفظتك (رصيدك LYD 12)');
    expect(ParcelPay.receiverLine(), 'كاش للكابتن وقت التسليم');
  });

  testWidgets('«مين يدفع؟» says how: a low balance is cash at pickup, the receiver cash at delivery', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_page(balance: 3));
    await t.pumpAndSettle();
    expect(find.text('من محفظتك لو رصيدك يكفي، وإلا كاش للكابتن لما ياخذ الطرد'), findsOneWidget, reason: 'no price yet');
    await _ready(t);
    expect(find.text('كاش للكابتن لما ياخذ الطرد'), findsOneWidget);
    expect(find.text('كاش للكابتن وقت التسليم'), findsOneWidget);
  });

  testWidgets('«التسليم بكود» is on with why it is safer; off warns him and sends needs_code false', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Map<String, Object?>? sent;
    await t.pumpWidget(_page(send: (p) async {
      sent = p;
      return IntercityResult(true, 'تم');
    }));
    await t.pumpAndSettle();
    expect(find.text('الكود أأمن: الكابتن ما يسلّمش الطرد إلا للي عنده الكود'), findsOneWidget);
    await _ready(t);
    await t.tap(find.byKey(const ValueKey('parcel-code-switch')));
    await t.pumpAndSettle();
    expect(find.text('بدون كود: أنت المسؤول عن التسليم'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('parcel-request')));
    await t.pumpAndSettle();
    expect(find.text('بدون كود: أنت المسؤول عن التسليم'), findsNWidgets(2), reason: 'the summary says it too');
    await t.tap(find.byKey(const ValueKey('parcel-confirm')));
    await t.pumpAndSettle();
    expect(sent!['needs_code'], false);
  });

  testWidgets('saved receivers and pickup places: kept after a booking, one tap fills, a long press removes', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(_page());
    await t.pumpAndSettle();
    await _ready(t);
    await t.tap(find.byKey(const ValueKey('parcel-request')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parcel-confirm')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parcel-save-label-المحل')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('parcel-save')));
    await t.pumpAndSettle();
    expect((await ParcelSaved.receivers()).single.name, 'أحمد');
    expect((await ParcelSaved.places()).single.label, 'المحل');
    expect((await ParcelSaved.places()).single.place.address, 'محلي');

    // next time: chips above the receiver and under «من وين ياخذها الكابتن»
    final asked = <String>[];
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_page(drop: const IcPlace(32.39, 15.13, 'الزروق'), asked: asked));
    await t.pumpAndSettle();
    expect(find.text('مكانك الآن · شارع طرابلس'), findsNothing, reason: 'a prefilled pickup is not «مكانك الآن»');
    asked.clear();
    await t.tap(find.text('المحل'));
    await t.pumpAndSettle();
    expect(find.text('محلي'), findsOneWidget);
    expect(asked, ['small', 'medium', 'large'], reason: 'priced again from the saved place');
    await t.tap(find.text('أحمد'));
    await t.pump();
    expect(t.widget<TextField>(find.byKey(const ValueKey('parcel-name'))).controller!.text, 'أحمد');
    expect(t.widget<TextField>(find.byKey(const ValueKey('parcel-phone'))).controller!.text, '0912345678');
    // already saved: not asked again
    await t.tap(find.byKey(const ValueKey('parcel-rules')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('parcel-request')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('parcel-confirm')));
    await t.pumpAndSettle();
    expect(find.text('نحفظوا للمرات الجاية؟'), findsNothing);

    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_page());
    await t.pumpAndSettle();
    await t.longPress(find.text('أحمد'));
    await t.pumpAndSettle();
    expect(await ParcelSaved.receivers(), isEmpty);
    await t.longPress(find.text('المحل'));
    await t.pumpAndSettle();
    expect(await ParcelSaved.places(), isEmpty);
  });

  test('saved receivers: newest first, the same number once, ten at most', () async {
    for (var i = 0; i < 12; i++) {
      await ParcelSaved.saveReceiver('م$i', '09100000${i.toString().padLeft(2, '0')}');
    }
    await ParcelSaved.saveReceiver('م11 جديد', '091 000 0011');
    final r = await ParcelSaved.receivers();
    expect(r.length, 10);
    expect(r.first.name, 'م11 جديد');
    expect(r.where((e) => SavedReceiver.digits(e.phone) == '0910000011').length, 1);
  });

  test('the place search lists saved places and favourites, and gives back the plain address', () {
    final (favs, plain) = ParcelPlaces.favourites([const SavedPickPlace('البيت', IcPlace(32.1, 15.2, 'شارع بنغازي'))], [
      {'address_name': 'Work', 'pick_address': 'المنطقة الحرة', 'pick_lat': '32.3', 'pick_lng': '15.2'},
      {'address_name': 'Bad', 'pick_address': 'x', 'pick_lat': null},
    ]);
    expect(favs.map((e) => e.address), ['🏠 البيت · شارع بنغازي', '⭐ Work · المنطقة الحرة']);
    expect(plain['🏠 البيت · شارع بنغازي'], 'شارع بنغازي');
    expect(ParcelPlaces.recents([
      {'address': 'الزروق', 'latlng': [32.39, 15.13]},
      {'address': 'bad', 'latlng': ['x', 1]},
    ]).single.address, 'الزروق');
  });

  test('the drop pin is blue (owner 2026-11-19), the pickup green, and the map hint says so', () {
    expect(ParcelPin.dropColor, const Color(0xff0879FA));
    expect(ParcelPin.pickColor, const Color(0xff16A34A));
    expect(ParcelPlaces.copy.mapHints[1], contains('الأزرق'));
  });

  testWidgets('«لما الزبون يختار»: offers first only when the admin\'s default says so', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    expect(ParcelHome({'price_mode': 'choice', 'price_default': 'offers'}).startWithOffers, isTrue);
    expect(ParcelHome({'price_mode': 'choice', 'price_default': 'fixed'}).startWithOffers, isFalse);
    expect(ParcelHome({'price_mode': 'choice'}).startWithOffers, isFalse);
    expect(ParcelHome({'price_mode': 'offers'}).startWithOffers, isTrue);
    await t.pumpWidget(_page(home: ParcelHome({..._home().raw, 'price_mode': 'choice', 'price_default': 'offers'}), drop: const IcPlace(32.39, 15.13, 'الزروق')));
    await t.pumpAndSettle();
    expect(find.textContaining('اطلب عروض'), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_page(home: ParcelHome({..._home().raw, 'price_mode': 'choice', 'price_default': 'fixed'}), drop: const IcPlace(32.39, 15.13, 'الزروق')));
    await t.pumpAndSettle();
    expect(find.text('اطلب توصيل · LYD 10.5'), findsOneWidget);
  });

  testWidgets('«اطلبها مرة ثانية» fills the page: both places, the receiver and the size, priced at once', (t) async {
    await t.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final asked = <String>[];
    await t.pumpWidget(_page(drop: const IcPlace(32.39, 15.13, 'الزروق'), name: 'سالم', phone: '0923334444', size: 'small', asked: asked));
    await t.pumpAndSettle();
    expect(asked, ['small', 'medium', 'large']);
    expect(find.text('الزروق'), findsOneWidget);
    expect(find.text('شارع طرابلس'), findsOneWidget);
    expect(t.widget<TextField>(find.byKey(const ValueKey('parcel-name'))).controller!.text, 'سالم');
    expect(find.text('اطلب توصيل · LYD 8.5'), findsOneWidget, reason: 'the small size');
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
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await t.tap(find.byKey(const ValueKey('parcel-copy-code')));
    await t.pump();
    expect(copied, '4827');
    expect(find.text('نسخنا الكود 4827'), findsOneWidget);
    expect(ParcelCodeCard.of({'parcel': {'code': null}}), isNull, reason: 'a driver never gets the code');
    expect(ParcelCodeCard.of({'parcel': {'code': '4827', 'delivered': true}}), isNull);
    expect(ParcelCodeCard.of({}), isNull);
  });

  testWidgets('a parcel without a code says he answers for it, and the card says who pays how', (t) async {
    final card = ParcelCodeCard.of({
      'parcel': {'code': '4827', 'needs_code': false, 'receiver_name': 'أحمد', 'pay': {'who': 'sender', 'how': 'cash', 'amount': 12, 'sender': 'تدفع 12 LYD كاش للكابتن لما ياخذ الطرد'}},
    })!;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: card))));
    expect(find.text('💵 تدفع 12 LYD كاش للكابتن لما ياخذ الطرد'), findsOneWidget);
    expect(find.textContaining('بدون كود'), findsOneWidget);
    expect(find.byKey(const ValueKey('parcel-copy-code')), findsNothing);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('the home bar: «طرود» (the admin can rename it) opens where parcels are open', (t) async {
    var opened = 0;
    Widget bar(VoidCallback? onDelivery) => MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: HomeServicesStrip(
                services: HomeServices.build(
                  rtl: true,
                  onRideWithoutDestination: () {},
                  onSoon: (_) {},
                  onDelivery: onDelivery,
                  parcels: ParcelApi.notifier.value,
                ),
              ),
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
