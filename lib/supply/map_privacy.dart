import 'dart:math' as math;

/// A captain's car is drawn near his real spot, never exactly on it (owner 2026-11-16): a fixed
/// offset per captain (the same every time, so the car does not jump), up to [meters] away.
class MapPrivacy {
  static List<double> blur(Object? id, List<dynamic> spot, int meters) {
    final lat = (spot[0] as num).toDouble();
    final lng = (spot[1] as num).toDouble();
    if (meters <= 0) return [lat, lng];
    final seed = id.toString().codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
    final angle = (seed % 360) * math.pi / 180;
    final distance = meters * (0.5 + (seed % 50) / 100); // half to all of the allowance
    final dLat = distance * math.cos(angle) / 111320;
    final dLng = distance * math.sin(angle) / (111320 * math.cos(lat * math.pi / 180));
    return [lat + dLat, lng + dLng];
  }
}
