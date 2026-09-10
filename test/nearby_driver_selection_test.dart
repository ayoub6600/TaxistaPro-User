import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation/searching/nearby_driver_selection.dart';

double _flatDistance(double lat1, double lon1, double lat2, double lon2) {
  final dLat = (lat2 - lat1).abs();
  final dLon = (lon2 - lon1).abs();
  return dLat + dLon;
}

Map<String, dynamic> _driver(
  String id, {
  double lat = 32.37,
  double lon = 15.09,
  Object? updatedAt,
  Object isActive = 1,
  Object isAvailable = 1,
  List<String>? vehicleTypes,
  String? name,
}) {
  return {
    'id': id,
    'is_active': isActive,
    'is_available': isAvailable,
    'transport_type': 'taxi',
    'vehicle_types': vehicleTypes ?? const ['economy'],
    'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    'l': [lat, lon],
    if (name != null) 'name': name,
  };
}

Map<String, dynamic> _offer(
  String driverId, {
  String price = '29',
  String isRejected = 'none',
  String? driverName,
}) {
  return {
    'driver_id': driverId,
    'price': price,
    'base_price': '23',
    'currency': 'LYD',
    'is_rejected': isRejected,
    if (driverName != null) 'driver_name': driverName,
  };
}

List<NearbyDriverCandidate> _nearby(List<Map<String, dynamic>> drivers) {
  return nearbySearchCandidates(
    source: drivers,
    serviceType: 'economy',
    transportType: 0,
    pickupLatitude: 32.37,
    pickupLongitude: 15.09,
    distanceBetween: _flatDistance,
  );
}

