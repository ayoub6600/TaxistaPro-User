/// Selection pipeline for the rider "searching for a driver" screen.
///
/// Kept free of Flutter and of app globals so it can be unit tested: the
/// caller injects the distance function and the raw Firebase payloads.
///
/// Dispatch contract this mirrors (backend + driver app):
///  * `request-meta/<requestId>` is the channel a driver is notified on. The
///    driver app listens with `orderByChild('driver_id').equalTo(<own id>)`,
///    so a driver is targeted only while a `driver_id` is present. The driver
///    app deletes that field when it skips the ride, which is how a driver
///    stops being targeted.
///  * The backend also writes the batch shape `request-meta/<requestId>/<driverId>`
///    (SendRequestToNextDriversJob), so both shapes must be understood.
///  * `bid-meta/<requestId>/drivers/*` holds submitted offers.
///
/// Proximity alone is NOT evidence of targeting: a nearby driver that has not
/// been notified must never be presented as viewing the request.
library;

typedef DistanceBetween = double Function(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
);

class NearbyDriverCandidate {
  const NearbyDriverCandidate({
    required this.data,
    required this.distance,
    this.targeted = false,
  });

  final Map<String, dynamic> data;
  final double distance;

  /// True only when the dispatcher has this driver on the request: either an
  /// active `request-meta` entry or a submitted offer.
  final bool targeted;

  NearbyDriverCandidate copyWith({
    Map<String, dynamic>? data,
    bool? targeted,
  }) {
    return NearbyDriverCandidate(
      data: data ?? this.data,
      distance: distance,
      targeted: targeted ?? this.targeted,
    );
  }

  String get driverId => (data['id'] ?? data['driver_id']).toString();

  double? get counterOffer =>
      double.tryParse(data['counter_offer']?.toString() ?? '');

  double? get counterOfferBase =>
      double.tryParse(data['counter_offer_base']?.toString() ?? '');

  String get counterOfferCurrency =>
      data['counter_offer_currency']?.toString() ?? 'LYD';

  String? get vehicleMake =>
      data['vehicle_make']?.toString().trim().isNotEmpty == true
          ? data['vehicle_make'].toString()
          : null;

  String? get vehicleModel =>
      data['vehicle_model']?.toString().trim().isNotEmpty == true
          ? data['vehicle_model'].toString()
          : null;

  double? get rating => double.tryParse(data['rating']?.toString() ?? '');

  int? get completedTrips =>
      int.tryParse(data['driver_completed_rides_count']?.toString() ?? '');

  String get revealKey =>
      (data['id'] ?? data['driver_id'] ?? avatarUrl ?? name).toString();

  String get name {
    final rawName = data['name'] ??
        data['driver_name'] ??
        data['first_name'] ??
        data['full_name'];
    final value = rawName?.toString().trim() ?? '';
    if (value.isEmpty) return '';
    return value.split(RegExp(r'\s+')).first;
  }

  String? get avatarUrl {
    final raw = data['profile_picture'] ??
        data['profile_image'] ??
        data['avatar'] ??
        data['image'];
    final value = raw?.toString().trim() ?? '';
    return value.startsWith('http://') || value.startsWith('https://')
        ? value
        : null;
  }
}

/// Drivers broadcasting a fresh location near the pickup, filtered to the
/// requested service. These are map presence only, never "viewing".
List<NearbyDriverCandidate> nearbySearchCandidates({
  required List<dynamic> source,
  required dynamic serviceType,
  required int transportType,
  required double pickupLatitude,
  required double pickupLongitude,
  required DistanceBetween distanceBetween,
  DateTime? now,
}) {
  final candidates = <NearbyDriverCandidate>[];
  final reference = now ?? DateTime.now();

  for (final raw in source) {
    if (raw is! Map) continue;
    final driver = Map<String, dynamic>.from(raw);
    if (!searchFlagIsOn(driver['is_active']) ||
        !searchFlagIsOn(driver['is_available'])) {
      continue;
    }

    final transport = driver['transport_type']?.toString();
    final supportsTransport = transportType != 0 ||
        transport == null ||
        transport == 'taxi' ||
        transport == 'both';
    if (!supportsTransport || !searchDriverSupports(driver, serviceType)) {
      continue;
    }

    final updatedAt = int.tryParse(driver['updated_at']?.toString() ?? '');
    if (updatedAt == null ||
        reference
                .difference(DateTime.fromMillisecondsSinceEpoch(updatedAt))
                .inMinutes >
            2) {
      continue;
    }

    final location = driver['l'];
    if (location is! List || location.length < 2) continue;
    final latitude = double.tryParse(location[0].toString());
    final longitude = double.tryParse(location[1].toString());
    if (latitude == null || longitude == null) continue;

    candidates.add(
      NearbyDriverCandidate(
        data: driver,
        distance: distanceBetween(
          pickupLatitude,
          pickupLongitude,
          latitude,
          longitude,
        ),
      ),
    );
  }

  candidates.sort((a, b) => a.distance.compareTo(b.distance));
  return candidates;
}

