/// Pure helpers for driver offers on the rider's scheduled rides.
///
/// Three fares are never confused: the reference (fair) fare, the driver's
/// proposed fare, and the final agreed fare (empty until the rider accepts).
library;

/// 16 -> "16", 16.5 -> "16.5", 16.25 -> "16.25".
String moneyLabel(Object? value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return '';
  final text = number.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

class ScheduledOffer {
  const ScheduledOffer({
    required this.offerId,
    required this.referenceFare,
    required this.proposedFare,
    required this.currency,
    this.driverName,
    this.driverPhoto,
    this.vehicle,
    this.version = 1,
  });

  final int offerId;
  final num referenceFare;
  final num proposedFare;
  final String currency;
  final String? driverName;
  final String? driverPhoto;
  final String? vehicle;
  final int version;

  static ScheduledOffer? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['offer_id'] is num
        ? (raw['offer_id'] as num).toInt()
        : int.tryParse('${raw['offer_id']}');
    final proposed = raw['proposed_fare'] is num
        ? raw['proposed_fare'] as num
        : num.tryParse('${raw['proposed_fare']}');
    if (id == null || proposed == null) return null;
    final reference = raw['reference_fare'] is num
        ? raw['reference_fare'] as num
        : (num.tryParse('${raw['reference_fare']}') ?? 0);
    final make = (raw['vehicle_make'] ?? '').toString().trim();
    final model = (raw['vehicle_model'] ?? '').toString().trim();
    final vehicle = [make, model].where((part) => part.isNotEmpty).join(' ');
    return ScheduledOffer(
      offerId: id,
      referenceFare: reference,
      proposedFare: proposed,
      currency: (raw['currency'] ?? '').toString(),
      driverName: raw['driver_name']?.toString(),
      driverPhoto: raw['driver_photo']?.toString(),
      vehicle: vehicle.isEmpty ? null : vehicle,
      version: raw['version'] is num ? (raw['version'] as num).toInt() : 1,
    );
  }
}

/// The pending offers on one scheduled ride (already filtered server-side).
List<ScheduledOffer> offersOfRide(Object? ride) {
  if (ride is! Map) return const [];
  final raw = ride['scheduled_offers'];
  if (raw is! List) return const [];
  return raw.map(ScheduledOffer.fromJson).whereType<ScheduledOffer>().toList();
}

/// What the Home banner shows.
class ScheduledOfferSummary {
  const ScheduledOfferSummary({
    this.offerCount = 0,
    this.rideCount = 0,
    this.firstRideId,
    this.firstTripStart,
    this.lowestFare,
    this.currency = '',
  });

  final int offerCount;
  final int rideCount;
  final String? firstRideId;

  /// Market wall clock of the earliest ride that has offers (as sent by the
  /// server, never converted with the phone's timezone).
  final String? firstTripStart;
  final num? lowestFare;
  final String currency;

  bool get hasOffers => offerCount > 0;

  static const none = ScheduledOfferSummary();
}

/// Only rides still without a driver can carry offers a rider may answer.
ScheduledOfferSummary summarizeScheduledOffers(Iterable<Object?> rides) {
  var offers = 0;
  var rideCount = 0;
  String? firstId;
  String? firstStart;
  num? lowest;
  var currency = '';
  for (final ride in rides) {
    if (ride is! Map || ride.isEmpty || ride['driver_id'] != null) continue;
    final list = offersOfRide(ride);
    if (list.isEmpty) continue;
    offers += list.length;
    rideCount++;
    final start = (ride['trip_start_time_raw'] ?? ride['trip_start_time'])?.toString();
    if (firstId == null ||
        (start != null && firstStart != null && start.compareTo(firstStart) < 0)) {
      firstId = ride['id']?.toString();
      firstStart = start;
    }
    for (final offer in list) {
      if (lowest == null || offer.proposedFare < lowest) {
        lowest = offer.proposedFare;
        currency = offer.currency;
      }
    }
  }
  if (offers == 0) return ScheduledOfferSummary.none;
  return ScheduledOfferSummary(
    offerCount: offers,
    rideCount: rideCount,
    firstRideId: firstId,
    firstTripStart: firstStart,
    lowestFare: lowest,
    currency: currency,
  );
}

/// The rider's answer to an offer, mapped from the server's reply so the
/// screen reacts to what the backend decided instead of to a generic error.
enum OfferAnswer { done, gone, unavailable, failed }

OfferAnswer offerAnswerOf(int status, [String body = '']) {
  if (status >= 200 && status < 300) return OfferAnswer.done;
  if (status == 410 || status == 404) return OfferAnswer.gone;
  if (status == 409) return OfferAnswer.unavailable;
  return OfferAnswer.failed;
}
