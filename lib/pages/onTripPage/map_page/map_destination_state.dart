part of '../map_page.dart';

extension _MapDestinationState on _MapsState {
  bool get hasPickupAndDrop =>
      addressList.any((element) => element.type == 'pickup') &&
      addressList.any((element) => element.type == 'drop');

  void resetDestinationEntry() {
    addressList.removeWhere((element) => element.type == 'drop');
    _pickupSearchController.clear();
    dropAddressController.clear();
    addAutoFill.clear();
    infoMessage = '';
    _sessionToken = null;
    rideWithoutDestination = false;
    rentalRide = false;
    _pickaddress = false;
    _dropaddress = true;
    _bottom = 1;
    _isbottom = -1000;
  }

  Future<void> prepareDestinationEntry(Size media) async {
    setState(resetDestinationEntry);
    await ensurePickupForDestination();
    if (mounted) setState(() {});
  }

  Future<bool> ensurePickupForDestination() async {
    if (addressList.any((element) => element.type == 'pickup')) return true;

    final pickupLatLng =
        currentLocation is LatLng ? currentLocation as LatLng : center;
    if (pickupLatLng.latitude == 0 && pickupLatLng.longitude == 0) {
      return false;
    }

    var pickupAddress = pickupAddressConfirmation.trim();
    if (pickupAddress.isEmpty) {
      pickupAddress =
          (await geoCoding(pickupLatLng.latitude, pickupLatLng.longitude))
                  ?.trim() ??
              '';
    }
    if (pickupAddress.isEmpty) return false;

    addressList.add(
      AddressList(
        id: '1',
        type: 'pickup',
        address: pickupAddress,
        pickup: true,
        latlng: pickupLatLng,
        name: userDetails['name'],
        number: userDetails['mobile'],
      ),
    );
    pickupAddressConfirmation = pickupAddress;
    return true;
  }

