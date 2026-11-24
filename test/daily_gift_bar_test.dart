import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/growth/daily_gift/daily_gift_bar.dart';
import 'package:taxista/growth/daily_gift/daily_gift_model.dart';

DailyGiftOffer offer([String state = 'live']) => DailyGiftOffer(
    state: state, secondsLeft: 15156, amount: '5 دينار', startLabel: '10 صباحًا', endLabel: '11 مساءً', minFare: '10 دينار', date: '2026-11-10');

Widget host(Widget child, {double width = 412}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(body: Center(child: SizedBox(width: width - 36, child: child))),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the clock reads hours, minutes, seconds and never goes negative', () {
    expect(DailyGiftOffer.clock(15156), '04:12:36');
    expect(DailyGiftOffer.clock(59), '00:00:59');
    expect(DailyGiftOffer.clock(-4), '00:00:00');
  });

  test('a campaign that is off shows nothing', () {
    expect(DailyGiftOffer.fromJson({'state': 'off'}), isNull);
    expect(DailyGiftOffer.fromJson(null), isNull);
    expect(DailyGiftOffer.fromJson({'state': 'live', 'seconds_left': 9, 'amount': '5 دينار'})!.isLive, isTrue);
  });

  testWidgets('a later open goes straight to the line: «هديتك اليوم 5 دينار» and a stopwatch with the time left', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer())));
    await tester.pump();
    expect(find.textContaining('هديتك اليوم 5 دينار', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.text('04:12:36'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('تنتهي صلاحية الهدية بعد 04:12:36')), findsOneWidget);
    expect(dailyGiftBarShown.value, isTrue);
  });

  testWidgets('before the gift starts, the small line says what the countdown is for', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer('upcoming'))));
    await tester.pump();
    expect(find.text('تبدأ الهدية بعد'), findsOneWidget);
  });

  testWidgets('with the home sheet up it is a small gift that still opens the terms', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer(), iconOnly: true)));
    await tester.pump();
    expect(find.byKey(const ValueKey('daily-gift-icon')), findsOneWidget);
    expect(find.textContaining('هديتك اليوم', findRichText: true), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('daily-gift-icon'))).width, lessThan(60));
    await tester.tap(find.byKey(const ValueKey('daily-gift-icon')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('اطلب مشوارك'), findsOneWidget);
  });

  testWidgets('the first open shows the box alone, then the burst, then the line', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer(), playIntro: true)));
    await tester.pump(const Duration(milliseconds: 800));
    final hidden = tester.widget<Opacity>(find.descendant(of: find.byType(Stack).first, matching: find.byType(Opacity)).first);
    expect(hidden.opacity, 0, reason: 'only the box on screen');
    await tester.pump(const Duration(milliseconds: 3000));
    expect(tester.takeException(), isNull);
    final shown = tester.widget<Opacity>(find.descendant(of: find.byType(Stack).first, matching: find.byType(Opacity)).first);
    expect(shown.opacity, 1);
  });

  testWidgets('the countdown moves by itself', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer())));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('04:12:34'), findsOneWidget);
  });

  for (final state in ['live', 'upcoming', 'used', 'sold_out']) {
    testWidgets('no overflow on a small phone: $state', (tester) async {
      await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer(state)), width: 320));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tapping opens the terms', (tester) async {
    await tester.pumpWidget(host(DailyGiftBar(offerForTest: offer())));
    await tester.pump();
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('اطلب مشوارك'), findsOneWidget);
    expect(find.textContaining('مشوار واحد في اليوم'), findsOneWidget);
  });
}
