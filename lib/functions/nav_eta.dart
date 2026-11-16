/// The captain's in-app navigation writes its time left on his Firebase node (nav_eta_s, nav_eta_at
/// in ms, nav_ride). Minutes left for this ride, or null when there is none, it is for another ride,
/// or it is older than two minutes (he left the navigation).
int? navEtaMinutes(Map? driverNode, String rideId, {DateTime? now}) {
  if (driverNode == null) return null;
  final s = driverNode['nav_eta_s'];
  final at = driverNode['nav_eta_at'];
  if (s is! num || at is! num || '${driverNode['nav_ride']}' != rideId) return null;
  final age = (now ?? DateTime.now()).millisecondsSinceEpoch - at.toInt();
  if (age < 0 || age > 120000) return null;
  final left = s - age / 1000;
  return left <= 0 ? 0 : (left / 60).ceil();
}