  Future<void> openDropLocationPicker() async {
    addAutoFill.clear();
    final pickupReady = await ensurePickupForDestination();
    if (!mounted) return;

    if (!pickupReady) {
      setState(() {
        infoMessage = languageDirection == 'rtl'
            ? 'تعذر تحديد نقطة الانطلاق. فعّل الموقع وحاول مرة أخرى.'
            : 'Could not determine your pickup point. Enable location and try again.';
      });
      return;
    }

    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DropLocation(returnSelectionOnly: true),
      ),
    );
    if (!mounted || selected != true) return;
    final drop = addressList.where((element) => element.type == 'drop');
    if (drop.isNotEmpty) {
      dropAddressController.text = drop.first.address;
    }
    _pickaddress = false;
    _dropaddress = false;
    addAutoFill.clear();
    infoMessage = '';
    setState(() {});
  }

  Future<void> openPickupLocationPicker() async {
    final pickupReady = await ensurePickupForDestination();
    if (!mounted) return;
    if (!pickupReady) {
      setState(() {
        infoMessage = languageDirection == 'rtl'
            ? 'تعذر تحديد نقطة الانطلاق. فعّل الموقع وحاول مرة أخرى.'
            : 'Could not determine your pickup point. Enable location and try again.';
      });
      return;
    }

    final pickupIndex =
        addressList.indexWhere((element) => element.type == 'pickup');
    if (pickupIndex < 0) return;
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DropLocation(
          from: pickupIndex,
          returnSelectionOnly: true,
          selectingPickup: true,
        ),
      ),
    );
    if (!mounted || selected != true) return;
    final pickup = addressList.where((element) => element.type == 'pickup');
    if (pickup.isNotEmpty) {
      pickupAddressConfirmation = pickup.first.address;
      center = pickup.first.latlng;
    }
    _pickupSearchController.clear();
    addAutoFill.clear();
    infoMessage = '';
    _pickaddress = false;
    _dropaddress = !addressList.any((element) => element.type == 'drop');
    setState(() {});
  }

  Future<void> selectRecentDestination(
    Map<dynamic, dynamic> recent, {
    bool navigateAfterSelection = true,
  }) async {
    final coordinates = recent['latlng'];
    if (coordinates is! List || coordinates.length < 2) return;
    final destination = LatLng(
      (coordinates[0] as num).toDouble(),
      (coordinates[1] as num).toDouble(),
    );
    final address = recent['address']?.toString() ?? '';

    if (_pickaddress) {
      _setPickup(address, destination);
      return;
    }

    final pickupReady = await ensurePickupForDestination();
    if (!mounted) return;
    if (!pickupReady) {
      setState(() {
        infoMessage = languageDirection == 'rtl'
            ? 'تعذر تحديد نقطة الانطلاق. فعّل الموقع وحاول مرة أخرى.'
            : 'Could not determine your pickup point. Enable location and try again.';
      });
      return;
    }

    addressList.removeWhere((element) => element.type == 'drop');
    addressList.add(
      AddressList(
        id: '2',
        type: 'drop',
        address: address,
        pickup: false,
        latlng: destination,
      ),
    );
    polyList.clear();
    infoMessage = '';
    dropAddressController.text = address;
    _dropaddress = false;
    _pickaddress = false;
    addAutoFill.clear();
    setState(() {});
    if (navigateAfterSelection) navigateWhenRouteReady();
  }

  Future<void> selectFavoriteDestination(
    Map<dynamic, dynamic> favorite, {
    bool navigateAfterSelection = true,
  }) async {
    final latitude = _quickCoordinate(favorite['pick_lat']);
    final longitude = _quickCoordinate(favorite['pick_lng']);
    final address = favorite['pick_address']?.toString().trim() ?? '';
    if (latitude == null || longitude == null || address.isEmpty) return;

    if (_pickaddress) {
      _setPickup(address, LatLng(latitude, longitude));
      return;
    }

    final pickupReady = await ensurePickupForDestination();
    if (!mounted) return;
    if (!pickupReady) {
      setState(() {
        infoMessage = languageDirection == 'rtl'
            ? 'تعذر تحديد نقطة الانطلاق. فعّل الموقع وحاول مرة أخرى.'
            : 'Could not determine your pickup point. Enable location and try again.';
      });
      return;
    }

    _setDestination(address, LatLng(latitude, longitude));
    if (navigateAfterSelection) navigateWhenRouteReady();
  }

  Future<void> selectAutocompleteSuggestion(
    Map<dynamic, dynamic> suggestion,
  ) async {
    var latitude = _quickCoordinate(suggestion['lat']);
    var longitude = _quickCoordinate(suggestion['lon']);

    if (latitude == null || longitude == null) {
      final placeId = suggestion['place']?.toString();
      if (placeId == null || placeId.isEmpty) return;
      final resolved = await geoCodingForLatLng(placeId, _sessionToken);
      _sessionToken = null;
      if (resolved == null || !mounted) return;
      latitude = _quickCoordinate(resolved['lat']);
      longitude = _quickCoordinate(resolved['lng']);
    }
    if (latitude == null || longitude == null || !mounted) return;

    final address = (suggestion['description'] ?? suggestion['display_name'])
            ?.toString()
            .trim() ??
        '';
    if (address.isEmpty) return;
    final point = LatLng(latitude, longitude);

    if (_pickaddress) {
      _setPickup(address, point);
      return;
    }

    _setDestination(address, point);
    _rememberRecentDestination(address, point);
  }

  void _setDestination(String address, LatLng point) {
    addressList.removeWhere((element) => element.type == 'drop');
    addressList.add(
      AddressList(
        id: '2',
        type: 'drop',
        address: address,
        pickup: false,
        latlng: point,
      ),
    );
    dropAddressController.text = address;
    polyList.clear();
    addAutoFill.clear();
    infoMessage = '';
    _pickaddress = false;
    _dropaddress = false;
    setState(() {});
  }

  void _setPickup(String address, LatLng point) {
    final pickups = addressList.where((element) => element.type == 'pickup');
    if (pickups.isEmpty) {
      addressList.add(
        AddressList(
          id: '1',
          type: 'pickup',
          pickup: true,
          address: address,
          latlng: point,
          name: userDetails['name'],
          number: userDetails['mobile'],
        ),
      );
    } else {
      pickups.first
        ..address = address
        ..latlng = point;
    }
    pickupAddressConfirmation = address;
    center = point;
    polyList.clear();
    _pickupSearchController.clear();
    pickupAddressController.clear();
    addAutoFill.clear();
    infoMessage = '';
    _pickaddress = false;
    _dropaddress = !addressList.any((element) => element.type == 'drop');
    setState(() {});
  }

  void _rememberRecentDestination(String address, LatLng point) {
    recentSearchesList.removeWhere(
      (item) => item is Map && item['address']?.toString() == address,
    );
    recentSearchesList.add({
      'address': address,
      'id': '2',
      'type': 'drop',
      'pickup': false,
      'latlng': [point.latitude, point.longitude],
    });
    while (recentSearchesList.length > 4) {
      recentSearchesList.removeAt(0);
    }
    pref.setString('recentsearch', jsonEncode(recentSearchesList));
  }

  Map<dynamic, dynamic>? quickFavorite(String addressName) {
    for (final value in favAddress) {
      if (value is Map &&
          value['address_name']?.toString().toLowerCase() ==
              addressName.toLowerCase()) {
        return value;
      }
    }
    return null;
  }

  Future<void> useQuickFavorite(
    Size media,
    String addressName,
  ) async {
    final favorite = quickFavorite(addressName);
    if (favorite == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DropLocation(
            from: 'favourite',
            favName: addressName,
          ),
        ),
      );
      if (mounted) setState(() {});
      return;
    }

    final pickupReady = await ensurePickupForDestination();
    if (!mounted) return;
    if (!pickupReady) {
      setState(() {
        infoMessage = languageDirection == 'rtl'
            ? 'تعذر تحديد نقطة الانطلاق. فعّل الموقع وحاول مرة أخرى.'
            : 'Could not determine your pickup point. Enable location and try again.';
      });
      return;
    }

    final latitude = _quickCoordinate(favorite['pick_lat']);
    final longitude = _quickCoordinate(favorite['pick_lng']);
    final address = favorite['pick_address']?.toString().trim() ?? '';
    if (latitude == null || longitude == null || address.isEmpty) {
      await prepareDestinationEntry(media);
      return;
    }

    addressList.removeWhere((element) => element.type == 'drop');
    addressList.add(
      AddressList(
        id: '2',
        type: 'drop',
        address: address,
        pickup: false,
        latlng: LatLng(latitude, longitude),
      ),
    );
    polyList.clear();
    infoMessage = '';
    setState(() {});
    navigateWhenRouteReady();
  }

  double? _quickCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void navigateWhenRouteReady() {
    if (!hasPickupAndDrop) return;
    polyList.clear();
    navigate();
  }
}
