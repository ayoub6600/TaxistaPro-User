import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'functions.dart' show decodePolylinePoints, mapkey, packageName, signKey;

/// The road between two places for the parcels map (owner 2026-11-19: «من المكان الحقيقي إلى المكان
/// الحقيقي»). Shares the booking map's cache; a straight line when the road can't be had.
class ParcelRoute {
  static Future<List<LatLng>> between(LatLng a, LatLng b) async {
    final key = 'polyline_${a.latitude}_${a.longitude}|${b.latitude}_${b.longitude}';
    try {
      final box = Hive.isBoxOpen('geocoding_cache') ? Hive.box('geocoding_cache') : null;
      final cached = box?.get(key);
      if (cached is String && cached.isNotEmpty) return decodePolylinePoints(cached);
      final r = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=${a.latitude}%2C${a.longitude}'
            '&destination=${b.latitude}%2C${b.longitude}&avoid=ferries|indoor&mode=driving&key=$mapkey'),
        headers: Platform.isAndroid ? {'X-Android-Package': packageName, 'X-Android-Cert': signKey} : {'X-IOS-Bundle-Identifier': packageName},
      ).timeout(const Duration(seconds: 10));
      final routes = r.statusCode == 200 ? jsonDecode(r.body)['routes'] : null;
      if (routes is List && routes.isNotEmpty) {
        final points = '${routes.first['overview_polyline']['points']}';
        box?.put(key, points);
        final line = decodePolylinePoints(points);
        if (line.length >= 2) return line;
      }
    } catch (_) {}
    return [a, b];
  }

  /// the point a share (0..1) of the way along the line, by distance
  static LatLng along(List<LatLng> line, double share) {
    if (line.length < 2) return line.first;
    final legs = <double>[];
    var total = 0.0;
    for (var i = 1; i < line.length; i++) {
      final d = _dist(line[i - 1], line[i]);
      legs.add(d);
      total += d;
    }
    var left = total * share.clamp(0.0, 1.0);
    for (var i = 0; i < legs.length; i++) {
      if (left <= legs[i] || i == legs.length - 1) {
        final t = legs[i] == 0 ? 0.0 : (left / legs[i]).clamp(0.0, 1.0);
        final p = line[i], q = line[i + 1];
        return LatLng(p.latitude + (q.latitude - p.latitude) * t, p.longitude + (q.longitude - p.longitude) * t);
      }
      left -= legs[i];
    }
    return line.last;
  }

  static double _dist(LatLng a, LatLng b) {
    final dx = (a.longitude - b.longitude) * 0.85; // close enough at Libya's latitudes, only for spacing
    final dy = a.latitude - b.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }

  static LatLngBounds bounds(List<LatLng> pts) {
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      s = p.latitude < s ? p.latitude : s;
      n = p.latitude > n ? p.latitude : n;
      w = p.longitude < w ? p.longitude : w;
      e = p.longitude > e ? p.longitude : e;
    }
    return LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e));
  }
}
