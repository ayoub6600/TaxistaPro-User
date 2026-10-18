import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation/widgets/vehicle_service_card.dart';

void main() {
  testWidgets('offer controls sit inside the selected car card',
      (tester) async {
    var offered = 30.0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => VehicleServiceCard(
        service: const {
          'name': 'تاكسيستا اقتصادي',
          'capacity': 4,
          'total': 30,
          'currency': 'LYD',
          'transport_type': 'taxi'
        },
        selected: true,
        arrivalText: '',
        offerFareLabel: '',
        fairFare: 30,
        chosenFare: offered,
        minimumFare: 27,
        onFareStep: (step) => setState(() => offered += step),
      ),
    ))));
    expect(find.text('السعر العادل'), findsOneWidget);
    expect(find.text('30 LYD'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();
    expect(offered, 29);
    expect(find.text('29'), findsOneWidget);
  });

  testWidgets('scheduled configured floor disables further decreases',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: VehicleServiceCard(
      service: {'name': 'Economy', 'total': 32, 'currency': 'LYD'},
      selected: true,
      arrivalText: '',
      offerFareLabel: '',
      fairFare: 32,
      chosenFare: 29,
      minimumFare: 29,
      maximumFare: 35.2,
      onFareStep: _noopStep,
    ))));
    final minus = tester.widget<InkWell>(find.ancestor(
        of: find.byIcon(Icons.remove_rounded), matching: find.byType(InkWell)));
    expect(minus.onTap, isNull);
    expect(find.text('السعر العادل'), findsOneWidget);
    expect(find.text('32 LYD'), findsOneWidget);
  });

  testWidgets('bidding service shows adjusted cash after first-ride gift',
      (tester) async {
    var offered = 11.0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => VehicleServiceCard(
        service: const {
          'name': 'تاكسيستا اقتصادي',
          'capacity': 4,
          'total': 11,
          'currency': 'LYD',
          'transport_type': 'taxi',
          'enable_bidding': true,
          'signup_bonus_available': true,
          'signup_bonus_amount': 10,
        },
        selected: true,
        arrivalText: '',
        offerFareLabel: 'عرض الأجرة الخاصة بك',
        fairFare: 11,
        chosenFare: offered,
        minimumFare: 9,
        onFareStep: (step) => setState(() => offered += step),
      ),
    ))));
    expect(find.text('المتبقي نقدًا بعد الهدية: 1 دينار'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('المتبقي نقدًا بعد الهدية: 2 دينار'), findsOneWidget);
  });

  testWidgets('economy shows its fare before selection without an expired gift',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: VehicleServiceCard(
      service: {
        'name': 'تاكسيستا اقتصادي',
        'capacity': 4,
        'total': 11,
        'currency': 'LYD',
        'transport_type': 'taxi',
        'enable_bidding': true,
        'signup_bonus_available': false,
        'signup_bonus_amount': 0,
      },
      selected: false,
      arrivalText: 'الأقرب 2 د',
      offerFareLabel: 'عرض الأجرة الخاصة بك',
    ))));
    expect(find.text('LYD 11'), findsOneWidget);
    expect(find.text('الأقرب 2 د'), findsOneWidget);
    expect(find.textContaining('هدية'), findsNothing);
  });
}

void _noopStep(int step) {}
