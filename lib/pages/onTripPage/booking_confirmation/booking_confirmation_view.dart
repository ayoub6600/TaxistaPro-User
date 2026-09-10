part of '../booking_confirmation.dart';

mixin _BookingConfirmationView
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationMapCanvas,
        _BookingConfirmationMarkerSnapshots,
        _BookingConfirmationStatusOverlays,
        _BookingConfirmationVehicleServices,
        _BookingConfirmationSelectionSheet,
        _BookingConfirmationPendingRequest,
        _BookingConfirmationActiveRide,
        _BookingConfirmationMapControls,
        _BookingConfirmationModalOverlays {
  Widget buildBookingConfirmation(BuildContext context) {
    GeoHasher geo = GeoHasher();

    const latitudeRadius = 0.0144927536231884;
    const longitudeRadius = 0.0181818181818182;
    final pickupAddresses =
        addressList.where((element) => element.type == 'pickup');
    final pickupLatitude = pickupAddresses.isNotEmpty
        ? pickupAddresses.first.latlng.latitude
        : double.tryParse(userRequestData['pick_lat']?.toString() ?? '') ?? 0;
    final pickupLongitude = pickupAddresses.isNotEmpty
        ? pickupAddresses.first.latlng.longitude
        : double.tryParse(userRequestData['pick_lng']?.toString() ?? '') ?? 0;
    final lowerLat = pickupLatitude - (latitudeRadius * 1.24);
    final lowerLon = pickupLongitude - (longitudeRadius * 1.24);
    final greaterLat = pickupLatitude + (latitudeRadius * 1.24);
    final greaterLon = pickupLongitude + (longitudeRadius * 1.24);
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    popFunction() {
      if (userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        return true;
      } else {
        return false;
      }
    }

    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: popFunction(),
      onPopInvoked: (did) {
        noDriverFound = false;
        tripReqError = false;
        serviceNotAvailable = false;
        if (userRequestData.isNotEmpty &&
            userRequestData['accepted_at'] == null) {
        } else {
          if (widget.type == null) {
            if (dropConfirmed) {
              setState(() {
                dropConfirmed = false;
                promoStatus = false;
                addCoupon = false;
                promoKey.clear();
              });
            } else {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Maps()),
                  (route) => false);

              addressList.removeWhere((element) => element.id == 'drop');
              ismulitipleride = false;
              etaDetails.clear();
              promoKey.clear();
              promoStatus = null;
              promoStatus = false;
              addCoupon = false;
              rentalOption.clear();
              myMarker.clear();
              dropStopList.clear();
              isOutStation = false;
            }
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Maps()),
                (route) => false);
            addressList.removeWhere((element) => element.id == 'drop');
            isRentalRide = false;
            isOutStation = false;
            ismulitipleride = false;
            etaDetails.clear();
            promoKey.clear();
            promoStatus = null;
            promoStatus = false;
            addCoupon = false;
            rentalOption.clear();
            myMarker.clear();
            dropStopList.clear();
          }
        }
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, value, child) {
                  if (_controller != null) {
                    final isRegularDriverSearch = userRequestData.isNotEmpty &&
                        userRequestData['accepted_at'] == null &&
                        userRequestData['is_bid_ride'] != 1;
                    mapPadding = isRegularDriverSearch
                        ? _searchingSheetHeight(media)
                        : bookingSheetHeight(media);
                    scheduleRouteCameraFit(media);
                  }
                  if (polyGot == false &&
                      polyline.isEmpty &&
                      addressList.length > 1 &&
                      userRequestData.isEmpty &&
                      requestCancelledByDriver == false) {
                    polyline.clear();
                    polyGot = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) unawaited(getPolylines('', '', '', ''));
                    });
                  }
                  if (cancelRequestByUser == true) {
                    myMarker.clear();
                    polyline.clear();

                    addressList
                        .removeWhere((element) => element.type == 'drop');
                    ismulitipleride = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Maps()),
                          (route) => false);
                    });
                  } else if (requestCancelledByDriver == true) {
                    if (polyGot == false &&
                        polyline.isEmpty &&
                        addressList.length > 1) {
                      polyline.clear();
                      polyGot = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) unawaited(getPolylines('', '', '', ''));
                      });
                      LatLngBounds bound;
                      if (userRequestData.isNotEmpty) {
                        if (userRequestData['pick_lat'] >
                                userRequestData['drop_lat'] &&
                            userRequestData['pick_lng'] >
                                userRequestData['drop_lng']) {
                          bound = LatLngBounds(
                              southwest: LatLng(userRequestData['drop_lat'],
                                  userRequestData['drop_lng']),
                              northeast: LatLng(userRequestData['pick_lat'],
                                  userRequestData['pick_lng']));
                        } else if (userRequestData['pick_lng'] >
                            userRequestData['drop_lng']) {
                          bound = LatLngBounds(
                              southwest: LatLng(userRequestData['pick_lat'],
                                  userRequestData['drop_lng']),
                              northeast: LatLng(userRequestData['drop_lat'],
                                  userRequestData['pick_lng']));
                        } else if (userRequestData['pick_lat'] >
                            userRequestData['drop_lat']) {
                          bound = LatLngBounds(
                              southwest: LatLng(userRequestData['drop_lat'],
                                  userRequestData['pick_lng']),
                              northeast: LatLng(userRequestData['pick_lat'],
                                  userRequestData['drop_lng']));
                        } else {
                          bound = LatLngBounds(
                              southwest: LatLng(userRequestData['pick_lat'],
                                  userRequestData['pick_lng']),
                              northeast: LatLng(userRequestData['drop_lat'],
                                  userRequestData['drop_lng']));
                        }
                      } else {
                        if (addressList
                                    .firstWhere(
                                        (element) => element.type == 'pickup')
                                    .latlng
                                    .latitude >
                                addressList
                                    .lastWhere(
                                        (element) => element.type == 'drop')
                                    .latlng
                                    .latitude &&
                            addressList
                                    .firstWhere(
                                        (element) => element.type == 'pickup')
                                    .latlng
                                    .longitude >
                                addressList
                                    .lastWhere(
                                        (element) => element.type == 'drop')
                                    .latlng
                                    .longitude) {
                          bound = LatLngBounds(
                              southwest: addressList
                                  .lastWhere(
                                      (element) => element.type == 'drop')
                                  .latlng,
                              northeast: addressList
                                  .firstWhere(
                                      (element) => element.type == 'pickup')
                                  .latlng);
                        } else if (addressList
                                .firstWhere(
                                    (element) => element.type == 'pickup')
                                .latlng
                                .longitude >
                            addressList
                                .lastWhere((element) => element.type == 'drop')
                                .latlng
                                .longitude) {
                          bound = LatLngBounds(
                              southwest: LatLng(
                                  addressList
                                      .firstWhere(
                                          (element) => element.type == 'pickup')
                                      .latlng
                                      .latitude,
                                  addressList
                                      .lastWhere(
                                          (element) => element.type == 'drop')
                                      .latlng
                                      .longitude),
                              northeast: LatLng(
                                  addressList
                                      .lastWhere(
                                          (element) => element.type == 'drop')
                                      .latlng
                                      .latitude,
                                  addressList
                                      .firstWhere(
                                          (element) => element.type == 'pickup')
                                      .latlng
                                      .longitude));
                        } else if (addressList
                                .firstWhere(
                                    (element) => element.type == 'pickup')
                                .latlng
                                .latitude >
                            addressList
                                .lastWhere((element) => element.type == 'drop')
                                .latlng
                                .latitude) {
                          bound = LatLngBounds(
                              southwest: LatLng(
                                  addressList
                                      .lastWhere(
                                          (element) => element.type == 'drop')
                                      .latlng
                                      .latitude,
                                  addressList
                                      .firstWhere(
                                          (element) => element.type == 'pickup')
                                      .latlng
                                      .longitude),
                              northeast: LatLng(
                                  addressList
                                      .firstWhere(
                                          (element) => element.type == 'pickup')
                                      .latlng
                                      .latitude,
                                  addressList
                                      .lastWhere(
                                          (element) => element.type == 'drop')
                                      .latlng
                                      .longitude));
                        } else {
                          bound = LatLngBounds(
                              southwest: addressList
                                  .firstWhere(
                                      (element) => element.type == 'pickup')
                                  .latlng,
                              northeast: addressList
                                  .lastWhere(
                                      (element) => element.type == 'drop')
                                  .latlng);
                        }
                      }
                      CameraUpdate cameraUpdate =
                          CameraUpdate.newLatLngBounds(bound, 50);
                      _controller!.animateCamera(cameraUpdate);
                    }
                  }
                  if (changeBound == true &&
                      mapType == 'google' &&
                      userRequestData.isNotEmpty &&
                      widget.type == null &&
                      userRequestData['is_completed'] != 1) {
                    changeBound = false;
                    LatLngBounds bound;
                    if (userRequestData['pick_lat'] >
                            userRequestData['drop_lat'] &&
                        userRequestData['pick_lng'] >
                            userRequestData['drop_lng']) {
                      bound = LatLngBounds(
                          southwest: LatLng(userRequestData['drop_lat'],
                              userRequestData['drop_lng']),
                          northeast: LatLng(userRequestData['pick_lat'],
                              userRequestData['pick_lng']));
                    } else if (userRequestData['pick_lng'] >
                        userRequestData['drop_lng']) {
                      bound = LatLngBounds(
                          southwest: LatLng(userRequestData['pick_lat'],
                              userRequestData['drop_lng']),
                          northeast: LatLng(userRequestData['drop_lat'],
                              userRequestData['pick_lng']));
                    } else if (userRequestData['pick_lat'] >
                        userRequestData['drop_lat']) {
                      bound = LatLngBounds(
                          southwest: LatLng(userRequestData['drop_lat'],
                              userRequestData['pick_lng']),
                          northeast: LatLng(userRequestData['pick_lat'],
                              userRequestData['drop_lng']));
                    } else {
                      bound = LatLngBounds(
                          southwest: LatLng(userRequestData['pick_lat'],
                              userRequestData['pick_lng']),
                          northeast: LatLng(userRequestData['drop_lat'],
                              userRequestData['drop_lng']));
                    }
                    CameraUpdate cameraUpdate =
                        CameraUpdate.newLatLngBounds(bound, 50);
                    if (_controller != null) {
                      _controller!.animateCamera(cameraUpdate);
                    }
                  }
                  if (userRequestData['is_completed'] == 1 &&
                      currentpage == true) {
                    currentpage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                          (route) => false);
                    });
                  }
                  if (userRequestData.isNotEmpty &&
                      timing == null &&
                      userRequestData['accepted_at'] == null) {
                    timer();
                  } else if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    timing = null;
                  }
                  if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    if (myMarker
                        .where((element) =>
                            element.markerId == const MarkerId('pointdistance'))
                        .isNotEmpty) {
                      myMarker.removeWhere((element) =>
                          element.markerId == const MarkerId('pointdistance'));
                    }
                  }

                  if ((userRequestData.isEmpty ||
                          userRequestData['accepted_at'] == null ||
                          userRequestData['is_driver_arrived'] == 1) &&
                      fmPolyGot == false &&
                      fmpoly.isEmpty &&
                      mapType != 'google') {
                    fmPolyGot = true;
                    getPoly(true, '', '');
                  }

                  return StreamBuilder<DatabaseEvent>(
                      stream: (userRequestData['driverDetail'] == null &&
                              pinLocationIcon != null)
                          ? fdb.onValue.asBroadcastStream()
                          : null,
                      builder: (context, AsyncSnapshot<DatabaseEvent> event) {
                        if (event.hasData) {
                          if (event.data!.snapshot.value != null) {
                            if (userRequestData['accepted_at'] == null) {
                              DataSnapshot snapshots = event.data!.snapshot;
                              driversData = snapshots.children
                                  .map((element) => element.value)
                                  .whereType<Map>()
                                  .map(Map<String, dynamic>.from)
                                  .toList(growable: true);
                              if (choosenVehicle != null &&
                                  etaDetails.isNotEmpty) {
                                driversData.forEach((e) {
                                  if (e['is_active'] == 1 &&
                                      e['is_available'] == true) {
                                    if (((choosenTransportType == 0 && e['transport_type'] == 'taxi') ||
                                            (choosenTransportType == 0 &&
                                                e['transport_type'] ==
                                                    'both')) &&
                                        ((e['vehicle_types'] != null && ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) || (widget.type == 1 && e['vehicle_types'].contains(rentalOption[choosenVehicle]['type_id'])))) ||
                                            ((widget.type != 1 && e['vehicle_type'] == etaDetails[choosenVehicle]['type_id']) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_type'] ==
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains(
                                                    'car#${e['id']}#${e['vehicle_type_icon']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car#${e['id']}#${e['vehicle_type_icon']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null ||
                                            mapType != 'google') {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null ||
                                                mapType != 'google') {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  'car#${e['id']}#${e['vehicle_type_icon']}',
                                                  e['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else if (((choosenTransportType == 1 && e['transport_type'] == 'delivery') ||
                                            choosenTransportType == 1 &&
                                                e['transport_type'] ==
                                                    'both') &&
                                        ((e['vehicle_types'] != null && ((widget.type != 1 && e['vehicle_types'].contains(etaDetails[choosenVehicle]['type_id'])) || (widget.type == 1 && e['vehicle_types'].contains(rentalOption[choosenVehicle]['type_id'])))) ||
                                            ((widget.type != 1 && e['vehicle_type'] == etaDetails[choosenVehicle]['type_id']) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_type'] ==
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains(
                                                    'car#${e['id']}#${e['vehicle_type_icon']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car#${e['id']}#${e['vehicle_type_icon']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null ||
                                            mapType != 'google') {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null ||
                                                mapType != 'google') {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${e['id']}#${e['vehicle_type_icon']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  'car#${e['id']}#${e['vehicle_type_icon']}',
                                                  e['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      if (myMarker
                                          .where((element) => element.markerId
                                              .toString()
                                              .contains(
                                                  'car#${e['id']}#${e['vehicle_type_icon']}'))
                                          .isNotEmpty) {
                                        myMarker.removeWhere((element) =>
                                            element.markerId.toString().contains(
                                                'car#${e['id']}#${e['vehicle_type_icon']}'));
                                      }
                                    }
                                  } else {
                                    if (myMarker
                                        .where((element) => element.markerId
                                            .toString()
                                            .contains(
                                                'car#${e['id']}#${e['vehicle_type_icon']}'))
                                        .isNotEmpty) {
                                      myMarker.removeWhere((element) =>
                                          element.markerId.toString().contains(
                                              'car#${e['id']}#${e['vehicle_type_icon']}'));
                                    }
                                  }
                                });
                              }
                            }
                          }
                        }

                        return StreamBuilder<DatabaseEvent>(
                            stream: (userRequestData['driverDetail'] != null &&
                                    pinLocationIcon != null)
                                ? FirebaseDatabase.instance
                                    .ref(
                                        'drivers/driver_${userRequestData['driverDetail']['data']['id']}')
                                    .onValue
                                    .asBroadcastStream()
                                : null,
                            builder:
                                (context, AsyncSnapshot<DatabaseEvent> event) {
                              if (event.hasData) {
                                if (event.data!.snapshot.value != null) {
                                  if (userRequestData['accepted_at'] != null) {
                                    driversData = <dynamic>[];
                                    if (myMarker.length > 3) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                    }
                                    DataSnapshot snapshots =
                                        event.data!.snapshot;
                                    if (snapshots != null) {
                                      driverData = jsonDecode(
                                          jsonEncode(snapshots.value));
                                      final driverLocation = driverData['l'];
                                      if (userRequestData.isNotEmpty &&
                                          driverLocation is List &&
                                          driverLocation.length >= 2 &&
                                          driverLocation[0] != null &&
                                          driverLocation[1] != null) {
                                        if (userRequestData['arrived_at'] ==
                                            null) {
                                          if (polyline.isEmpty &&
                                              polyGot == false &&
                                              mapType == 'google' &&
                                              userRequestData['drop_lat'] !=
                                                  null) {
                                            polyGot = true;
                                            final driverLatitude =
                                                driverData['l'][0];
                                            final driverLongitude =
                                                driverData['l'][1];
                                            final pickupLatitude =
                                                userRequestData['pick_lat'];
                                            final pickupLongitude =
                                                userRequestData['pick_lng'];
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (!mounted) return;
                                              unawaited(getPolylines(
                                                driverLatitude,
                                                driverLongitude,
                                                pickupLatitude,
                                                pickupLongitude,
                                              ));
                                            });
                                            LatLngBounds bound;
                                            if (userRequestData.isNotEmpty) {
                                              if (driverData['l'][0] >
                                                      userRequestData[
                                                          'pick_lat'] &&
                                                  driverData['l'][1] >
                                                      userRequestData[
                                                          'pick_lng']) {
                                                bound = LatLngBounds(
                                                    southwest: LatLng(
                                                        userRequestData[
                                                            'pick_lat'],
                                                        userRequestData[
                                                            'pick_lng']),
                                                    northeast: LatLng(
                                                        driverData['l'][0],
                                                        driverData['l'][1]));
                                              } else if (driverData['l'][1] >
                                                  userRequestData['pick_lng']) {
                                                bound = LatLngBounds(
                                                    southwest: LatLng(
                                                        driverData['l'][0],
                                                        userRequestData[
                                                            'pick_lng']),
                                                    northeast: LatLng(
                                                        userRequestData[
                                                            'pick_lat'],
                                                        driverData['l'][1]));
                                              } else if (driverData['l'][0] >
                                                  userRequestData['pick_lat']) {
                                                bound = LatLngBounds(
                                                    southwest: LatLng(
                                                        userRequestData[
                                                            'pick_lat'],
                                                        driverData['l'][1]),
                                                    northeast: LatLng(
                                                        driverData['l'][0],
                                                        userRequestData[
                                                            'pick_lng']));
                                              } else {
                                                bound = LatLngBounds(
                                                    southwest: LatLng(
                                                        driverData['l'][0],
                                                        driverData['l'][1]),
                                                    northeast: LatLng(
                                                        userRequestData[
                                                            'pick_lat'],
                                                        userRequestData[
                                                            'pick_lng']));
                                              }
                                              CameraUpdate cameraUpdate =
                                                  CameraUpdate.newLatLngBounds(
                                                      bound, 50);
                                              _controller!
                                                  .animateCamera(cameraUpdate);
                                            }
                                          }
                                          var distCalc = calculateDistance(
                                              userRequestData['pick_lat'],
                                              userRequestData['pick_lng'],
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        } else if (userRequestData[
                                                    'is_rental'] !=
                                                true &&
                                            userRequestData['drop_lat'] !=
                                                null) {
                                          var distCalc = calculateDistance(
                                            driverData['l'][0],
                                            driverData['l'][1],
                                            userRequestData['drop_lat'],
                                            userRequestData['drop_lng'],
                                          );
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        }
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains(
                                                    'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car#${driverData['id']}#${driverData['vehicle_type_icon']}'),
                                            rotation: (myBearings[
                                                        driverData['id']
                                                            .toString()] !=
                                                    null)
                                                ? myBearings[
                                                    driverData['id'].toString()]
                                                : 0.0,
                                            position: LatLng(driverData['l'][0],
                                                driverData['l'][1]),
                                            icon: (driverData[
                                                        'vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null ||
                                            mapType != 'google') {
                                          if (userRequestData.isNotEmpty &&
                                              mapType != 'google' &&
                                              fmpoly.isEmpty &&
                                              fmPolyGot == false) {
                                            fmPolyGot = true;
                                            getPoly(false, driverData['l'][0],
                                                driverData['l'][1]);
                                          } else {}

                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                  .position
                                                  .longitude,
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          if (dist > 100) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                        .position
                                                        .latitude !=
                                                    driverData['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                            .position
                                                            .longitude !=
                                                        driverData['l'][1] &&
                                                    _controller != null ||
                                                mapType != 'google') {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );

                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car#${driverData['id']}#${driverData['vehicle_type_icon']}'))
                                                      .position
                                                      .longitude,
                                                  driverData['l'][0],
                                                  driverData['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  'car#${driverData['id']}#${driverData['vehicle_type_icon']}',
                                                  driverData['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  buildBookingMapCanvas(context, media),
                                  ...buildMapControls(media),
                                  buildRideSelectionSheet(media, fdb, geo),
                                  ...buildModalOverlays(media, fdb, geo),
                                ],
                              );
                            });
                      });
                }),
          ),
        ),
      ),
    );
  }
}
