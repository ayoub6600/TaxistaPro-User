import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLaunchCoordinator {
  static const double regionalZoom = 6.2;
  static const double cityZoom = 10.8;
  static const double neighborhoodZoom = 15.5;

  bool _started = false;

  Future<void> animateToLocation({
    required GoogleMapController controller,
    required LatLng target,
  }) async {
    if (_started) return;
    _started = true;

    try {
      // Keep the regional view visible briefly after the splash starts
      // revealing the live map. Starting earlier hides the zoom behind it.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, cityZoom),
      );
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, 13.1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, neighborhoodZoom),
      );
    } catch (error) {
      debugPrint('Map launch camera animation skipped: $error');
    }
  }
}
