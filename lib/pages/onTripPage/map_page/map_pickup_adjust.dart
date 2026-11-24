// ignore_for_file: invalid_use_of_protected_member
part of '../map_page.dart';

/// The pickup on the home map (owner 2026-11-24, Google Maps cost): it is the phone's own place and
/// the mascot stands there as a marker, so panning or zooming changes nothing and asks nobody for an
/// address. Only «من أين» (a tap on the pickup field) starts the pickup-adjust mode: the mascot waits
/// in the middle of the screen, the map moves the pickup, and the address is asked once when the map
/// stops (through the server's shared cache, see lib/maps/pin_address.dart), never while it moves.
extension _MapPickupAdjust on _MapsState {
  /// Where the mascot marker stands: the phone's place on the home screen, the chosen pickup while
  /// the trip is being planned; none in pickup-adjust mode (the pin in the middle is the pickup).
  LatLng? get _pickupMarkerPoint {
    if (_pickupAdjust) return null;
    if (_bottom == 1) {
      final pickup = addressList.where((e) => e.type == 'pickup');
      if (pickup.isNotEmpty) return pickup.first.latlng;
    }
    return currentLocation is LatLng ? currentLocation as LatLng : null;
  }

  /// the mascot + the rider's name as one marker image, made again only when the name changes
  void _ensureMascotIcon() {
    final name = _riderFirstName();
    if (_mascotIconName == name) return;
    _mascotIconName = name;
    unawaited(_makeMascotIcon(name, MediaQuery.devicePixelRatioOf(context)));
  }

  Future<void> _makeMascotIcon(String name, double ratio) async {
    try {
      final icon = await riderMascotMarkerIcon(name, ratio);
      if (mounted && _mascotIconName == name) setState(() => _mascotIcon = icon);
    } catch (_) {
      _mascotIconName = null; // asked again on the next build
    }
  }

  Set<Marker> _withPickupMarker(Iterable<Marker> cars) {
    final point = _pickupMarkerPoint;
    final icon = _mascotIcon;
    if (point == null || icon == null) return Set<Marker>.from(cars);
    return {
      ...cars,
      Marker(
        markerId: const MarkerId('rider-pickup'),
        position: point,
        icon: icon,
        anchor: const Offset(.5, 1),
        zIndex: 5,
        consumeTapEvents: true,
      ),
    };
  }

