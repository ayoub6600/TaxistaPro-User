import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../functions/functions.dart' show mapType;
import '../../functions/parcel_route.dart';
import '../../functions/tr.dart';
import '../onTripPage/map_page.dart' show mapStyle;
import 'parcel_pins.dart';

/// The real map above «شن تبعت؟» (owner 2026-11-19): the green pin where the captain takes it, the blue
/// pin where it goes, the road between them, and 📦 moving along it. Fits both places in view.
class ParcelMap extends StatefulWidget {
  const ParcelMap({super.key, required this.pick, this.drop, this.topInset = 0, this.bottomInset = 0, this.mover = '📦'});

  final LatLng pick;
  final LatLng? drop;
  final double topInset;
  final double bottomInset;

  /// what moves along the road (🚚 on the moving page)
  final String mover;

  static String get pickLabel => tr('الكابتن ياخذها من هنا', 'Picked up here');
  static String get dropLabel => tr('توصل هنا', 'Delivered here');

  @override
  State<ParcelMap> createState() => _ParcelMapState();
}

class _ParcelMapState extends State<ParcelMap> with SingleTickerProviderStateMixin {
  GoogleMapController? _g;
  final _fm = fm.MapController();
  List<LatLng> _road = const [];
  BitmapDescriptor? _pickIcon, _dropIcon, _boxIcon;
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  int _gen = 0;
  bool get _google => mapType == 'google';

  @override
  void initState() {
    super.initState();
    // ~20 moves a second: smooth enough, and the map's markers aren't redrawn every frame
    var last = 0;
    _move.addListener(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_road.length >= 2 && now - last >= 50) {
        last = now;
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _icons());
    _loadRoad();
  }

  @override
  void didUpdateWidget(ParcelMap old) {
    super.didUpdateWidget(old);
    if (old.pick != widget.pick || old.drop != widget.drop) _loadRoad();
  }

  @override
  void dispose() {
    _move.dispose();
    _g?.dispose();
    _fm.dispose();
    super.dispose();
  }

  Future<void> _icons() async {
    if (!mounted || !_google) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final pick = await ParcelPin.bitmap(label: ParcelMap.pickLabel, color: ParcelPin.pickColor, icon: Icons.inventory_2_rounded, dpr: dpr);
    final drop = await ParcelPin.bitmap(label: ParcelMap.dropLabel, color: ParcelPin.dropColor, icon: Icons.flag_rounded, dpr: dpr);
    final box = await ParcelPin.parcel(dpr, mover: widget.mover);
    if (mounted) {
      setState(() {
        _pickIcon = pick;
        _dropIcon = drop;
        _boxIcon = box;
      });
    }
  }

  Future<void> _loadRoad() async {
    final gen = ++_gen;
    final d = widget.drop;
    _move.stop();
    // no setState here: this runs from initState and didUpdateWidget, and a build follows both
    _road = d == null ? const [] : [widget.pick, d];
    _fit();
    if (d == null) return;
    final road = await ParcelRoute.between(widget.pick, d);
    if (!mounted || gen != _gen) return;
    setState(() => _road = road);
    _fit();
    // the parcel travels only when the phone allows motion
    if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) _move.repeat();
  }

  void _fit() {
    final pts = [widget.pick, if (widget.drop != null) widget.drop!, ..._road];
    if (_google) {
      final g = _g;
      if (g == null) return;
      g.animateCamera(pts.length < 2 || widget.drop == null
          ? CameraUpdate.newLatLngZoom(widget.pick, 15.5)
          : CameraUpdate.newLatLngBounds(ParcelRoute.bounds(pts), 56));
    } else {
      try {
        if (widget.drop == null) {
          _fm.move(ll.LatLng(widget.pick.latitude, widget.pick.longitude), 15.5);
        } else {
          final b = ParcelRoute.bounds(pts);
          _fm.fitCamera(fm.CameraFit.bounds(
              bounds: fm.LatLngBounds(ll.LatLng(b.southwest.latitude, b.southwest.longitude), ll.LatLng(b.northeast.latitude, b.northeast.longitude)),
              padding: EdgeInsets.fromLTRB(56, widget.topInset + 80, 56, widget.bottomInset + 40)));
        }
      } catch (_) {} // before the first frame the camera isn't ready; onMapReady fits again
    }
  }

  LatLng? get _box => _road.length >= 2 && _move.isAnimating ? ParcelRoute.along(_road, Curves.easeInOut.transform(_move.value)) : null;

  @override
  Widget build(BuildContext context) => _google ? _googleMap() : _osm();

  Widget _googleMap() {
    final box = _box;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: widget.pick, zoom: 15),
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
        if (_pickIcon != null) Marker(markerId: const MarkerId('pick'), position: widget.pick, icon: _pickIcon!, anchor: const Offset(.5, 1), zIndex: 2),
        if (_dropIcon != null && widget.drop != null)
          Marker(markerId: const MarkerId('drop'), position: widget.drop!, icon: _dropIcon!, anchor: const Offset(.5, 1), zIndex: 2),
        if (_boxIcon != null && box != null) Marker(markerId: const MarkerId('box'), position: box, icon: _boxIcon!, anchor: const Offset(.5, .5), zIndex: 3),
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
  }

  Widget _osm() {
    final box = _box;
    ll.LatLng p(LatLng v) => ll.LatLng(v.latitude, v.longitude);
    final pickSize = ParcelPin.measure(ParcelMap.pickLabel), dropSize = ParcelPin.measure(ParcelMap.dropLabel);
    return fm.FlutterMap(
      mapController: _fm,
      options: fm.MapOptions(initialCenter: p(widget.pick), initialZoom: 15, onMapReady: _fit,
          interactionOptions: const fm.InteractionOptions(flags: fm.InteractiveFlag.drag | fm.InteractiveFlag.pinchZoom)),
      children: [
        fm.TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.taxistapro.user'),
        if (_road.length >= 2)
          fm.PolylineLayer(polylines: [
            fm.Polyline(points: _road.map(p).toList(), color: const Color(0xff0873FF), strokeWidth: 5, borderColor: Colors.white, borderStrokeWidth: 2),
          ]),
        fm.MarkerLayer(markers: [
          fm.Marker(point: p(widget.pick), width: pickSize.width, height: pickSize.height, alignment: Alignment.topCenter,
              child: ParcelPinWidget(label: ParcelMap.pickLabel, color: ParcelPin.pickColor, icon: Icons.inventory_2_rounded)),
          if (widget.drop != null)
            fm.Marker(point: p(widget.drop!), width: dropSize.width, height: dropSize.height, alignment: Alignment.topCenter,
                child: ParcelPinWidget(label: ParcelMap.dropLabel, color: ParcelPin.dropColor, icon: Icons.flag_rounded)),
          if (box != null)
            fm.Marker(point: p(box), width: 34, height: 34,
                child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x40102A56), blurRadius: 5)]),
                    child: Center(child: Text(widget.mover, style: const TextStyle(fontSize: 18))))),
        ]),
        const fm.RichAttributionWidget(attributions: [fm.TextSourceAttribution('OpenStreetMap contributors')]),
      ],
    );
  }
}
