part of '../drop_loc_select.dart';

mixin _DropLocationView on State<DropLocation>, _DropLocationController {
  Widget buildDropLocation(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        if (_getDropDetails) {
          setState(() {
            _getDropDetails = false;
          });
        }
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: page,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: media.height * 1,
                        width: media.width * 1,
                        child: (_state == '3')
                            ? (mapType == 'google')
                                ? GoogleMap(
                                    onMapCreated: _onMapCreated,
                                    initialCameraPosition: CameraPosition(
                                      target: _center,
                                      zoom: 14.0,
                                    ),
                                    onCameraMove: (CameraPosition position) {
                                      _centerLocation = position.target;
                                      _center = position.target;
                                      if (!_isMapMoving && mounted) {
                                        setState(() {
                                          _isMapMoving = true;
                                          if (!useMyAddress) {
                                            dropAddressConfirmation = '';
                                          }
                                        });
                                      }
                                    },
                                    onCameraIdle: _settleMapSelection,
                                    minMaxZoomPreference:
                                        const MinMaxZoomPreference(8.0, 20.0),
                                    myLocationButtonEnabled: false,
                                    buildingsEnabled: false,
                                    zoomControlsEnabled: false,
                                    myLocationEnabled: true,
                                  )
                                : fm.FlutterMap(
                                    mapController: _fmController,
                                    options: fm.MapOptions(
                                        onMapEvent: (event) {
                                          _centerLocation = LatLng(
                                            event.camera.center.latitude,
                                            event.camera.center.longitude,
                                          );
                                          _center = _centerLocation;

                                          final source = event.source;
                                          final movementStarted = source ==
                                                  fm.MapEventSource.dragStart ||
                                              source ==
                                                  fm.MapEventSource
                                                      .multiFingerGestureStart;
                                          final movementEnded = source ==
                                                  fm.MapEventSource.dragEnd ||
                                              source ==
                                                  fm.MapEventSource
                                                      .multiFingerEnd;
                                          if (movementStarted &&
                                              !_isMapMoving &&
                                              mounted) {
                                            setState(() {
                                              _isMapMoving = true;
                                              if (!useMyAddress) {
                                                dropAddressConfirmation = '';
                                              }
                                            });
                                          }
                                          if (movementEnded) {
                                            _settleMapSelection();
                                          }
                                          if (source ==
                                                  fm.MapEventSource
                                                      .nonRotatedSizeChange &&
                                              dropAddressConfirmation.isEmpty) {
                                            _settleMapSelection();
                                          }
                                        },
                                        initialCenter: fmlt.LatLng(
                                            _center.latitude,
                                            _center.longitude),
                                        initialZoom: 16,
                                        onTap: (P, L) {
                                          setState(() {});
                                        }),
                                    children: [
                                      fm.TileLayer(
                                        // minZoom: 10,
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.Ayoub.Usertaxista',
                                      ),
                                      const fm.RichAttributionWidget(
                                        attributions: [],
                                      ),
                                    ],
                                  )
                            : (_state == '2')
                                ? Container(
                                    height: media.height * 1,
                                    width: media.width * 1,
                                    alignment: Alignment.center,
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.6,
                                      height: media.width * 0.3,
                                      decoration: BoxDecoration(
                                          color: page,
                                          boxShadow: [
                                            BoxShadow(
                                                blurRadius: 5,
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                spreadRadius: 2)
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_loc_permission'],
                                            style: GoogleFonts.notoSans(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  _state = '';
                                                });
                                                await location
                                                    .requestPermission();
                                                getLocs();
                                              },
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_ok'],
                                                style: GoogleFonts.notoSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        media.width * twenty,
                                                    color: buttonColor),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),
                      ),
                      if (_state == '3' && !_getDropDetails)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: const Alignment(0, -.12),
                              child: _TaxistaCenterPin(
                                moving: _isMapMoving,
                                selectingPickup:
                                    widget.selectingPickup || widget.from == 0,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                          bottom: 0 + MediaQuery.of(context).viewInsets.bottom,
                          child: (_getDropDetails == false)
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: _TaxistaMapControl(
                                        icon: Icons.my_location_rounded,
                                        semanticLabel:
                                            languageDirection == 'rtl'
                                                ? 'موقعي الحالي'
                                                : 'Current location',
                                        onTap: () async {
                                          if (locationAllowed == true) {
                                            final target =
                                                currentLocation ?? center;
                                            if (mapType == 'google') {
                                              _controller?.animateCamera(
                                                  CameraUpdate.newLatLngZoom(
                                                      target, 18.0));
                                            } else {
                                              _fmController.move(
                                                fmlt.LatLng(target.latitude,
                                                    target.longitude),
                                                18,
                                              );
                                            }
                                            center = target;
                                            _centerLocation = target;
                                          } else {
                                            if (serviceEnabled == true) {
                                              setState(() {
                                                _locationDenied = true;
                                              });
                                            } else {
                                              // await location.requestService();
                                              await geolocs.Geolocator
                                                  .getCurrentPosition(
                                                      desiredAccuracy: geolocs
                                                          .LocationAccuracy
                                                          .low);
                                              if (await geolocs
                                                  .GeolocatorPlatform.instance
                                                  .isLocationServiceEnabled()) {
                                                setState(() {
                                                  _locationDenied = true;
                                                });
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      width: media.width,
                                      padding: EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        14 +
                                            MediaQuery.paddingOf(context)
                                                .bottom,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(30),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x260C274D),
                                            blurRadius: 34,
                                            offset: Offset(0, -10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD7DEE8),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            (widget.selectingPickup ||
                                                    widget.from == 0)
                                                ? (languageDirection == 'rtl'
                                                    ? 'حدّد موقع الانطلاق'
                                                    : 'Choose the pickup location')
                                                : (languageDirection == 'rtl'
                                                    ? 'ثبّت وجهتك على الخريطة'
                                                    : 'Pin your destination on the map'),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.notoSans(
                                              fontSize: 21.sp,
                                              fontWeight: FontWeight.w800,
                                              color: _pickerInk,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            (widget.selectingPickup ||
                                                    widget.from == 0)
                                                ? (languageDirection == 'rtl'
                                                    ? 'حرّك الخريطة وحدد المكان الذي تريد أن يصل إليه السائق'
                                                    : 'Move the map and choose where the driver should arrive')
                                                : (languageDirection == 'rtl'
                                                    ? 'حرّك الخريطة حتى يكون المؤشر فوق المكان المطلوب'
                                                    : 'Move the map until the pin is over the requested place'),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.notoSans(
                                              fontSize: 12.sp,
                                              height: 1.45,
                                              fontWeight: FontWeight.w500,
                                              color: _pickerMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          _TaxistaSelectedAddress(
                                            address: dropAddressConfirmation,
                                            rtl: languageDirection == 'rtl',
                                            selectingPickup:
                                                widget.selectingPickup ||
                                                    widget.from == 0,
                                            canFavorite: dropAddressConfirmation
                                                    .isNotEmpty &&
                                                favAddress.length < 4 &&
                                                widget.from != 'favourite',
                                            isFavorite: favAddress.any(
                                              (element) =>
                                                  element['pick_address'] ==
                                                  dropAddressConfirmation,
                                            ),
                                            onFavorite: () {
                                              if (dropAddressConfirmation
                                                  .isEmpty) {
                                                return;
                                              }
                                              if (favAddress
                                                  .where((element) =>
                                                      element['pick_address'] ==
                                                      dropAddressConfirmation)
                                                  .isNotEmpty) {
                                                return;
                                              }
                                              setState(() {
                                                favSelectedAddress =
                                                    dropAddressConfirmation;
                                                favLat = _center.latitude;
                                                favLng = _center.longitude;
                                                favAddressAdd = true;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          Button(
                                              onTap: () async {
                                                if (dropAddressConfirmation !=
                                                    '') {
                                                  //remove in envato
                                                  if (choosenTransportType ==
                                                          0 &&
                                                      widget.from == null) {
                                                    debugPrint("---------->1");

                                                    if (addressList
                                                        .where((element) =>
                                                            element.type ==
                                                            'drop')
                                                        .isEmpty) {
                                                      addressList.add(AddressList(
                                                          id: (addressList
                                                                      .length +
                                                                  1)
                                                              .toString(),
                                                          type: 'drop',
                                                          address:
                                                              dropAddressConfirmation,
                                                          latlng: _center,
                                                          pickup: false));
                                                    } else {
                                                      debugPrint(
                                                          "---------->2");
                                                      addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .address =
                                                          dropAddressConfirmation;
                                                      addressList
                                                          .firstWhere(
                                                              (element) =>
                                                                  element
                                                                      .type ==
                                                                  'drop')
                                                          .latlng = _center;
                                                    }
                                                  } else if (choosenTransportType ==
                                                          0 &&
                                                      widget.from != null) {
                                                    debugPrint("---------->3");
                                                    // setState(() {
                                                    //  // polyline.clear();
                                                    //   // polyline.add(Polyline(
                                                    //   //   polylineId:
                                                    //   //       const PolylineId(
                                                    //   //           "unique_route"), // Ensure the same ID is used
                                                    //   //   points: [
                                                    //   //     LatLng(
                                                    //   //         addressList[widget
                                                    //   //                 .from]
                                                    //   //             .latlng
                                                    //   //             .latitude,
                                                    //   //         addressList[widget
                                                    //   //                 .from]
                                                    //   //             .latlng
                                                    //   //             .longitude),
                                                    //   //     LatLng(
                                                    //   //         _center.latitude,
                                                    //   //         _center
                                                    //   //             .longitude),
                                                    //   //   ],
                                                    //   //   color: Colors.red,
                                                    //   //   width: 5,
                                                    //   // ));
                                                    // });

                                                    if (widget.from != null &&
                                                        widget.from !=
                                                            'add stop' &&
                                                        widget.from !=
                                                            'favourite') {
                                                      addressList[widget.from]
                                                          .name = '';
                                                      addressList[widget.from]
                                                          .number = '';
                                                      addressList[widget.from]
                                                              .address =
                                                          dropAddressConfirmation;
                                                      addressList[widget.from]
                                                          .latlng = _center;
                                                      addressList[widget.from]
                                                          .instructions = null;
                                                    } else if (widget.from ==
                                                        'add stop') {
                                                      var address = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .address;
                                                      var type = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .type;
                                                      var name = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .name;
                                                      var number = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .number;
                                                      var instruction =
                                                          addressList[addressList
                                                                      .length -
                                                                  1]
                                                              .instructions;
                                                      var pickup = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .pickup;
                                                      var id = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .id;
                                                      var latlng = addressList[
                                                              addressList
                                                                      .length -
                                                                  1]
                                                          .latlng;

                                                      addressList[addressList
                                                                      .length -
                                                                  1]
                                                              .id =
                                                          (addressList.length +
                                                                  1)
                                                              .toString();
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .type = 'drop';
                                                      addressList[addressList
                                                                      .length -
                                                                  1]
                                                              .address =
                                                          dropAddressConfirmation;
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .latlng = _center;
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .name = '';
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .number = '';
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .instructions = null;
                                                      addressList[addressList
                                                                  .length -
                                                              1]
                                                          .pickup = false;

                                                      addressList.add(
                                                          AddressList(
                                                              id: id,
                                                              type: type,
                                                              address: address,
                                                              latlng: latlng,
                                                              name: name,
                                                              number: number,
                                                              instructions:
                                                                  instruction,
                                                              pickup: pickup));
                                                    } else if (widget.from ==
                                                        'favourite') {
                                                      setState(() {
                                                        _isLoading = true;
                                                        favSelectedAddress =
                                                            dropAddressConfirmation;
                                                        favLat =
                                                            _center.latitude;
                                                        favLng =
                                                            _center.longitude;
                                                      });

                                                      await addFavLocation(
                                                          favLat,
                                                          favLng,
                                                          favSelectedAddress,
                                                          widget.favName);
                                                      valueNotifierHome
                                                          .incrementNotifier();
                                                    }
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    Navigator.pop(
                                                        context, true);
                                                  } else if (choosenTransportType ==
                                                      1) {
                                                    if (widget.from == null) {
                                                      debugPrint(
                                                          "---------->4");
                                                      if ((addressList
                                                          .where((element) =>
                                                              element.id == '2')
                                                          .isEmpty)) {
                                                        addressList.add(AddressList(
                                                            id: (addressList
                                                                        .length +
                                                                    1)
                                                                .toString(),
                                                            type: 'drop',
                                                            address:
                                                                dropAddressConfirmation,
                                                            latlng: _center,
                                                            instructions: null,
                                                            pickup: false));
                                                      } else {
                                                        debugPrint(
                                                            "---------->5");
                                                        addressList
                                                                .firstWhere(
                                                                    (element) =>
                                                                        element
                                                                            .id ==
                                                                        '2')
                                                                .address =
                                                            dropAddressConfirmation;
                                                        addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .id ==
                                                                    '2')
                                                            .latlng = _center;
                                                      }
                                                    }
                                                    debugPrint("---------->6");
                                                    if (recentSearchesList
                                                            .length >
                                                        3) {
                                                      recentSearchesList
                                                          .removeAt(0);
                                                    }

                                                    if (recentSearchesList.any(
                                                        (mapTested) =>
                                                            mapTested[
                                                                'address'] ==
                                                            addressList[1]
                                                                .address
                                                                .toString())) {
                                                    } else {
                                                      debugPrint(
                                                          "---------->7");
                                                      recentSearchesList.add({
                                                        'address':
                                                            addressList[1]
                                                                .address,
                                                        'id': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .id,
                                                        'type': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .type,
                                                        'pickup': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .pickup,
                                                        'latlng': [
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .latitude,
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .longitude,
                                                        ]
                                                      });
                                                      pref.setString(
                                                          'recentsearch',
                                                          jsonEncode(
                                                              recentSearchesList));
                                                    }
                                                    setState(() {
                                                      _getDropDetails = true;
                                                    });
                                                  }
                                                  if (addressList.length >= 2 &&
                                                      choosenTransportType ==
                                                          0 &&
                                                      widget.from == null) {
                                                    ismulitipleride = false;

                                                    if (recentSearchesList
                                                            .length >
                                                        3) {
                                                      debugPrint(
                                                          "---------->9");
                                                      recentSearchesList
                                                          .removeAt(0);
                                                    }

                                                    if (recentSearchesList.any(
                                                        (mapTested) =>
                                                            mapTested[
                                                                'address'] ==
                                                            addressList[1]
                                                                .address
                                                                .toString())) {
                                                    } else {
                                                      polyline.clear();
                                                      debugPrint(
                                                          "---------->10");
                                                      recentSearchesList.add({
                                                        'address':
                                                            addressList[1]
                                                                .address,
                                                        'id': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .id,
                                                        'type': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .type,
                                                        'pickup': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .pickup,
                                                        'latlng': [
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .latitude,
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .longitude
                                                        ],
                                                      });
                                                      pref.setString(
                                                          'recentsearch',
                                                          jsonEncode(
                                                                  recentSearchesList)
                                                              .toString());
                                                    }
                                                    if (widget
                                                        .returnSelectionOnly) {
                                                      if (context.mounted) {
                                                        Navigator.pop(
                                                            context, true);
                                                      }
                                                      return;
                                                    }
                                                    var val = await Navigator
                                                        .pushReplacement(
                                                      // ignore: use_build_context_synchronously
                                                      context,
                                                      smoothPageRoute(
                                                        builder: (_) =>
                                                            BookingConfirmation(),
                                                      ),
                                                    );
                                                    if (val == true) {
                                                      setState(() {});
                                                    }
                                                  }
                                                  if (addressList.length >= 2 &&
                                                      choosenTransportType ==
                                                          2 &&
                                                      widget.from == null) {
                                                    debugPrint("---------->12");
                                                    ismulitipleride = false;

                                                    if (recentSearchesList
                                                            .length >=
                                                        3) {
                                                      recentSearchesList
                                                          .removeAt(0);
                                                    }

                                                    if (recentSearchesList.any(
                                                        (mapTested) =>
                                                            mapTested[
                                                                'address'] ==
                                                            addressList[1]
                                                                .address
                                                                .toString())) {
                                                    } else {
                                                      debugPrint(
                                                          "---------->13");
                                                      recentSearchesList.add({
                                                        'address':
                                                            addressList[1]
                                                                .address,
                                                        'id': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .id,
                                                        'type': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .type,
                                                        'pickup': addressList
                                                            .firstWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop')
                                                            .pickup,
                                                        'latlng': [
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .latitude,
                                                          addressList
                                                              .firstWhere(
                                                                  (element) =>
                                                                      element
                                                                          .type ==
                                                                      'drop')
                                                              .latlng
                                                              .longitude
                                                        ]
                                                      });
                                                      pref.setString(
                                                          'recentsearch',
                                                          jsonEncode(
                                                                  recentSearchesList)
                                                              .toString());
                                                    }
                                                    // ignore: use_build_context_synchronously
                                                    var val = await Navigator
                                                        .pushReplacement(
                                                      // ignore: use_build_context_synchronously
                                                      context,
                                                      smoothPageRoute(
                                                        builder: (_) =>
                                                            BookingConfirmation(),
                                                      ),
                                                    );
                                                    if (val) {
                                                      setState(() {});
                                                    }
                                                  }
                                                }
                                              },
                                              text: (widget.selectingPickup ||
                                                      widget.from == 0)
                                                  ? (languageDirection == 'rtl'
                                                      ? 'تأكيد موقع الانطلاق'
                                                      : 'Confirm pickup')
                                                  : languages[choosenLanguage]
                                                      ['text_confirm'],
                                              width: double.infinity,
                                              height: 56.0,
                                              backgroundcolor: _pickerBlue,
                                              fontweight: FontWeight.w800)
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  height: media.height * 1,
                                  color: Colors.transparent.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        color: page,
                                        width: media.width * 1,
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: media.width * 0.9,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    (widget.from.toString() !=
                                                            '1')
                                                        ? languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_give_buyerdata']
                                                        : languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_give_userdata'],
                                                    style: GoogleFonts.notoSans(
                                                        color: textColor,
                                                        fontSize: media.width *
                                                            sixteen,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  InkWell(
                                                      onTap: () async {
                                                        var nav = await Navigator
                                                            .push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const PickContact(
                                                                              from: '2',
                                                                            )));
                                                        if (nav) {
                                                          setState(() {
                                                            buyerName.text =
                                                                pickedName;
                                                            buyerNumber.text =
                                                                pickedNumber;
                                                          });
                                                        }
                                                      },
                                                      child: Icon(
                                                          Icons
                                                              .contact_page_rounded,
                                                          color: textColor))
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  useMyDetails = !useMyDetails;
                                                  if (useMyDetails == true) {
                                                    buyerName.text =
                                                        userDetails['name']
                                                            .toString();
                                                    buyerNumber.text =
                                                        userDetails['mobile']
                                                            .toString();
                                                  } else {
                                                    buyerName.text = '';
                                                    buyerNumber.text = '';
                                                  }
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Container(
                                                    alignment: Alignment.center,
                                                    height: media.width * 0.05,
                                                    width: media.width * 0.05,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: textColor)),
                                                    child: useMyDetails
                                                        ? Icon(
                                                            Icons.done,
                                                            size: media.width *
                                                                0.04,
                                                            color: textColor,
                                                          )
                                                        : Container(),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.025,
                                                  ),
                                                  MyText(
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_use_my_name_number'],
                                                      size:
                                                          media.width * twelve)
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  media.width * 0.03,
                                                  (languageDirection == 'rtl')
                                                      ? media.width * 0.04
                                                      : 0,
                                                  media.width * 0.03,
                                                  media.width * 0.01),
                                              height: media.width * 0.1,
                                              width: media.width * 0.9,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          media.width * 0.02),
                                                  color: page),
                                              child: TextField(
                                                onChanged: (val) {
                                                  setState(() {});
                                                },
                                                controller: buyerName,
                                                readOnly: (useMyDetails)
                                                    ? true
                                                    : false,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText:
                                                      languages[choosenLanguage]
                                                          ['text_name'],
                                                  hintStyle:
                                                      GoogleFonts.notoSans(
                                                          color: textColor
                                                              .withOpacity(0.3),
                                                          fontSize:
                                                              media.width *
                                                                  twelve),
                                                ),
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                style: GoogleFonts.notoSans(
                                                    color: textColor,
                                                    fontSize:
                                                        media.width * twelve),
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  media.width * 0.03,
                                                  (languageDirection == 'rtl')
                                                      ? media.width * 0.04
                                                      : 0,
                                                  media.width * 0.03,
                                                  media.width * 0.01),
                                              height: media.width * 0.1,
                                              width: media.width * 0.9,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          media.width * 0.02),
                                                  color: page),
                                              child: TextField(
                                                onChanged: (val) {
                                                  setState(() {});
                                                },
                                                controller: buyerNumber,
                                                keyboardType:
                                                    TextInputType.number,
                                                readOnly: (useMyDetails)
                                                    ? true
                                                    : false,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  counterText: '',
                                                  hintText:
                                                      languages[choosenLanguage]
                                                          ['text_givenumber'],
                                                  hintStyle:
                                                      GoogleFonts.notoSans(
                                                          color: textColor
                                                              .withOpacity(0.3),
                                                          fontSize:
                                                              media.width *
                                                                  twelve),
                                                ),
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                style: GoogleFonts.notoSans(
                                                    color: textColor,
                                                    fontSize:
                                                        media.width * twelve),
                                                maxLength: 20,
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  media.width * 0.03,
                                                  (languageDirection == 'rtl')
                                                      ? media.width * 0.04
                                                      : 0,
                                                  media.width * 0.03,
                                                  media.width * 0.01),
                                              // height: media.width * 0.1,
                                              width: media.width * 0.9,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          media.width * 0.02),
                                                  color: page),
                                              child: TextField(
                                                controller: instructions,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  counterText: '',
                                                  hintText:
                                                      languages[choosenLanguage]
                                                          ['text_instructions'],
                                                  hintStyle:
                                                      GoogleFonts.notoSans(
                                                          color: textColor
                                                              .withOpacity(0.3),
                                                          fontSize:
                                                              media.width *
                                                                  twelve),
                                                ),
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                style: GoogleFonts.notoSans(
                                                    color: textColor,
                                                    fontSize:
                                                        media.width * twelve),
                                                maxLines: 4,
                                                minLines: 2,
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.03,
                                            ),
                                            Button(
                                              onTap: () async {
                                                if (widget.from != null &&
                                                    widget.from != 'add stop') {
                                                  addressList[widget.from]
                                                      .name = buyerName.text;
                                                  addressList[widget.from]
                                                          .number =
                                                      buyerNumber.text;
                                                  addressList[widget.from]
                                                          .address =
                                                      dropAddressConfirmation;
                                                  addressList[widget.from]
                                                      .latlng = _center;
                                                  addressList[widget.from]
                                                          .instructions =
                                                      (instructions
                                                              .text.isNotEmpty)
                                                          ? instructions.text
                                                          : null;
                                                } else if (widget.from ==
                                                        'add stop' &&
                                                    buyerName.text.isNotEmpty &&
                                                    buyerNumber
                                                        .text.isNotEmpty) {
                                                  var address = addressList[
                                                          addressList.length -
                                                              1]
                                                      .address;
                                                  var type = addressList[
                                                          addressList.length -
                                                              1]
                                                      .type;
                                                  var name = addressList[
                                                          addressList.length -
                                                              1]
                                                      .name;
                                                  var number = addressList[
                                                          addressList.length -
                                                              1]
                                                      .number;
                                                  var instruction = addressList[
                                                          addressList.length -
                                                              1]
                                                      .instructions;
                                                  var pickup = addressList[
                                                          addressList.length -
                                                              1]
                                                      .pickup;
                                                  var id = addressList[
                                                          addressList.length -
                                                              1]
                                                      .id;
                                                  var latlng = addressList[
                                                          addressList.length -
                                                              1]
                                                      .latlng;

                                                  addressList[addressList
                                                                  .length -
                                                              1]
                                                          .id =
                                                      (addressList.length + 1)
                                                          .toString();
                                                  addressList[
                                                          addressList.length -
                                                              1]
                                                      .type = 'drop';
                                                  addressList[addressList
                                                                  .length -
                                                              1]
                                                          .address =
                                                      dropAddressConfirmation;
                                                  addressList[
                                                          addressList.length -
                                                              1]
                                                      .latlng = _center;
                                                  addressList[
                                                          addressList.length -
                                                              1]
                                                      .name = buyerName.text;
                                                  addressList[addressList
                                                                  .length -
                                                              1]
                                                          .number =
                                                      buyerNumber.text;
                                                  addressList[addressList
                                                                  .length -
                                                              1]
                                                          .instructions =
                                                      (instructions
                                                              .text.isNotEmpty)
                                                          ? instructions.text
                                                          : null;
                                                  addressList[
                                                          addressList.length -
                                                              1]
                                                      .pickup = false;

                                                  addressList.add(AddressList(
                                                      id: id,
                                                      type: type,
                                                      address: address,
                                                      latlng: latlng,
                                                      name: name,
                                                      number: number,
                                                      instructions: instruction,
                                                      pickup: pickup));
                                                } else if (widget.from ==
                                                    null) {
                                                  if (buyerName
                                                          .text.isNotEmpty &&
                                                      buyerNumber
                                                          .text.isNotEmpty) {
                                                    addressList
                                                            .firstWhere(
                                                                (e) =>
                                                                    e.type ==
                                                                    'pickup')
                                                            .name =
                                                        userDetails['name'];
                                                    addressList
                                                            .firstWhere(
                                                                (e) =>
                                                                    e.type ==
                                                                    'pickup')
                                                            .number =
                                                        userDetails['mobile'];
                                                    addressList
                                                        .firstWhere((e) =>
                                                            e.type == 'drop')
                                                        .name = buyerName.text;
                                                    addressList
                                                            .firstWhere(
                                                                (e) =>
                                                                    e.type ==
                                                                    'drop')
                                                            .number =
                                                        buyerNumber.text;
                                                    addressList
                                                            .firstWhere(
                                                                (e) =>
                                                                    e.type ==
                                                                    'drop')
                                                            .instructions =
                                                        (instructions.text
                                                                .isNotEmpty)
                                                            ? instructions.text
                                                            : null;
                                                  }
                                                }

                                                if (addressList.length >= 2 &&
                                                    buyerName.text.isNotEmpty &&
                                                    buyerNumber
                                                        .text.isNotEmpty &&
                                                    widget.from == null) {
                                                  ismulitipleride = false;

                                                  Navigator.pushReplacement(
                                                    context,
                                                    smoothPageRoute(
                                                      builder: (_) =>
                                                          BookingConfirmation(),
                                                    ),
                                                  );
                                                } else if (addressList.length >=
                                                        2 &&
                                                    buyerName.text.isNotEmpty &&
                                                    buyerNumber
                                                        .text.isNotEmpty &&
                                                    widget.from != null) {
                                                  Navigator.pop(context, true);
                                                } else if (addressList.length ==
                                                        1 &&
                                                    widget.from.toString() ==
                                                        '1' &&
                                                    buyerName.text.isNotEmpty &&
                                                    buyerNumber
                                                        .text.isNotEmpty &&
                                                    widget.from != null) {
                                                  Navigator.pop(context, true);
                                                }
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'],
                                              color:
                                                  (buyerName.text.isNotEmpty &&
                                                          buyerNumber
                                                              .text.isNotEmpty)
                                                      // ? buttonColor
                                                      ? Colors.black
                                                      : Colors.grey,
                                              borcolor:
                                                  (buyerName.text.isNotEmpty &&
                                                          buyerNumber
                                                              .text.isNotEmpty)
                                                      // ? buttonColor
                                                      ? Colors.black
                                                      : Colors.grey,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),

                      //autofill address
                      Positioned(
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(18,
                                MediaQuery.of(context).padding.top + 12, 18, 0),
                            width: media.width * 1,
                            height: (addAutoFill.isNotEmpty)
                                ? media.width * 1.3
                                : null,
                            color: (addAutoFill.isEmpty)
                                ? Colors.transparent
                                : page,
                            child: Column(
                              children: [
                                Row(
                                  textDirection: TextDirection.ltr,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (_getDropDetails == false ||
                                            choosenTransportType == 0) {
                                          Navigator.pop(context);
                                        } else {
                                          setState(() {
                                            _getDropDetails = false;
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: 54,
                                        width: 54,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: const Color(0xFF10213F)
                                                      .withValues(alpha: .13),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 7))
                                            ],
                                            color: Colors.white),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.arrow_back_rounded,
                                          color: _pickerInk,
                                          size: 27,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 54,
                                      width: media.width - 126,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                                color: const Color(0xFF10213F)
                                                    .withValues(alpha: .13),
                                                blurRadius: 22,
                                                offset: const Offset(0, 8))
                                          ],
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(27)),
                                      child: TextField(
                                          controller: search,
                                          autofocus: false,
                                          decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                color: _pickerBlue,
                                                size: 25,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              border: InputBorder.none,
                                              hintText: languages[
                                                      choosenLanguage]
                                                  ['text_4lettersforautofill'],
                                              hintStyle: GoogleFonts.notoSans(
                                                  fontSize: 14,
                                                  color: _pickerMuted)),
                                          style: GoogleFonts.notoSans(
                                              color: _pickerInk,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          onChanged: (val) {
                                            if (val.isEmpty) {
                                              _sessionToken = null;
                                            }
                                            _debouncer.run(() {
                                              if (val.length >= 4) {
                                                if (storedAutoAddress
                                                    .where((element) =>
                                                        element['description']
                                                            .toString()
                                                            .toLowerCase()
                                                            .contains(val
                                                                .toLowerCase()))
                                                    .isNotEmpty) {
                                                  addAutoFill.removeWhere(
                                                      (element) =>
                                                          element['description']
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains(val
                                                                  .toLowerCase()) ==
                                                          false);
                                                  storedAutoAddress
                                                      .where((element) =>
                                                          element['description']
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains(val
                                                                  .toLowerCase()))
                                                      .forEach((element) {
                                                    addAutoFill.add(element);
                                                  });
                                                  valueNotifierHome
                                                      .incrementNotifier();
                                                } else {
                                                  _sessionToken ??=
                                                      const Uuid().v4();
                                                  getAutocomplete(
                                                      val,
                                                      _sessionToken,
                                                      _center.latitude,
                                                      _center.longitude);
                                                }
                                              } else if (val.isEmpty) {
                                                setState(() {
                                                  addAutoFill.clear();
                                                });
                                              }
                                            });
                                          }),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                (addAutoFill.isNotEmpty)
                                    ? Container(
                                        height: media.height * 0.45,
                                        padding:
                                            EdgeInsets.all(media.width * 0.02),
                                        width: media.width * 0.9,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.05),
                                            color: page),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: addAutoFill
                                                .asMap()
                                                .map((i, value) {
                                                  return MapEntry(
                                                      i,
                                                      (i < 7)
                                                          ? Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                onTap:
                                                                    () async {
                                                                  Map<String,
                                                                          dynamic>?
                                                                      val;

                                                                  // ✅ في حالة lat/lon فاضية، نجيبها من Google API أو الكاش
                                                                  if (addAutoFill[
                                                                              i]
                                                                          [
                                                                          'lat'] ==
                                                                      '') {
                                                                    val =
                                                                        await geoCodingForLatLng(
                                                                      addAutoFill[
                                                                              i]
                                                                          [
                                                                          'place'],
                                                                      _sessionToken,
                                                                    );
                                                                    _sessionToken =
                                                                        null;

                                                                    if (val !=
                                                                        null) {
                                                                      // ✅ نحفظ القيم في العنصر لتقليل التكرار مستقبلاً
                                                                      addAutoFill[
                                                                              i]
                                                                          [
                                                                          'lat'] = val[
                                                                              'lat']
                                                                          .toString();
                                                                      addAutoFill[
                                                                              i]
                                                                          [
                                                                          'lon'] = val[
                                                                              'lng']
                                                                          .toString();
                                                                    }
                                                                  }

                                                                  setState(() {
                                                                    useMyAddress =
                                                                        true;
                                                                    _center =
                                                                        LatLng(
                                                                      double.parse(addAutoFill[i]
                                                                              [
                                                                              'lat']
                                                                          .toString()),
                                                                      double.parse(addAutoFill[i]
                                                                              [
                                                                              'lon']
                                                                          .toString()),
                                                                    );

                                                                    dropAddressConfirmation =
                                                                        addAutoFill[i]
                                                                            [
                                                                            'description'];

                                                                    if (mapType ==
                                                                        'google') {
                                                                      _controller?.moveCamera(CameraUpdate.newLatLngZoom(
                                                                          _center,
                                                                          14.0));
                                                                    } else {
                                                                      _fmController
                                                                          .move(
                                                                        fmlt.LatLng(
                                                                            _center.latitude,
                                                                            _center.longitude),
                                                                        14,
                                                                      );
                                                                    }
                                                                  });

                                                                  FocusManager
                                                                      .instance
                                                                      .primaryFocus
                                                                      ?.unfocus();
                                                                  addAutoFill
                                                                      .clear();
                                                                  search.text =
                                                                      '';
                                                                },
                                                                // onTap:
                                                                //     () async {
                                                                //   // ignore: prefer_typing_uninitialized_variables
                                                                //   var val;
                                                                //   if (addAutoFill[
                                                                //               i]
                                                                //           [
                                                                //           'lat'] ==
                                                                //       '') {
                                                                //     val = await geoCodingForLatLng(
                                                                //         addAutoFill[i]
                                                                //             [
                                                                //             'place'],
                                                                //         _sessionToken);
                                                                //     _sessionToken =
                                                                //         null;
                                                                //   }

                                                                //   setState(() {
                                                                //     useMyAddress =
                                                                //         true;
                                                                //     _center = (addAutoFill[i]['lat'] ==
                                                                //             '')
                                                                //         ? LatLng(
                                                                //             double.parse(val['lat']
                                                                //                 .toString()),
                                                                //             double.parse(val['lng']
                                                                //                 .toString()))
                                                                //         : LatLng(
                                                                //             double.parse(addAutoFill[i]['lat'].toString()),
                                                                //             double.parse(addAutoFill[i]['lon'].toString()));
                                                                //     dropAddressConfirmation =
                                                                //         addAutoFill[i]
                                                                //             [
                                                                //             'description'];
                                                                //     if (mapType ==
                                                                //         'google') {
                                                                //       _controller?.moveCamera(CameraUpdate.newLatLngZoom(
                                                                //           _center,
                                                                //           14.0));
                                                                //     } else {
                                                                //       _fmController.move(
                                                                //           fmlt.LatLng(
                                                                //               _center.latitude,
                                                                //               _center.longitude),
                                                                //           14);
                                                                //     }
                                                                //   });
                                                                //   FocusManager
                                                                //       .instance
                                                                //       .primaryFocus
                                                                //       ?.unfocus();
                                                                //   addAutoFill
                                                                //       .clear();
                                                                //   search.text =
                                                                //       '';
                                                                // },

                                                                child:
                                                                    Container(
                                                                  padding: EdgeInsets.fromLTRB(
                                                                      0,
                                                                      media.width *
                                                                          0.04,
                                                                      0,
                                                                      media.width *
                                                                          0.04),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Container(
                                                                        height: media.width *
                                                                            0.1,
                                                                        width: media.width *
                                                                            0.1,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              Colors.grey[200],
                                                                        ),
                                                                        child: const Icon(
                                                                            Icons.access_time),
                                                                      ),
                                                                      Container(
                                                                        alignment:
                                                                            Alignment.centerLeft,
                                                                        width: media.width *
                                                                            0.7,
                                                                        child: Text(
                                                                            (addAutoFill[i]['description'] != null)
                                                                                ? addAutoFill[i]['description']
                                                                                : addAutoFill[i]['display_name'],
                                                                            style: GoogleFonts.notoSans(
                                                                              fontSize: media.width * twelve,
                                                                              color: textColor,
                                                                            ),
                                                                            maxLines: 2),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : Container());
                                                })
                                                .values
                                                .toList(),
                                          ),
                                        ),
                                      )
                                    : Container()
                              ],
                            ),
                          )),

                      //fav address
                      (favAddressAdd == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: media.width * 0.1,
                                            width: media.width * 0.1,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: page),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  favName = '';
                                                  favAddressAdd = false;
                                                });
                                              },
                                              child: const Icon(
                                                  Icons.cancel_outlined),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_saveaddressas'],
                                            style: GoogleFonts.notoSans(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Text(
                                            favSelectedAddress,
                                            style: GoogleFonts.notoSans(
                                                fontSize: media.width * twelve,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Home';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            (favName == 'Home')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_home'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Work';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child:
                                                            (favName == 'Work')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        const BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_work'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();
                                                  setState(() {
                                                    favName = 'Others';
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.01),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height:
                                                            media.height * 0.05,
                                                        width:
                                                            media.width * 0.05,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                                width: 1.2)),
                                                        alignment:
                                                            Alignment.center,
                                                        child: (favName ==
                                                                'Others')
                                                            ? Container(
                                                                height: media
                                                                        .width *
                                                                    0.03,
                                                                width: media
                                                                        .width *
                                                                    0.03,
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              )
                                                            : Container(),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.01,
                                                      ),
                                                      Text(languages[
                                                              choosenLanguage]
                                                          ['text_others'])
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          (favName == 'Others')
                                              ? Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.025),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2)),
                                                  child: TextField(
                                                    decoration: InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_enterfavname'],
                                                        hintStyle: GoogleFonts
                                                            .notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    twelve,
                                                                color:
                                                                    hintColor)),
                                                    maxLines: 1,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        favNameText = val;
                                                      });
                                                    },
                                                  ),
                                                )
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () async {
                                                if (favName == 'Others' &&
                                                    favNameText != '') {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  var val =
                                                      await addFavLocation(
                                                          favLat,
                                                          favLng,
                                                          favSelectedAddress,
                                                          favNameText);
                                                  setState(() {
                                                    _isLoading = false;
                                                    if (val == true) {
                                                      favLat = '';
                                                      favLng = '';
                                                      favSelectedAddress = '';
                                                      favNameText = '';
                                                      favName = 'Home';
                                                      favAddressAdd = false;
                                                    } else if (val ==
                                                        'logout') {
                                                      navigateLogout();
                                                    }
                                                  });
                                                } else if (favName == 'Home' ||
                                                    favName == 'Work') {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  var val =
                                                      await addFavLocation(
                                                          favLat,
                                                          favLng,
                                                          favSelectedAddress,
                                                          favName);
                                                  setState(() {
                                                    _isLoading = false;
                                                    if (val == true) {
                                                      favLat = '';
                                                      favLng = '';
                                                      favSelectedAddress = '';
                                                      favNameText = '';
                                                      favName = 'Home';
                                                      favAddressAdd = false;
                                                    } else if (val ==
                                                        'logout') {
                                                      navigateLogout();
                                                    }
                                                  });
                                                }
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      (_locationDenied == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.9,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _locationDenied = false;
                                            });
                                          },
                                          child: Container(
                                            height: media.height * 0.05,
                                            width: media.height * 0.05,
                                            decoration: BoxDecoration(
                                              color: page,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.cancel,
                                                color: buttonColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.025),
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: page,
                                        boxShadow: [
                                          BoxShadow(
                                              blurRadius: 2.0,
                                              spreadRadius: 2.0,
                                              color:
                                                  Colors.black.withOpacity(0.2))
                                        ]),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                            width: media.width * 0.8,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_open_loc_settings'],
                                              style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            )),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                                onTap: () async {
                                                  await perm.openAppSettings();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_open_settings'],
                                                  style: GoogleFonts.notoSans(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                )),
                                            InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    _locationDenied = false;
                                                    _isLoading = true;
                                                  });

                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_done'],
                                                  style: GoogleFonts.notoSans(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ))
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                          : Container(),

                      //loader
                      (_isLoading == true)
                          ? const Positioned(child: Loading())
                          : Container(),
                      //no internet
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                  });
                                },
                              ))
                          : Container()
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