  void _moveMapTo(LatLng to, double zoom) {
    if (mapType == 'google') {
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(to, zoom));
    } else {
      _fmController.move(fmlt.LatLng(to.latitude, to.longitude), zoom);
    }
  }

  /// «من أين»: from the trip editor's pickup field (or «اختر من الخريطة» while searching a pickup)
  void startPickupAdjust() {
    FocusScope.of(context).unfocus();
    final pickup = addressList.where((e) => e.type == 'pickup');
    final from = pickup.isNotEmpty ? pickup.first.latlng : _homePickupPoint;
    final known = pickup.isNotEmpty ? pickup.first.address.trim() : '';
    setState(() {
      _pickupAdjust = true;
      _isPickingLocation = false;
      _pickaddress = false;
      _pickupSearchController.clear();
      addAutoFill.clear();
      infoMessage = '';
      _sessionToken = null;
      _centerLocation = from;
      // the pickup's own address is already known: arriving there asks nothing
      _adjustAskedAt = from;
      _adjustAddress = known.isEmpty ? null : known;
    });
    _moveMapTo(from, 17);
    if (known.isEmpty) unawaited(_settlePickupAdjust(force: true));
  }

  /// The map stopped in pickup-adjust mode: one address for where it stopped.
  Future<void> _settlePickupAdjust({bool force = false}) async {
    if (!_pickupAdjust || !mounted) return;
    final spot = _centerLocation;
    if (_isPickingLocation) setState(() => _isPickingLocation = false);
    if (!force && _adjustAskedAt == spot) return;
    _adjustAskedAt = spot;
    setState(() {
      _adjustAddress = null;
      // the real captains around the new spot when it went more than a km
      final carsAt = _carsCenter;
      if (carsAt == null || calculateDistance(carsAt.latitude, carsAt.longitude, spot.latitude, spot.longitude) > 1000) {
        carsAround(spot);
      }
    });
    final address = await geoCoding(spot.latitude, spot.longitude);
    if (!mounted || !_pickupAdjust || _adjustAskedAt != spot) return;
    setState(() => _adjustAddress = address?.trim() ?? '');
  }

  void confirmPickupAdjust() {
    final rtl = languageDirection == 'rtl';
    final spot = _centerLocation;
    final found = _adjustAddress?.trim() ?? '';
    _pickupAdjust = false;
    _isPickingLocation = false;
    _adjustAddress = null;
    _setPickup(found.isNotEmpty ? found : (rtl ? 'نقطة محددة على الخريطة' : 'A point on the map'), spot);
  }

  void cancelPickupAdjust() {
    final pickup = addressList.where((e) => e.type == 'pickup');
    setState(() {
      _pickupAdjust = false;
      _isPickingLocation = false;
      _adjustAddress = null;
    });
    if (pickup.isNotEmpty) _moveMapTo(pickup.first.latlng, 16);
  }

  /// typing an address instead: back to the trip editor with the pickup field as a search box
  void searchPickupInstead() {
    setState(() {
      _pickupAdjust = false;
      _isPickingLocation = false;
      _adjustAddress = null;
      _pickupSearchController.clear();
      _pickaddress = true;
      _dropaddress = false;
      addAutoFill.clear();
      infoMessage = '';
      _sessionToken = null;
    });
  }

  Widget buildPickupAdjustPanel(Size media) {
    final rtl = languageDirection == 'rtl';
    final moving = _isPickingLocation;
    final address = _adjustAddress;
    final ready = !moving && address != null;
    final line = moving
        ? (rtl ? 'يحدد نقطة اللقاء…' : 'Choosing the meeting point…')
        : address == null
            ? (rtl ? 'جارٍ تحديد العنوان…' : 'Finding the address…')
            : address.isEmpty
                ? (rtl ? 'نقطة محددة على الخريطة' : 'A point on the map')
                : address;
    const ink = Color(0xFF10213F);
    const muted = Color(0xFF64748B);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + 14,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [BoxShadow(color: Color(0x2210213F), blurRadius: 14, offset: Offset(0, 4))],
              ),
              child: Text(rtl ? 'حرّك الخريطة لتحديد نقطة الانطلاق' : 'Move the map to set your pickup',
                  textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: ink, height: 1.3)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(alignment: AlignmentDirectional.centerEnd, child: MapRecenterButton(onTap: recenterMap)),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [BoxShadow(color: Color(0x2410213F), blurRadius: 24, offset: Offset(0, -6))],
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: theme.withValues(alpha: .1), shape: BoxShape.circle),
                      child: Icon(Icons.my_location_rounded, color: theme, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(rtl ? 'من أين؟' : 'Pickup', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: muted, height: 1.3)),
                        Text(line,
                            key: const ValueKey('pickup-adjust-address'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: ready ? ink : muted, height: 1.35)),
                      ]),
                    ),
                    IconButton(
                      tooltip: rtl ? 'رجوع' : 'Back',
                      onPressed: cancelPickupAdjust,
                      icon: const Icon(Icons.close_rounded),
                      color: muted,
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: const ValueKey('pickup-adjust-confirm'),
                      onPressed: ready ? confirmPickupAdjust : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme,
                        disabledBackgroundColor: theme.withValues(alpha: .35),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(rtl ? 'تأكيد نقطة الانطلاق' : 'Confirm pickup',
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: searchPickupInstead,
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: Text(rtl ? 'ابحث عن عنوان' : 'Search for an address',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
