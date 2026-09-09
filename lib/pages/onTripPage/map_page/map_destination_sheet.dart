part of '../map_page.dart';

extension _MapDestinationSheet on _MapsState {
  Widget buildDestinationEditor(Size media) {
    if (_bottom != 1) return const SizedBox.shrink();

    final rtl = languageDirection == 'rtl';
    final pickup = addressList.where((element) => element.type == 'pickup');
    final pickupAddress = pickup.isNotEmpty ? pickup.first.address : '';

    return TripSelectionOverlay(
      rtl: rtl,
      pickupAddress: pickupAddress,
      pickupSearchController: _pickupSearchController,
      destinationController: dropAddressController,
      pickupEditing: _pickaddress,
      destinationEditing: _dropaddress,
      infoMessage: infoMessage,
      searchResults: buildDestinationSearchResults(media),
      places: _tripSelectionPlaces(),
      canContinue: hasPickupAndDrop,
      onBack: _closeDestinationEditor,
      onPickupTap: _handlePickupFieldTap,
      onPickupChanged: _handleLocationQuery,
      onClearPickup: () {
        setState(() {
          _pickupSearchController.clear();
          addAutoFill.clear();
          infoMessage = '';
          _sessionToken = null;
        });
      },
      onDestinationTap: _handleDestinationFieldTap,
      onDestinationChanged: _handleLocationQuery,
      onClearDestination: () {
        setState(() {
          dropAddressController.clear();
          addressList.removeWhere((element) => element.type == 'drop');
          addAutoFill.clear();
          infoMessage = '';
          _sessionToken = null;
          _dropaddress = true;
        });
      },
      onChooseFromMap:
          _pickaddress ? openPickupLocationPicker : openDropLocationPicker,
      onContinue: () {
        FocusScope.of(context).unfocus();
        navigateWhenRouteReady();
      },
    );
  }

  void _closeDestinationEditor() {
    FocusScope.of(context).unfocus();
    setState(() {
      _pickupSearchController.clear();
      _bottom = 0;
      isOutStation = false;
      addAutoFill.clear();
      infoMessage = '';
      _sessionToken = null;
      _pickaddress = false;
      _dropaddress = false;
      _lastPickupFieldTapAt = null;
      _lastDestinationFieldTapAt = null;

      final modules = userDetails['enable_modules_for_applications'];
      if (modules == 'delivery') {
        choosenTransportType = 1;
        transportType = 'delivery';
      } else {
        choosenTransportType = 0;
        transportType = 'taxi';
      }
    });
  }

