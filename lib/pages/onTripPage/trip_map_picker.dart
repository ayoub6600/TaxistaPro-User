import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'trip_place.dart';

class TripMapPicker extends StatefulWidget {
  const TripMapPicker({
    super.key,
    required this.rtl,
    required this.role,
    required this.initialCenter,
    required this.reverseGeocode,
    this.initialPlace,
    this.useGoogleMap = true,
    this.mapStyle,
  });

  final bool rtl;
  final TripPointRole role;
  final LatLng initialCenter;
  final TripPlace? initialPlace;
  final bool useGoogleMap;
  final String? mapStyle;
  final Future<String?> Function(LatLng) reverseGeocode;

  @override
  State<TripMapPicker> createState() => _TripMapPickerState();
}

class _TripMapPickerState extends State<TripMapPicker> {
  GoogleMapController? _googleController;
  final _otherController = fm.MapController();
  Timer? _debounce;
  late LatLng _center = widget.initialCenter;
  late TripPlace? _place = widget.initialPlace;
  int _generation = 0;
  bool _loading = false;
  bool _moving = false;
  String? _error;

  bool get _pickup => widget.role == TripPointRole.pickup;
  Color get _color => _pickup ? const Color(0xFF16875A) : const Color(0xFF0879FA);
  String _copy(String ar, String en) => widget.rtl ? ar : en;

  @override
  void initState() {
    super.initState();
    if (_place?.coordinates != _center) _place = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _place == null) _resolveCenter();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _googleController?.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _move(LatLng center) {
    if (center == _center) return;
    _generation++;
    _debounce?.cancel();
    setState(() {
      _center = center;
      _place = null;
      _error = null;
      _moving = true;
    });
  }

  Future<void> _resolveCenter() async {
    if (_place?.coordinates == _center) {
      setState(() => _moving = false);
      return;
    }
    final position = _center;
    final generation = ++_generation;
    setState(() {
      _moving = false;
      _loading = true;
      _error = null;
    });
    try {
      final address = await widget.reverseGeocode(position);
      if (!mounted || generation != _generation) return;
      if (address == null || address.trim().isEmpty) {
        throw StateError('Address unavailable');
      }
      setState(() {
        _place = TripPlace(address: address, coordinates: position);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = _copy('تعذّر تحميل العنوان. تأكد من الاتصال وحاول مجددًا.',
            'Could not load the address. Check your connection and retry.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: widget.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(_pickup ? _copy('نقطة مقابلة السائق', 'Driver meeting point')
                : _copy('تحديد الوجهة', 'Choose destination'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          body: Column(children: [
            Expanded(child: Stack(alignment: Alignment.center, children: [
              if (widget.useGoogleMap)
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _center, zoom: 16),
                  style: widget.mapStyle,
                  onMapCreated: (controller) {
                    if (!mounted) { controller.dispose(); return; }
                    _googleController = controller;
                  },
                  onCameraMove: (camera) => _move(camera.target),
                  onCameraIdle: _resolveCenter,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: false,
                )
              else
                fm.FlutterMap(
                  mapController: _otherController,
                  options: fm.MapOptions(
                    initialCenter: ll.LatLng(_center.latitude, _center.longitude),
                    initialZoom: 16,
                    onPositionChanged: (camera, hasGesture) {
                      _move(LatLng(camera.center.latitude, camera.center.longitude));
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), _resolveCenter);
                    },
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.Ayoub.Usertaxista',
                    ),
                    const fm.RichAttributionWidget(attributions: [
                      fm.TextSourceAttribution('OpenStreetMap contributors'),
                    ]),
                  ],
                ),
              IgnorePointer(child: Transform.translate(
                offset: const Offset(0, -24),
                child: Icon(Icons.location_on_rounded, size: 52, color: _color),
              )),
              Positioned(top: 14, left: 20, right: 20,
                child: IgnorePointer(child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12)]),
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: Text(_pickup
                        ? _copy('حرّك الخريطة إلى مكان واضح وآمن لانتظار السائق.',
                            'Move the map to a clear, safe place to meet your driver.')
                        : _copy('حرّك الخريطة حتى تصبح العلامة فوق مكان الوصول.',
                            'Move the map until the pin marks your destination.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, height: 1.4))),
                )),
              ),
            ])),
            SafeArea(top: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min, children: [
                  Text(_pickup ? _copy('هنا ستقابل السائق', 'Meet your driver here')
                      : _copy('هنا ستكون وجهتك', 'Your destination'),
                      style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 8),
                  if (_loading || _moving)
                    Row(children: [
                      SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _color)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_copy('جارٍ تحديد العنوان…', 'Finding the address…'))),
                    ])
                  else if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Color(0xFFB42318), height: 1.4)),
                    TextButton(onPressed: _resolveCenter,
                        child: Text(_copy('إعادة المحاولة', 'Retry'))),
                  ] else
                    Text(_place?.address ?? '', maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: !_loading && !_moving && _place != null
                        ? () => Navigator.pop(context, _place) : null,
                    style: FilledButton.styleFrom(backgroundColor: _color,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(_pickup ? _copy('تأكيد نقطة اللقاء', 'Confirm meeting point')
                        : _copy('تأكيد الوجهة', 'Confirm destination'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ]),
            )),
          ]),
        ),
      );
}