/// Reads the drivers the dispatcher currently has on this request.
///
/// Accepts both `request-meta` shapes and ignores entries whose `driver_id`
/// was cleared, which is how the driver app signals "I skipped this ride".
Set<String> targetedDriverIds(dynamic requestMetadata) {
  final ids = <String>{};
  if (requestMetadata is! Map) return ids;
  final root = Map<dynamic, dynamic>.from(requestMetadata);

  void addFrom(Map<dynamic, dynamic> entry) {
    final id = entry['driver_id']?.toString().trim();
    if (id == null || id.isEmpty || id == 'null') return;
    if (entry.containsKey('active') && !searchFlagIsOn(entry['active'])) return;
    ids.add(id);
  }

  addFrom(root);
  for (final value in root.values) {
    if (value is Map) addFrom(Map<dynamic, dynamic>.from(value));
  }
  return ids;
}

/// Submitted offers keyed by driver id, skipping rejected/expired ones.
Map<String, Map<String, dynamic>> submittedOffers(
    dynamic counterOfferMetadata) {
  final offers = <String, Map<String, dynamic>>{};
  if (counterOfferMetadata is! Map) return offers;
  for (final value in counterOfferMetadata.values) {
    if (value is! Map || value['driver_id'] == null) continue;
    if (value['is_rejected']?.toString() != 'none') continue;
    final offer = Map<String, dynamic>.from(value);
    final id = offer['driver_id'].toString().trim();
    if (id.isEmpty) continue;
    offers[id] = offer;
  }
  return offers;
}

/// Merges nearby presence, dispatcher targeting and submitted offers into one
/// ordered list. Targeted drivers come first; every candidate carries whether
/// there is real evidence it received the request.
List<NearbyDriverCandidate> prioritizeTargetedDrivers(
  List<NearbyDriverCandidate> nearby,
  dynamic requestMetadata,
  dynamic counterOfferMetadata,
) {
  final offers = submittedOffers(counterOfferMetadata);
  // An offer can only exist if the driver received the request, so it counts
  // as targeting evidence even after request-meta moved on to another driver.
  final targetedIds = targetedDriverIds(requestMetadata)..addAll(offers.keys);

  NearbyDriverCandidate decorate(NearbyDriverCandidate candidate) {
    final offer = offers[candidate.driverId];
    final targeted = targetedIds.contains(candidate.driverId);
    if (offer == null) return candidate.copyWith(targeted: targeted);
    return candidate.copyWith(
      targeted: targeted,
      data: {
        ...candidate.data,
        if (offer['driver_name'] != null) 'name': offer['driver_name'],
        if (offer['driver_img'] != null) 'profile_picture': offer['driver_img'],
        'counter_offer': offer['price'],
        'counter_offer_base': offer['base_price'],
        'counter_offer_currency': offer['currency'],
      },
    );
  }

  final metadataById = <String, Map<String, dynamic>>{};
  if (requestMetadata is Map) {
    final root = Map<dynamic, dynamic>.from(requestMetadata);
    void collect(Map<dynamic, dynamic> entry) {
      final id = entry['driver_id']?.toString();
      if (id == null || id.isEmpty || id == 'null') return;
      metadataById.putIfAbsent(id, () => Map<String, dynamic>.from(entry));
    }

    collect(root);
    for (final value in root.values) {
      if (value is Map) collect(Map<dynamic, dynamic>.from(value));
    }
  }

  final nearbyById = <String, NearbyDriverCandidate>{
    for (final candidate in nearby) candidate.driverId: candidate,
  };

  final targeted = <NearbyDriverCandidate>[];
  final seen = <String>{};
  for (final id in targetedIds) {
    if (!seen.add(id)) continue;
    final known = nearbyById[id];
    if (known != null) {
      targeted.add(decorate(known));
      continue;
    }
    final offer = offers[id];
    final metadata = metadataById[id];
    targeted.add(
      NearbyDriverCandidate(
        targeted: true,
        data: {
          'id': id,
          if (offer?['driver_name'] != null)
            'name': offer!['driver_name']
          else if (metadata?['name'] != null)
            'name': metadata!['name'],
          if (offer?['driver_img'] != null)
            'profile_picture': offer!['driver_img']
          else if (metadata?['profile_picture'] != null)
            'profile_picture': metadata!['profile_picture'],
          if (metadata?['rating'] != null) 'rating': metadata!['rating'],
          if (offer != null) ...{
            'counter_offer': offer['price'],
            'counter_offer_base': offer['base_price'],
            'counter_offer_currency': offer['currency'],
          },
        },
        distance: double.infinity,
      ),
    );
  }

  return [
    ...targeted,
    ...nearby
        .where((candidate) => !seen.contains(candidate.driverId))
        .map(decorate),
  ];
}

bool searchFlagIsOn(dynamic value) =>
    value == true || value == 1 || value?.toString() == '1';

bool searchDriverSupports(Map<String, dynamic> driver, dynamic serviceType) {
  if (serviceType == null) return true;
  final expected = serviceType.toString();
  final types = driver['vehicle_types'];
  if (types is List && types.any((type) => type.toString() == expected)) {
    return true;
  }
  return driver['vehicle_type']?.toString() == expected;
}