  void _handlePickupFieldTap() {
    final now = DateTime.now();
    final previousTap = _lastPickupFieldTapAt;
    final isDoubleTap = previousTap != null &&
        now.difference(previousTap) <= const Duration(milliseconds: 360);
    _lastPickupFieldTapAt = isDoubleTap ? null : now;

    if (isDoubleTap) {
      FocusScope.of(context).unfocus();
      openPickupLocationPicker();
      return;
    }

    if (_pickaddress) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pickupSearchController.clear();
      _pickaddress = true;
      _dropaddress = false;
      addAutoFill.clear();
      infoMessage = '';
      _sessionToken = null;
    });
  }

  void _handleDestinationFieldTap() {
    final now = DateTime.now();
    final previousTap = _lastDestinationFieldTapAt;
    final isDoubleTap = previousTap != null &&
        now.difference(previousTap) <= const Duration(milliseconds: 360);
    _lastDestinationFieldTapAt = isDoubleTap ? null : now;

    if (isDoubleTap) {
      FocusScope.of(context).unfocus();
      openDropLocationPicker();
      return;
    }

    if (_dropaddress && !_pickaddress) return;
    setState(() {
      _pickupSearchController.clear();
      _pickaddress = false;
      _dropaddress = true;
      addAutoFill.clear();
      infoMessage = '';
      _sessionToken = null;
    });
  }

  void _handleLocationQuery(String value) {
    if (!_pickaddress) {
      setState(() {
        addressList.removeWhere((element) => element.type == 'drop');
      });
    }
    if (value.isEmpty) _sessionToken = null;

    _debouncer.run(() async {
      final query = value.trim();
      final activeController =
          _pickaddress ? _pickupSearchController : dropAddressController;
      if (!mounted || activeController.text.trim() != query) return;

      if (query.isEmpty) {
        setState(() {
          addAutoFill.clear();
          infoMessage = '';
        });
        return;
      }

      if (query.length < 4) {
        setState(() {
          addAutoFill.clear();
          infoMessage =
              languages[choosenLanguage]['text_min4_letters']?.toString() ??
                  (languageDirection == 'rtl'
                      ? 'اكتب 4 أحرف على الأقل'
                      : 'Enter at least 4 characters');
        });
        return;
      }

      final normalized = query.toLowerCase();
      final storedMatches = storedAutoAddress.where((element) {
        final description =
            element['description']?.toString().toLowerCase() ?? '';
        final displayName =
            element['display_name']?.toString().toLowerCase() ?? '';
        return description.contains(normalized) ||
            displayName.contains(normalized);
      }).toList();

      if (storedMatches.isNotEmpty) {
        setState(() {
          addAutoFill
            ..clear()
            ..addAll(storedMatches);
          infoMessage =
              languages[choosenLanguage]['text_search_results']?.toString() ??
                  '';
        });
        return;
      }

      setState(() {
        infoMessage =
            languages[choosenLanguage]['text_searching']?.toString() ?? '';
      });
      _sessionToken ??= const Uuid().v4();
      await getAutocomplete(
        query,
        _sessionToken,
        center.latitude,
        center.longitude,
      );
      if (!mounted || activeController.text.trim() != query) return;

      setState(() {
        infoMessage = addAutoFill.isEmpty
            ? languages[choosenLanguage]['text_search_no_results']
                    ?.toString() ??
                ''
            : languages[choosenLanguage]['text_search_results']?.toString() ??
                '';
      });
    });
  }

  List<TripSelectionPlaceData> _tripSelectionPlaces() {
    final places = <TripSelectionPlaceData>[];
    final seenAddresses = <String>{};

    for (final favorite in favAddress.reversed) {
      if (favorite is! Map) continue;
      final address = favorite['pick_address']?.toString().trim() ?? '';
      if (address.isEmpty || !seenAddresses.add(address.toLowerCase()))
        continue;
      final name = favorite['address_name']?.toString().trim() ?? '';
      places.add(
        TripSelectionPlaceData(
          title: name.isEmpty ? address : _localizedPlaceName(name),
          subtitle: name.isEmpty ? '' : address,
          icon: _placeIcon(name),
          accent: _placeAccent(name),
          onTap: () => selectFavoriteDestination(
            favorite,
            navigateAfterSelection: false,
          ),
        ),
      );
      if (places.length == 4) return places;
    }

    for (final recent in recentSearchesList.reversed) {
      if (recent is! Map) continue;
      final address = recent['address']?.toString().trim() ?? '';
      if (address.isEmpty || !seenAddresses.add(address.toLowerCase()))
        continue;
      final parts = address.split(',');
      places.add(
        TripSelectionPlaceData(
          title: parts.first.trim(),
          subtitle: parts.length > 1 ? parts.skip(1).join(',').trim() : '',
          icon: Icons.history_rounded,
          accent: const Color(0xFF2381E9),
          onTap: () => selectRecentDestination(
            recent,
            navigateAfterSelection: false,
          ),
        ),
      );
      if (places.length == 4) break;
    }
    return places;
  }

  String _localizedPlaceName(String name) {
    if (languageDirection != 'rtl') return name;
    return switch (name.toLowerCase()) {
      'home' => 'المنزل',
      'work' => 'العمل',
      _ => name,
    };
  }

  IconData _placeIcon(String name) {
    return switch (name.toLowerCase()) {
      'home' => Icons.home_rounded,
      'work' => Icons.work_rounded,
      _ => Icons.star_rounded,
    };
  }

  Color _placeAccent(String name) {
    return switch (name.toLowerCase()) {
      'home' => const Color(0xFF0873FF),
      'work' => const Color(0xFF6E55C8),
      _ => const Color(0xFF22B879),
    };
  }
}
