import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// Where Taxista works: the market's zones from the server (request/service-zones), drawn on the map as a
/// soft blue area with its border, so a rider sees the limits before choosing a destination. An older server
/// without the endpoint simply draws nothing.
class ServiceZones {
  static final ValueNotifier<Set<Polygon>> polygons = ValueNotifier(<Polygon>{});
  static DateTime? _loadedAt;
  static bool _loading = false;

  static Future<void> load({bool force = false}) async {
    if (_loading || bearerToken.isEmpty) return;
    final last = _loadedAt;
    if (!force && last != null && DateTime.now().difference(last) < const Duration(hours: 6)) return;
    _loading = true;
    try {
      final r = await http.get(Uri.parse('${url}api/v1/request/service-zones'), headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return;
      final zones = (jsonDecode(r.body)['data']?['zones'] as List?) ?? const [];
      final out = <Polygon>{};
      for (final z in zones) {
        if (z is! Map) continue;
        final rings = (z['polygons'] as List?) ?? const [];
        for (var i = 0; i < rings.length; i++) {
          final ring = (rings[i] as List).whereType<List>().map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
          if (ring.length < 3) continue;
          out.add(Polygon(
            polygonId: PolygonId('zone-${z['id']}-$i'),
            points: ring,
            strokeWidth: 2,
            strokeColor: const Color(0xff0873FF).withValues(alpha: .7),
            fillColor: const Color(0xff0873FF).withValues(alpha: .05),
            consumeTapEvents: false,
            zIndex: 0,
          ));
        }
      }
      _loadedAt = DateTime.now();
      polygons.value = out;
    } catch (_) {
      // no zones drawn: the server still refuses a destination outside them
    } finally {
      _loading = false;
    }
  }
}
