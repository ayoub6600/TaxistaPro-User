import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/supply/far_captains_panel.dart';
import 'package:taxista/supply/home_captains.dart';
import 'package:taxista/supply/map_privacy.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Stack(children: [Positioned.fill(child: child)]))),
    );

Map<String, dynamic> _far({bool picked = false}) => {
      'show': true,
      'title': 'ما فيش كابتن قريب منك توا',
      'subtitle': 'فيه كباتن أبعد شوية. تبي نبعتولهم الطلب؟',
      'offer_seconds': 20,
      'captains': [
        {'driver_id': 7, 'first_name': 'محمد', 'rating': 4.9, 'car': 'هيونداي أكسنت بيضاء', 'km': 9.2, 'minutes': 18, 'picked': picked},
      ],
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('far captains: shown by the server, «ابعتله» counts down, then back to the list', (tester) async {
    int? pickedId;
    await tester.pumpWidget(_wrap(FarCaptainsPanel(
      requestId: 'r1',
      loader: (_) async => _far(),
      picker: (_, id) async {
        pickedId = id;
        return {'sent': true, 'driver_id': id, 'first_name': 'محمد', 'seconds': 3};
      },
    )));
    await tester.pump();
    expect(find.text('ما فيش كابتن قريب منك توا'), findsOneWidget);
    expect(find.text('محمد ⭐ 4.9'), findsOneWidget);
    expect(find.text('9.2 كم · يوصلك في حوالي 18 دقيقة'), findsOneWidget);
    await tester.tap(find.text('ابعتله'));
    await tester.pump();
    expect(pickedId, 7);
    expect(find.text('بعتنا الطلب لـمحمد'), findsOneWidget);
    expect(find.text('0:03'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('بعتنا الطلب لـمحمد'), findsNothing);
    expect(find.text('ابعتله'), findsOneWidget);
    await tester.tap(find.text('كمّل البحث لكل الكباتن'));
    await tester.pump();
    expect(find.text('ما فيش كابتن قريب منك توا'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('far captains: nothing when the server says no, and the server error is shown on a failed pick', (tester) async {
    await tester.pumpWidget(_wrap(FarCaptainsPanel(requestId: 'r2', loader: (_) async => {'show': false})));
    await tester.pump();
    expect(find.byType(Material), findsWidgets);
    expect(find.text('ابعتله'), findsNothing);

    await tester.pumpWidget(_wrap(FarCaptainsPanel(
      requestId: 'r3',
      loader: (_) async => _far(),
      picker: (_, __) async => {'_error': 'الكابتن هذا ما عادش متاح. اختار واحد ثاني أو ابعت للكل.'},
    )));
    await tester.pump();
    await tester.tap(find.text('ابعتله'));
    await tester.pump();
    expect(find.text('الكابتن هذا ما عادش متاح. اختار واحد ثاني أو ابعت للكل.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home: the chip says the real count near, the city total and the honest line when nobody is near', (tester) async {
    homeCaptainsInfo.value = {
      'enabled': true,
      'online_text': '12 كابتن متصل في مصراتة توا',
      'total_text': '35 كابتن تاكسيستا في مصراتة',
      'empty_title': 'ما فيش كابتن متصل قريب منك توا',
      'empty_line': 'أكثر وقت فيه كباتن متصلين: من 8:30 لين 10:30 الصبح',
    };
    homeNearCars.value = 4;
    await tester.pumpWidget(_wrap(const Column(children: [HomeCaptainsChip(), HomeNoCaptainsLine()])));
    expect(find.text('12 كابتن متصل في مصراتة توا'), findsOneWidget);
    expect(find.text('ما فيش كابتن متصل قريب منك توا'), findsNothing);
    homeNearCars.value = 0;
    await tester.pump();
    expect(find.text('35 كابتن تاكسيستا في مصراتة'), findsOneWidget);
    expect(find.text('ما فيش كابتن متصل قريب منك توا'), findsOneWidget);
    expect(find.text('أكثر وقت فيه كباتن متصلين: من 8:30 لين 10:30 الصبح'), findsOneWidget);
    homeCaptainsInfo.value = null; // the city has it off
    await tester.pump();
    expect(find.textContaining('كابتن'), findsNothing);
  });

  test('a car is drawn near its spot, the same way every time, within the allowance', () {
    final a = MapPrivacy.blur(23, [32.36, 15.10], 150);
    final b = MapPrivacy.blur(23, [32.36, 15.10], 150);
    expect(a, b);
    final dLat = (a[0] - 32.36) * 111320;
    final dLng = (a[1] - 15.10) * 111320 * 0.8445;
    final meters = (dLat * dLat + dLng * dLng);
    expect(meters > 70 * 70 && meters <= 151 * 151, isTrue, reason: '$meters');
    expect(MapPrivacy.blur(23, [32.36, 15.10], 0), [32.36, 15.10]);
  });

  test('the loader asks again only when the pin moved more than a km', () async {
    var calls = 0;
    Future<Map<String, dynamic>?> api(double a, double b) async {
      calls++;
      return {'enabled': true, 'online_text': 'x'};
    }

    await HomeCaptainsLoader.around(32.36, 15.10, api: api);
    await HomeCaptainsLoader.around(32.361, 15.101, api: api);
    expect(calls, 1);
    await HomeCaptainsLoader.around(32.40, 15.10, api: api);
    expect(calls, 2);
    expect(homeCaptainsInfo.value?['online_text'], 'x');
  });
}
