import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/city_launch.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget sheet(Future<bool> Function() notify) => MaterialApp(
        home: Scaffold(
          body: CityLaunchSheet(
            data: const {'zone_id': 'z1', 'city': 'طرابلس', 'title': 'تاكسيستا قريبًا في طرابلس 🚖', 'body': 'نجهزوا في السائقين هنا.'},
            notify: notify,
          ),
        ),
      );

  testWidgets('shows the city and confirms after «بلّغني»', (t) async {
    var calls = 0;
    await t.pumpWidget(sheet(() async => ++calls > 0));
    expect(find.text('تاكسيستا قريبًا في طرابلس 🚖'), findsOneWidget);
    await t.tap(find.text('🔔 بلّغني لما تفتح'));
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('يوصلك إشعار'), findsOneWidget);
    expect(find.text('🔔 بلّغني لما تفتح'), findsNothing);
  });

  testWidgets('a failed call keeps the button and says so', (t) async {
    await t.pumpWidget(sheet(() async => false));
    await t.tap(find.text('🔔 بلّغني لما تفتح'));
    await t.pumpAndSettle();
    expect(find.text('ما قدرناش نسجلوك، جرّب مرة ثانية.'), findsOneWidget);
    expect(find.text('🔔 بلّغني لما تفتح'), findsOneWidget);
  });
}
