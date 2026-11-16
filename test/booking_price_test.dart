import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/functions.dart';

/// Owner 2026-11-16: a scheduled negotiated booking of 25.3 showed «16» (the instant fare) to the rider.
void main() {
  test('the price the rider agreed', () {
    expect(bookingPrice({'is_later': 1, 'is_bid_ride': 1, 'request_eta_amount': '16.00', 'offerred_ride_fare': '25.30'}), 25.3);
    expect(bookingPrice({'is_later': 1, 'is_bid_ride': 1, 'request_eta_amount': '16.00', 'offerred_ride_fare': '25.30', 'rider_proposed_fare': '27'}), 27);
    expect(bookingPrice({'is_later': 1, 'is_bid_ride': 1, 'request_eta_amount': '16', 'offerred_ride_fare': '25.3', 'accepted_ride_fare': '28'}), 28);
    expect(bookingPrice({'is_later': 1, 'is_bid_ride': 0, 'request_eta_amount': '12.00', 'offerred_ride_fare': '0'}), 12);
    expect(bookingPrice({'is_later': 0, 'is_bid_ride': 1, 'request_eta_amount': '16', 'offerred_ride_fare': '25.3'}), 16);
    expect([priceText(25.3), priceText(12), priceText(12.5)], ['25.3', '12', '12.5']);
  });
}
