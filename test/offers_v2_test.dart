import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/offers_v2_api.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation/searching/nearby_driver_selection.dart';

void main() {
  final on = {'offers_v2': {'enabled': true, 'search_seconds': 120, 'auto_accept': true}};
  final off = {'offers_v2': {'enabled': false}};
  final ride = {'id': 'r', 'is_bid_ride': 1, 'is_later': 0, 'rider_proposed_fare': '16.00', 'offers_v2': {'offer_seconds': 45, 'favorite': {'driver_id': '7', 'name': 'أحمد', 'seconds_left': 10}}};

  test('only a negotiated ride now, with the admin\'s switch on', () {
    expect(OffersV2.activeFor(ride, on), isTrue);
    expect(OffersV2.activeFor({...ride, 'offers_v2': null}, off), isFalse);
    expect(OffersV2.activeFor({...ride, 'is_later': 1}, on), isFalse, reason: 'a booked ride keeps its own screen');
    expect(OffersV2.activeFor({...ride, 'is_bid_ride': 0}, on), isFalse, reason: 'a fixed price has nothing to negotiate');
    expect(OffersV2.activeFor(const {}, on), isFalse);
  });

  test('times, price and the favourite come from the server', () {
    expect(OffersV2.searchSeconds(ride, on), 120);
    expect(OffersV2.offerSeconds(ride), 45);
    expect(OffersV2.currentFare(ride), 16);
    expect(OffersV2.favorite(ride)!['name'], 'أحمد');
    expect(OffersV2.step(const {}), 1);
    expect(OffersV2.step({'bidding_amount_increase_or_decrease': '0.5'}), 0.5);
    expect(OffersV2.clock(118), '1:58');
    expect(OffersV2.money(18), '18');
  });

  test('an offer card knows the heart, the time it was sent and the minutes away', () {
    const d = NearbyDriverCandidate(data: {'id': 7, 'counter_offer': '18', 'favorite': true, 'bid_time': 1700000000000}, distance: 1600);
    expect(d.isFavorite, isTrue);
    expect(d.bidTime, 1700000000000);
    expect(d.etaMinutes, 4);
    expect(const NearbyDriverCandidate(data: {'next_ride_eta': '6'}, distance: 200).etaMinutes, 6);
    expect(const NearbyDriverCandidate(data: {}, distance: double.infinity).etaMinutes, isNull, reason: 'no position, no minutes');
  });
}
