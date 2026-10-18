import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation.dart';
import 'package:taxista/pages/onTripPage/bookingwidgets.dart';

void main() {
  testWidgets('legacy taxi type without image or description opens safely',
      (tester) async {
    etaDetails = [
      {
        'name': 'تاكسي عادي',
        'icon': null,
        'short_description': null,
        'description': null,
        'enable_bidding': false,
        'total': 9,
        'currency': 'LYD',
        'payment_type': 'cash,wallet,card,wallet_and_cash',
        'price_per_time': 0,
        'price_per_distance': 1.6,
        'unit_in_words': 'KM',
      }
    ];
    choosenVehicle = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, child) => const MaterialApp(
        home: Scaffold(
          body: VehicleInfoBottomSheet(
            i: 0,
            width: 390,
            isOneway: true,
            type: null,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
  });
}
