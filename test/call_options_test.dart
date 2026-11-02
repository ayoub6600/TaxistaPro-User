import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/widgets/call_options.dart';

/// The ride card's single "اتصال": the free call first, then WhatsApp and the phone; a free call
/// that cannot go through brings the sheet back with the reason.
void main() {
  late List<Uri> opened;

  setUp(() {
    opened = [];
    CallOptions.launch = (uri) async {
      opened.add(uri);
      return true;
    };
  });

  test('numbers for WhatsApp and the phone lose the trunk 0 after the country code', () {
    expect(CallOptions.digits('+2180912345678'), '218912345678');
    expect(CallOptions.digits('+218912345678'), '218912345678');
    expect(CallOptions.digits('+2001012345678'), '201012345678');
    expect(CallOptions.digits('00218 91-234-5678'), '218912345678');
    expect(CallOptions.digits(''), isNull);
    expect(CallOptions.digits(null), isNull);
  });

  Future<void> open(WidgetTester tester, {String? mobile, required Future<String?> Function() freeCall}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: CallOptionsButton(peerName: 'محمد', mobile: mobile, freeCall: freeCall))),
    ));
    await tester.tap(find.byKey(const ValueKey('call-options-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('one button, three ways: free call, WhatsApp, phone', (tester) async {
    var calls = 0;
    await open(tester, mobile: '+2180912345678', freeCall: () async {
      calls++;
      return null;
    });
    expect(find.text('اتصال بـمحمد'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-option-free')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-option-whatsapp')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-option-phone')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('call-option-whatsapp')));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://wa.me/218912345678');

    await tester.tap(find.byKey(const ValueKey('call-options-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('call-option-phone')));
    await tester.pumpAndSettle();
    expect(opened.last.toString(), 'tel:+218912345678');

    await tester.tap(find.byKey(const ValueKey('call-options-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('call-option-free')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('اتصال بـمحمد'), findsNothing, reason: 'the call screen takes over');
  });

  testWidgets('a free call that cannot go through comes back with the reason and the other two ways', (tester) async {
    await open(tester, mobile: '+218912345678', freeCall: () async => 'تطبيق السائق قديم ولا يستقبل المكالمات المجانية.');
    await tester.tap(find.byKey(const ValueKey('call-option-free')));
    await tester.pumpAndSettle();
    expect(find.text('تطبيق السائق قديم ولا يستقبل المكالمات المجانية.'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-option-phone')), findsOneWidget);
  });

  testWidgets('without a number only the free call is offered', (tester) async {
    await open(tester, mobile: null, freeCall: () async => null);
    expect(find.byKey(const ValueKey('call-option-free')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-option-whatsapp')), findsNothing);
    expect(find.byKey(const ValueKey('call-option-phone')), findsNothing);
  });
}
