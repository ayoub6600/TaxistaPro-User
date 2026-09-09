part of '../booking_confirmation.dart';

mixin _BookingConfirmationVehicleServices
    on State<BookingConfirmation>, _BookingConfirmationController {
  double vehicleSelectionSheetHeight(Size media) {
    final visibleServiceCount = uniqueServices(etaDetails).length;
    final additionalCards = max(0, visibleServiceCount - 2);
    final compactHeight = media.height * 0.66 + additionalCards * 98.0;

    return min(compactHeight, media.height * 0.90);
  }

  double bookingSheetHeight(Size media) {
    if (!bottomChooseMethod && widget.type != 1) {
      return _ontripBottom
          ? media.height * 0.90
          : vehicleSelectionSheetHeight(media);
    }
    if (!bottomChooseMethod && widget.type == 1) {
      return media.height * 0.60;
    }
    return media.height * 0.90;
  }

  Map<int, dynamic> uniqueServices(List services) {
    final result = <int, dynamic>{};
    final seen = <String>{};

    for (final entry in services.asMap().entries) {
      final service = entry.value as Map;
      final isRentalPackage = service['typesWithPrice'] != null;
      final key = isRentalPackage
          ? '${service['id']}:${service['package_name']}'
          : [
              service['name']?.toString().trim().toLowerCase(),
              service['total'] ?? service['min_price'],
              service['transport_type'],
            ].join(':');
      if (seen.add(key)) result[entry.key] = entry.value;
    }

    return result;
  }

  Widget buildVehicleServiceOption({
    required BuildContext context,
    required Query driverQuery,
    required Size media,
    required int index,
    required bool isOneWay,
    required dynamic bookingType,
  }) {
    return StreamBuilder<DatabaseEvent>(
      stream: driverQuery.onValue,
      builder: (context, snapshot) {
        _updateArrivalEstimate(snapshot.data, index);

        return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (choosenVehicle != index) {
                  setState(() => choosenVehicle = index);
                  myMarker.removeWhere(
                    (marker) => marker.markerId.toString().contains('car'),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => VehicleInfoBottomSheet(
                    i: index,
                    width: media.width,
                    isOneway: isOneWay,
                    type: bookingType,
                  ),
                );
              },
              child: VehicleServiceCard(
                service: Map<String, dynamic>.from(
                  etaDetails[index] as Map,
                ),
                selected: choosenVehicle == index,
                arrivalText:
                    minutes[etaDetails[index]['type_id']]?.toString() ?? '',
                offerFareLabel: languages[choosenLanguage]
                    ['text_offer_your_fare'],
              ),
            ));
      },
    );
  }

  void _updateArrivalEstimate(DatabaseEvent? event, int index) {
    final serviceType = etaDetails[index]['type_id'];
    minutes[serviceType] = '';
    if (event == null || addressList.isEmpty) return;

    final pickup =
        addressList.firstWhere((address) => address.type == 'pickup');
    final distances = <double>[];

    for (final snapshot in event.snapshot.children) {
      final driver = snapshot.value;
      if (driver is! Map || !_supportsService(driver, serviceType)) continue;

      final updatedAt = driver['updated_at'];
      final location = driver['l'];
      if (updatedAt is! int || location is! List || location.length < 2) {
        continue;
      }
      if (DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(updatedAt))
              .inMinutes >
          2) {
        continue;
      }

      final distance = calculateDistance(
        pickup.latlng.latitude,
        pickup.latlng.longitude,
        (location[0] as num).toDouble(),
        (location[1] as num).toDouble(),
      );
      distances.add(distance / 1000);
    }

    if (distances.isEmpty) return;
    minutes[serviceType] = _arrivalLabel(distances.reduce(min));
  }

  bool _supportsService(Map driver, dynamic serviceType) {
    if (driver['is_active'] != 1 || driver['is_available'] != true) {
      return false;
    }
    final supportedTypes = driver['vehicle_types'];
    return (supportedTypes is List && supportedTypes.contains(serviceType)) ||
        driver['vehicle_type'] == serviceType;
  }

  String _arrivalLabel(double distanceKm) {
    if (distanceKm <= 1) return '2 mins';
    if (distanceKm <= 3) return '5 mins';
    if (distanceKm <= 5) return '8 mins';
    if (distanceKm <= 7) return '11 mins';
    if (distanceKm <= 10) return '14 mins';
    return '15 mins';
  }
}