void main() {
  group('nearbySearchCandidates', () {
    test('keeps fresh, active, matching drivers sorted by distance', () {
      final result = _nearby([
        _driver('far', lat: 32.60),
        _driver('near', lat: 32.38),
      ]);

      expect(result.map((c) => c.driverId), ['near', 'far']);
      expect(result.every((c) => c.targeted), isFalse);
    });

    test('drops stale, offline and mismatched drivers', () {
      final stale = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      final result = _nearby([
        _driver('stale', updatedAt: stale),
        _driver('offline', isAvailable: 0),
        _driver('inactive', isActive: 0),
        _driver('other-service', vehicleTypes: ['premium']),
        _driver('ok'),
      ]);

      expect(result.map((c) => c.driverId), ['ok']);
    });

    test('survives malformed rows without throwing', () {
      final result = nearbySearchCandidates(
        source: [
          'not-a-map',
          {'id': 'no-location', 'is_active': 1, 'is_available': 1},
          {
            ..._driver('bad-coords'),
            'l': ['x', 'y']
          },
          {..._driver('missing-updated-at'), 'updated_at': null},
          _driver('ok'),
        ],
        serviceType: null,
        transportType: 0,
        pickupLatitude: 32.37,
        pickupLongitude: 15.09,
        distanceBetween: _flatDistance,
      );

      expect(result.map((c) => c.driverId), ['ok']);
    });
  });

  group('targetedDriverIds', () {
    test('reads the flat single-driver request-meta shape', () {
      expect(targetedDriverIds({'driver_id': 3, 'active': 1}), {'3'});
    });

    test('reads the batched request-meta/<requestId>/<driverId> shape', () {
      final meta = {
        '3': {'driver_id': 3, 'active': 1},
        '9': {'driver_id': '9', 'active': 1},
      };
      expect(targetedDriverIds(meta), {'3', '9'});
    });

    test('treats a cleared driver_id as no longer targeted', () {
      // The driver app deletes request-meta/<id>/driver_id when it skips.
      final meta = {
        'name': 'محمد عباس',
        'rating': 4.33,
        'active': 1,
        'is_accepted': 0,
      };
      expect(targetedDriverIds(meta), isEmpty);
    });

    test('ignores inactive entries and invalid payloads', () {
      expect(targetedDriverIds({'driver_id': 3, 'active': 0}), isEmpty);
      expect(targetedDriverIds({'driver_id': 'null'}), isEmpty);
      expect(targetedDriverIds(null), isEmpty);
      expect(targetedDriverIds('nonsense'), isEmpty);
    });
  });

  group('submittedOffers', () {
    test('keeps pending offers and drops rejected ones', () {
      final offers = submittedOffers({
        'driver_3': _offer('3'),
        'driver_9': _offer('9', isRejected: 'by_user'),
      });
      expect(offers.keys, ['3']);
    });
  });

  group('prioritizeTargetedDrivers', () {
    test('marks only dispatched drivers as targeted', () {
      final nearby = _nearby([_driver('3'), _driver('7'), _driver('9')]);

      final result = prioritizeTargetedDrivers(
        nearby,
        {'driver_id': 3, 'active': 1},
        null,
      );

      final targeted = result.where((c) => c.targeted).map((c) => c.driverId);
      expect(targeted, ['3']);
      // Everyone else is still returned for the map, but not as targeted.
      expect(result.map((c) => c.driverId).toSet(), {'3', '7', '9'});
      expect(
        result.firstWhere((c) => c.driverId == '7').targeted,
        isFalse,
        reason: 'a nearby driver that was never notified is not viewing',
      );
    });

    test('puts targeted drivers first', () {
      final nearby = _nearby([_driver('7', lat: 32.371), _driver('9')]);
      final result = prioritizeTargetedDrivers(
        nearby,
        {'driver_id': 9, 'active': 1},
        null,
      );
      expect(result.first.driverId, '9');
    });

    test('handles multiple targeted drivers from a dispatch batch', () {
      final nearby = _nearby([_driver('3'), _driver('9'), _driver('7')]);
      final result = prioritizeTargetedDrivers(
        nearby,
        {
          '3': {'driver_id': 3, 'active': 1},
          '9': {'driver_id': 9, 'active': 1},
        },
        null,
      );

      final targeted =
          result.where((c) => c.targeted).map((c) => c.driverId).toList();
      expect(targeted, containsAll(['3', '9']));
      expect(targeted, hasLength(2));
      expect(result.firstWhere((c) => c.driverId == '7').targeted, isFalse);
    });

    test('does not duplicate a driver present in meta and nearby', () {
      final nearby = _nearby([_driver('3', name: 'محمد')]);
      final result = prioritizeTargetedDrivers(
        nearby,
        {'driver_id': 3, 'active': 1},
        {'driver_3': _offer('3')},
      );

      expect(result.where((c) => c.driverId == '3'), hasLength(1));
      expect(result, hasLength(1));
    });

    test('binds an offer to the right driver and counts as targeting proof',
        () {
      final nearby = _nearby([_driver('3'), _driver('9')]);
      final result = prioritizeTargetedDrivers(
        nearby,
        null, // request-meta already moved on to another driver
        {'driver_9': _offer('9', price: '31', driverName: 'أحمد')},
      );

      final withOffer = result.firstWhere((c) => c.driverId == '9');
      expect(withOffer.counterOffer, 31);
      expect(withOffer.counterOfferBase, 23);
      expect(withOffer.counterOfferCurrency, 'LYD');
      expect(withOffer.name, 'أحمد');
      expect(withOffer.targeted, isTrue);

      final other = result.firstWhere((c) => c.driverId == '3');
      expect(other.counterOffer, isNull);
      expect(other.targeted, isFalse);
    });

    test('keeps an offering driver that is no longer broadcasting a location',
        () {
      final result = prioritizeTargetedDrivers(
        const [],
        null,
        {'driver_5': _offer('5', driverName: 'سالم')},
      );

      expect(result, hasLength(1));
      expect(result.single.driverId, '5');
      expect(result.single.targeted, isTrue);
      expect(result.single.counterOffer, 29);
    });

    test('fails safely on malformed metadata', () {
      final nearby = _nearby([_driver('3')]);
      final result = prioritizeTargetedDrivers(nearby, 'garbage', 42);
      expect(result.map((c) => c.driverId), ['3']);
      expect(result.single.targeted, isFalse);
    });
  });
}
