import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation.dart';

void main() {
  test('a single destination is not also quoted as an extra stop', () {
    // Confirmation collects the final drop in dropStopList. Re-sending that
    // one point made ETA price the route twice, but create-request omitted it.
    expect(shouldSendStopsForEta(2, 1), isFalse);
    expect(shouldSendStopsForEta(2, 0), isFalse);
    expect(shouldSendStopsForEta(3, 2), isTrue);
  });
  test('valid displayed quote is reused for a discounted rider offer', () {
    final booking = <String, dynamic>{
      'vehicle_type': 'zone-1',
      'pick_lat': 32.37,
      'pick_lng': 15.09,
      'drop_lat': 32.43,
      'drop_lng': 15.22,
      'request_eta_amount': '19.00',
    };
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final payload = {
      'zone': 'zone-1',
      'pick': [32.37, 15.09],
      'drop': [32.43, 15.22],
      'stops': [],
      'immediate': 19.0,
      'issued': 1700000000,
    };
    final token =
        '${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.signature';
    expect(currentImmediateFareQuote(token, booking, now: now), isTrue);
    expect(
        currentImmediateFareQuote(token, booking,
            now: now.add(const Duration(minutes: 15))),
        isFalse);
    expect(
        currentImmediateFareQuote(token, {...booking, 'drop_lat': 32.44},
            now: now),
        isFalse);
    expect(
        currentImmediateFareQuote(token, {...booking, 'request_eta_amount': 13},
            now: now),
        isFalse);
  });
  test('offer quote refresh uses the same route and stops as the booking', () {
    final booking = <String, dynamic>{
      'pick_lat': 32.37,
      'pick_lng': 15.09,
      'drop_lat': 32.43,
      'drop_lng': 15.22,
      'stops': '[{"latitude":32.4,"longitude":15.1}]',
      'request_eta_amount': 33,
      'offerred_ride_fare': 32,
    };
    final quote = immediateOfferQuoteInput(booking);
    expect(quote['pick_lat'], booking['pick_lat']);
    expect(quote['drop_lng'], booking['drop_lng']);
    expect(quote['stops'], booking['stops']);
    expect(quote.containsKey('offerred_ride_fare'), isFalse);
  });
  test('adjusted rider price stays in regular dispatch, not legacy bidding',
      () {
    for (final offered in [32.0, 34.0]) {
      final booking = <String, dynamic>{
        'request_eta_amount': 33,
        'is_bid_ride': 1,
        'offerred_ride_fare': 99,
      };
      applyImmediateRiderProposal(booking, offered);
      expect(booking['rider_proposed_fare'], offered);
      expect(booking.containsKey('is_bid_ride'), isFalse);
      expect(booking.containsKey('offerred_ride_fare'), isFalse);
    }
  });
  test('taxi proposal searches normally even on an older bid-flagged row', () {
    expect(
        isLegacyBiddingSearchRequest(
          {'is_bid_ride': 1, 'offerred_ride_fare': 18},
          {'enable_modules_for_applications': 'taxi'},
        ),
        isFalse);
    expect(
        isLegacyBiddingSearchRequest(
          {'is_bid_ride': 1, 'offerred_ride_fare': 18},
          <String, dynamic>{},
        ),
        isTrue);
    expect(
        isLegacyBiddingSearchRequest(
          {'is_bid_ride': 0, 'rider_proposed_fare': 18},
          {'enable_modules_for_applications': 'taxi'},
        ),
        isFalse);
  });
  test('offer begins at fair fare and lower limit is admin percentage', () {
    expect(minimumRiderOffer(29, 10), 26.10);
    expect(minimumRiderOffer(32, 0), 32);
    expect(minimumRiderOffer(20, 50), 10);
    expect(minimumRiderOffer(20, 90), 10);
  });

  test('the admin floor admits 29 from a fair 30', () {
    expect(29 >= minimumRiderOffer(30, 10), isTrue);
  });

  group('per-market minimum offer (Libya 25%, Qena independent)', () {
    test('a fair 13 with a 25% limit allows 9.75 and offers 10, 11, 12, 13, 15', () {
      final floor = minimumRiderOffer(13, 25);
      expect(floor, 9.75);
      for (final offer in [10.0, 11.0, 12.0, 13.0, 15.0]) {
        expect(offer >= floor, isTrue, reason: '$offer must be an acceptable offer');
      }
      expect(9.0 >= floor, isFalse);
    });

    test('the stepper walks 13 down to 10 and up to 15, and stops at the floor', () {
      final floor = minimumRiderOffer(13, 25);
      var offer = 13.0;
      final down = <double>[];
      for (var i = 0; i < 5; i++) {
        offer = steppedFareOffer(offer, -1, floor, null);
        down.add(offer);
      }
      expect(down, [12.0, 11.0, 10.0, 9.75, 9.75]);

      offer = 13.0;
      offer = steppedFareOffer(offer, 1, floor, null);
      offer = steppedFareOffer(offer, 1, floor, null);
      expect(offer, 15.0);
    });

    test('a market with no discount allowance can only raise the offer', () {
      final floor = minimumRiderOffer(13, 0);
      expect(steppedFareOffer(13, -1, floor, null), 13.0);
      expect(steppedFareOffer(13, 1, floor, null), 14.0);
    });

    test('another market keeps its own limit', () {
      final libya = minimumRiderOffer(13, 25);
      final qena = minimumRiderOffer(13, 10);
      expect(libya, 9.75);
      expect(qena, 11.7);
      expect(10.0 >= libya, isTrue);
      expect(10.0 >= qena, isFalse);
    });

    test('a scheduled ride is capped by its ceiling when stepping up', () {
      expect(steppedFareOffer(14, 1, 10, 14.5), 14.5);
    });
  });
}
