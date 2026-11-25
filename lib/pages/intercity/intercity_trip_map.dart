import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../functions/functions.dart' show mapType;
import '../../functions/intercity_api.dart';
import '../../functions/parcel_route.dart';
import '../onTripPage/map_page.dart' show mapStyle;
import 'intercity_style.dart';

/// The real map above «كيف تحب تسافر؟»: where he stands (green), the city he travels to (blue) and a
/// line between them, both always in view. It only shows the trip: it takes no touches. Without the
/// two places (an old server answer) the drawn route stays.
class IcTripMap extends StatefulWidget {
  const IcTripMap({super.key, required this.pick, required this.route, this.topInset = 0, this.bottomInset = 0});

  final IcPlace pick;
  final IntercityRoute route;

  /// what the top bar and the sheet cover of the map
  final double topInset;
  final double bottomInset;

  static const fromColor = Color(0xff17A45B);

  @override
  State<IcTripMap> createState() => _IcTripMapState();
}

class _IcTripMapState extends State<IcTripMap> {
  GoogleMapController? _g;
  final _fm = fm.MapController();
  BitmapDescriptor? _fromIcon, _toIcon;
  Size? _size;
  Timer? _soon;
  bool _fitted = false;

  bool get _google => mapType == 'google';
  LatLng get _from => LatLng(widget.pick.lat, widget.pick.lng);
  LatLng get _to => LatLng(widget.route.lat, widget.route.lng);
  bool get _known => (widget.pick.lat != 0 || widget.pick.lng != 0) && (widget.route.lat != 0 || widget.route.lng != 0);
  LatLng get _middle => LatLng((_from.latitude + _to.latitude) / 2, (_from.longitude + _to.longitude) / 2);

  /// near the zoom the fit will choose, so the first picture barely moves (the strip of map is wide
  /// and short: a degree north-south needs far more room than one east-west)
  double get _zoom {
    final span = math.max((_from.longitude - _to.longitude).abs(), (_from.latitude - _to.latitude).abs() * 3.5);
    return span <= 0 ? 12 : (math.log(300 / span) / math.ln2).clamp(4.0, 13.0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _icons());
  }

  @override
  void didUpdateWidget(IcTripMap old) {
    super.didUpdateWidget(old);
    if (old.route.lat != widget.route.lat || old.route.lng != widget.route.lng || old.pick.lat != widget.pick.lat || old.pick.lng != widget.pick.lng) _fitSoon();
  }

  @override
  void dispose() {
    _soon?.cancel();
    _g?.dispose();
    _fm.dispose();
    super.dispose();
  }

  Future<void> _icons() async {
    if (!mounted || !_google || !_known) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final from = await _dot(IcTripMap.fromColor, dpr), to = await _dot(IcStyle.blue, dpr);
    if (mounted) {
      setState(() {
        _fromIcon = from;
        _toIcon = to;
      });
    }
  }

  /// a round dot with a white ring, as the drawing of the trip had
  static Future<BitmapDescriptor> _dot(Color color, double dpr) async {
    const s = 30.0, c = Offset(s / 2, s / 2);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(dpr);
    canvas.drawCircle(c.translate(0, 1), 13, Paint()
      ..color = const Color(0x40102A56)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(c, 13, Paint()..color = Colors.white);
    canvas.drawCircle(c, 9, Paint()..color = color);
    final img = await rec.endRecording().toImage((s * dpr).ceil(), (s * dpr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }

  /// the map takes a moment to know its new size (the sheet grew) or its new city
  void _fitSoon() {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 250), _fit);
  }

  void _fit() {
    final size = _size;
    if (!mounted || size == null || !_known) return;
    final b = ParcelRoute.bounds([_from, _to]);
    // the air around the two dots, less of it when the sheet leaves a short map
    final free = size.height - widget.topInset - widget.bottomInset;
    final pad = ((free < size.width ? free : size.width) / 2 - 16).clamp(0.0, 48.0);
    if (_google) {
      final g = _g;
      if (g == null) return;
      final to = CameraUpdate.newLatLngBounds(b, pad);
      // the first time it is simply there; another city glides to its place
      (_fitted ? g.animateCamera(to) : g.moveCamera(to)).catchError((Object _) {});
      _fitted = true;
    } else {
      try {
        _fm.fitCamera(fm.CameraFit.bounds(
            bounds: fm.LatLngBounds(ll.LatLng(b.southwest.latitude, b.southwest.longitude), ll.LatLng(b.northeast.latitude, b.northeast.longitude)),
            padding: EdgeInsets.fromLTRB(pad, widget.topInset + pad, pad, widget.bottomInset + pad)));
      } catch (_) {} // before the first frame the camera isn't ready; onMapReady fits again
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_known) return CustomPaint(painter: IcRoutePainter());
    return LayoutBuilder(builder: (context, c) {
      if (c.biggest != _size) {
        _size = c.biggest;
        _fitSoon();
      }
      return IgnorePointer(child: _google ? _googleMap() : _osm());
    });
  }

  Widget _googleMap() => GoogleMap(
        initialCameraPosition: CameraPosition(target: _middle, zoom: _zoom),
        style: mapStyle.isEmpty ? null : mapStyle,
        padding: EdgeInsets.only(top: widget.topInset, bottom: widget.bottomInset),
        onMapCreated: (c) {
          if (!mounted) {
            c.dispose();
            return;
          }
          _g = c;
          _fitSoon();
        },
        markers: {
          if (_fromIcon != null) Marker(markerId: const MarkerId('from'), position: _from, icon: _fromIcon!, anchor: const Offset(.5, .5), zIndex: 2),
          if (_toIcon != null) Marker(markerId: const MarkerId('to'), position: _to, icon: _toIcon!, anchor: const Offset(.5, .5), zIndex: 3),
        },
        polylines: {
          Polyline(polylineId: const PolylineId('under'), points: [_from, _to], color: Colors.white, width: 9, startCap: Cap.roundCap, endCap: Cap.roundCap),
          Polyline(polylineId: const PolylineId('trip'), points: [_from, _to], color: IcStyle.blue, width: 5, startCap: Cap.roundCap, endCap: Cap.roundCap),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        buildingsEnabled: false,
        compassEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
      );

  Widget _osm() {
    ll.LatLng p(LatLng v) => ll.LatLng(v.latitude, v.longitude);
    Widget dot(Color color) => DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Color(0x40102A56), blurRadius: 4, offset: Offset(0, 1))]),
        );
    return fm.FlutterMap(
      mapController: _fm,
      options: fm.MapOptions(
        initialCenter: p(_middle),
        initialZoom: _zoom,
        onMapReady: _fit,
        interactionOptions: const fm.InteractionOptions(flags: fm.InteractiveFlag.none),
      ),
      children: [
        fm.TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.taxistapro.user'),
        fm.PolylineLayer(polylines: [
          fm.Polyline(points: [p(_from), p(_to)], color: IcStyle.blue, strokeWidth: 5, borderColor: Colors.white, borderStrokeWidth: 2),
        ]),
        fm.MarkerLayer(markers: [
          fm.Marker(point: p(_from), width: 26, height: 26, child: dot(IcTripMap.fromColor)),
          fm.Marker(point: p(_to), width: 26, height: 26, child: dot(IcStyle.blue)),
        ]),
        Padding(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: const fm.SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
        ),
      ],
    );
  }
}
