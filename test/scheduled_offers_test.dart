import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/map_page/widgets/scheduled_offer_banner.dart';
import 'package:taxista/utils/scheduled_offers.dart';

Map<String, dynamic> offer(int id, num proposed, {num reference = 13, String currency = 'LYD', String name = 'سالم'}) => {
      'offer_id': id,
      'version': 1,
      'reference_fare': reference,
      'proposed_fare': proposed,
      'currency': currency,
      'driver_name': name,
      'driver_photo': null,
      'vehicle_make': 'Toyota',
      'vehicle_model': 'Corolla',
    };

Map<String, dynamic> ride(String id, List offers, {String start = '2026-09-26T07:45:00', Object? driverId}) => {
      'id': id,
      'driver_id': driverId,
      'trip_start_time_raw': start,
      'scheduled_offers': offers,
    };

void main() {
  group('offers on a scheduled ride', () {
    test('parse: reference 13, proposed 16, final fare untouched', () {
      final parsed = offersOfRide(ride('r1', [offer(7, 16)]));
      expect(parsed, hasLength(1));
      expect(parsed.single.offerId, 7);
      expect(parsed.single.referenceFare, 13);
      expect(parsed.single.proposedFare, 16);
      expect(parsed.single.currency, 'LYD');
      expect(parsed.single.vehicle, 'Toyota Corolla');
    });

    test('a malformed or missing list never crashes the page', () {
      expect(offersOfRide(null), isEmpty);
      expect(offersOfRide({'scheduled_offers': null}), isEmpty);
      expect(offersOfRide({'scheduled_offers': 'nope'}), isEmpty);
      expect(offersOfRide({'scheduled_offers': [null, 5, {'offer_id': 'x'}]}), isEmpty);
    });

    test('amounts read naturally', () {
      expect(moneyLabel(16), '16');
      expect(moneyLabel(16.0), '16');
      expect(moneyLabel(16.5), '16.5');
      expect(moneyLabel('16.25'), '16.25');
      expect(moneyLabel(null), '');
    });
  });

  group('Home summary', () {
    test('no offers -> no banner', () {
      expect(summarizeScheduledOffers([ride('r1', [])]).hasOffers, isFalse);
      expect(summarizeScheduledOffers(const []).hasOffers, isFalse);
      expect(summarizeScheduledOffers([{}]).hasOffers, isFalse);
    });

    test('one ride, one offer: count, time and amount for the banner', () {
      final s = summarizeScheduledOffers([ride('r1', [offer(7, 16)])]);
      expect(s.hasOffers, isTrue);
      expect(s.offerCount, 1);
      expect(s.rideCount, 1);
      expect(s.firstRideId, 'r1');
      expect(s.firstTripStart, '2026-09-26T07:45:00');
      expect(s.lowestFare, 16);
      expect(s.currency, 'LYD');
    });

    test('several offers: total count, earliest ride, lowest price', () {
      final s = summarizeScheduledOffers([
        ride('late', [offer(1, 20)], start: '2026-09-28T09:00:00'),
        ride('early', [offer(2, 18), offer(3, 15)], start: '2026-09-26T07:45:00'),
      ]);
      expect(s.offerCount, 3);
      expect(s.rideCount, 2);
      expect(s.firstRideId, 'early');
      expect(s.lowestFare, 15);
    });

    test('a ride that already has a driver never shows an answerable offer', () {
      final s = summarizeScheduledOffers([ride('taken', [offer(1, 16)], driverId: 42)]);
      expect(s.hasOffers, isFalse);
    });

    test('Qena reads EGP, Libya LYD - the currency comes from the offer', () {
      expect(summarizeScheduledOffers([ride('q', [offer(1, 40, reference: 30, currency: 'EGP')])]).currency, 'EGP');
    });

    test('server answers map to controlled outcomes', () {
      expect(offerAnswerOf(200), OfferAnswer.done);
      expect(offerAnswerOf(409), OfferAnswer.unavailable);
      expect(offerAnswerOf(410), OfferAnswer.gone);
      expect(offerAnswerOf(404), OfferAnswer.gone);
      expect(offerAnswerOf(500), OfferAnswer.failed);
    });
  });

  group('Home banner', () {
    Future<void> pump(WidgetTester tester, ScheduledOfferSummary s, {bool rtl = true, VoidCallback? onTap}) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(body: ScheduledOfferBanner(summary: s, rtl: rtl, onTap: onTap ?? () {})),
        ));

    testWidgets('says there is a new offer, with time and amount, and opens on tap', (tester) async {
      var taps = 0;
      await pump(tester, summarizeScheduledOffers([ride('r1', [offer(7, 16)])]), onTap: () => taps++);
      expect(find.text('لديك عرض جديد لرحلتك المجدولة'), findsOneWidget);
      expect(find.textContaining('2026-09-26  07:45'), findsOneWidget);
      expect(find.textContaining('16 LYD'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scheduled-offer-banner')));
      expect(taps, 1);
    });

    testWidgets('several offers show the count', (tester) async {
      await pump(tester, summarizeScheduledOffers([ride('r1', [offer(1, 16), offer(2, 17)])]));
      expect(find.text('لديك 2 عروض جديدة لرحلاتك المجدولة'), findsOneWidget);
    });

    testWidgets('english copy', (tester) async {
      await pump(tester, summarizeScheduledOffers([ride('r1', [offer(7, 16)])]), rtl: false);
      expect(find.text('You have a new offer for your scheduled ride'), findsOneWidget);
    });
  });

  group('wiring', () {
    String read(String p) => File(p).readAsStringSync();

    test('the rider answers through the scheduled-offer endpoints, not the live-bid one', () {
      final fn = read('lib/functions/parts/scheduled_rides.dart');
      expect(fn.contains('scheduled/offers/\$action'), isTrue);
      expect(fn.contains("'accept'"), isTrue);
      expect(fn.contains("'reject'"), isTrue);
      expect(fn.contains('respond-for-bid'), isFalse,
          reason: 'respond-for-bid starts a live ride; a scheduled ride is only reserved');
    });

    test('the page shows reference fare, driver offer, accept and decline', () {
      final page = read('lib/pages/NavigatorPages/upcoming_scheduled_rides.dart');
      for (final text in ['السعر المرجعي', 'عرض السائق', 'قبول العرض', 'رفض العرض']) {
        expect(page.contains(text), isTrue, reason: text);
      }
    });

    test('a push about an offer refreshes Home and a tapped one opens the page', () {
      final n = read('lib/functions/notifications.dart');
      expect("_isScheduledOfferPush".allMatches(n).length, greaterThanOrEqualTo(4));
      expect(n.contains("'scheduled-ride-offer'"), isTrue);
      expect(n.contains('_handleScheduledOfferPush(opened: true)'), isTrue);
      final view = read('lib/pages/onTripPage/map_page/map_view.dart');
      expect(view.contains('openScheduledOffersRequested'), isTrue);
    });

    test('Home refreshes offers on arrival and on resume, never on a timer', () {
      final home = read('lib/pages/onTripPage/map_page.dart');
      expect('refreshScheduledOfferSummary'.allMatches(home).length, greaterThanOrEqualTo(3));
      final fn = read('lib/functions/parts/scheduled_rides.dart');
      expect(fn.contains('PollGate'), isTrue);
    });
  });
}
