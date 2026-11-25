import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/prior_balance.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation/widgets/vehicle_service_card.dart';
import 'package:taxista/widgets/prior_balance_widgets.dart';

/// «رصيد سابق»: the ride of 2026-11-25 - fare 11, old balance 4, the rider must hand the captain 15.
Widget host(Widget child) => MaterialApp(
    home: Directionality(
        textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: SizedBox(width: 380, child: child)))));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('who pays it', () {
    test('a cash ride or wallet + cash collects it; the wallet alone never does', () {
      expect(priorBalanceSplit(paymentOpt: 1, prior: 4, fare: 11)?.total, 15);
      expect(priorBalanceSplit(paymentOpt: '1', prior: '4.00', fare: 11)?.total, 15);
      expect(priorBalanceSplit(paymentOpt: '3', prior: 4, fare: 11)?.total, 15);
      expect(priorBalanceSplit(paymentOpt: '2', prior: 4, fare: 11), isNull);
      expect(priorBalanceSplit(paymentOpt: '0', prior: 4, fare: 11), isNull);
    });

    test('nothing owed or no field: nothing extra', () {
      expect(priorBalanceSplit(paymentOpt: 1, prior: null, fare: 11), isNull);
      expect(priorBalanceSplit(paymentOpt: 1, prior: 0, fare: 11), isNull);
      expect(priorBalanceSplit(paymentOpt: 1, prior: '', fare: 11), isNull);
      expect(priorBalanceSplit(paymentOpt: 1, prior: -3, fare: 11), isNull);
      expect(activeRidePriorBalance({'payment_opt': '1'}, fare: 11), isNull);
    });

    test('during the ride it comes from prior_balance_due, after it from the bill', () {
      expect(activeRidePriorBalance({'payment_opt': '1', 'prior_balance_due': 4}, fare: 11)?.prior, 4);
      expect(activeRidePriorBalance({'payment_opt': '2', 'prior_balance_due': 4}, fare: 11), isNull);
      final ride = {
        'payment_opt': '1',
        'requestBill': {
          'data': {'total_amount': 11, 'prior_balance_collected': 4}
        },
      };
      expect(invoicePriorBalance(ride, fare: 11)?.total, 15);
      expect(
          invoicePriorBalance({
            'requestBill': {
              'data': {'total_amount': 11}
            }
          }, fare: 11),
          isNull);
      expect(invoicePriorBalance({}, fare: 11), isNull);
    });
  });

  group('the words', () {
    const split = PriorBalanceSplit(fare: 11, prior: 4);
    const words = PriorBalanceWords(split, 'LYD', arabic: true);

    test('amount first, «د.ل», no «.00»', () {
      expect(words.total, '15 د.ل');
      expect(words.payCaptainLabel, 'تدفع للكابتن');
      expect(words.dueBreakdown, '11 أجرة + 4 رصيد سابق عليك');
      expect(words.fareLine, 'أجرة الرحلة 11 د.ل');
      expect(words.priorLine, 'رصيد سابق عليك 4 د.ل');
      expect(words.priceAddOn, '+ 4 د.ل رصيد سابق عليك');
      expect(words.bookingNote, 'عليك 4 د.ل من رحلة سابقة، تدفعها للكابتن مع هذي الرحلة.');
    });

    test('never «LYD» in Arabic; half dinars keep their cents', () {
      const half = PriorBalanceWords(PriorBalanceSplit(fare: 11.5, prior: 4), 'LYD', arabic: true);
      expect(half.total, '15.50 د.ل');
      expect(half.dueBreakdown, '11.50 أجرة + 4 رصيد سابق عليك');
      expect(words.total.contains('LYD'), isFalse);
    });
  });

  group('on screen', () {
    const words = PriorBalanceWords(PriorBalanceSplit(fare: 11, prior: 4), 'LYD', arabic: true);

    testWidgets('active ride: «تدفع للكابتن 15 د.ل» with «11 أجرة + 4 رصيد سابق عليك»', (tester) async {
      await tester.pumpWidget(host(const PriorBalanceDueBadge(words: words)));
      expect(find.text('تدفع للكابتن'), findsOneWidget);
      expect(find.text('15 د.ل'), findsOneWidget);
      expect(find.text('11 أجرة + 4 رصيد سابق عليك'), findsOneWidget);
      expect(find.textContaining('11.00'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invoice: the big number is the total, both parts under it', (tester) async {
      await tester.pumpWidget(host(const PriorBalancePaidSummary(title: 'تدفع للكابتن نقدًا', words: words)));
      expect(find.text('15 د.ل'), findsOneWidget);
      expect(find.text('أجرة الرحلة 11 د.ل'), findsOneWidget);
      expect(find.text('رصيد سابق عليك 4 د.ل'), findsOneWidget);
      final total = tester.widget<Text>(find.byKey(const ValueKey('prior-paid-total')));
      final fare = tester.widget<Text>(find.text('أجرة الرحلة 11 د.ل'));
      expect(total.style!.fontSize! > fare.style!.fontSize!, isTrue, reason: 'the total is the big number');
    });

    testWidgets('services sheet: the line under the price and the calm note above the button', (tester) async {
      await tester.pumpWidget(host(Column(mainAxisSize: MainAxisSize.min, children: [
        VehicleServiceCard(
          service: const {
            'name': 'اقتصادي',
            'pricing_mode': 'fixed',
            'currency': 'LYD',
            'total': 11,
            'transport_type': 'taxi',
            'icon': ''
          },
          selected: true,
          arrivalText: '',
          offerFareLabel: 'عرض',
          priorBalanceLine: words.priceAddOn,
        ),
        const PriorBalanceBookingNote(words: words),
      ])));
      expect(find.text('11 د.ل'), findsOneWidget, reason: 'the fare itself stays 11');
      expect(find.text('+ 4 د.ل رصيد سابق عليك'), findsOneWidget);
      expect(find.text('عليك 4 د.ل من رحلة سابقة، تدفعها للكابتن مع هذي الرحلة.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no old balance: the card shows no extra line', (tester) async {
      await tester.pumpWidget(host(const VehicleServiceCard(
        service: {
          'name': 'اقتصادي',
          'pricing_mode': 'fixed',
          'currency': 'LYD',
          'total': 11,
          'transport_type': 'taxi',
          'icon': ''
        },
        selected: true,
        arrivalText: '',
        offerFareLabel: 'عرض',
      )));
      expect(find.byKey(const ValueKey('service-prior-balance')), findsNothing);
    });
  });
}
