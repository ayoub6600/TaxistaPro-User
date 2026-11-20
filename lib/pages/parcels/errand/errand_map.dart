import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../functions/functions.dart' show mapType;
import '../../../functions/parcel_route.dart';
import '../../../functions/tr.dart';
import '../../onTripPage/map_page.dart' show mapStyle;
import '../parcel_pins.dart';

/// «مشوار بوقفات» on the real map: each stop a blue pin with its number, the green pin where he
/// gets them, and the road stop by stop. Fits everything in view.
class ErrandMap extends StatefulWidget {
  const ErrandMap({super.key, required this.stops, required this.drop, this.topInset = 0, this.bottomInset = 0});

  final List<LatLng> stops;
  final LatLng drop;
  final double topInset;
  final double bottomInset;

  static String stopLabel(int n) => tr('الوقفة $n', 'Stop $n');
  static String get dropLabel => tr('يجيبهم هنا', 'Brought here');

  @override
  State<ErrandMap> createState() => _ErrandMapState();
}

class _ErrandMapState extends State<ErrandMap> {
  GoogleMapController? _g;
  final _fm = fm.MapController();
  List<LatLng> _road = const [];
  final Map<String, BitmapDescriptor> _icons = {};
  int _gen = 0;
  bool get _google => mapType == 'google';

  List<LatLng> get _points => [...widget.stops, widget.drop];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeIcons());
    _loadRoad();
  }

  @override
  void didUpdateWidget(ErrandMap old) {
    super.didUpdateWidget(old);
    if (old.drop != widget.drop || !_same(old.stops, widget.stops)) {
      _loadRoad();
      _makeIcons();
    }
  }

  static bool _same(List<LatLng> a, List<LatLng> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _g?.dispose();
    _fm.dispose();
    super.dispose();
  }

  Future<void> _makeIcons() async {
    if (!mounted || !_google) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final want = {for (var i = 1; i <= widget.stops.length; i++) ErrandMap.stopLabel(i): ParcelPin.dropColor, ErrandMap.dropLabel: ParcelPin.pickColor};
    for (final e in want.entries) {
      if (_icons.containsKey(e.key)) continue;
      final icon = e.value == ParcelPin.pickColor ? Icons.flag_rounded : Icons.storefront_rounded;
      final b = await ParcelPin.bitmap(label: e.key, color: e.value, icon: icon, dpr: dpr);
      if (!mounted) return;
      _icons[e.key] = b;
    }
    if (mounted) setState(() {});
  }

  /// the road leg by leg (straight lines until each comes)
  Future<void> _loadRoad() async {
    final gen = ++_gen;
    final pts = _points;
    _road = pts.length >= 2 ? pts : const [];
    _fit();
    if (pts.length < 2) return;
    final legs = await Future.wait([for (var i = 1; i < pts.length; i++) ParcelRoute.between(pts[i - 1], pts[i])]);
    if (!mounted || gen != _gen) return;
    setState(() => _road = [for (final l in legs) ...l]);
    _fit();
  }

  void _fit() {
    final pts = [..._points, ..._road];
    final one = _points.length < 2;
    if (_google) {
      _g?.animateCamera(one ? CameraUpdate.newLatLngZoom(widget.drop, 15.5) : CameraUpdate.newLatLngBounds(ParcelRoute.bounds(pts), 56));
      return;
    }
    try {
      if (one) {
        _fm.move(ll.LatLng(widget.drop.latitude, widget.drop.longitude), 15.5);
      } else {
        final b = ParcelRoute.bounds(pts);
        _fm.fitCamera(fm.CameraFit.bounds(
            bounds: fm.LatLngBounds(ll.LatLng(b.southwest.latitude, b.southwest.longitude), ll.LatLng(b.northeast.latitude, b.northeast.longitude)),
            padding: EdgeInsets.fromLTRB(56, widget.topInset + 80, 56, widget.bottomInset + 40)));
      }
    } catch (_) {} // the camera isn't ready before the first frame; onMapReady fits again
  }

  /// (label, place, colour) for every pin
  List<(String, LatLng, Color)> get _pins => [
        for (var i = 0; i < widget.stops.length; i++) (ErrandMap.stopLabel(i + 1), widget.stops[i], ParcelPin.dropColor),
        (ErrandMap.dropLabel, widget.drop, ParcelPin.pickColor),
      ];

  @override
  Widget build(BuildContext context) => _google ? _googleMap() : _osm();

  Widget _googleMap() => GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.drop, zoom: 15),
        style: mapStyle.isEmpty ? null : mapStyle,
        padding: EdgeInsets.only(top: widget.topInset + 64, bottom: widget.bottomInset + 10),
        onMapCreated: (c) {
          if (!mounted) {
            c.dispose();
            return;
          }
          _g = c;
          Future.delayed(const Duration(milliseconds: 250), _fit);
        },
        markers: {
          for (final (label, at, _) in _pins)
            if (_icons[label] != null) Marker(markerId: MarkerId(label), position: at, icon: _icons[label]!, anchor: const Offset(.5, 1), zIndex: 2),
        },
        polylines: {
          if (_road.length >= 2) ...{
            Polyline(polylineId: const PolylineId('under'), points: _road, color: Colors.white, width: 9),
            Polyline(polylineId: const PolylineId('road'), points: _road, color: const Color(0xff0873FF), width: 5),
          },
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        buildingsEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      );

  Widget _osm() {
    ll.LatLng p(LatLng v) => ll.LatLng(v.latitude, v.longitude);
    return fm.FlutterMap(
      mapController: _fm,
      options: fm.MapOptions(
          initialCenter: p(widget.drop),
          initialZoom: 15,
          onMapReady: _fit,
          interactionOptions: const fm.InteractionOptions(flags: fm.InteractiveFlag.drag | fm.InteractiveFlag.pinchZoom)),
      children: [
        fm.TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.taxistapro.user'),
        if (_road.length >= 2)
          fm.PolylineLayer(polylines: [
            fm.Polyline(points: _road.map(p).toList(), color: const Color(0xff0873FF), strokeWidth: 5, borderColor: Colors.white, borderStrokeWidth: 2),
          ]),
        fm.MarkerLayer(markers: [
          for (final (label, at, color) in _pins)
            fm.Marker(
                point: p(at),
                width: ParcelPin.measure(label).width,
                height: ParcelPin.measure(label).height,
                alignment: Alignment.topCenter,
                child: ParcelPinWidget(label: label, color: color, icon: color == ParcelPin.pickColor ? Icons.flag_rounded : Icons.storefront_rounded)),
        ]),
        const fm.RichAttributionWidget(attributions: [fm.TextSourceAttribution('OpenStreetMap contributors')]),
      ],
    );
  }
}
