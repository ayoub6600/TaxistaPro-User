part of '../map_page.dart';

extension _MapLocationServices on _MapsState {
  Future<void> recenterMap() async {
    if (locationAllowed == true) {
      final target =
          currentLocation is LatLng ? currentLocation as LatLng : center;
      if (mapType == 'google') {
        await _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16),
        );
      } else {
        _fmController.move(
          fmlt.LatLng(target.latitude, target.longitude),
          12,
        );
      }
      center = target;
      return;
    }

    if (serviceEnabled == true) {
      setState(() => _locationDenied = true);
      return;
    }

    await getLocationPermission();
    if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      if (mounted) setState(() => _locationDenied = true);
    }
  }

  void navigateLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    return (await frame.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void navigate() {
    ismulitipleride = false;
    if (choosenTransportType == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => BookingConfirmation()),
        (_) => false,
      );
    } else if (choosenTransportType == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DropLocation()),
      );
    }
  }

  Future<void> getLocs() async {
    if (signKey == '' || packageName == '') {
      final buildKeys = await PackageInfo.fromPlatform();
      signKey = buildKeys.buildSignature;
      packageName = buildKeys.packageName;
    }

    myBearings.clear();
    addressList.clear();
    serviceEnabled = await location.serviceEnabled();
    polyline.clear();
    pinLocationIcon = BitmapDescriptor.fromBytes(
      await getBytesFromAsset('assets/images/top-taxi.png', 80),
    );
    deliveryIcon = BitmapDescriptor.fromBytes(
      await getBytesFromAsset('assets/images/deliveryicon.png', 40),
    );
    bikeIcon = BitmapDescriptor.fromBytes(
      await getBytesFromAsset('assets/images/bike.png', 40),
    );

    permission = await geolocs.GeolocatorPlatform.instance.checkPermission();
    if (!mounted) return;

    if (permission == geolocs.LocationPermission.denied ||
        permission == geolocs.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;
      state = gettingPerm > 1 || locationAllowed == false ? '3' : '2';
      locationAllowed = false;
      _loading = false;
      setState(() {});
      fdbfun();
      return;
    }

    final lastPosition = await geolocs.Geolocator.getLastKnownPosition();
    final position = lastPosition ??
        await geolocs.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocs.LocationAccuracy.low,
        );
    if (!mounted) return;

    final locatedCenter = LatLng(position.latitude, position.longitude);
    center = locatedCenter;
    currentLocation = locatedCenter;
    _centerLocation = locatedCenter;
    _lastCenter = locatedCenter;
    locationAllowed = true;
    state = '3';
    _loading = false;
    setState(() {});

    if (positionStream == null || positionStream!.isPaused) {
      positionStreamData();
    }
    fdbfun();
  }

  Future<void> getLocationPermission() async {
    if (permission == geolocs.LocationPermission.denied ||
        permission == geolocs.LocationPermission.deniedForever) {
      if (permission != geolocs.LocationPermission.deniedForever) {
        await perm.Permission.location.request();
      }
      if (serviceEnabled == false) await location.requestService();
    } else if (serviceEnabled == false) {
      await location.requestService();
    }
    if (!mounted) return;
    setState(() => _loading = true);
    await getLocs();
  }

  void fdbfun() {
    lowerLat = center.latitude - (lat * 1.24);
    lowerLon = center.longitude - (lon * 1.24);
    greaterLat = center.latitude + (lat * 1.24);
    greaterLon = center.longitude + (lon * 1.24);
    lower = geo.encode(lowerLon, lowerLat);
    higher = geo.encode(greaterLon, greaterLat);
    fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);
  }
}
