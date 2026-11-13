import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/functions.dart' show geoCoding, mapType;
import '../../functions/intercity_api.dart' show IcPlace;
import 'trip_map_picker.dart';
import 'trip_place.dart';

/// A place chosen by moving the map under the pin (the app's own map), or null.
Future<IcPlace?> placeOnMap(BuildContext context, {required LatLng center, TripPointRole role = TripPointRole.destination}) async {
  final p = await Navigator.of(context).push<TripPlace?>(MaterialPageRoute(
    builder: (_) => TripMapPicker(
      rtl: true,
      role: role,
      initialCenter: center,
      reverseGeocode: (p) => geoCoding(p.latitude, p.longitude),
      useGoogleMap: mapType == 'google',
    ),
  ));
  final c = p?.coordinates;
  return c == null ? null : IcPlace(c.latitude, c.longitude, p!.address);
}
