import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/contests/contests_api.dart';
import 'package:taxista/functions/freight_api.dart';
import 'package:taxista/pages/onTripPage/home_sheet/home_places_sheet.dart';
import 'package:taxista/pages/onTripPage/home_sheet/home_services.dart';
import 'package:taxista/pages/onTripPage/home_sheet/rider_home_sheet.dart';

List<HomeService> _services({bool travel = true, bool freight = false, bool parcels = true, bool tow = false, List<String>? opened}) =>
    HomeServices.build(
      rtl: true,
      onRideWithoutDestination: () => opened?.add('open_ride'),
      onSoon: (s) => opened?.add('soon:$s'),
      onTravel: travel ? () => opened?.add('travel') : null,
      onFreight: freight ? () => opened?.add('freight') : null,
      onDelivery: parcels ? () => opened?.add('parcels') : null,
      onTow: tow ? () => opened?.add('tow') : null,
    );

/// more services than a phone shows at once (the row then scrolls)
List<HomeService> _many() => [
      ..._services(freight: true, tow: true),
      for (final n in ['أولى', 'ثانية'])
        HomeService(id: 'extra-$n', label: 'خدمة $n', icon: Icons.star_rounded, color: Colors.indigo, onTap: () {}),
    ];

List<HomeService> _more(List<String>? opened) => [
      for (final id in ['scheduled', 'recurring', 'wallet', 'invite'])
        HomeService(id: id, label: 'صفحة $id', icon: Icons.star_rounded, color: Colors.teal, onTap: () => opened?.add(id)),
    ];

