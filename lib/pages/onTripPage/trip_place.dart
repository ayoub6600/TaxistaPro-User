import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TripPointRole { pickup, destination }

/// Search results may be unresolved until selected; a confirmed point always
/// carries coordinates. Roles belong to the trip, never to a recent result.
class TripPlace {
  const TripPlace({required this.address, this.coordinates, this.placeId});

  final String address;
  final LatLng? coordinates;
  final String? placeId;

  static LatLng? parseCoordinates(dynamic latitude, dynamic longitude) {
    final lat = double.tryParse(latitude.toString());
    final lng = double.tryParse(longitude.toString());
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite ||
        lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return LatLng(lat, lng);
  }
}

class TripSelection {
  const TripSelection({this.pickup, this.destination});

  final TripPlace? pickup;
  final TripPlace? destination;

  bool get isComplete =>
      pickup?.coordinates != null && destination?.coordinates != null;

  TripPlace? point(TripPointRole role) =>
      role == TripPointRole.pickup ? pickup : destination;

  TripSelection select(TripPointRole role, TripPlace? place) => TripSelection(
        pickup: role == TripPointRole.pickup ? place : pickup,
        destination: role == TripPointRole.destination ? place : destination,
      );
}

/// Words another flow puts on the shared search and map screens (parcels: «من وين ياخذها الكابتن»),
/// one per role: [pickup, destination]. Null keeps the ride's words.
class TripCopy {
  const TripCopy({required this.title, required this.labels, required this.asks, required this.confirm, required this.mapHints, required this.mapConfirm});

  final String title;
  final List<String> labels;
  final List<String> asks;
  final String confirm;
  final List<String> mapHints;
  final List<String> mapConfirm;

  static int of(TripPointRole r) => r == TripPointRole.pickup ? 0 : 1;
}
