import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/cancel_quote_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<String?> open(WidgetTester tester, Map q, String tap) async {
    String? got = 'unset';
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) => TextButton(onPressed: () async => got = await CancelQuote.ask(c, q), child: const Text('go')))));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(q['title']), findsOneWidget);
    await tester.tap(find.text(tap));
    await tester.pumpAndSettle();
    return got;
  }

  final optional = {
    'applies': true, 'mandatory': false, 'title': 'الكابتن محمد في الطريق إليك 🚕', 'message': 'قطع حوالي 2 كم إليك',
    'pay_label': 'نعم، ألغِ وعوّض الكابتن 2 LYD', 'free_label': 'لا، ألغِ بدون تعويض', 'wait_label': 'خليني نستنى الكابتن',
  };

  testWidgets('the rider can pay, cancel free, or keep waiting', (tester) async {
    expect(await open(tester, optional, 'نعم، ألغِ وعوّض الكابتن 2 LYD'), 'pay');
    expect(await open(tester, optional, 'لا، ألغِ بدون تعويض'), 'free');
    expect(await open(tester, optional, 'خليني نستنى الكابتن'), isNull);
  });

  testWidgets('no free cancel left: no «بدون تعويض» button', (tester) async {
    final q = {...optional, 'mandatory': true, 'free_label': null, 'pay_label': 'ألغِ وادفع 2 LYD'};
    expect(await open(tester, q, 'ألغِ وادفع 2 LYD'), 'pay');
    expect(find.text('لا، ألغِ بدون تعويض'), findsNothing);
  });
}
