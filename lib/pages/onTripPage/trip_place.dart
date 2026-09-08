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
