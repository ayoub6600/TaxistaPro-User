import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// The route as it should be drawn from where the car is now (owner 2026-11-25:
/// the blue line stayed behind the moving car). Finds the closest point of the
/// route to [car], drops everything the car has already passed and starts the
/// line at the car itself.
///
/// The route is left as it is when the car is farther than [maxOffRouteMeters]
/// from every part of it (a wrong turn or a stale route): cutting then would eat
/// a piece the car has not driven yet.
List<LatLng> trimRouteToCar(List<LatLng> route, LatLng car,
    {double maxOffRouteMeters = 250}) {
  if (route.length < 2) return route;

  // Flat metres around the car: plenty precise for a city route.
  final latRad = car.latitude * math.pi / 180;
  const metersPerDegLat = 111320.0;
  final metersPerDegLng = 111320.0 * math.cos(latRad);
  double x(LatLng p) => (p.longitude - car.longitude) * metersPerDegLng;
  double y(LatLng p) => (p.latitude - car.latitude) * metersPerDegLat;

  final distances = List<double>.filled(route.length - 1, 0);
  var best = double.infinity;
  for (var i = 0; i < route.length - 1; i++) {
    final ax = x(route[i]), ay = y(route[i]);
    final bx = x(route[i + 1]), by = y(route[i + 1]);
    final dx = bx - ax, dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    var t = lengthSquared == 0 ? 0.0 : -(ax * dx + ay * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);
    final px = ax + t * dx, py = ay + t * dy;
    distances[i] = math.sqrt(px * px + py * py);
    if (distances[i] < best) best = distances[i];
  }
  if (best > maxOffRouteMeters) return route;

  // The first segment that is about as close as the best one: when the road
  // comes back near itself the car is on the earlier pass, not the later one.
  var segment = 0;
  for (var i = 0; i < distances.length; i++) {
    if (distances[i] <= best + 15) {
      segment = i;
      break;
    }
  }

  return <LatLng>[car, ...route.sublist(segment + 1)];
}