Future<void> _pump(
  WidgetTester t,
  List<HomeService> services, {
  Size size = const Size(390, 844),
  VoidCallback? onWhereTo,
  VoidCallback? onPlaces,
  ValueNotifier<bool>? expanded,
  Widget Function(BuildContext, bool)? above,
  List<HomeService> more = const [],
}) async {
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size, padding: const EdgeInsets.only(top: 47, bottom: 34)),
      child: Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE8EEF5))),
          Positioned.fill(
            child: RiderHomeSheet(
              services: services,
              onWhereTo: onWhereTo ?? () {},
              onPlaces: onPlaces ?? () {},
              expanded: expanded,
              above: above,
              more: more,
            ),
          ),
        ]),
      ),
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compact: «إلى أين؟», «أماكني» and the five services in the owner\'s order, right to left', (t) async {
    var where = 0, places = 0;
    await _pump(t, _services(), onWhereTo: () => where++, onPlaces: () => places++);
    expect(t.takeException(), isNull);
    await t.tap(find.text('إلى أين؟'));
    await t.tap(find.bySemanticsLabel('أماكني'));
    expect((where, places), (1, 1));
    final xs = [for (final l in ['بدون وجهة', 'سفر', 'نقل بضائع', 'طرود', 'ونش']) t.getCenter(find.text(l)).dx];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], lessThan(xs[i - 1]), reason: 'from the right');
    }
    // the panel stays small: «خدمات أخرى» waits under it
    expect(find.text('خدمات أخرى').hitTestable(), findsNothing);
  });

  testWidgets('a service closed in the city says «قريبًا» and its tap says so', (t) async {
    final opened = <String>[];
    await _pump(t, _services(opened: opened));
    expect(find.text('قريبًا'), findsNWidgets(2), reason: 'نقل بضائع and ونش are closed here');
    await t.tap(find.text('ونش'));
    await t.tap(find.text('طرود'));
    await t.tap(find.text('بدون وجهة'));
    expect(opened, ['soon:ونش', 'parcels', 'open_ride']);
  });

  testWidgets('the blue line hides when every service fits, and follows the scroll from the right when they do not', (t) async {
    await _pump(t, _services());
    expect(find.byKey(const ValueKey('services-track')), findsNothing, reason: 'five fit on a 390 pt phone');

    await _pump(t, _many());
    expect(find.byKey(const ValueKey('services-track')), findsOneWidget);
    final track = t.getRect(find.byKey(const ValueKey('services-track')));
    final start = t.getRect(find.byKey(const ValueKey('services-track-bar')));
    expect(start.right, closeTo(track.right, .5), reason: 'nothing scrolled: the blue part is at the right');
    // in Arabic the rest of the row is to the left: a swipe to the right brings it
    await t.drag(find.byKey(const ValueKey('home-services')), const Offset(300, 0));
    await t.pumpAndSettle();
    final end = t.getRect(find.byKey(const ValueKey('services-track-bar')));
    expect(end.left, closeTo(track.left, .5));
    expect(find.text('خدمة ثانية').hitTestable(), findsOneWidget);
    await t.drag(find.byKey(const ValueKey('home-services')), const Offset(-300, 0));
    await t.pumpAndSettle();
    expect(t.getRect(find.byKey(const ValueKey('services-track-bar'))).right, closeTo(track.right, .5));
  });

  testWidgets('a sideways swipe on the services never moves the panel', (t) async {
    final expanded = ValueNotifier(false);
    await _pump(t, _many(), expanded: expanded);
    final top = t.getTopLeft(find.text('إلى أين؟')).dy;
    await t.drag(find.byKey(const ValueKey('home-services')), const Offset(250, -8));
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.text('إلى أين؟')).dy, top);
    expect(expanded.value, isFalse);
  });

  testWidgets('pulled up: «خدمات أخرى» shows the other pages, never the row\'s services again; pulled down: compact again', (t) async {
    final expanded = ValueNotifier(false);
    final opened = <String>[];
    await _pump(t, _services(opened: opened), expanded: expanded, more: _more(opened), above: (_, up) => Text(up ? 'gift icon' : 'gift bar'));
    expect(find.text('gift bar'), findsOneWidget);
    expect(find.text('خدمات أخرى').hitTestable(), findsNothing);
    final top = t.getTopLeft(find.text('إلى أين؟')).dy;

    await t.drag(find.text('إلى أين؟'), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(expanded.value, isTrue);
    expect(find.text('gift icon'), findsOneWidget);
    expect(t.getTopLeft(find.text('إلى أين؟')).dy, lessThan(top - 150), reason: 'the same panel, higher');
    expect(find.text('خدمات أخرى').hitTestable(), findsOneWidget);
    for (final id in ['scheduled', 'recurring', 'wallet', 'invite']) {
      expect(find.byKey(ValueKey('home-more-$id')).hitTestable(), findsOneWidget, reason: id);
    }
    expect(find.text('بدون وجهة'), findsOneWidget, reason: 'only once: in the row');
    await t.tap(find.byKey(const ValueKey('home-more-wallet')));
    expect(opened, ['wallet']);
    // the field and the sideways row are still there
    expect(find.text('إلى أين؟').hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('home-services')).hitTestable(), findsOneWidget);

    await t.drag(find.text('إلى أين؟'), const Offset(0, 400));
    await t.pumpAndSettle();
    expect(expanded.value, isFalse);
    expect(t.getTopLeft(find.text('إلى أين؟')).dy, closeTo(top, 1));
    expect(find.text('gift bar'), findsOneWidget);
  });

  testWidgets('the handle opens and closes it too', (t) async {
    final expanded = ValueNotifier(false);
    await _pump(t, _services(), expanded: expanded, more: _more(null));
    await t.tap(find.bySemanticsLabel('خدمات أخرى'));
    await t.pumpAndSettle();
    expect(expanded.value, isTrue);
    await t.tap(find.bySemanticsLabel('تصغير'));
    await t.pumpAndSettle();
    expect(expanded.value, isFalse);
  });

  for (final size in const [Size(320, 568), Size(360, 640), Size(430, 932)]) {
    testWidgets('no overflow on ${size.width.toInt()}×${size.height.toInt()}, compact and pulled up', (t) async {
      await _pump(t, _many(), size: size, more: _more(null));
      expect(t.takeException(), isNull);
      await t.drag(find.text('إلى أين؟'), const Offset(0, -500));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('إلى أين؟').hitTestable(), findsOneWidget);
    });
  }

  test('the owner\'s names, and the admin\'s own name when he set one', () {
    final list = HomeServices.build(rtl: true, onRideWithoutDestination: () {}, onSoon: (_) {});
    expect([for (final s in list) s.label], ['بدون وجهة', 'نقل بضائع', 'طرود', 'ونش']);
    final named = HomeServices.build(rtl: true, onRideWithoutDestination: () {}, onSoon: (_) {}, freight: FreightHome({'home_name': 'نقل أثاث'}));
    expect(named[1].label, 'نقل أثاث');
  });

  testWidgets('«أماكني» lists the places and runs the tapped one after closing', (t) async {
    final picked = <String>[];
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showHomePlacesSheet(context, rtl: true, places: [
                HomeQuickDestination(label: 'المنزل', subtitle: 'أضف عنواناً', icon: Icons.home_rounded, accent: Colors.blue, isConfigured: false, onTap: () => picked.add('home')),
                HomeQuickDestination(label: 'العمل', subtitle: 'شارع طرابلس', icon: Icons.work_rounded, accent: Colors.purple, onTap: () => picked.add('work')),
                HomeQuickDestination(label: 'سوق الذهب', subtitle: 'مصراتة', icon: Icons.history_rounded, accent: Colors.green, onTap: () => picked.add('recent')),
              ]),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('أماكني'), findsOneWidget);
    await t.tap(find.text('سوق الذهب'));
    await t.pumpAndSettle();
    expect(picked, ['recent']);
    expect(find.text('أماكني'), findsNothing);
  });

  test('the × on the result card closes that announcement only', () async {
    final result = {'id': 9, 'kind': 'winners', 'contest': {'status': 'paid'}};
    ContestsApi.homePost.value = Map<String, dynamic>.from(result);
    await ContestsApi.dismissHome();
    expect(ContestsApi.homePost.value, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('contests_home_closed'), [ContestsApi.homeKey(result)]);
    // the next announcement is another key
    expect(ContestsApi.homeKey({'id': 10, 'kind': 'contest', 'contest': {'status': 'open'}}), isNot(ContestsApi.homeKey(result)));
    expect(ContestsApi.homeKey({'id': 9, 'kind': 'contest', 'contest': {'status': 'open'}}), isNot(ContestsApi.homeKey(result)));
  });
}
