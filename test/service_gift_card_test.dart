import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/growth/daily_gift/agreed_gift_sheet.dart';
import 'package:taxista/growth/daily_gift/service_gift.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation/widgets/vehicle_service_card.dart';

Widget host(Widget child) => MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: SizedBox(width: 380, child: child)))));

Map<String, dynamic> service(String mode) => {'name': 'تاكسيستا', 'pricing_mode': mode, 'currency': 'LYD', 'total': 18, 'transport_type': 'taxi', 'icon': ''};

const gift = ServiceGiftQuote(minor: 500, words: '5 دينار');

void main() {
  VehicleServiceCard card(String mode, {ServiceGiftQuote? g}) => VehicleServiceCard(service: service(mode), selected: true, arrivalText: '', offerFareLabel: 'عرض', gift: g);

  testWidgets('a fixed fare shows the old price and the price after the gift', (tester) async {
    await tester.pumpWidget(host(card('fixed', g: gift)));
    expect(find.text('LYD 18'), findsOneWidget);
    expect(find.text('LYD 13'), findsOneWidget);
    expect(find.textContaining('هدية اليوم'), findsOneWidget);
  });

  testWidgets('no gift, no change', (tester) async {
    await tester.pumpWidget(host(card('fixed')));
    expect(find.text('LYD 18'), findsOneWidget);
    expect(find.textContaining('هدية'), findsNothing);
  });

  testWidgets('a negotiated ride carries the gift on top of its own frame', (tester) async {
    await tester.pumpWidget(host(card('bidding', g: gift)));
    final line = find.textContaining('تنخصم بعد الاتفاق', findRichText: true);
    expect(line, findsOneWidget);
    expect(tester.getTopLeft(line).dy, lessThan(tester.getTopLeft(find.text('تاكسيستا')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the short description from the admin panel is on the card', (tester) async {
    await tester.pumpWidget(host(VehicleServiceCard(service: {...service('bidding'), 'short_description': 'فاوض بالسعر الذي يناسبك'}, selected: false, arrivalText: '', offerFareLabel: 'فاوض')));
    expect(find.text('فاوض بالسعر الذي يناسبك'), findsOneWidget);
    expect(find.text('فاوض'), findsOneWidget);
  });

  test('a png from the server is recognised, a jpg is not', () {
    expect(hasTransparentVehicleImage('https://x/vehicle-type-icons/abc.png/content'), isTrue);
    expect(hasTransparentVehicleImage('https://x/abc.PNG?v=1'), isTrue);
    expect(hasTransparentVehicleImage('https://x/vehicle-type-icons/abc.jpg/content'), isFalse);
    expect(hasTransparentVehicleImage(''), isFalse);
  });

  testWidgets('no description, no empty line', (tester) async {
    await tester.pumpWidget(host(VehicleServiceCard(service: service('fixed'), selected: false, arrivalText: '', offerFareLabel: 'فاوض')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sheet after the agreement says what the rider pays', (tester) async {
    await tester.pumpWidget(host(const AgreedGiftSheet(agreed: '60.50 ج.م', gift: '5 ج.م', payable: '55.50 ج.م')));
    expect(find.text('55.50 ج.م'), findsOneWidget);
    expect(find.text('− 5 ج.م'), findsOneWidget);
  });
}
