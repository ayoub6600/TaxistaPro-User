import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/widgets/signup_welcome_gift_dialog.dart';

void main() {
  testWidgets('branded welcome gift dialog shows reward and first-ride copy',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SignupWelcomeGiftDialog(reward: '10', isArabic: true),
      ),
    ));

    expect(find.text('10 دينار'), findsOneWidget);
    expect(find.text('أهلًا بك في تاكسيستا!'), findsOneWidget);
    expect(find.text('تُخصم تلقائيًا من أول رحلة'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
