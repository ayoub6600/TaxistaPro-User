part of '../booking_confirmation.dart';

mixin _BookingConfirmationView
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildBookingConfirmation(BuildContext context) {
    GeoHasher geo = GeoHasher();

    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude -
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double lowerLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude -
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lon * 1.24)
            : 0.0;

    double greaterLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude +
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double greaterLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude +
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lat * 1.24)
            : 0.0;
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
                    mapPadding = media.width * 1;
                  }
                  if (polyGot == false &&
                      polyline.isEmpty &&
                      addressList.length > 1 &&
                      userRequestData.isEmpty &&
                      requestCancelledByDriver == false) {
                    polyline.clear();
                    polyGot = true;
                    getPolylines('', '', '', '');
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
                      getPolylines('', '', '', '');
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
                              // ignore: unnecessary_null_comparison
                              if (snapshots != null &&
                                  choosenVehicle != null &&
                                  etaDetails.isNotEmpty) {
                                driversData = [];
                                // ignore: avoid_function_literals_in_foreach_calls
                                snapshots.children.forEach((element) {
                                  driversData.add(element.value);
                                });
                                // ignore: avoid_function_literals_in_foreach_calls
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
                                                  // _controller,
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
                                    driversData.clear();
                                    if (myMarker.length > 3) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                    }
                                    DataSnapshot snapshots =
                                        event.data!.snapshot;
                                    // ignore: unnecessary_null_comparison
                                    if (snapshots != null) {
                                      driverData = jsonDecode(
                                          jsonEncode(snapshots.value));
                                      if (userRequestData != {}) {
                                        if (userRequestData['arrived_at'] ==
                                            null) {
                                          if (polyline.isEmpty &&
                                              polyGot == false &&
                                              mapType == 'google' &&
                                              userRequestData['drop_lat'] !=
                                                  null) {
                                            polyGot = true;
                                            getPolylines(
                                                //Ahmed

                                                driverData['l'][0],
                                                driverData['l'][1],
                                                userRequestData['pick_lat'],
                                                userRequestData['pick_lng']);
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
                                                  // _controller,
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
                                  Container(
                                      alignment: Alignment.topCenter,
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      //get drivers location updates
                                      child: (mapType == 'google')
                                          ? StreamBuilder<List<Marker>>(
                                              stream: mapMarkerStream,
                                              builder: (context, snapshot) {
                                                return GoogleMap(
                                                  padding: EdgeInsets.only(
                                                      bottom: mapPadding,
                                                      top: media.height * 0.1 +
                                                          MediaQuery.of(context)
                                                              .padding
                                                              .top),
                                                  onMapCreated: _onMapCreated,
                                                  compassEnabled: false,
                                                  initialCameraPosition:
                                                      CameraPosition(
                                                    target: _center,
                                                    zoom: 11.0,
                                                  ),
                                                  markers: Set<Marker>.from(
                                                      myMarker),
                                                  polylines: polyline,
                                                  minMaxZoomPreference:
                                                      const MinMaxZoomPreference(
                                                          0.0, 20.0),
                                                  myLocationButtonEnabled:
                                                      false,
                                                  buildingsEnabled: false,
                                                  zoomControlsEnabled: false,
                                                  myLocationEnabled: true,
                                                );
                                              })
                                          : StreamBuilder<List<Marker>>(
                                              stream: mapMarkerStream,
                                              builder: (context, snapshot) {
                                                return SizedBox(
                                                  height: (userRequestData
                                                          .isEmpty)
                                                      ? media.height -
                                                          media.width * 0.5
                                                      : ((media.height * 1.1) -
                                                          media.width),
                                                  child: fm.FlutterMap(
                                                    mapController:
                                                        _fmController,
                                                    options: fm.MapOptions(
                                                        initialCenter:
                                                            fmlt.LatLng(
                                                                _center
                                                                    .latitude,
                                                                _center
                                                                    .longitude),
                                                        initialZoom: 13,
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

                                                      // fm.PolylineLayer(
                                                      //   polylines: [
                                                      //     fm.Polyline(
                                                      //         points: fmpoly,
                                                      //         color:
                                                      //             Colors.blue,
                                                      //         strokeWidth: 4),
                                                      //   ],
                                                      // ),

                                                      // fm.MarkerLayer(
                                                      //   markers: [
                                                      //     for (var k = 0;
                                                      //         k <
                                                      //             addressList
                                                      //                 .length;
                                                      //         k++)
                                                      //       fm.Marker(
                                                      //           alignment: Alignment
                                                      //               .topCenter,
                                                      //           point: fmlt.LatLng(
                                                      //               addressList[k]
                                                      //                   .latlng
                                                      //                   .latitude,
                                                      //               addressList[k]
                                                      //                   .latlng
                                                      //                   .longitude),
                                                      //           width: (k == 0 ||
                                                      //                   k ==
                                                      //                       addressList.length -
                                                      //                           1)
                                                      //               ? media.width *
                                                      //                   0.7
                                                      //               : 10,
                                                      //           height: (k == 0 ||
                                                      //                   k ==
                                                      //                       addressList.length -
                                                      //                           1)
                                                      //               ? media.width * 0.15 +
                                                      //                   10
                                                      //               : 18,
                                                      //           child:
                                                      //               (k == 0 ||
                                                      //                       k ==
                                                      //                           addressList.length - 1)
                                                      //                   ? Column(
                                                      //                       children: [
                                                      //                         Container(
                                                      //                             decoration: BoxDecoration(
                                                      //                                 gradient: LinearGradient(colors: [
                                                      //                                   (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                      //                                   (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                      //                                 ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                      //                                 borderRadius: BorderRadius.circular(5)),
                                                      //                             width: (platform == TargetPlatform.android) ? media.width * 0.7 : media.width * 0.9,
                                                      //                             padding: const EdgeInsets.all(5),
                                                      //                             child: (userRequestData.isNotEmpty)
                                                      //                                 ? Text(
                                                      //                                     addressList[k].address,
                                                      //                                     maxLines: 1,
                                                      //                                     overflow: TextOverflow.fade,
                                                      //                                     softWrap: false,
                                                      //                                     style: GoogleFonts.notoSans(color: textColor, fontSize: (platform == TargetPlatform.android) ? media.width * twelve : media.width * sixteen),
                                                      //                                   )
                                                      //                                 : (addressList.where((element) => element.type == 'pickup').isNotEmpty)
                                                      //                                     ? Text(
                                                      //                                         addressList[k].address,
                                                      //                                         maxLines: 1,
                                                      //                                         overflow: TextOverflow.fade,
                                                      //                                         softWrap: false,
                                                      //                                         style: GoogleFonts.notoSans(color: textColor, fontSize: (platform == TargetPlatform.android) ? media.width * twelve : media.width * sixteen),
                                                      //                                       )
                                                      //                                     : Container()),
                                                      //                         const SizedBox(
                                                      //                           height: 10,
                                                      //                         ),
                                                      //                         Container(
                                                      //                           decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage((addressList[k].type == 'pickup') ? 'assets/images/pick_icon.png' : 'assets/images/drop_icon.png'), fit: BoxFit.contain)),
                                                      //                           height: (platform == TargetPlatform.android) ? media.width * 0.07 : media.width * 0.12,
                                                      //                           width: (platform == TargetPlatform.android) ? media.width * 0.07 : media.width * 0.12,
                                                      //                         ),
                                                      //                       ],
                                                      //                     )
                                                      //                   : MyText(
                                                      //                       text:
                                                      //                           k.toString(),
                                                      //                       size:
                                                      //                           16,
                                                      //                       fontweight:
                                                      //                           FontWeight.bold,
                                                      //                       color:
                                                      //                           Colors.red,
                                                      //                     )),
                                                      //     for (var i = 0;
                                                      //         i <
                                                      //             myMarker
                                                      //                 .length;
                                                      //         i++)
                                                      //       fm.Marker(
                                                      //           alignment:
                                                      //               Alignment
                                                      //                   .topCenter,
                                                      //           point: fmlt.LatLng(
                                                      //               myMarker[i]
                                                      //                   .position
                                                      //                   .latitude,
                                                      //               myMarker[i]
                                                      //                   .position
                                                      //                   .longitude),
                                                      //           width: media
                                                      //                   .width *
                                                      //               0.7,
                                                      //           height: 50,
                                                      //           child: RotationTransition(
                                                      //               turns: AlwaysStoppedAnimation(myMarker[i].rotation / 360),
                                                      //               child: (myMarker[i].markerId.toString().contains('car#') == true)
                                                      //                   ? Image.asset(
                                                      //                       (myMarker[i].markerId.toString().replaceAll('MarkerId(', '').replaceAll(')', '').split('#')[2].toString() == 'taxi')
                                                      //                           ? 'assets/images/top-taxi.png'
                                                      //                           : (myMarker[i].markerId.toString().replaceAll('MarkerId(', '').replaceAll(')', '').split('#')[2].toString() == 'truck')
                                                      //                               ? 'assets/images/deliveryicon.png'
                                                      //                               : 'assets/images/bike.png',
                                                      //                     )
                                                      //                   : Container()))
                                                      //   ],
                                                      // ),

                                                      // fm.MarkerLayer()

                                                      const fm
                                                          .RichAttributionWidget(
                                                        attributions: [],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              })),

                                  Positioned(
                                    top: MediaQuery.of(context).padding.top +
                                        12.5,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: (userRequestData
                                                                .isNotEmpty &&
                                                            userRequestData[
                                                                    'accepted_at'] ==
                                                                null)
                                                        ? Colors.transparent
                                                        : Colors.black
                                                            .withOpacity(0.2),
                                                    spreadRadius: 2,
                                                    blurRadius: 2)
                                              ],
                                            ),
                                            child: Material(
                                              color: (userRequestData
                                                          .isNotEmpty &&
                                                      userRequestData[
                                                              'accepted_at'] ==
                                                          null)
                                                  ? Colors.transparent
                                                  : page,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      media.width * 0.05),
                                              // color: page,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        media.width * 0.05),
                                                onTap: () {
                                                  // Reset flags
                                                  noDriverFound = false;
                                                  tripReqError = false;
                                                  serviceNotAvailable = false;

                                                  // Check if there is a user request that has not been accepted
                                                  if (userRequestData
                                                          .isNotEmpty &&
                                                      userRequestData[
                                                              'accepted_at'] ==
                                                          null) {
                                                    return; // Exit early if a trip is in progress
                                                  }

                                                  // Handle navigation and state updates
                                                  bool
                                                      shouldResetDropConfirmed =
                                                      widget.type == null &&
                                                          dropConfirmed;

                                                  if (shouldResetDropConfirmed) {
                                                    setState(() {
                                                      dropConfirmed = false;
                                                      promoStatus = false;
                                                      addCoupon = false;
                                                      promoKey.clear();
                                                    });
                                                  } else {
                                                    Navigator
                                                        .pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const Maps()),
                                                      (route) => false,
                                                    );
                                                    isRentalRide = false;
                                                    ismulitipleride = false;
                                                    isOutStation = false;
                                                    etaDetails.clear();
                                                    promoKey.clear();
                                                    promoStatus = false;
                                                    addCoupon = false;
                                                    rentalOption.clear();
                                                    myMarker.clear();
                                                    dropStopList.clear();
                                                    addressList.removeWhere(
                                                        (element) =>
                                                            element.id ==
                                                            'drop');
                                                  }
                                                },
                                                child: SizedBox(
                                                  height: media.width * 0.1,
                                                  width: media.width * 0.1,
                                                  child: Icon(
                                                    Icons.arrow_back,
                                                    color: (userRequestData
                                                                .isNotEmpty &&
                                                            userRequestData[
                                                                    'accepted_at'] ==
                                                                null)
                                                        ? Colors.transparent
                                                        : textColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: media.width * 1.25,
                                    // top: media.width*0.2 + MediaQuery.of(context).padding.top,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (userRequestData.isNotEmpty &&
                                              userRequestData['accepted_at'] !=
                                                  null)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              media.width *
                                                                  0.02),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            spreadRadius: 2)
                                                      ],
                                                      color: page),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            media.width * 0.02),
                                                    child: InkWell(
                                                      onTap: () async {
                                                        await Share.share(
                                                            'Your Driver is ${userRequestData['driverDetail']['data']['name']}. ${userRequestData['driverDetail']['data']['car_color']} ${userRequestData['driverDetail']['data']['car_make_name']} ${userRequestData['driverDetail']['data']['car_model_name']}, Vehicle Number: ${userRequestData['driverDetail']['data']['car_number']}. Track with link: ${url}track/request/${userRequestData['id']}');
                                                      },
                                                      child: Container(
                                                          height:
                                                              media.width * 0.1,
                                                          width:
                                                              media.width * 0.1,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Icon(
                                                            Icons.share,
                                                            size: media.width *
                                                                sixteen,
                                                            color: textColor,
                                                          )),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          (userRequestData.isNotEmpty &&
                                                  userRequestData[
                                                          'is_trip_start'] ==
                                                      1)
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            spreadRadius: 2)
                                                      ],
                                                      color: page,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              media.width *
                                                                  0.02)),
                                                  child: Material(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            media.width * 0.02),
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                        onTap: () async {
                                                          setState(() {
                                                            showSos = true;
                                                          });
                                                        },
                                                        child: Container(
                                                          height:
                                                              media.width * 0.1,
                                                          width:
                                                              media.width * 0.1,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Text(
                                                            'SOS',
                                                            style: GoogleFonts.notoSans(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor),
                                                          ),
                                                        )),
                                                  ),
                                                )
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.025,
                                          ),
                                          (userRequestData.isNotEmpty)
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              media.width *
                                                                  0.02),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            spreadRadius: 2)
                                                      ],
                                                      color: page),
                                                  child: Material(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            media.width * 0.02),
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        if (locationAllowed ==
                                                            true) {
                                                          if (mapType ==
                                                              'google') {
                                                            if (currentLocation !=
                                                                null) {
                                                              _controller?.animateCamera(
                                                                  CameraUpdate
                                                                      .newLatLngZoom(
                                                                          currentLocation,
                                                                          18.0));
                                                              center =
                                                                  currentLocation;
                                                            } else {
                                                              _controller?.animateCamera(
                                                                  CameraUpdate
                                                                      .newLatLngZoom(
                                                                          center,
                                                                          18.0));
                                                            }
                                                          } else {
                                                            if (currentLocation !=
                                                                null) {
                                                              _controller?.animateCamera(
                                                                  CameraUpdate
                                                                      .newLatLngZoom(
                                                                          currentLocation,
                                                                          18.0));
                                                              _fmController.move(
                                                                  fmlt.LatLng(
                                                                      currentLocation
                                                                          .latitude,
                                                                      currentLocation
                                                                          .longitude),
                                                                  14);
                                                              center =
                                                                  currentLocation;
                                                            } else {
                                                              _fmController.move(
                                                                  fmlt.LatLng(
                                                                      center
                                                                          .latitude,
                                                                      center
                                                                          .longitude),
                                                                  14);
                                                            }
                                                          }
                                                        } else {
                                                          if (serviceEnabled ==
                                                              true) {
                                                            setState(() {
                                                              _locationDenied =
                                                                  true;
                                                            });
                                                          } else {
                                                            // await location.requestService();
                                                            await geolocs
                                                                    .Geolocator
                                                                .getCurrentPosition(
                                                                    desiredAccuracy:
                                                                        geolocs
                                                                            .LocationAccuracy
                                                                            .low);
                                                            if (await geolocs
                                                                .GeolocatorPlatform
                                                                .instance
                                                                .isLocationServiceEnabled()) {
                                                              setState(() {
                                                                _locationDenied =
                                                                    true;
                                                              });
                                                            }
                                                          }
                                                        }
                                                      },
                                                      child: SizedBox(
                                                        height:
                                                            media.width * 0.1,
                                                        width:
                                                            media.width * 0.1,
                                                        child: Icon(
                                                            Icons
                                                                .my_location_sharp,
                                                            color: textColor),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container()
                                        ],
                                      ),
                                    ),
                                  ),
                                  (etaDetails.isNotEmpty &&
                                          userRequestData.isEmpty &&
                                          dropConfirmed &&
                                          widget.type != 1)
                                      ? AnimatedPositioned(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          right: media.width * 0.05,
                                          top: (_ontripBottom)
                                              ? media.width * 0.2
                                              : media.width * 0.8,
                                          child: InkWell(
                                            onTap: () async {
                                              if (_ontripBottom) {
                                                if (userRequestData[
                                                        'is_trip_start'] ==
                                                    1) {
                                                } else {}
                                                _ontripBottom = false;
                                              } else {
                                                _ontripBottom = true;
                                              }

                                              setState(() {});
                                            },
                                            child: Container(
                                              height: media.width * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                        blurRadius: 2,
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        spreadRadius: 2)
                                                  ],
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          media.width * 0.02)),
                                              child: Icon(
                                                (_ontripBottom)
                                                    ? Icons.zoom_in_map
                                                    : Icons.zoom_out_map,
                                                color: textColor,
                                              ),
                                            ),
                                          ))
                                      : Container(),

                                  //show bottom nav bar for choosing ride type and vehicles
                                  (isLoading == false &&
                                          addressList.isNotEmpty &&
                                          etaDetails.isNotEmpty &&
                                          userRequestData.isEmpty &&
                                          noDriverFound == false &&
                                          tripReqError == false &&
                                          dropConfirmed == true &&
                                          lowWalletBalance == false)
                                      ? (_chooseGoodsType == true ||
                                              choosenTransportType == 0)
                                          ? Positioned(
                                              bottom: 0 +
                                                  MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                padding: EdgeInsets.only(
                                                    top: media.width * 0.02,
                                                    bottom: media.width * 0.0),
                                                width: media.width * 1,
                                                height: (bottomChooseMethod ==
                                                            false &&
                                                        widget.type != 1)
                                                    ? (_ontripBottom == true)
                                                        ? media.width * 1.9
                                                        : media.height * 0.9
                                                    : (bottomChooseMethod ==
                                                                false &&
                                                            widget.type == 1)
                                                        ? media.height * 0.6
                                                        : media.height * 0.9,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    25),
                                                            topRight:
                                                                Radius.circular(
                                                                    25)),
                                                    color: page),
                                                child:
                                                    (isRentalRide == true &&
                                                            etaDetails
                                                                .isNotEmpty)
                                                        ? Column(
                                                            children: [
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.025,
                                                              ),
                                                              SizedBox(
                                                                width: media
                                                                        .width *
                                                                    1,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      margin: EdgeInsets.only(
                                                                          left: media.width *
                                                                              0.05,
                                                                          right:
                                                                              media.width * 0.05),
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      child:
                                                                          MyText(
                                                                        text: languages[choosenLanguage]
                                                                            [
                                                                            'text_availablerides'],
                                                                        size: media.width *
                                                                            fourteen,
                                                                        fontweight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child:
                                                                        SingleChildScrollView(
                                                                      // scrollDirection:
                                                                      //     Axis.horizontal,
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: etaDetails
                                                                            .asMap()
                                                                            .map((i, value) {
                                                                              return MapEntry(
                                                                                  i,
                                                                                  Padding(
                                                                                    padding: EdgeInsets.only(top: 10, left: media.width * 0.05, right: media.width * 0.05),
                                                                                    child: Material(
                                                                                      color: Colors.transparent,
                                                                                      child: InkWell(
                                                                                        onTap: () {
                                                                                          if (rentalChoosenOption != i) {
                                                                                            setState(() {
                                                                                              rentalOption = etaDetails[i]['typesWithPrice']['data'];
                                                                                              rentalChoosenOption = i;
                                                                                              choosenVehicle = null;
                                                                                              payingVia = 0;
                                                                                            });
                                                                                          } else {}
                                                                                        },
                                                                                        child: Container(
                                                                                          padding: EdgeInsets.all(media.width * 0.02),
                                                                                          width: media.width * 0.8,
                                                                                          decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(media.width * 0.01),
                                                                                            border: Border.all(
                                                                                                color: (rentalChoosenOption != i)
                                                                                                    ? (isDarkTheme == true)
                                                                                                        ? Colors.white
                                                                                                        : hintColor
                                                                                                    : Colors.orange),
                                                                                            // color: page,
                                                                                          ),
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: Column(
                                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      etaDetails[i]['package_name'].toString(),
                                                                                                      style: GoogleFonts.notoSans(
                                                                                                        fontSize: media.width * sixteen,
                                                                                                        fontWeight: FontWeight.w600,
                                                                                                        color: (rentalChoosenOption == i)
                                                                                                            ? (isDarkTheme == true)
                                                                                                                ? Colors.white
                                                                                                                : textColor
                                                                                                            : (isDarkTheme == true)
                                                                                                                ? const Color(0xff8A8A8A)
                                                                                                                : textColor,
                                                                                                      ),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      etaDetails[i]['short_description'].toString(),
                                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: greyText),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              Text(
                                                                                                '${etaDetails[i]['currency']} ${etaDetails[i]['min_price']} - ${etaDetails[i]['currency']}${etaDetails[i]['max_price']}',
                                                                                                style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: greyText),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ));
                                                                            })
                                                                            .values
                                                                            .toList(),
                                                                      ),
                                                                    )),
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.025,
                                                              ),
                                                              Button(
                                                                  width: media
                                                                          .width *
                                                                      0.5,
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      isRentalRide =
                                                                          false;
                                                                      rentalOption =
                                                                          etaDetails[rentalChoosenOption]['typesWithPrice']
                                                                              [
                                                                              'data'];
                                                                      // rentalChoosenOption = i;
                                                                      choosenVehicle =
                                                                          null;
                                                                      payingVia =
                                                                          0;
                                                                    });
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_confirm']),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.05,
                                                              )
                                                            ],
                                                          )

                                                        // child:
                                                        : (isRentalRide ==
                                                                    false &&
                                                                etaDetails
                                                                    .isNotEmpty)
                                                            ? Column(
                                                                children: [
                                                                  (isOutStation ==
                                                                          true)
                                                                      ? SizedBox(
                                                                          height:
                                                                              media.width * 0.02,
                                                                        )
                                                                      : const SizedBox(),
                                                                  (isOutStation ==
                                                                          true)
                                                                      ? Material(
                                                                          elevation:
                                                                              5,
                                                                          borderRadius:
                                                                              BorderRadius.circular(media.width * 0.02),
                                                                          child:
                                                                              Container(
                                                                            width:
                                                                                media.width * 0.9,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: page,
                                                                              borderRadius: BorderRadius.circular(media.width * 0.02),
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: [
                                                                                Expanded(
                                                                                  child: InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        isOneWayTrip = true;
                                                                                        toDate = null;
                                                                                      });
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.all(media.width * 0.03),
                                                                                      decoration: BoxDecoration(border: Border.all(color: isOneWayTrip ? Colors.orange : page), borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              MyText(
                                                                                                text: languages[choosenLanguage]['text_one_way_trip'],
                                                                                                size: media.width * fourteen,
                                                                                                fontweight: FontWeight.bold,
                                                                                              ),
                                                                                              (isOneWayTrip)
                                                                                                  ? Container(
                                                                                                      height: media.width * 0.04,
                                                                                                      width: media.width * 0.04,
                                                                                                      alignment: Alignment.center,
                                                                                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.orange),
                                                                                                      child: Icon(
                                                                                                        Icons.done,
                                                                                                        size: media.width * 0.03,
                                                                                                        color: page,
                                                                                                      ),
                                                                                                    )
                                                                                                  : Container()
                                                                                            ],
                                                                                          ),
                                                                                          MyText(
                                                                                            text: languages[choosenLanguage]['text_get_drop_off'],
                                                                                            size: media.width * twelve,
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Expanded(
                                                                                  child: InkWell(
                                                                                    onTap: () {
                                                                                      setState(() {
                                                                                        isOneWayTrip = false;
                                                                                      });
                                                                                    },
                                                                                    child: Container(
                                                                                      padding: EdgeInsets.all(media.width * 0.03),
                                                                                      decoration: BoxDecoration(border: Border.all(color: (!isOneWayTrip) ? Colors.orange : page), borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: MyText(
                                                                                                  text: languages[choosenLanguage]['text_round_trip'],
                                                                                                  size: media.width * fourteen,
                                                                                                  fontweight: FontWeight.bold,
                                                                                                  maxLines: 1,
                                                                                                ),
                                                                                              ),
                                                                                              (!isOneWayTrip)
                                                                                                  ? Container(
                                                                                                      height: media.width * 0.04,
                                                                                                      width: media.width * 0.04,
                                                                                                      alignment: Alignment.center,
                                                                                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.orange),
                                                                                                      child: Icon(
                                                                                                        Icons.done,
                                                                                                        size: media.width * 0.03,
                                                                                                        color: page,
                                                                                                      ),
                                                                                                    )
                                                                                                  : Container()
                                                                                            ],
                                                                                          ),
                                                                                          MyText(
                                                                                            text: languages[choosenLanguage]['text_car_return'],
                                                                                            size: media.width * twelve,
                                                                                            maxLines: 1,
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Container(),
                                                                  (isOutStation ==
                                                                          true)
                                                                      ? SizedBox(
                                                                          height:
                                                                              media.width * 0.02,
                                                                        )
                                                                      : const SizedBox(),
                                                                  (isOutStation ==
                                                                          true)
                                                                      ? InkWell(
                                                                          onTap:
                                                                              () {
                                                                            setState(() {
                                                                              _isDateTimebottom = 0;
                                                                            });
                                                                            Future.delayed(const Duration(milliseconds: 200),
                                                                                () {
                                                                              setState(() {
                                                                                if (isOneWayTrip) {
                                                                                  _dateTimeHeight = media.height * 0.45;
                                                                                } else {
                                                                                  _dateTimeHeight = media.height * 0.5;
                                                                                }
                                                                              });
                                                                            });
                                                                          },
                                                                          child:
                                                                              SizedBox(
                                                                            width:
                                                                                media.width * 0.9,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_booking_for'],
                                                                                  size: media.width * twelve,
                                                                                  fontweight: FontWeight.w500,
                                                                                ),
                                                                                SizedBox(
                                                                                  width: media.width * 0.07,
                                                                                ),
                                                                                MyText(
                                                                                  // ignore: unnecessary_null_comparison
                                                                                  text: (fromDate != null) ? DateFormat('d MMM, h:mm a').format(fromDate).toString() : DateFormat('d MMM, h:mm a').format(DateTime.now().add(Duration(minutes: int.parse(userDetails['user_can_make_a_ride_after_x_miniutes'])))).toString(),
                                                                                  size: media.width * twelve,
                                                                                  // color: buttonColor,
                                                                                  color: Colors.orange,
                                                                                ),
                                                                                (!isOneWayTrip)
                                                                                    ? MyText(
                                                                                        text: ' -- ${(toDate != null) ? DateFormat('d MMM, h:mm a').format(toDate!).toString() : languages[choosenLanguage]['text_select']}',
                                                                                        size: media.width * twelve,
                                                                                        // color: buttonColor,
                                                                                        color: Colors.orange,
                                                                                      )
                                                                                    : const SizedBox(),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : Container(),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                  if (isRentalRide ==
                                                                          false &&
                                                                      etaDetails
                                                                          .isNotEmpty &&
                                                                      widget.type !=
                                                                          1)
                                                                    SizedBox(
                                                                      width:
                                                                          media.width *
                                                                              1,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Container(
                                                                            margin:
                                                                                EdgeInsets.only(left: media.width * 0.05, right: media.width * 0.05),
                                                                            width:
                                                                                media.width * 0.9,
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_availablerides'],
                                                                              size: media.width * fourteen,
                                                                              fontweight: FontWeight.bold,
                                                                              color: Colors.blue,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  SizedBox(
                                                                    height:
                                                                        20.h,
                                                                  ),
                                                                  if (etaDetails
                                                                          .isNotEmpty &&
                                                                      widget.type !=
                                                                          1)
                                                                    Expanded(
                                                                      child: SizedBox(
                                                                          width: media.width * 1,
                                                                          child: SingleChildScrollView(
                                                                              physics: const BouncingScrollPhysics(),
                                                                              child: Column(
                                                                                children: [
                                                                                  Column(
                                                                                    children: etaDetails
                                                                                        .asMap()
                                                                                        .map((i, value) {
                                                                                          return MapEntry(
                                                                                              i,
                                                                                              StreamBuilder<DatabaseEvent>(
                                                                                                  stream: fdb.onValue,
                                                                                                  builder: (context, AsyncSnapshot event) {
                                                                                                    if (event.data != null) {
                                                                                                      minutes[etaDetails[i]['type_id']] = '';
                                                                                                      List vehicleList = [];
                                                                                                      List vehicles = [];
                                                                                                      List<double> minsList = [];
                                                                                                      event.data!.snapshot.children.forEach((e) {
                                                                                                        vehicleList.add(e.value);
                                                                                                      });
                                                                                                      if (vehicleList.isNotEmpty) {
                                                                                                        vehicleList.forEach(
                                                                                                          (e) async {
                                                                                                            if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(etaDetails[i]['type_id'])) || e['vehicle_type'] == etaDetails[i]['type_id'])) {
                                                                                                              DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                                              if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                                                vehicles.add(e);
                                                                                                                if (vehicles.isNotEmpty) {
                                                                                                                  var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                                                  minsList.add(double.parse((dist / 1000).toString()));
                                                                                                                  var minDist = minsList.reduce(min);
                                                                                                                  if (minDist > 0 && minDist <= 1) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '2 mins';
                                                                                                                  } else if (minDist > 1 && minDist <= 3) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '5 mins';
                                                                                                                  } else if (minDist > 3 && minDist <= 5) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '8 mins';
                                                                                                                  } else if (minDist > 5 && minDist <= 7) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '11 mins';
                                                                                                                  } else if (minDist > 7 && minDist <= 10) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '14 mins';
                                                                                                                  } else if (minDist > 10) {
                                                                                                                    minutes[etaDetails[i]['type_id']] = '15 mins';
                                                                                                                  }
                                                                                                                } else {
                                                                                                                  minutes[etaDetails[i]['type_id']] = '';
                                                                                                                }
                                                                                                              }
                                                                                                            }
                                                                                                          },
                                                                                                        );
                                                                                                      } else {
                                                                                                        minutes[etaDetails[i]['type_id']] = '';
                                                                                                      }
                                                                                                    } else {
                                                                                                      minutes[etaDetails[i]['type_id']] = '';
                                                                                                    }
                                                                                                    return Padding(
                                                                                                      padding: EdgeInsets.only(top: 10, left: media.width * 0.05, right: media.width * 0.05),
                                                                                                      child: Material(
                                                                                                        color: Colors.transparent,
                                                                                                        child: InkWell(
                                                                                                          onTap: () {
                                                                                                            if (choosenVehicle != i) {
                                                                                                              setState(() {
                                                                                                                choosenVehicle = i;
                                                                                                                // myMarker.clear();
                                                                                                              });
                                                                                                              myMarker.removeWhere((element) => element.markerId.toString().contains('car'));
                                                                                                            } else {
                                                                                                              showModalBottomSheet(
                                                                                                                  context: context,
                                                                                                                  isScrollControlled: true,
                                                                                                                  builder: (context) {
                                                                                                                    return VehicleInfoBottomSheet(
                                                                                                                      i: i,
                                                                                                                      width: media.width,
                                                                                                                      isOneway: isOneWayTrip,
                                                                                                                      type: widget.type,
                                                                                                                    );
                                                                                                                  });
                                                                                                            }
                                                                                                          },
                                                                                                          child: Container(
                                                                                                            padding: EdgeInsets.all(media.width * 0.02),
                                                                                                            height: media.width * 0.157,
                                                                                                            decoration: BoxDecoration(
                                                                                                                borderRadius: BorderRadius.circular(20.r),
                                                                                                                border: Border.all(
                                                                                                                    color: (choosenVehicle != i)
                                                                                                                        ? (isDarkTheme == true)
                                                                                                                            ? Colors.white
                                                                                                                            : hintColor
                                                                                                                        : Colors.blue),
                                                                                                                color: choosenVehicle == i ? Colors.blue.withOpacity(0.2) : Colors.grey[200]),
                                                                                                            child: Row(
                                                                                                              children: [
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.12,
                                                                                                                  child: (etaDetails[i]['icon'] != null)
                                                                                                                      ? Image.network(
                                                                                                                          etaDetails[i]['icon'],
                                                                                                                          fit: BoxFit.contain,
                                                                                                                        )
                                                                                                                      : Container(),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.02,
                                                                                                                ),
                                                                                                                Column(
                                                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                                  children: [
                                                                                                                    Row(
                                                                                                                      children: [
                                                                                                                        SizedBox(
                                                                                                                          width: media.width * 0.3,
                                                                                                                          child: Text(etaDetails[i]['name'],
                                                                                                                              maxLines: 1,
                                                                                                                              overflow: TextOverflow.ellipsis,
                                                                                                                              style: GoogleFonts.notoSans(
                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                  fontWeight: FontWeight.w600,
                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                          ? Colors.black
                                                                                                                                          : textColor
                                                                                                                                      : textColor)),
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    ),
                                                                                                                    Row(
                                                                                                                      children: [
                                                                                                                        Row(
                                                                                                                          children: [
                                                                                                                            (minutes[etaDetails[i]['type_id']] != null && minutes[etaDetails[i]['type_id']] != '')
                                                                                                                                ? Text(
                                                                                                                                    minutes[etaDetails[i]['type_id']].toString(),
                                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                                  )
                                                                                                                                : Text(
                                                                                                                                    '--',
                                                                                                                                    style: GoogleFonts.notoSans(
                                                                                                                                        fontSize: media.width * twelve,
                                                                                                                                        color: (choosenVehicle != i)
                                                                                                                                            ? (isDarkTheme == true)
                                                                                                                                                ? hintColor
                                                                                                                                                : const Color(0xff8A8A8A)
                                                                                                                                            : const Color(0xff8A8A8A)),
                                                                                                                                  ),
                                                                                                                            SizedBox(
                                                                                                                              width: media.width * 0.02,
                                                                                                                            ),
                                                                                                                            Icon(
                                                                                                                              (etaDetails[i]['transport_type'] == 'delivery') ? CupertinoIcons.bag : Icons.person,
                                                                                                                              size: media.width * 0.04,
                                                                                                                              color: const Color(0xff8A8A8A),
                                                                                                                            ),
                                                                                                                            SizedBox(
                                                                                                                              width: media.width * 0.4,
                                                                                                                              child: Text(
                                                                                                                                (etaDetails[i]['transport_type'] == 'delivery') ? etaDetails[i]['size'].toString() : etaDetails[i]['capacity'].toString(),
                                                                                                                                maxLines: 1,
                                                                                                                                overflow: TextOverflow.ellipsis,
                                                                                                                                style: GoogleFonts.notoSans(
                                                                                                                                    fontSize: media.width * twelve,
                                                                                                                                    color: (choosenVehicle != i)
                                                                                                                                        ? (isDarkTheme == true)
                                                                                                                                            ? Colors.black
                                                                                                                                            : const Color(0xff8A8A8A)
                                                                                                                                        : const Color(0xff8A8A8A)),
                                                                                                                              ),
                                                                                                                            ),
                                                                                                                          ],
                                                                                                                        ),
                                                                                                                      ],
                                                                                                                    )
                                                                                                                  ],
                                                                                                                ),
                                                                                                                (widget.type != 2)
                                                                                                                    ? Expanded(
                                                                                                                        child: (etaDetails[i]['has_discount'] != true || etaDetails[i]['enable_bidding'] == true)
                                                                                                                            ? (isOneWayTrip)
                                                                                                                                ? Row(
                                                                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                    children: [
                                                                                                                                      Text(
                                                                                                                                        etaDetails[i]['currency'] + etaDetails[i]['total'].toString(),
                                                                                                                                        style: GoogleFonts.notoSans(
                                                                                                                                            fontSize: media.width * fourteen,
                                                                                                                                            fontWeight: FontWeight.w700,
                                                                                                                                            color: (choosenVehicle != i)
                                                                                                                                                ? (isDarkTheme == true)
                                                                                                                                                    ? const Color(0xff8A8A8A)
                                                                                                                                                    : textColor
                                                                                                                                                : textColor),
                                                                                                                                      ),
                                                                                                                                    ],
                                                                                                                                  )
                                                                                                                                : Container()
                                                                                                                            : Row(
                                                                                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                children: [
                                                                                                                                  Text(
                                                                                                                                    etaDetails[i]['currency'] + ' ',
                                                                                                                                    style: GoogleFonts.notoSans(
                                                                                                                                        fontSize: media.width * fourteen,
                                                                                                                                        color: (choosenVehicle != i)
                                                                                                                                            ? (isDarkTheme == true)
                                                                                                                                                ? const Color(0xff8A8A8A)
                                                                                                                                                : textColor
                                                                                                                                            : (isDarkTheme == true)
                                                                                                                                                ? Colors.white
                                                                                                                                                : textColor,
                                                                                                                                        fontWeight: FontWeight.w600),
                                                                                                                                  ),
                                                                                                                                  Column(
                                                                                                                                    children: [
                                                                                                                                      Text(
                                                                                                                                        etaDetails[i]['total'].toString(),
                                                                                                                                        style: GoogleFonts.notoSans(
                                                                                                                                            fontSize: media.width * fourteen,
                                                                                                                                            color: (choosenVehicle != i)
                                                                                                                                                ? (isDarkTheme == true)
                                                                                                                                                    ? const Color(0xff8A8A8A)
                                                                                                                                                    : textColor
                                                                                                                                                : (isDarkTheme == true)
                                                                                                                                                    ? Colors.white
                                                                                                                                                    : textColor,
                                                                                                                                            fontWeight: FontWeight.w600,
                                                                                                                                            decoration: TextDecoration.lineThrough),
                                                                                                                                      ),
                                                                                                                                      Text(
                                                                                                                                        etaDetails[i]['discounted_totel'].toString(),
                                                                                                                                        style: GoogleFonts.notoSans(
                                                                                                                                            fontSize: media.width * fourteen,
                                                                                                                                            color: (choosenVehicle != i)
                                                                                                                                                ? (isDarkTheme == true)
                                                                                                                                                    ? const Color(0xff8A8A8A)
                                                                                                                                                    : textColor
                                                                                                                                                : (isDarkTheme == true)
                                                                                                                                                    ? Colors.white
                                                                                                                                                    : textColor,
                                                                                                                                            fontWeight: FontWeight.w700),
                                                                                                                                      )
                                                                                                                                    ],
                                                                                                                                  ),
                                                                                                                                ],
                                                                                                                              ))
                                                                                                                    : Container()
                                                                                                              ],
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    );
                                                                                                  }));
                                                                                        })
                                                                                        .values
                                                                                        .toList(),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.05,
                                                                                  )
                                                                                ],
                                                                              ))),
                                                                    )
                                                                  else
                                                                    (etaDetails.isNotEmpty &&
                                                                            widget.type ==
                                                                                1)
                                                                        ? Expanded(
                                                                            child: SizedBox(
                                                                                width: media.width * 1,
                                                                                child: Column(
                                                                                  children: [
                                                                                    Container(
                                                                                      padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.0, media.width * 0.05, media.width * 0.025),
                                                                                      child: Column(
                                                                                        children: [
                                                                                          Row(
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: MyText(
                                                                                                  text: languages[choosenLanguage]['text_select_package'],
                                                                                                  size: media.width * fourteen,
                                                                                                  fontweight: FontWeight.bold,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          SizedBox(
                                                                                            height: media.width * 0.025,
                                                                                          ),
                                                                                          Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.orange.withOpacity(0.14)), padding: EdgeInsets.fromLTRB(media.width * 0.05, media.width * 0.025, media.width * 0.05, media.width * 0.025), child: MyText(text: etaDetails[rentalChoosenOption]['package_name'].toString(), size: media.width * fifteen, fontweight: FontWeight.w500)),
                                                                                              InkWell(
                                                                                                  onTap: () {
                                                                                                    setState(() {
                                                                                                      isRentalRide = true;
                                                                                                    });
                                                                                                  },
                                                                                                  child: MyText(text: languages[choosenLanguage]['text_edit'], size: media.width * fifteen, fontweight: FontWeight.w500)),
                                                                                            ],
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 1,
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        children: [
                                                                                          InkWell(
                                                                                            onTap: () {
                                                                                              setState(() {
                                                                                                isRentalRide = true;
                                                                                              });
                                                                                            },
                                                                                            child: Container(
                                                                                              margin: EdgeInsets.only(left: media.width * 0.05, right: media.width * 0.05),
                                                                                              width: media.width * 0.9,
                                                                                              child: MyText(
                                                                                                text: languages[choosenLanguage]['text_availablerides'],
                                                                                                size: media.width * fourteen,
                                                                                                fontweight: FontWeight.bold,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      height: media.width * 0.025,
                                                                                    ),
                                                                                    Expanded(
                                                                                      child: SizedBox(
                                                                                        width: media.width * 0.9,
                                                                                        child: SingleChildScrollView(
                                                                                          physics: const BouncingScrollPhysics(),
                                                                                          child: Column(
                                                                                            children: [
                                                                                              Column(
                                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                                  children: rentalOption
                                                                                                      .asMap()
                                                                                                      .map((i, value) {
                                                                                                        return MapEntry(
                                                                                                            i,
                                                                                                            StreamBuilder<DatabaseEvent>(
                                                                                                                stream: fdb.onValue,
                                                                                                                builder: (context, AsyncSnapshot event) {
                                                                                                                  if (event.data != null) {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '';
                                                                                                                    List vehicleList = [];
                                                                                                                    List vehicles = [];
                                                                                                                    List<double> minsList = [];
                                                                                                                    event.data!.snapshot.children.forEach((e) {
                                                                                                                      vehicleList.add(e.value);
                                                                                                                    });
                                                                                                                    if (vehicleList.isNotEmpty) {
                                                                                                                      // ignore: avoid_function_literals_in_foreach_calls
                                                                                                                      vehicleList.forEach(
                                                                                                                        (e) async {
                                                                                                                          if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(rentalOption[i]['type_id'])) || e['vehicle_type'] == rentalOption[i]['type_id'])) {
                                                                                                                            DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                                                            if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                                                              vehicles.add(e);
                                                                                                                              if (vehicles.isNotEmpty) {
                                                                                                                                var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                                                                minsList.add(double.parse((dist / 1000).toString()));
                                                                                                                                var minDist = minsList.reduce(min);
                                                                                                                                if (minDist > 0 && minDist <= 1) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '2 mins';
                                                                                                                                } else if (minDist > 1 && minDist <= 3) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '5 mins';
                                                                                                                                } else if (minDist > 3 && minDist <= 5) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '8 mins';
                                                                                                                                } else if (minDist > 5 && minDist <= 7) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '11 mins';
                                                                                                                                } else if (minDist > 7 && minDist <= 10) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '14 mins';
                                                                                                                                } else if (minDist > 10) {
                                                                                                                                  minutes[rentalOption[i]['type_id']] = '15 mins';
                                                                                                                                }
                                                                                                                              } else {
                                                                                                                                minutes[rentalOption[i]['type_id']] = '';
                                                                                                                              }
                                                                                                                            }
                                                                                                                          }
                                                                                                                        },
                                                                                                                      );
                                                                                                                    } else {
                                                                                                                      minutes[rentalOption[i]['type_id']] = '';
                                                                                                                    }
                                                                                                                  } else {
                                                                                                                    minutes[rentalOption[i]['type_id']] = '';
                                                                                                                  }
                                                                                                                  return Padding(
                                                                                                                    padding: const EdgeInsets.only(
                                                                                                                      top: 10,
                                                                                                                    ),
                                                                                                                    child: Material(
                                                                                                                      color: Colors.transparent,
                                                                                                                      child: InkWell(
                                                                                                                        onTap: () {
                                                                                                                          if (choosenVehicle != i) {
                                                                                                                            setState(() {
                                                                                                                              choosenVehicle = i;
                                                                                                                            });
                                                                                                                          } else {
                                                                                                                            showModalBottomSheet(
                                                                                                                                context: context,
                                                                                                                                isScrollControlled: true,
                                                                                                                                builder: (context) {
                                                                                                                                  // return VehicleInfoBottomSheet(
                                                                                                                                  //   i: i,
                                                                                                                                  //   width: media.width,
                                                                                                                                  //   isOneway: isOneWayTrip,
                                                                                                                                  //   type: widget.type,
                                                                                                                                  // );
                                                                                                                                  return Container(
                                                                                                                                    width: media.width,
                                                                                                                                    padding: EdgeInsets.all(media.width * 0.05),
                                                                                                                                    decoration: BoxDecoration(
                                                                                                                                      color: page,
                                                                                                                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(media.width * 0.08), topRight: Radius.circular(media.width * 0.08)),
                                                                                                                                    ),
                                                                                                                                    child: Column(
                                                                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                                                                      children: [
                                                                                                                                        Image.network(
                                                                                                                                          rentalOption[choosenVehicle]['icon'],
                                                                                                                                          width: media.width * 0.4,
                                                                                                                                        ),
                                                                                                                                        SizedBox(
                                                                                                                                          height: media.width * 0.02,
                                                                                                                                        ),
                                                                                                                                        MyText(
                                                                                                                                          text: '${rentalOption[choosenVehicle]['name']} (${etaDetails[rentalChoosenOption]['package_name']})',
                                                                                                                                          size: media.width * sixteen,
                                                                                                                                          fontweight: FontWeight.bold,
                                                                                                                                        ),
                                                                                                                                        SizedBox(
                                                                                                                                          height: media.width * 0.03,
                                                                                                                                        ),
                                                                                                                                        MyText(
                                                                                                                                          text: rentalOption[choosenVehicle]['short_description'],
                                                                                                                                          size: media.width * fourteen,
                                                                                                                                        ),
                                                                                                                                        SizedBox(
                                                                                                                                          height: media.width * 0.05,
                                                                                                                                        ),
                                                                                                                                        Container(
                                                                                                                                          width: media.width * 0.9,
                                                                                                                                          padding: EdgeInsets.all(media.width * 0.02),
                                                                                                                                          decoration: BoxDecoration(
                                                                                                                                            color: hintColor.withOpacity(0.1).withOpacity(0.1),
                                                                                                                                          ),
                                                                                                                                          child: Column(
                                                                                                                                            children: [
                                                                                                                                              Row(
                                                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                                                children: [
                                                                                                                                                  MyText(text: 'Fare', size: media.width * fourteen),
                                                                                                                                                  (rentalOption[choosenVehicle]['has_discount'] != true)
                                                                                                                                                      ? Row(
                                                                                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                                          children: [
                                                                                                                                                            Text(rentalOption[choosenVehicle]['currency'] + rentalOption[choosenVehicle]['fare_amount'].toString(),
                                                                                                                                                                style: GoogleFonts.notoSans(
                                                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                                                  fontWeight: FontWeight.w700,
                                                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                                                          ? Colors.white
                                                                                                                                                                          : textColor
                                                                                                                                                                      : textColor,
                                                                                                                                                                )),
                                                                                                                                                          ],
                                                                                                                                                        )
                                                                                                                                                      : Row(
                                                                                                                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                                          children: [
                                                                                                                                                            Text(rentalOption[choosenVehicle]['currency'],
                                                                                                                                                                style: GoogleFonts.notoSans(
                                                                                                                                                                  fontSize: media.width * fourteen,
                                                                                                                                                                  fontWeight: FontWeight.w700,
                                                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                                                          ? Colors.white
                                                                                                                                                                          : textColor
                                                                                                                                                                      : textColor,
                                                                                                                                                                )),
                                                                                                                                                            Column(
                                                                                                                                                              children: [
                                                                                                                                                                Text(rentalOption[choosenVehicle]['fare_amount'].toString(),
                                                                                                                                                                    style: GoogleFonts.notoSans(
                                                                                                                                                                        fontSize: media.width * fourteen,
                                                                                                                                                                        fontWeight: FontWeight.w700,
                                                                                                                                                                        color: (choosenVehicle != i)
                                                                                                                                                                            ? (isDarkTheme == true)
                                                                                                                                                                                ? Colors.white
                                                                                                                                                                                : textColor
                                                                                                                                                                            : textColor,
                                                                                                                                                                        decoration: TextDecoration.lineThrough)),
                                                                                                                                                                Text(rentalOption[choosenVehicle]['discounted_totel'].toString(),
                                                                                                                                                                    style: GoogleFonts.notoSans(
                                                                                                                                                                      fontSize: media.width * fourteen,
                                                                                                                                                                      fontWeight: FontWeight.w700,
                                                                                                                                                                      color: (choosenVehicle != i)
                                                                                                                                                                          ? (isDarkTheme == true)
                                                                                                                                                                              ? Colors.white
                                                                                                                                                                              : textColor
                                                                                                                                                                          : textColor,
                                                                                                                                                                    )),
                                                                                                                                                              ],
                                                                                                                                                            ),
                                                                                                                                                          ],
                                                                                                                                                        )
                                                                                                                                                ],
                                                                                                                                              ),
                                                                                                                                              SizedBox(
                                                                                                                                                height: media.width * 0.05,
                                                                                                                                              ),
                                                                                                                                              FareBreakupDetails(width: media.width * 0.9, heading: 'Time Price', value: '${rentalOption[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['time_price_per_min'].toString()} / min'),
                                                                                                                                              SizedBox(
                                                                                                                                                height: media.width * 0.05,
                                                                                                                                              ),
                                                                                                                                              FareBreakupDetails(width: media.width * 0.9, heading: 'Distance Price', value: '${rentalOption[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['distance_price_per_km'].toString()} / ${rentalOption[choosenVehicle]['unit_in_words']}'),
                                                                                                                                              SizedBox(
                                                                                                                                                height: media.width * 0.05,
                                                                                                                                              ),
                                                                                                                                              FareBreakupDetails(width: media.width * 0.9, heading: 'Payment Types', value: rentalOption[choosenVehicle]['payment_type'].toString()),
                                                                                                                                            ],
                                                                                                                                          ),
                                                                                                                                        )
                                                                                                                                      ],
                                                                                                                                    ),
                                                                                                                                  );
                                                                                                                                });
                                                                                                                          }
                                                                                                                        },
                                                                                                                        child: Container(
                                                                                                                          padding: EdgeInsets.all(media.width * 0.02),
                                                                                                                          // margin: EdgeInsets.only(top: 10, left: media.width * 0.05, right: media.width * 0.05),
                                                                                                                          height: media.width * 0.157,
                                                                                                                          decoration: BoxDecoration(
                                                                                                                              borderRadius: BorderRadius.circular(media.width * 0.01),
                                                                                                                              border: Border.all(
                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                          ? Colors.white
                                                                                                                                          : hintColor
                                                                                                                                      : Colors.orange),
                                                                                                                              // : Colors.black),
                                                                                                                              // color: page,
                                                                                                                              color: choosenVehicle == i ? Colors.orange.withOpacity(0.2) : null),
                                                                                                                          child: Row(
                                                                                                                            children: [
                                                                                                                              SizedBox(
                                                                                                                                width: media.width * 0.12,
                                                                                                                                child: (rentalOption[i]['icon'] != null)
                                                                                                                                    ? Image.network(
                                                                                                                                        rentalOption[i]['icon'],
                                                                                                                                        fit: BoxFit.contain,
                                                                                                                                        // width: media.width*0.07,
                                                                                                                                      )
                                                                                                                                    : Container(),
                                                                                                                              ),
                                                                                                                              SizedBox(
                                                                                                                                width: media.width * 0.02,
                                                                                                                              ),
                                                                                                                              Column(
                                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                                                children: [
                                                                                                                                  Row(
                                                                                                                                    children: [
                                                                                                                                      SizedBox(
                                                                                                                                        width: media.width * 0.3,
                                                                                                                                        child: Text(rentalOption[i]['name'],
                                                                                                                                            style: GoogleFonts.notoSans(
                                                                                                                                                fontSize: media.width * fourteen,
                                                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                                                color: (choosenVehicle != i)
                                                                                                                                                    ? (isDarkTheme == true)
                                                                                                                                                        ? hintColor
                                                                                                                                                        : textColor
                                                                                                                                                    : textColor)),
                                                                                                                                      ),
                                                                                                                                    ],
                                                                                                                                  ),
                                                                                                                                  Row(
                                                                                                                                    children: [
                                                                                                                                      Row(
                                                                                                                                        children: [
                                                                                                                                          (minutes[rentalOption[i]['type_id']] != null && minutes[rentalOption[i]['type_id']] != '')
                                                                                                                                              ? Text(
                                                                                                                                                  minutes[rentalOption[i]['type_id']].toString(),
                                                                                                                                                  style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                                                )
                                                                                                                                              : Text(
                                                                                                                                                  '--',
                                                                                                                                                  style: GoogleFonts.notoSans(
                                                                                                                                                      fontSize: media.width * twelve,
                                                                                                                                                      color: (choosenVehicle != i)
                                                                                                                                                          ? (isDarkTheme == true)
                                                                                                                                                              ? hintColor
                                                                                                                                                              : const Color(0xff8A8A8A)
                                                                                                                                                          : const Color(0xff8A8A8A)),
                                                                                                                                                ),
                                                                                                                                          SizedBox(
                                                                                                                                            width: media.width * 0.02,
                                                                                                                                          ),
                                                                                                                                          Icon(
                                                                                                                                            Icons.person,
                                                                                                                                            size: media.width * 0.04,
                                                                                                                                            color: const Color(0xff8A8A8A),
                                                                                                                                          ),
                                                                                                                                          SizedBox(
                                                                                                                                            width: media.width * 0.4,
                                                                                                                                            child: Text(
                                                                                                                                              rentalOption[i]['capacity'].toString(),
                                                                                                                                              maxLines: 1,
                                                                                                                                              overflow: TextOverflow.ellipsis,
                                                                                                                                              style: GoogleFonts.notoSans(
                                                                                                                                                  fontSize: media.width * twelve,
                                                                                                                                                  color: (choosenVehicle != i)
                                                                                                                                                      ? (isDarkTheme == true)
                                                                                                                                                          ? hintColor
                                                                                                                                                          : const Color(0xff8A8A8A)
                                                                                                                                                      : const Color(0xff8A8A8A)),
                                                                                                                                            ),
                                                                                                                                          ),
                                                                                                                                        ],
                                                                                                                                      ),
                                                                                                                                    ],
                                                                                                                                  )
                                                                                                                                ],
                                                                                                                              ),
                                                                                                                              (widget.type != 2)
                                                                                                                                  ? Expanded(
                                                                                                                                      child: (rentalOption[i]['has_discount'] != true || rentalOption[i]['enable_bidding'] == true)
                                                                                                                                          ? (isOneWayTrip)
                                                                                                                                              ? Row(
                                                                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                                  children: [
                                                                                                                                                    Text(
                                                                                                                                                      rentalOption[i]['currency'] + rentalOption[i]['fare_amount'].toString(),
                                                                                                                                                      style: GoogleFonts.notoSans(
                                                                                                                                                          fontSize: media.width * fourteen,
                                                                                                                                                          fontWeight: FontWeight.w700,
                                                                                                                                                          color: (choosenVehicle != i)
                                                                                                                                                              ? (isDarkTheme == true)
                                                                                                                                                                  ? Colors.white
                                                                                                                                                                  : textColor
                                                                                                                                                              : textColor),
                                                                                                                                                    ),
                                                                                                                                                  ],
                                                                                                                                                )
                                                                                                                                              : Container()
                                                                                                                                          : Row(
                                                                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                                              children: [
                                                                                                                                                Text(
                                                                                                                                                  rentalOption[i]['currency'] + ' ',
                                                                                                                                                  style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                                                                                ),
                                                                                                                                                Column(
                                                                                                                                                  children: [
                                                                                                                                                    Text(
                                                                                                                                                      rentalOption[i]['fare_amount'].toString(),
                                                                                                                                                      style: GoogleFonts.notoSans(
                                                                                                                                                          fontSize: media.width * fourteen,
                                                                                                                                                          color: (choosenVehicle != i)
                                                                                                                                                              ? (isDarkTheme == true)
                                                                                                                                                                  ? Colors.white
                                                                                                                                                                  : textColor
                                                                                                                                                              : Colors.black,
                                                                                                                                                          fontWeight: FontWeight.w600,
                                                                                                                                                          decoration: TextDecoration.lineThrough),
                                                                                                                                                    ),
                                                                                                                                                    Text(
                                                                                                                                                      rentalOption[i]['discounted_totel'].toString(),
                                                                                                                                                      style: GoogleFonts.notoSans(
                                                                                                                                                          fontSize: media.width * fourteen,
                                                                                                                                                          color: (choosenVehicle != i)
                                                                                                                                                              ? (isDarkTheme == true)
                                                                                                                                                                  ? Colors.white
                                                                                                                                                                  : textColor
                                                                                                                                                              : Colors.black,
                                                                                                                                                          fontWeight: FontWeight.w700),
                                                                                                                                                    )
                                                                                                                                                  ],
                                                                                                                                                ),
                                                                                                                                              ],
                                                                                                                                            ))
                                                                                                                                  : Container()
                                                                                                                            ],
                                                                                                                          ),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  );
                                                                                                                }));
                                                                                                      })
                                                                                                      .values
                                                                                                      .toList()),
                                                                                              SizedBox(
                                                                                                height: media.width * 0.05,
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                )),
                                                                          )
                                                                        : Container(),
                                                                  Container(
                                                                    width: media
                                                                        .width,
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.03),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                            blurRadius:
                                                                                2,
                                                                            color:
                                                                                Colors.black.withOpacity(0.2),
                                                                            spreadRadius: 2)
                                                                      ],
                                                                      color:
                                                                          page,
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        (choosenTransportType ==
                                                                                1)
                                                                            ? Column(
                                                                                children: [
                                                                                  InkWell(
                                                                                    onTap: () {
                                                                                      pickerName.text = addressList[0].name;
                                                                                      pickerNumber.text = addressList[0].number;
                                                                                      instructions.text = (addressList[0].instructions != null) ? addressList[0].instructions : '';
                                                                                      _editUserDetails = true;
                                                                                      setState(() {});
                                                                                    },
                                                                                    child: Column(
                                                                                      children: [
                                                                                        SizedBox(
                                                                                          width: media.width * 0.9,
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.35,
                                                                                                child: Text(
                                                                                                  addressList[0].name,
                                                                                                  style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: buttonColor, fontWeight: FontWeight.w600),
                                                                                                  maxLines: 1,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.35,
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      addressList[0].number,
                                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: buttonColor, fontWeight: FontWeight.w600),
                                                                                                      textAlign: TextAlign.end,
                                                                                                      maxLines: 1,
                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.025,
                                                                                                    ),
                                                                                                    Icon(
                                                                                                      Icons.edit,
                                                                                                      size: media.width * 0.04,
                                                                                                      color: buttonColor,
                                                                                                    )
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                        SizedBox(
                                                                                          height: media.width * 0.0,
                                                                                        ),
                                                                                        (addressList[0].instructions != null)
                                                                                            ? SizedBox(
                                                                                                width: media.width * 0.9,
                                                                                                child: Text(
                                                                                                  languages[choosenLanguage]['text_instructions'] + ' : ' + addressList[0].instructions,
                                                                                                  style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: verifyDeclined, fontWeight: FontWeight.w600),
                                                                                                  maxLines: 1,
                                                                                                  overflow: TextOverflow.ellipsis,
                                                                                                ))
                                                                                            : Container()
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              )
                                                                            : Container(),
                                                                        (selectedGoodsId !=
                                                                                '')
                                                                            ? Container(
                                                                                padding: EdgeInsets.only(top: media.width * 0.03),
                                                                                width: media.width * 0.9,
                                                                                child: Column(
                                                                                  children: [
                                                                                    SizedBox(
                                                                                      width: media.width * 0.9,
                                                                                      child: Text(
                                                                                        languages[choosenLanguage]['text_goods_type'],
                                                                                        style: GoogleFonts.notoSans(
                                                                                          color: textColor,
                                                                                          fontSize: media.width * fourteen,
                                                                                        ),
                                                                                        maxLines: 1,
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(height: media.width * 0.02),
                                                                                    InkWell(
                                                                                      onTap: () async {
                                                                                        var val = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ChooseGoods()));
                                                                                        if (val) {
                                                                                          setState(() {});
                                                                                        }
                                                                                      },
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            width: media.width * 0.7,
                                                                                            child: Text(
                                                                                              goodsTypeList.firstWhere((e) => e['id'] == int.parse(selectedGoodsId))['goods_type_name'] + ' (' + goodsSize + ')',
                                                                                              style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: buttonColor),
                                                                                              maxLines: 1,
                                                                                              overflow: TextOverflow.ellipsis,
                                                                                            ),
                                                                                          ),
                                                                                          Icon(
                                                                                            Icons.arrow_forward_ios,
                                                                                            size: media.width * 0.04,
                                                                                            color: buttonColor,
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              )
                                                                            : Container(),
                                                                        Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            (choosenVehicle != null && widget.type != 1)
                                                                                ? Container(
                                                                                    padding: EdgeInsets.symmetric(
                                                                                      horizontal: media.width * 0.05,
                                                                                      vertical: media.width * 0.02,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(20.r),
                                                                                      color: Colors.blue[200],
                                                                                    ),
                                                                                    height: media.width * 0.106,
                                                                                    width: media.width * 0.8,
                                                                                    alignment: Alignment.center,
                                                                                    child: SingleChildScrollView(
                                                                                        scrollDirection: Axis.horizontal,
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            showModalBottomSheet(
                                                                                                context: context,
                                                                                                isScrollControlled: true,
                                                                                                builder: (context) {
                                                                                                  return ChoosePaymentMethodContainer(
                                                                                                    type: widget.type,
                                                                                                    onTap: () {
                                                                                                      setState(() {
                                                                                                        payingVia = choosenInPopUp;
                                                                                                      });
                                                                                                      Navigator.pop(context);
                                                                                                    },
                                                                                                  );
                                                                                                });
                                                                                          },
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            children: [
                                                                                              (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                  ? Image.asset(
                                                                                                      'assets/images/cash-on-delivery.png',
                                                                                                      width: media.width * 0.07,
                                                                                                      height: media.width * 0.7,
                                                                                                      fit: BoxFit.contain,
                                                                                                    )
                                                                                                  : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                                                      ? Image.asset(
                                                                                                          'assets/images/wallet (1).png',
                                                                                                          width: media.width * 0.07,
                                                                                                          height: media.width * 0.07,
                                                                                                          fit: BoxFit.contain,
                                                                                                        )
                                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                          ? Image.asset(
                                                                                                              "assets/images/debit-card.png",
                                                                                                              width: media.width * 0.07,
                                                                                                              height: media.width * 0.07,
                                                                                                              fit: BoxFit.contain,
                                                                                                            )
                                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                                                              ? Image.asset(
                                                                                                                  'assets/images/upi.png',
                                                                                                                  width: media.width * 0.07,
                                                                                                                  height: media.width * 0.07,
                                                                                                                  fit: BoxFit.contain,
                                                                                                                )
                                                                                                              : Container(),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.02,
                                                                                              ),
                                                                                              MyText(
                                                                                                text: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? languages[choosenLanguage]['text_cash']
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                                                        ? languages[choosenLanguage]['text_wallet']
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                            ? languages[choosenLanguage]['text_card']
                                                                                                            : languages[choosenLanguage]['text_upi'],
                                                                                                size: media.width * sixteen,
                                                                                                fontweight: FontWeight.w600,
                                                                                                color: Colors.white,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.03,
                                                                                              ),
                                                                                              RotatedBox(
                                                                                                quarterTurns: 1,
                                                                                                child: Icon(
                                                                                                  Icons.arrow_forward_ios,
                                                                                                  color: Colors.white,
                                                                                                  size: media.width * 0.03,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        )),
                                                                                  )
                                                                                : (choosenVehicle != null && widget.type == 1)
                                                                                    ? InkWell(
                                                                                        onTap: () {
                                                                                          showModalBottomSheet(
                                                                                              context: context,
                                                                                              isScrollControlled: true,
                                                                                              builder: (context) {
                                                                                                return ChoosePaymentMethodContainer(
                                                                                                  type: widget.type,
                                                                                                  onTap: () {
                                                                                                    setState(() {
                                                                                                      payingVia = choosenInPopUp;
                                                                                                    });
                                                                                                    Navigator.pop(context);
                                                                                                  },
                                                                                                );
                                                                                              });
                                                                                        },
                                                                                        child: SizedBox(
                                                                                          height: media.width * 0.106,
                                                                                          width: media.width * 0.4,
                                                                                          child: SingleChildScrollView(
                                                                                            scrollDirection: Axis.horizontal,
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              children: [
                                                                                                (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/cash.png',
                                                                                                        width: media.width * 0.07,
                                                                                                        height: media.width * 0.07,
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/wallet.png',
                                                                                                            width: media.width * 0.07,
                                                                                                            height: media.width * 0.07,
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/card.png',
                                                                                                                width: media.width * 0.07,
                                                                                                                height: media.width * 0.07,
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'upi')
                                                                                                                ? Image.asset(
                                                                                                                    'assets/images/upi.png',
                                                                                                                    width: media.width * 0.07,
                                                                                                                    height: media.width * 0.07,
                                                                                                                    fit: BoxFit.contain,
                                                                                                                  )
                                                                                                                : Container(),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.02,
                                                                                                ),
                                                                                                MyText(
                                                                                                  text: (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                      ? languages[choosenLanguage]['text_cash']
                                                                                                      : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'wallet')
                                                                                                          ? languages[choosenLanguage]['text_wallet']
                                                                                                          : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                              ? languages[choosenLanguage]['text_card']
                                                                                                              : languages[choosenLanguage]['text_upi'],
                                                                                                  size: media.width * sixteen,
                                                                                                  fontweight: FontWeight.w600,
                                                                                                  color: (isDarkTheme == true) ? Colors.white : Colors.black,
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.03,
                                                                                                ),
                                                                                                RotatedBox(
                                                                                                  quarterTurns: 1,
                                                                                                  child: Icon(
                                                                                                    Icons.arrow_forward_ios,
                                                                                                    color: textColor,
                                                                                                    size: media.width * 0.03,
                                                                                                  ),
                                                                                                )
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                    : Container(),
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              20.h,
                                                                        ),
                                                                        ((userDetails['enable_driver_preference_for_user'] != '1' && userDetails['enable_pet_preference_for_user'] != '1' && userDetails['enable_luggage_preference_for_user'] != '1') ||
                                                                                choosenTransportType == 1 ||
                                                                                userDetails['enable_modules_for_applications'] == 'delivery')
                                                                            ? Container()
                                                                            : Container(
                                                                                margin: EdgeInsets.only(left: media.width * 0.05, right: media.width * 0.05),
                                                                                //height: 50.h,
                                                                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                                                                decoration: BoxDecoration(
                                                                                  borderRadius: BorderRadius.circular(20.r),
                                                                                  color: Colors.blue[200],
                                                                                ),
                                                                                alignment: Alignment.center,
                                                                                child: Center(
                                                                                  child: Column(
                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Row(
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                        children: [
                                                                                          InkWell(
                                                                                            onTap: () {
                                                                                              if (addPetPreferences == true) {
                                                                                                choosePets = true;
                                                                                              } else {
                                                                                                choosePets = false;
                                                                                              }
                                                                                              if (addLuggagePreferences == true) {
                                                                                                chooseLuggages = true;
                                                                                              } else {
                                                                                                chooseLuggages = false;
                                                                                              }
                                                                                              showModalBottomSheet(
                                                                                                  context: context,
                                                                                                  isScrollControlled: true,
                                                                                                  builder: (context) {
                                                                                                    return ChoosePreferencesContainer(
                                                                                                      type: widget.type,
                                                                                                      onTap: () {
                                                                                                        setState(() {
                                                                                                          addLuggagePreferences = chooseLuggages;
                                                                                                          addPetPreferences = choosePets;
                                                                                                        });
                                                                                                        Navigator.pop(context);
                                                                                                      },
                                                                                                    );
                                                                                                  });
                                                                                            },
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                                              children: [
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.05,
                                                                                                  width: media.width * 0.075,
                                                                                                  child: Image.asset(
                                                                                                    'assets/images/Tune.png',
                                                                                                    color: Colors.white,
                                                                                                  ),
                                                                                                ),
                                                                                                MyText(
                                                                                                  text: languages[choosenLanguage]['text_ride_preference'],
                                                                                                  size: 14.sp,
                                                                                                  fontweight: FontWeight.w600,
                                                                                                  color: Colors.white,
                                                                                                ),
                                                                                                if (addPetPreferences == true || addLuggagePreferences == true)
                                                                                                  MyText(
                                                                                                    text: ' :- ',
                                                                                                    size: media.width * fourteen,
                                                                                                    fontweight: FontWeight.w600,
                                                                                                    color: Colors.white,
                                                                                                  ),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.025,
                                                                                                ),
                                                                                                if (addPetPreferences == true)
                                                                                                  MyText(
                                                                                                    text: languages[choosenLanguage]['text_pets'],
                                                                                                    size: media.width * fourteen,
                                                                                                    fontweight: FontWeight.w600,
                                                                                                    color: Colors.grey,
                                                                                                  ),
                                                                                                if (addPetPreferences == true && addLuggagePreferences == true)
                                                                                                  MyText(
                                                                                                    text: ', ',
                                                                                                    size: media.width * fourteen,
                                                                                                    fontweight: FontWeight.w600,
                                                                                                    color: Colors.grey,
                                                                                                  ),
                                                                                                if (addLuggagePreferences == true)
                                                                                                  MyText(
                                                                                                    text: languages[choosenLanguage]['text_luggages'],
                                                                                                    size: media.width * fourteen,
                                                                                                    fontweight: FontWeight.w600,
                                                                                                    color: Colors.grey,
                                                                                                  ),
                                                                                                SizedBox(
                                                                                                  width: media.width * 0.025,
                                                                                                ),
                                                                                                (addPetPreferences == false && addLuggagePreferences == false)
                                                                                                    ? Container()
                                                                                                    : Icon(
                                                                                                        // Icons.arrow_forward_ios,
                                                                                                        Icons.edit,
                                                                                                        size: media.width * 0.03,
                                                                                                        color: Colors.grey,
                                                                                                      )
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                        SizedBox(
                                                                          height:
                                                                              20.h,
                                                                        ),
                                                                        (selectedGoodsId == '' &&
                                                                                choosenTransportType == 1)
                                                                            ? Button(
                                                                                width: media.width * 0.9,
                                                                                onTap: () async {
                                                                                  var val = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ChooseGoods()));
                                                                                  if (val) {
                                                                                    setState(() {});
                                                                                  }
                                                                                },
                                                                                text: languages[choosenLanguage]['text_choose_goods'],
                                                                              )
                                                                            : SizedBox(
                                                                                width: media.width * 0.9,
                                                                                child: Column(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    (userDetails['show_ride_later_feature'] == true && ((widget.type == null) ? (etaDetails[choosenVehicle]['enable_bidding'] == null || etaDetails[choosenVehicle]['enable_bidding'] == false) : true) && isOutStation == false)
                                                                                        ? Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                            children: [
                                                                                              Expanded(
                                                                                                child: InkWell(
                                                                                                  onTap: () async {
                                                                                                    if (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['has_discount'] == true && etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['discounted_totel'])) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) || ((rentalOption.isNotEmpty && (etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['fare_amount']) && rentalOption[choosenVehicle]['has_discount'] == false) || (rentalOption.isNotEmpty && rentalOption[choosenVehicle]['has_discount'] == true && etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['discounted_totel']) || rentalOption.isNotEmpty && rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) {
                                                                                                      if (choosenVehicle != null) {
                                                                                                        setState(() {
                                                                                                          choosenDateTime = DateTime.now().add(Duration(minutes: int.parse(userDetails['user_can_make_a_ride_after_x_miniutes'])));
                                                                                                          // _dateTimePicker = true;
                                                                                                        });

                                                                                                        showModalBottomSheet(
                                                                                                            context: context,
                                                                                                            isScrollControlled: true,
                                                                                                            // isDismissible: false,
                                                                                                            builder: (context) {
                                                                                                              return RideLaterBottomSheet(
                                                                                                                type: widget.type,
                                                                                                              );
                                                                                                            });
                                                                                                      }
                                                                                                    } else {
                                                                                                      setState(() {
                                                                                                        islowwalletbalance = true;
                                                                                                      });
                                                                                                    }
                                                                                                  },
                                                                                                  child: (!confirmRideLater)
                                                                                                      ? Container(
                                                                                                          decoration: BoxDecoration(
                                                                                                            color: Colors.blue[200],
                                                                                                            borderRadius: BorderRadius.circular(20.r),
                                                                                                          ),
                                                                                                          //   backgroundColor: Colors.blue[200],
                                                                                                          //    height: media.width * 0.12,
                                                                                                          //  width: media.width * 0.12,
                                                                                                          //   decoration: BoxDecoration(color: page, borderRadius: BorderRadius.circular(media.width * 0.02), border: Border.all(color: textColor)),
                                                                                                          padding: EdgeInsets.symmetric(
                                                                                                            vertical: 10.h,
                                                                                                            //horizontal: media.width * 0.01,
                                                                                                          ),
                                                                                                          child: (confirmRideLater == false)
                                                                                                              ? Row(
                                                                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                  children: [
                                                                                                                    Icon(
                                                                                                                      Icons.access_time,
                                                                                                                      size: media.width * sixteen,
                                                                                                                      color: Colors.white,
                                                                                                                    ),
                                                                                                                    MyText(
                                                                                                                      text: languages[choosenLanguage]['text_ride_later'],
                                                                                                                      size: media.width * twelve,
                                                                                                                      color: Colors.white,
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                )
                                                                                                              : MyText(
                                                                                                                  text: DateFormat().format(choosenDateTime).toString(),
                                                                                                                  size: media.width * twelve,
                                                                                                                ),
                                                                                                        )
                                                                                                      : Container(
                                                                                                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                                                                                          decoration: BoxDecoration(
                                                                                                            borderRadius: BorderRadius.circular(20.r),
                                                                                                            color: Colors.blue[200],
                                                                                                          ),
                                                                                                          alignment: Alignment.center,
                                                                                                          child: Row(
                                                                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                            children: [
                                                                                                              Text(DateFormat().format(choosenDateTime).toString().split(" ")[1] + DateFormat().format(choosenDateTime).toString().split(" ")[2],
                                                                                                                  style: GoogleFonts.cairo(
                                                                                                                    fontSize: 12.sp,
                                                                                                                    fontWeight: FontWeight.w400,
                                                                                                                    color: Colors.white,
                                                                                                                  )),
                                                                                                              SizedBox(
                                                                                                                width: 10.w,
                                                                                                              ),
                                                                                                              Text(DateFormat().format(choosenDateTime).toString().split(" ")[3],
                                                                                                                  style: GoogleFonts.cairo(
                                                                                                                    fontSize: 12.sp,
                                                                                                                    fontWeight: FontWeight.w400,
                                                                                                                    color: Colors.white,
                                                                                                                  )),
                                                                                                            ],
                                                                                                          ),
                                                                                                        ),
                                                                                                ),
                                                                                              ),
                                                                                              (choosenVehicle != null && (widget.type == 1 || etaDetails[choosenVehicle]['enable_bidding'] == null || etaDetails[choosenVehicle]['enable_bidding'] == false) && widget.type != 2 && isOneWayTrip == true)
                                                                                                  ? Row(
                                                                                                      children: [
                                                                                                        InkWell(
                                                                                                          onTap: () {
                                                                                                            // setState(() {
                                                                                                            //   addCoupon =
                                                                                                            //       true;
                                                                                                            // });

                                                                                                            showModalBottomSheet(
                                                                                                                context: context,
                                                                                                                isScrollControlled: true,
                                                                                                                builder: (context) {
                                                                                                                  return ApplyCouponsContainer(
                                                                                                                    type: widget.type,
                                                                                                                  );
                                                                                                                });
                                                                                                          },
                                                                                                          child: Container(
                                                                                                            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                                                                                                            margin: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                                                                                                            //  height: media.width * 0.106,
                                                                                                            //width: media.width * 0.4,
                                                                                                            decoration: BoxDecoration(
                                                                                                              color: Colors.blue[200],
                                                                                                              borderRadius: BorderRadius.circular(20.r),
                                                                                                            ),
                                                                                                            child: Row(
                                                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                              children: [
                                                                                                                MyText(
                                                                                                                  text: languages[choosenLanguage]['text_coupons'],
                                                                                                                  size: media.width * fourteen,
                                                                                                                  fontweight: FontWeight.w600,
                                                                                                                  color: Colors.white,
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),

                                                                                                        //choses data
                                                                                                      ],
                                                                                                    )
                                                                                                  : Container(),
                                                                                            ],
                                                                                          )
                                                                                        : Container(),
                                                                                    SizedBox(
                                                                                      height: 20.h,
                                                                                    ),
                                                                                    Button(
                                                                                        borcolor: Colors.black,
                                                                                        // width: ((userDetails['show_ride_later_feature'] == true))
                                                                                        //     ? ((widget.type == null) ? (etaDetails[choosenVehicle]['enable_bidding'] == null || etaDetails[choosenVehicle]['enable_bidding'] == false) : true) && !isOutStation
                                                                                        //         ? (confirmRideLater == false)
                                                                                        //             ? media.width * 0.75
                                                                                        //             : media.width * 0.68
                                                                                        //         : media.width * 0.89
                                                                                        //     : media.width * 0.89,
                                                                                        onTap: () async {
                                                                                          if ((widget.type == 2) || (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['has_discount'] == true && etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['discounted_totel'])) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) || ((rentalOption.isNotEmpty && (etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['fare_amount']) && rentalOption[choosenVehicle]['has_discount'] == false) || (rentalOption.isNotEmpty && rentalOption[choosenVehicle]['has_discount'] == true && etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['discounted_totel']) || rentalOption.isNotEmpty && rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet'))) {
                                                                                            if (((widget.type == null) ? (etaDetails[choosenVehicle]['enable_bidding'] == true) : false) || isOutStation) {
                                                                                              if (isOutStation) {
                                                                                                print('isOutStation11');
                                                                                                if (isOneWayTrip && nofromdate) {
                                                                                                  setState(() {
                                                                                                    _showInfoInt = choosenVehicle;
                                                                                                    // _showInfo = true;
                                                                                                    showModalBottomSheet(
                                                                                                        context: context,
                                                                                                        isScrollControlled: true,
                                                                                                        builder: (context) {
                                                                                                          return CreateRequestBottomSheet(
                                                                                                            type: widget.type,
                                                                                                            showInfoInt: _showInfoInt,
                                                                                                            fromDate: fromDate,
                                                                                                            geo: geo,
                                                                                                            isOneWayTrip: isOneWayTrip,
                                                                                                            toDate: toDate,
                                                                                                            amount: etaDetails[choosenVehicle]['total'].toString(),
                                                                                                          );
                                                                                                        });
                                                                                                  });
                                                                                                } else {
                                                                                                  print('isOutStation12');
                                                                                                  if (!nofromdate || toDate == null) {
                                                                                                    setState(() {
                                                                                                      _isDateTimebottom = 0;
                                                                                                      if (!nofromdate) {
                                                                                                        isFromDate = true;
                                                                                                      } else {
                                                                                                        isFromDate = false;
                                                                                                        toDate = fromDate.add(const Duration(days: 1, minutes: 2));
                                                                                                      }
                                                                                                    });
                                                                                                    Future.delayed(const Duration(milliseconds: 200), () {
                                                                                                      setState(() {
                                                                                                        if (isOneWayTrip) {
                                                                                                          _dateTimeHeight = media.height * 0.45;
                                                                                                        } else {
                                                                                                          _dateTimeHeight = media.height * 0.5;
                                                                                                        }
                                                                                                      });
                                                                                                    });
                                                                                                  } else {
                                                                                                    print('isOutStation13');
                                                                                                    setState(() {
                                                                                                      _showInfoInt = choosenVehicle;
                                                                                                      // _showInfo = true;
                                                                                                      showModalBottomSheet(
                                                                                                          context: context,
                                                                                                          isScrollControlled: true,
                                                                                                          builder: (context) {
                                                                                                            return CreateRequestBottomSheet(
                                                                                                              type: widget.type,
                                                                                                              showInfoInt: _showInfoInt,
                                                                                                              fromDate: fromDate,
                                                                                                              geo: geo,
                                                                                                              isOneWayTrip: isOneWayTrip,
                                                                                                              toDate: toDate,
                                                                                                              amount: etaDetails[choosenVehicle]['total'].toString(),
                                                                                                            );
                                                                                                          });
                                                                                                    });
                                                                                                  }
                                                                                                }
                                                                                              } else {
                                                                                                print('isOutStation14');
                                                                                                setState(() {
                                                                                                  _showInfoInt = choosenVehicle;
                                                                                                  // _showInfo = true;
                                                                                                });
                                                                                                showModalBottomSheet(
                                                                                                    context: context,
                                                                                                    isScrollControlled: true,
                                                                                                    builder: (context) {
                                                                                                      return CreateRequestBottomSheet(
                                                                                                        type: widget.type,
                                                                                                        showInfoInt: _showInfoInt,
                                                                                                        fromDate: fromDate,
                                                                                                        geo: geo,
                                                                                                        isOneWayTrip: isOneWayTrip,
                                                                                                        toDate: toDate,
                                                                                                        amount: etaDetails[choosenVehicle]['total'].toString(),
                                                                                                      );
                                                                                                    });
                                                                                              }
                                                                                            } else {
                                                                                              setState(() {
                                                                                                isLoading = true;
                                                                                              });
                                                                                              print('isOutStation15');
                                                                                              dynamic result;
                                                                                              if (choosenVehicle != null) {
                                                                                                if (confirmRideLater == true) {
                                                                                                  if (widget.type != 1) {
                                                                                                    if (etaDetails[choosenVehicle]['has_discount'] == false) {
                                                                                                      dynamic val;
                                                                                                      setState(() {
                                                                                                        isLoading = true;
                                                                                                      });
                                                                                                      if (choosenTransportType == 0) {
                                                                                                        print('createRequestLater 1234');

// Debug print: Print the JSON payload being sent
                                                                                                        var jsonPayload = (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                            ? {
                                                                                                                'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                'drop_lat': addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                'drop_lng': addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                'poly_line': polyString,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                'drop_address': addressList.firstWhere((e) => e.type == 'drop').address,
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': 1,
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                // "rental_pack_id" : etaDetails[rentalChoosenOption]['id'],
                                                                                                                'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                              }
                                                                                                            : {
                                                                                                                'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': 1,
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                // "rental_pack_id" : etaDetails[rentalChoosenOption]['id'],
                                                                                                                'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                              };

                                                                                                        print('JSON Payload: $jsonPayload');

                                                                                                        val = await createRequestLater(jsonEncode(jsonPayload), 'api/v1/request/create');

                                                                                                        print("------------>11111");
                                                                                                      } else {
                                                                                                        print("------------>22222");
                                                                                                        if (dropStopList.isNotEmpty) {
                                                                                                          val = await createRequestLater(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'poly_line': polyString,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': 1,
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        } else {
                                                                                                          print("------------>3333333");
                                                                                                          val = await createRequestLater(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'poly_line': polyString,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': 1,
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        }
                                                                                                      }
                                                                                                      setState(() {
                                                                                                        if (val == 'success') {
                                                                                                          isLoading = false;
                                                                                                          showModalBottomSheet(
                                                                                                              context: context,
                                                                                                              isScrollControlled: false,
                                                                                                              isDismissible: false,
                                                                                                              builder: (context) {
                                                                                                                return const SuccessPopUp();
                                                                                                              });
                                                                                                        }
                                                                                                      });
                                                                                                    } else {
                                                                                                      dynamic val;
                                                                                                      setState(() {
                                                                                                        isLoading = true;
                                                                                                      });

                                                                                                      if (choosenTransportType == 0) {
                                                                                                        val = await createRequestLater(
                                                                                                            (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                                ? jsonEncode({
                                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                    'drop_lat': addressList.firstWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                    'drop_lng': addressList.firstWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                    'poly_line': polyString,
                                                                                                                    'ride_type': 1,
                                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                        ? 0
                                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                            ? 1
                                                                                                                            : 2,
                                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                    'drop_address': addressList.firstWhere((e) => e.type == 'drop').address,
                                                                                                                    'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                    'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                    'is_later': true,
                                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                    'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                    'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                  })
                                                                                                                : jsonEncode({
                                                                                                                    'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                    'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                    'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                    'ride_type': 1,
                                                                                                                    'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                        ? 0
                                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                            ? 1
                                                                                                                            : 2,
                                                                                                                    'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                    'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                    'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                    'is_later': true,
                                                                                                                    'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                    'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                    'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                  }),
                                                                                                            'api/v1/request/create');
                                                                                                      } else {
                                                                                                        if (dropStopList.isNotEmpty) {
                                                                                                          val = await createRequestLater(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'poly_line': polyString,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': true,
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        } else {
                                                                                                          val = await createRequestLater(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'poly_line': polyString,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                                'is_later': true,
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        }
                                                                                                      }
                                                                                                      setState(() {
                                                                                                        if (val == 'success') {
                                                                                                          isLoading = false;
                                                                                                          showModalBottomSheet(
                                                                                                              context: context,
                                                                                                              isScrollControlled: false,
                                                                                                              isDismissible: false,
                                                                                                              builder: (context) {
                                                                                                                return const SuccessPopUp();
                                                                                                              });
                                                                                                        }
                                                                                                      });
                                                                                                    }
                                                                                                  } else {
                                                                                                    if (rentalOption[choosenVehicle]['has_discount'] == false) {
                                                                                                      dynamic val;
                                                                                                      setState(() {
                                                                                                        isLoading = true;
                                                                                                      });

                                                                                                      if (choosenTransportType == 0) {
                                                                                                        val = await createRequestLater(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                              'is_later': 1,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                              'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                            }),
                                                                                                            'api/v1/request/create');
                                                                                                      } else {
                                                                                                        val = await createRequestLater(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                              'is_later': 1,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                                              'goods_type_quantity': goodsSize,
                                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                                            }),
                                                                                                            'api/v1/request/delivery/create');
                                                                                                      }

                                                                                                      if (val == 'success') {
                                                                                                        setState(() {
                                                                                                          if (val == 'success') {
                                                                                                            isLoading = false;
                                                                                                            showModalBottomSheet(
                                                                                                                context: context,
                                                                                                                isScrollControlled: false,
                                                                                                                isDismissible: false,
                                                                                                                builder: (context) {
                                                                                                                  return const SuccessPopUp();
                                                                                                                });
                                                                                                          }
                                                                                                        });
                                                                                                      } else if (val == 'logout') {
                                                                                                        navigateLogout();
                                                                                                      }
                                                                                                    } else {
                                                                                                      dynamic val;
                                                                                                      setState(() {
                                                                                                        isLoading = true;
                                                                                                      });

                                                                                                      if (choosenTransportType == 0) {
                                                                                                        val = await createRequestLater(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                              'is_later': 1,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                              'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                            }),
                                                                                                            'api/v1/request/create');
                                                                                                      } else {
                                                                                                        val = await createRequestLater(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                                              'trip_start_time': choosenDateTime.toString().substring(0, 19),
                                                                                                              'is_later': 1,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                                              'goods_type_quantity': goodsSize,
                                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                                            }),
                                                                                                            'api/v1/request/delivery/create');
                                                                                                      }

                                                                                                      if (val == 'success') {
                                                                                                        setState(() {
                                                                                                          if (val == 'success') {
                                                                                                            isLoading = false;
                                                                                                            showModalBottomSheet(
                                                                                                                context: context,
                                                                                                                isScrollControlled: false,
                                                                                                                isDismissible: false,
                                                                                                                builder: (context) {
                                                                                                                  return const SuccessPopUp();
                                                                                                                });
                                                                                                          }
                                                                                                        });
                                                                                                      } else if (val == 'logout') {
                                                                                                        navigateLogout();
                                                                                                      }
                                                                                                    }
                                                                                                  }
                                                                                                } else {
                                                                                                  print('isOutStation16');

                                                                                                  print("------>url ${url}api/v1/request/delivery/create");
                                                                                                  if (widget.type != 1) {
                                                                                                    if (etaDetails[choosenVehicle]['has_discount'] == false) {
                                                                                                      if (choosenTransportType == 0) {
                                                                                                        dropStopList.clear();
                                                                                                        if (addressList.length > 2) {
                                                                                                          for (var i = 1; i < addressList.length; i++) {
                                                                                                            dropStopList.add(DropStops(
                                                                                                              order: addressList[i].id,
                                                                                                              latitude: addressList[i].latlng.latitude,
                                                                                                              longitude: addressList[i].latlng.longitude,
                                                                                                              address: addressList[i].address,
                                                                                                            ));
                                                                                                          }

                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'poly_line': polyString,
                                                                                                                'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                              }),
                                                                                                              'api/v1/request/create');
                                                                                                        } else {
                                                                                                          result = await createRequest(
                                                                                                              (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                                  ? jsonEncode({
                                                                                                                      'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                      'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                      'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                      'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                      'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                      'ride_type': 1,
                                                                                                                      'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                          ? 0
                                                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                              ? 1
                                                                                                                              : 2,
                                                                                                                      'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                      'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                      'poly_line': polyString,
                                                                                                                      'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                      'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                    })
                                                                                                                  : jsonEncode({
                                                                                                                      'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                      'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                      'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                      'ride_type': 1,
                                                                                                                      'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                          ? 0
                                                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                              ? 1
                                                                                                                              : 2,
                                                                                                                      'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                      'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                      'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                    }),
                                                                                                              'api/v1/request/create');
                                                                                                        }
                                                                                                      } else {
                                                                                                        if (dropStopList.isNotEmpty) {
                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'poly_line': polyString,
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        } else {
                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'poly_line': polyString,
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'goods_type_quantity': goodsSize
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        }
                                                                                                      }
                                                                                                    } else {
                                                                                                      if (choosenTransportType == 0) {
                                                                                                        dropStopList.clear();
                                                                                                        if (addressList.length > 2) {
                                                                                                          for (var i = 1; i < addressList.length; i++) {
                                                                                                            dropStopList.add(DropStops(
                                                                                                              order: addressList[i].id,
                                                                                                              latitude: addressList[i].latlng.latitude,
                                                                                                              longitude: addressList[i].latlng.longitude,
                                                                                                              address: addressList[i].address,
                                                                                                            ));
                                                                                                          }

                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'discounted_total': etaDetails[choosenVehicle]['discounted_totel'],
                                                                                                                'poly_line': polyString,
                                                                                                                'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                              }),
                                                                                                              'api/v1/request/create');
                                                                                                        } else {
                                                                                                          result = await createRequest(
                                                                                                              (addressList.where((element) => element.type == 'drop').isNotEmpty)
                                                                                                                  ? jsonEncode({
                                                                                                                      'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                      'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                      'drop_lat': addressList.lastWhere((e) => e.type == 'drop').latlng.latitude,
                                                                                                                      'drop_lng': addressList.lastWhere((e) => e.type == 'drop').latlng.longitude,
                                                                                                                      'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                      'ride_type': 1,
                                                                                                                      'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                          ? 0
                                                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                              ? 1
                                                                                                                              : 2,
                                                                                                                      'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                      'drop_address': addressList.lastWhere((e) => e.type == 'drop').address,
                                                                                                                      'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                      'discounted_total': etaDetails[choosenVehicle]['discounted_totel'],
                                                                                                                      'poly_line': polyString,
                                                                                                                      'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                      'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                    })
                                                                                                                  : jsonEncode({
                                                                                                                      'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                                      'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                                      'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                      'ride_type': 1,
                                                                                                                      'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                          ? 0
                                                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                              ? 1
                                                                                                                              : 2,
                                                                                                                      'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                                      'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                      'discounted_total': etaDetails[choosenVehicle]['discounted_totel'],
                                                                                                                      'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                                      'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                                    }),
                                                                                                              'api/v1/request/create');
                                                                                                        }
                                                                                                      } else {
                                                                                                        if (dropStopList.isNotEmpty) {
                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'stops': jsonEncode(dropStopList),
                                                                                                                'goods_type_quantity': goodsSize,
                                                                                                                'discounted_total': etaDetails[choosenVehicle]['discounted_totel'],
                                                                                                                'poly_line': polyString
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        } else {
                                                                                                          result = await createRequest(
                                                                                                              jsonEncode({
                                                                                                                'pick_lat': addressList[0].latlng.latitude,
                                                                                                                'pick_lng': addressList[0].latlng.longitude,
                                                                                                                'drop_lat': addressList[addressList.length - 1].latlng.latitude,
                                                                                                                'drop_lng': addressList[addressList.length - 1].latlng.longitude,
                                                                                                                'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                                                                                                                'ride_type': 1,
                                                                                                                'payment_opt': (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                    ? 0
                                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                        ? 1
                                                                                                                        : 2,
                                                                                                                'pick_address': addressList[0].address,
                                                                                                                'drop_address': addressList[addressList.length - 1].address,
                                                                                                                'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                                                                                                                'request_eta_amount': etaDetails[choosenVehicle]['total'],
                                                                                                                'pickup_poc_name': addressList[0].name,
                                                                                                                'pickup_poc_mobile': addressList[0].number,
                                                                                                                'pickup_poc_instruction': addressList[0].instructions,
                                                                                                                'drop_poc_name': addressList[addressList.length - 1].name,
                                                                                                                'drop_poc_mobile': addressList[addressList.length - 1].number,
                                                                                                                'drop_poc_instruction': addressList[addressList.length - 1].instructions,
                                                                                                                'goods_type_id': selectedGoodsId.toString(),
                                                                                                                'goods_type_quantity': goodsSize,
                                                                                                                'discounted_total': etaDetails[choosenVehicle]['discounted_totel'],
                                                                                                                'poly_line': polyString
                                                                                                              }),
                                                                                                              'api/v1/request/delivery/create');
                                                                                                        }
                                                                                                      }
                                                                                                    }
                                                                                                  } else {
                                                                                                    print('isOutStation17');
                                                                                                    if (rentalOption[choosenVehicle]['has_discount'] == false) {
                                                                                                      if (choosenTransportType == 0) {
                                                                                                        result = await createRequest(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                              'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                            }),
                                                                                                            'api/v1/request/create');
                                                                                                      } else {
                                                                                                        result = await createRequest(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                                              'goods_type_quantity': goodsSize
                                                                                                            }),
                                                                                                            'api/v1/request/delivery/create');
                                                                                                      }
                                                                                                    } else {
                                                                                                      print('isOutStation18');
                                                                                                      print("------>url ${url}api/v1/request/create");
                                                                                                      if (choosenTransportType == 0) {
                                                                                                        result = await createRequest(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'discounted_total': rentalOption[choosenVehicle]['discounted_totel'],
                                                                                                              'is_pet_available': (addPetPreferences == false) ? false : true,
                                                                                                              'is_luggage_available': (addLuggagePreferences == false) ? false : true
                                                                                                            }),
                                                                                                            'api/v1/request/create');
                                                                                                      } else {
                                                                                                        print('isOutStation19');
                                                                                                        result = await createRequest(
                                                                                                            jsonEncode({
                                                                                                              'pick_lat': addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
                                                                                                              'pick_lng': addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
                                                                                                              'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                                                                                                              'ride_type': 1,
                                                                                                              'payment_opt': (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'card')
                                                                                                                  ? 0
                                                                                                                  : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] == 'cash')
                                                                                                                      ? 1
                                                                                                                      : 2,
                                                                                                              'pick_address': addressList.firstWhere((e) => e.type == 'pickup').address,
                                                                                                              'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                                                                                                              'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
                                                                                                              'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                                                                                                              'goods_type_id': selectedGoodsId.toString(),
                                                                                                              'goods_type_quantity': goodsSize,
                                                                                                              'pickup_poc_name': addressList[0].name,
                                                                                                              'pickup_poc_mobile': addressList[0].number,
                                                                                                              'pickup_poc_instruction': addressList[0].instructions,
                                                                                                              'discounted_total': rentalOption[choosenVehicle]['discounted_totel']
                                                                                                            }),
                                                                                                            'api/v1/request/delivery/create');
                                                                                                      }
                                                                                                    }
                                                                                                  }
                                                                                                }
                                                                                                if (result == 'logout') {
                                                                                                  navigateLogout();
                                                                                                } else if (result == 'success') {
                                                                                                  timer();
                                                                                                }
                                                                                                setState(() {
                                                                                                  isLoading = false;
                                                                                                });
                                                                                              }
                                                                                            }
                                                                                          } else {
                                                                                            setState(() {
                                                                                              islowwalletbalance = true;
                                                                                            });
                                                                                          }
                                                                                        },
                                                                                        text: (confirmRideLater == true || isOutStation) ? languages[choosenLanguage]['text_schedule'] : languages[choosenLanguage]['text_book_now']),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            : Container(),
                                              ))
                                          : Container()
                                      : Container(),

                                  //no driver found
                                  (noDriverFound == true)
                                      ? BookingStatusSheet(
                                          title: languages[choosenLanguage]
                                              ['text_nodriver'],
                                          actionLabel:
                                              languages[choosenLanguage]
                                                  ['text_tryagain'],
                                          icon: Icons.local_taxi_rounded,
                                          onAction: () async {
                                            setState(() {
                                              noDriverFound = false;
                                            });
                                          },
                                        )
                                      : Container(),

                                  //internal server error
                                  (tripReqError == true)
                                      ? BookingStatusSheet(
                                          title: tripError,
                                          actionLabel:
                                              languages[choosenLanguage]
                                                  ['text_tryanother'],
                                          icon: Icons.sync_problem_rounded,
                                          onAction: () async {
                                            setState(() {
                                              tripReqError = false;
                                            });
                                          },
                                        )
                                      : Container(),

                                  //service not available

                                  (serviceNotAvailable)
                                      ? BookingStatusSheet(
                                          title: languages[choosenLanguage]
                                              ['text_no_service'],
                                          actionLabel:
                                              languages[choosenLanguage]
                                                  ['text_tryagain'],
                                          icon: Icons.location_off_rounded,
                                          accentColor: const Color(0xffF59E0B),
                                          onAction: () async {
                                            setState(() {
                                              serviceNotAvailable = false;
                                              isLoading = true;
                                            });

                                            final val = widget.type != 1
                                                ? await etaRequest(
                                                    outstation: isOutStation)
                                                : await rentalEta();
                                            if (!mounted) return;
                                            if (val == 'logout') {
                                              navigateLogout();
                                              return;
                                            }

                                            setState(() {
                                              isLoading = false;
                                              dropConfirmed = val == true &&
                                                  etaDetails.isNotEmpty;
                                              serviceNotAvailable =
                                                  !dropConfirmed;
                                            });
                                          },
                                        )
                                      : Container(),

                                  // low wallet balance
                                  (islowwalletbalance == true)
                                      ? BookingStatusSheet(
                                          title: languages[choosenLanguage]
                                              ['text_wallet_balance_low'],
                                          actionLabel:
                                              languages[choosenLanguage]
                                                  ['text_ok'],
                                          icon: Icons
                                              .account_balance_wallet_rounded,
                                          accentColor: const Color(0xffF59E0B),
                                          onAction: () async {
                                            setState(() {
                                              islowwalletbalance = false;
                                            });
                                          },
                                        )
                                      : Container(),
                                  //choose payment method
                                  (_choosePayment == true)
                                      ? PaymentMethodSheet(
                                          methods: (widget.type != 1
                                                  ? etaDetails[choosenVehicle]
                                                      ['payment_type']
                                                  : rentalOption[choosenVehicle]
                                                      ['payment_type'])
                                              .toString()
                                              .split(',')
                                              .where((method) =>
                                                  method.trim().isNotEmpty)
                                              .map((method) => method.trim())
                                              .toList(),
                                          selectedIndex: payingVia,
                                          copy: Map<String, dynamic>.from(
                                              languages[choosenLanguage]),
                                          promoController: promoKey,
                                          promoStatus: promoStatus is int
                                              ? promoStatus as int
                                              : null,
                                          onClose: () {
                                            setState(() {
                                              _choosePayment = false;
                                              promoKey.clear();
                                              promoCode = '';
                                            });
                                          },
                                          onMethodSelected: (index) {
                                            setState(() {
                                              payingVia = index;
                                            });
                                          },
                                          onPromoChanged: (value) {
                                            setState(() {
                                              promoCode = value;
                                            });
                                          },
                                          onPromoRemoved: () async {
                                            setState(() {
                                              isLoading = true;
                                              promoStatus = null;
                                              promoCode = '';
                                              promoKey.clear();
                                            });
                                            final val = widget.type != 1
                                                ? await etaRequest(
                                                    outstation: isOutStation)
                                                : await rentalEta();
                                            if (!mounted) return;
                                            if (val == 'logout') {
                                              navigateLogout();
                                              return;
                                            }
                                            setState(() {
                                              isLoading = false;
                                            });
                                          },
                                          onConfirm: () async {
                                            if (promoCode.trim().isEmpty) {
                                              setState(() {
                                                _choosePayment = false;
                                              });
                                              return;
                                            }
                                            setState(() {
                                              isLoading = true;
                                            });
                                            final val = widget.type != 1
                                                ? await etaRequestWithPromo(
                                                    outstation: isOutStation)
                                                : await rentalRequestWithPromo();
                                            if (!mounted) return;
                                            if (val == 'logout') {
                                              navigateLogout();
                                              return;
                                            }
                                            setState(() {
                                              isLoading = false;
                                            });
                                          },
                                        )
                                      : Container(),

                                  (userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  null &&
                                              userRequestData['accepted_at'] ==
                                                  null ||
                                          userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  0 &&
                                              userRequestData['accepted_at'] ==
                                                  null)
                                      ? userRequestData.isNotEmpty &&
                                              userRequestData['is_bid_ride'] ==
                                                  1
                                          ? Positioned(
                                              bottom: 0,
                                              child: StreamBuilder<Object>(
                                                  stream: FirebaseDatabase
                                                      .instance
                                                      .ref()
                                                      .child(
                                                          'bid-meta/${userRequestData["id"]}')
                                                      .onValue
                                                      .asBroadcastStream(),
                                                  builder: (context,
                                                      AsyncSnapshot event) {
                                                    List driverList = [];
                                                    Map rideList = {};

                                                    // rideList = event.data!.snapshot;
                                                    if (event.data != null) {
                                                      DataSnapshot snapshots =
                                                          event.data!.snapshot;
                                                      if (snapshots.value !=
                                                          null) {
                                                        rideList = jsonDecode(
                                                            jsonEncode(snapshots
                                                                .value));
                                                        if (updateAmount
                                                            .text.isEmpty) {
                                                          updateAmount.text =
                                                              rideList['price']
                                                                  .toString();
                                                        }
                                                        if (rideList[
                                                                'drivers'] !=
                                                            null) {
                                                          Map driver = rideList[
                                                              'drivers'];
                                                          driver.forEach(
                                                              (key, value) {
                                                            if (driver[key][
                                                                    'is_rejected'] ==
                                                                'none') {
                                                              driverList
                                                                  .add(value);

                                                              if (driverList
                                                                  .isNotEmpty) {
                                                                audioPlayers.play(
                                                                    AssetSource(
                                                                        audio));
                                                              }
                                                            }
                                                          });

                                                          if (driverList
                                                              .isNotEmpty) {
                                                            if (driverBck
                                                                    .isNotEmpty &&
                                                                driverList[0][
                                                                        'user_id'] !=
                                                                    driverBck[0]
                                                                        [
                                                                        'user_id']) {
                                                              driverBck =
                                                                  driverList;
                                                            } else if (driverBck
                                                                .isEmpty) {
                                                              driverBck =
                                                                  driverList;
                                                            }
                                                          } else {
                                                            driverBck =
                                                                driverList;
                                                          }
                                                        } else {
                                                          driverBck =
                                                              driverList;
                                                        }
                                                      }
                                                    }
                                                    if (rideList == {}) {
                                                      userRequestData = {};
                                                      setState(() {});
                                                    }

                                                    return Container(
                                                      width: media.width * 1,
                                                      height: media.height * 1,
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Container(
                                                        width: media.width * 1,
                                                        height: (driverList
                                                                .isNotEmpty)
                                                            ? media.height * 1
                                                            : media.width *
                                                                0.72,
                                                        // height:(driverList.isNotEmpty) ? media.height*1 : media.width*1,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          12),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          12)),
                                                          color: page,
                                                        ),
                                                        padding: (driverList
                                                                .isNotEmpty)
                                                            ? EdgeInsets.fromLTRB(
                                                                0,
                                                                media.width *
                                                                        0.1 +
                                                                    MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top,
                                                                0,
                                                                0)
                                                            : EdgeInsets
                                                                .fromLTRB(
                                                                    0,
                                                                    media.width *
                                                                        0.05,
                                                                    0,
                                                                    media.width *
                                                                        0.05),
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _cancel =
                                                                        true;
                                                                  });
                                                                },
                                                                child: Text(
                                                                  languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_cancel'],
                                                                  style: GoogleFonts.notoSans(
                                                                      fontSize:
                                                                          media.width *
                                                                              sixteen,
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.02,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_findingdriver'],
                                                              style: GoogleFonts.notoSans(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            (driverList
                                                                    .isNotEmpty)
                                                                ? Expanded(
                                                                    child:
                                                                        Container(
                                                                      width:
                                                                          media.width *
                                                                              1,
                                                                      padding: EdgeInsets.fromLTRB(
                                                                          media.width *
                                                                              0.05,
                                                                          media.width * 0.05 +
                                                                              MediaQuery.of(context)
                                                                                  .padding
                                                                                  .top,
                                                                          media.width *
                                                                              0.05,
                                                                          media.width *
                                                                              0.05),
                                                                      // color: Colors.transparent.withOpacity(0.4),
                                                                      child:
                                                                          SingleChildScrollView(
                                                                        child: Column(
                                                                            children: driverList
                                                                                .asMap()
                                                                                .map((key, value) {
                                                                                  return MapEntry(
                                                                                      key,
                                                                                      ValueListenableBuilder(
                                                                                          valueListenable: valueNotifierTimer.value,
                                                                                          builder: (context, value, child) {
                                                                                            var val = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(driverList[key]['bid_time'])).inSeconds;
                                                                                            var calcDistance = calculateDistance(userRequestData['pick_lat'], userRequestData['pick_lng'], double.parse(driverList[key]['lat'].toString()), double.parse(driverList[key]['lng'].toString()));
                                                                                            if (int.parse(val.toString()) >= int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString()) + 5) {
                                                                                              FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}/drivers/driver_${driverList[key]["driver_id"]}').update({
                                                                                                "is_rejected": 'by_user'
                                                                                              });
                                                                                            }
                                                                                            return Container(
                                                                                              margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                                                              decoration:
                                                                                                  BoxDecoration(
                                                                                                      // borderRadius: BorderRadius.circular(10),
                                                                                                      color: page,
                                                                                                      boxShadow: [
                                                                                                    BoxShadow(blurRadius: 2, spreadRadius: 2, color: Colors.black.withOpacity(0.2))
                                                                                                  ]),
                                                                                              child: Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  Container(
                                                                                                    height: 5,
                                                                                                    width: (val < int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) ? (media.width * 0.85 / int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) * (int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString()) - double.parse(val.toString())) : 0,
                                                                                                    color: buttonColor,
                                                                                                  ),
                                                                                                  Container(
                                                                                                    padding: EdgeInsets.all(media.width * 0.05),
                                                                                                    child: Column(
                                                                                                      children: [
                                                                                                        Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              width: media.width * 0.1,
                                                                                                              height: media.width * 0.1,
                                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverList[key]['driver_img']), fit: BoxFit.cover)),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.05,
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                              child: Column(
                                                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                children: [
                                                                                                                  Text(
                                                                                                                    driverList[key]['driver_name'],
                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.left,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                  SizedBox(
                                                                                                                    height: media.width * 0.025,
                                                                                                                  ),
                                                                                                                  Text(
                                                                                                                    '${driverList[key]['vehicle_make']} ${driverList[key]['vehicle_model']}',
                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.left,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.01,
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                              child: Column(
                                                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                                                children: [
                                                                                                                  Text(
                                                                                                                    rideList['currency'] + driverList[key]['price'],
                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.center,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                  SizedBox(
                                                                                                                    height: media.width * 0.025,
                                                                                                                  ),
                                                                                                                  Text(
                                                                                                                    (calcDistance != null) ? '${double.parse((calcDistance / 1000).toString()).toStringAsFixed(0)} km' : '',
                                                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                                                    textAlign: TextAlign.center,
                                                                                                                    maxLines: 1,
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                        SizedBox(
                                                                                                          height: media.width * 0.05,
                                                                                                        ),
                                                                                                        Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                          children: [
                                                                                                            Button(
                                                                                                              onTap: () async {
                                                                                                                setState(() {
                                                                                                                  isLoading = true;
                                                                                                                });
                                                                                                                var val = await acceptRequest(jsonEncode({
                                                                                                                  'driver_id': driverList[key]['driver_id'],
                                                                                                                  'request_id': userRequestData['id'],
                                                                                                                  'accepted_ride_fare': driverList[key]['price'].toString(),
                                                                                                                  'offerred_ride_fare': rideList['price'],
                                                                                                                }));
                                                                                                                if (val == 'success') {
                                                                                                                  await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}').remove();
                                                                                                                }
                                                                                                                setState(() {
                                                                                                                  isLoading = false;
                                                                                                                });
                                                                                                              },
                                                                                                              text: languages[choosenLanguage]['text_accept'],
                                                                                                              width: media.width * 0.35,
                                                                                                              color: online,
                                                                                                              borcolor: online,
                                                                                                              textcolor: page,
                                                                                                            ),
                                                                                                            // SizedBox(height: media.width*0.025,),
                                                                                                            Button(
                                                                                                              onTap: () async {
                                                                                                                setState(() {
                                                                                                                  isLoading = true;
                                                                                                                });
                                                                                                                await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}/drivers/driver_${driverList[key]["driver_id"]}').update({"is_rejected": 'by_user'});
                                                                                                                setState(() {
                                                                                                                  isLoading = false;
                                                                                                                });
                                                                                                              },
                                                                                                              text: languages[choosenLanguage]['text_decline'],
                                                                                                              width: media.width * 0.35,
                                                                                                              color: verifyDeclined,
                                                                                                              borcolor: verifyDeclined,
                                                                                                              textcolor: page,
                                                                                                            )
                                                                                                          ],
                                                                                                        )
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            );
                                                                                          }));
                                                                                })
                                                                                .values
                                                                                .toList()),
                                                                      ),
                                                                    ),
                                                                  )
                                                                : Container(),
                                                            if (driverList
                                                                .isEmpty)
                                                              Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      '${languages[choosenLanguage]['text_offered_fare']} : ${rideList['currency']} ${rideList['price']}',
                                                                      style: GoogleFonts.notoSans(
                                                                          fontSize: media.width *
                                                                              sixteen,
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_current_fare'],
                                                                      style: GoogleFonts.notoSans(
                                                                          fontSize: media.width *
                                                                              eighteen,
                                                                          color:
                                                                              textColor,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    padding: EdgeInsets.only(
                                                                        top: media.width *
                                                                            0.02),
                                                                    child: (updateAmount.text.isNotEmpty &&
                                                                            updateAmount.text !=
                                                                                'null')
                                                                        ? Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceEvenly,
                                                                            children: [
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  if (updateAmount.text.isNotEmpty &&
                                                                                      (userRequestData['bidding_low_percentage'] == 0 ||
                                                                                          (double.parse(updateAmount.text.toString()) -
                                                                                                  // 10
                                                                                                  ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) >=
                                                                                              (double.parse(userRequestData['request_eta_amount'].toString()) - ((double.parse(userRequestData['bidding_low_percentage'].toString()) / 100) * double.parse(userRequestData['request_eta_amount'].toString()))))) {
                                                                                    setState(() {
                                                                                      updateAmount.text = (updateAmount.text.isEmpty)
                                                                                          ? (rideList['price'].toString().contains('.'))
                                                                                              ? (double.parse(rideList['price'].toString()) -
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toStringAsFixed(2)
                                                                                              : (int.parse(rideList['price'].toString()) -
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toString()
                                                                                          : (updateAmount.text.toString().contains('.'))
                                                                                              ? (double.parse(updateAmount.text.toString()) -
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toStringAsFixed(2)
                                                                                              : (int.parse(updateAmount.text.toString()) -
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toString();
                                                                                    });
                                                                                  }
                                                                                },
                                                                                child: Container(
                                                                                  width: media.width * 0.2,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(
                                                                                      color: (updateAmount.text.isNotEmpty &&
                                                                                              (userRequestData['bidding_low_percentage'] == 0 ||
                                                                                                  (double.parse(updateAmount.text.toString()) -
                                                                                                          // 10
                                                                                                          ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) >=
                                                                                                      (double.parse(userRequestData['request_eta_amount'].toString()) - ((double.parse(userRequestData['bidding_low_percentage'].toString()) / 100) * double.parse(userRequestData['request_eta_amount'].toString())))))
                                                                                          ? (isDarkTheme)
                                                                                              ? Colors.white
                                                                                              : Colors.black
                                                                                          : borderLines,
                                                                                      borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                                  padding: EdgeInsets.all(media.width * 0.025),
                                                                                  child: Text(
                                                                                    // '-10',
                                                                                    (userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? '-${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}' : '-${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: (isDarkTheme) ? Colors.black : Colors.white),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.4,
                                                                                child: TextField(
                                                                                  enabled: false,
                                                                                  textAlign: TextAlign.center,
                                                                                  keyboardType: TextInputType.number,
                                                                                  controller: updateAmount,
                                                                                  decoration: InputDecoration(
                                                                                    hintText: (rideList.isNotEmpty) ? rideList['price'].toString() : '',
                                                                                    hintStyle: GoogleFonts.notoSans(fontSize: media.width * sixteen, color: textColor),
                                                                                    border: UnderlineInputBorder(borderSide: BorderSide(color: hintColor)),
                                                                                  ),
                                                                                  style: GoogleFonts.notoSans(
                                                                                    color: textColor,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    if (userRequestData['bidding_high_percentage'] == 0 ||
                                                                                        (double.parse(updateAmount.text.toString()) +
                                                                                                // 10
                                                                                                ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) <=
                                                                                            (double.parse(userRequestData['request_eta_amount'].toString()) + ((double.parse(userRequestData['bidding_high_percentage'].toString()) / 100) * double.parse(userRequestData['request_eta_amount'].toString())))) {
                                                                                      updateAmount.text = (updateAmount.text.isEmpty)
                                                                                          ? (rideList['price'].toString().contains('.'))
                                                                                              ? (double.parse(rideList['price'].toString()) +
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toStringAsFixed(2)
                                                                                              : (int.parse(rideList['price'].toString()) +
                                                                                                      // 10
                                                                                                      ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                                                  .toString()
                                                                                          : (updateAmount.text.toString().contains('.'))
                                                                                              ? (double.parse(updateAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toStringAsFixed(2)
                                                                                              : (int.parse(updateAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toString();
                                                                                    }
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  width: media.width * 0.2,
                                                                                  alignment: Alignment.center,
                                                                                  decoration: BoxDecoration(
                                                                                      color: (userRequestData['bidding_high_percentage'] == 0 || (double.parse(updateAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) <= (double.parse(userRequestData['request_eta_amount'].toString()) + ((double.parse(userRequestData['bidding_high_percentage'].toString()) / 100) * double.parse(userRequestData['request_eta_amount'].toString()))))
                                                                                          ? (isDarkTheme)
                                                                                              ? Colors.white
                                                                                              : Colors.black
                                                                                          : borderLines,
                                                                                      borderRadius: BorderRadius.circular(media.width * 0.04)),
                                                                                  padding: EdgeInsets.all(media.width * 0.025),
                                                                                  child: Text(
                                                                                    (userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? '+${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}' : '+${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                                                                    // '+10',
                                                                                    style: GoogleFonts.notoSans(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: (isDarkTheme) ? Colors.black : Colors.white),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          )
                                                                        : Container(),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child:
                                                                        Button(
                                                                      onTap:
                                                                          () async {
                                                                        if (updateAmount
                                                                            .text
                                                                            .isNotEmpty) {
                                                                          setState(
                                                                              () {
                                                                            isLoading =
                                                                                true;
                                                                          });
                                                                          await FirebaseDatabase
                                                                              .instance
                                                                              .ref()
                                                                              .child('bid-meta/${userRequestData["id"]}')
                                                                              .update({
                                                                            'price':
                                                                                updateAmount.text,
                                                                            'updated_at':
                                                                                ServerValue.timestamp,
                                                                          });
                                                                          await FirebaseDatabase
                                                                              .instance
                                                                              .ref()
                                                                              .child('bid-meta/${userRequestData["id"]}/drivers')
                                                                              .remove();
                                                                          setState(
                                                                              () {
                                                                            updateAmount.clear();
                                                                            isLoading =
                                                                                false;
                                                                          });
                                                                        }
                                                                      },
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_update'],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                            )
                                          : Positioned(
                                              bottom: 0,
                                              child: Container(
                                                width: media.width * 1,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  12),
                                                          topRight:
                                                              Radius.circular(
                                                                  12)),
                                                  color: page,
                                                ),
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: media.width * 0.9,
                                                      child: MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_search_captain'],
                                                        size: media.width *
                                                            fourteen,
                                                        color: Colors.blue,
                                                        fontweight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    MyText(
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_finddriverdesc'],
                                                      size: media.width *
                                                          fourteen,
                                                      color: Colors.grey,
                                                      // textAlign: TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    SizedBox(
                                                      height: media.width * 0.4,
                                                      child: Image.asset(
                                                        (userDetails['is_delivery_app'] !=
                                                                    null &&
                                                                userDetails[
                                                                        'is_delivery_app'] ==
                                                                    true)
                                                            ? 'assets/images/ridesearching_delivery.png'
                                                            : 'assets/images/ridesearching.png',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Container(
                                                      height:
                                                          media.width * 0.048,
                                                      width: media.width * 0.9,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(media
                                                                          .width *
                                                                      0.024),
                                                          color: Colors.grey),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Container(
                                                        height:
                                                            media.width * 0.048,
                                                        width: (media.width *
                                                            0.9 *
                                                            (timing /
                                                                userDetails[
                                                                    'maximum_time_for_find_drivers_for_regular_ride'])),
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius
                                                                .circular(media
                                                                        .width *
                                                                    0.024),
                                                            color: buttonColor),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        (timing != null)
                                                            ? Text(
                                                                '${Duration(seconds: timing).toString().substring(3, 7)} mins',
                                                                style: GoogleFonts.cairo(
                                                                    fontSize:
                                                                        12.sp,
                                                                    color: Colors
                                                                        .black),
                                                              )
                                                            : Container()
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    Button(
                                                      onTap: () async {
                                                        bool confirm =
                                                            await showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                            title: Text(
                                                              'تأكيد',
                                                              style: GoogleFonts
                                                                  .cairo(
                                                                      fontSize:
                                                                          12.sp,
                                                                      color: Colors
                                                                          .black),
                                                            ),
                                                            content: Text(
                                                              "متأكد أنك تريد الإلغاء \u{1F97A}", // Unicode للإيموجي 🥹
                                                              style: GoogleFonts
                                                                  .cairo(
                                                                      fontSize:
                                                                          14.sp,
                                                                      color: Colors
                                                                          .grey),
                                                            ),
                                                            actions: [
                                                              Button(
                                                                text: '✅ نعم',
                                                                backgroundcolor:
                                                                    Colors.red,
                                                                onTap: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            true),
                                                              ),
                                                              const SizedBox(
                                                                  height: 10),
                                                              Button(
                                                                text: '❌ لا',
                                                                onTap: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirm) {
                                                          var val =
                                                              await cancelRequest();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        }
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_cancel'],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                          userRequestData['accepted_at'] !=
                                              null)
                                      ? AnimatedPositioned(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          bottom: addressBottom != null
                                              ? -addressBottom
                                              : -(media.height - media.width),
                                          child: GestureDetector(
                                            onVerticalDragStart: (v) {
                                              _cont.jumpTo(0.0);
                                              start = v.globalPosition.dy;
                                              if (addressBottom != null) {
                                                _addressBottom = addressBottom;
                                              } else {
                                                addressBottom = (media.height -
                                                    media.width);
                                                _addressBottom = addressBottom;
                                              }
                                              gesture.clear();
                                            },
                                            onVerticalDragUpdate: (v) {
                                              if ((_addressBottom +
                                                          (v.globalPosition.dy -
                                                              start)) >
                                                      media.height * 0.2 &&
                                                  (_addressBottom +
                                                          (v.globalPosition.dy -
                                                              start)) <
                                                      ((media.height * 1.2) -
                                                          media.width)) {
                                                addressBottom = _addressBottom +
                                                    (v.globalPosition.dy -
                                                        start);
                                              }
                                              setState(() {});
                                            },
                                            onVerticalDragEnd: (v) {},
                                            child: Container(
                                                padding: EdgeInsets.fromLTRB(
                                                    media.width * 0.025,
                                                    media.width * 0.02,
                                                    media.width * 0.025,
                                                    0),
                                                width: media.width * 1,
                                                height: media.height * 1.2,
                                                decoration: BoxDecoration(
                                                    color: page,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    12),
                                                            topRight:
                                                                Radius.circular(
                                                                    12))),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          height: 5,
                                                          width:
                                                              media.width * 0.2,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              color: hintColor),
                                                        )
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.01,
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            media.width * 0.9,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            (userRequestData[
                                                                            'is_trip_start'] !=
                                                                        1 &&
                                                                    userRequestData[
                                                                            'show_otp_feature'] ==
                                                                        true)
                                                                ? Container(
                                                                    width: media
                                                                            .width *
                                                                        0.3,
                                                                    height:
                                                                        media.width *
                                                                            0.1,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(media.width *
                                                                                0.02),
                                                                        color: Colors
                                                                            .grey
                                                                            .withOpacity(0.2)),
                                                                    child: (userRequestData['is_trip_start'] !=
                                                                                1 &&
                                                                            userRequestData['show_otp_feature'] ==
                                                                                true)
                                                                        ? MyText(
                                                                            text:
                                                                                'Otp : ${userRequestData['ride_otp']}',
                                                                            size:
                                                                                media.width * fourteen,
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            fontweight:
                                                                                FontWeight.bold,
                                                                            maxLines:
                                                                                1,
                                                                          )
                                                                        : Container(),
                                                                  )
                                                                : Container(),
                                                          ],
                                                        )),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.025,
                                                    ),
                                                    ((widget.type == null ||
                                                                (widget.type !=
                                                                            1 ||
                                                                        widget.type !=
                                                                            2) &&
                                                                    userRequestData[
                                                                            'is_trip_start'] ==
                                                                        0) &&
                                                            userRequestData[
                                                                        'waiting_charge']
                                                                    .toString() !=
                                                                '0')
                                                        ? Container(
                                                            width: media.width *
                                                                0.9,
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            color: borderColor
                                                                .withOpacity(
                                                                    0.1),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: MyText(
                                                                    text: ((userRequestData['accepted_at'] != null &&
                                                                            userRequestData['arrived_at'] ==
                                                                                null &&
                                                                            userRequestData['is_trip_start'] ==
                                                                                0))
                                                                        ? languages[choosenLanguage]
                                                                            [
                                                                            'text_captain_arrive']
                                                                        : (userRequestData['accepted_at'] != null &&
                                                                                userRequestData['arrived_at'] != null &&
                                                                                userRequestData['is_trip_start'] == 0)
                                                                            ? (userRequestData['is_bid_ride'] == 1)
                                                                                ? languages[choosenLanguage]['text_captain_arrived']
                                                                                : '${languages[choosenLanguage]['text_captain_arrived']}, ${languages[choosenLanguage]['text_waiting_time_text'].toString().replaceAll('5', userRequestData['free_waiting_time_in_mins_before_trip_start'].toString()).replaceAll('**', (userRequestData['requested_currency_symbol'].toString() + userRequestData['waiting_charge'].toString()))}'
                                                                            : (_dist != null)
                                                                                ? languages[choosenLanguage]['text_reaching_destination'].toString().replaceAll('1111', double.parse(((_dist * 2)).toString()).round().toString())
                                                                                : languages[choosenLanguage]['text_onride'],
                                                                    size: media
                                                                            .width *
                                                                        fourteen,
                                                                    color:
                                                                        greyText,
                                                                  ),
                                                                ),
                                                                if ((userRequestData['accepted_at'] != null &&
                                                                        userRequestData['arrived_at'] !=
                                                                            null &&
                                                                        userRequestData['is_trip_start'] ==
                                                                            0) &&
                                                                    (waitingTime /
                                                                                60)
                                                                            .toStringAsFixed(0) !=
                                                                        '0')
                                                                  Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.025),
                                                                    decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                12),
                                                                        color: const Color(0xff5BDD0A)
                                                                            .withOpacity(0.24)),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        MyText(
                                                                          text: languages[choosenLanguage]
                                                                              [
                                                                              'text_waiting_time'],
                                                                          size: media.width *
                                                                              twelve,
                                                                          color:
                                                                              greyText,
                                                                        ),
                                                                        MyText(
                                                                          text:
                                                                              '${(waitingTime / 60).toStringAsFixed(0)} ${languages[choosenLanguage]['text_mins']}',
                                                                          size: media.width *
                                                                              twelve,
                                                                          fontweight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              Colors.orange,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          )
                                                        : Container(),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.01,
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.025),
                                                      width: media.width * 0.9,
                                                      color: borderColor
                                                          .withOpacity(0.1),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.15,
                                                                          width:
                                                                              media.width * 0.15,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            image: DecorationImage(
                                                                                image: NetworkImage(
                                                                                  userRequestData['driverDetail']['data']['profile_picture'],
                                                                                ),
                                                                                fit: BoxFit.cover),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.03,
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.01,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.025,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Row(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .star,
                                                                          color:
                                                                              Colors.orange,
                                                                          size: media.width *
                                                                              0.05,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.005,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              MyText(
                                                                            color:
                                                                                greyText,
                                                                            text: (userRequestData['driverDetail']['data']['rating'] == 0)
                                                                                ? languages[choosenLanguage]['text_no_rating']
                                                                                : userRequestData['driverDetail']['data']['rating'].toString(),
                                                                            size:
                                                                                media.width * fourteen,
                                                                            fontweight:
                                                                                FontWeight.w600,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.01,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: MyText(
                                                                              text: userRequestData['driverDetail']['data']['name'].toString(),
                                                                              size: media.width * fourteen,
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              fontweight: FontWeight.w500),
                                                                        ),
                                                                      ],
                                                                    ),

                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                            child:
                                                                                MyText(
                                                                          text:
                                                                              '${userRequestData['driverDetail']['data']['car_color']} | ${userRequestData['driverDetail']['data']['car_make_name']} | ${userRequestData['driverDetail']['data']['car_model_name']}',
                                                                          size: media.width *
                                                                              twelve,
                                                                          maxLines:
                                                                              2,
                                                                        )),
                                                                      ],
                                                                    ),
//                                                                     Text(
//   userRequestData['data']['user_completed_rides_count'].toString(),
//   style: GoogleFonts.notoSans(
//     fontSize: media.width * fourteen,
//     fontWeight: FontWeight.w500,
//     color: Colors.black,
//   ),
// ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Expanded(
                                                                  child: Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height:
                                                                        media.width *
                                                                            0.3,
                                                                    width: media
                                                                            .width *
                                                                        0.3,
                                                                    child: Image.network(
                                                                        userRequestData['vehicle_type_image']
                                                                            .toString()),
                                                                  ),
                                                                  Text(
                                                                    languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_car_number'],
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Container(
                                                                        padding: EdgeInsets.only(
                                                                            left: media.width *
                                                                                0.025,
                                                                            right:
                                                                                media.width * 0.025),
                                                                        width: media.width *
                                                                            0.3,
                                                                        height: media.width *
                                                                            0.1,
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                Colors.yellow[700],
                                                                            borderRadius: BorderRadius.circular(5),
                                                                            border: Border.all(color: Colors.black, width: 2)),
                                                                        child: FittedBox(
                                                                            fit:
                                                                                BoxFit.fitWidth,
                                                                            child: Text('${userRequestData['driverDetail']['data']['car_number']}')),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ))
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.03,
                                                          ),
                                                          Container(
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  "عدد الطلبات المكتملة للسائق",
                                                                  style: GoogleFonts
                                                                      .notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.04,
                                                                ),
                                                                CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue,
                                                                  radius: media
                                                                          .width *
                                                                      0.04,
                                                                  child: Text(
                                                                    (userRequestData['driver_completed_rides_count'] ??
                                                                            0)
                                                                        .toString(),
                                                                    style: GoogleFonts
                                                                        .notoSans(
                                                                      fontSize:
                                                                          media.width *
                                                                              fourteen,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.03,
                                                          ),
                                                          if (userRequestData[
                                                                  'is_trip_start'] ==
                                                              0)
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                    child:
                                                                        InkWell(
                                                                  onTap:
                                                                      () async {
                                                                    var result = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                const ChatPage()));
                                                                    if (result) {
                                                                      setState(
                                                                          () {});
                                                                    }
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height: media
                                                                            .width *
                                                                        0.12,
                                                                    padding: EdgeInsets.only(
                                                                        left: media.width *
                                                                            0.05,
                                                                        right: media.width *
                                                                            0.05),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(media.width *
                                                                              0.07),
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.2),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Stack(
                                                                          children: [
                                                                            SizedBox(
                                                                              width: media.width * 0.1,
                                                                              child: const Icon(
                                                                                Icons.message,
                                                                                color: Colors.grey,
                                                                              ),
                                                                            ),
                                                                            if (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isNotEmpty)
                                                                              Positioned(
                                                                                  top: media.width * 0.01,
                                                                                  right: media.width * 0.01,
                                                                                  child: Container(
                                                                                    height: media.width * 0.02,
                                                                                    width: media.width * 0.02,
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: verifyDeclined),
                                                                                  ))
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.03,
                                                                        ),
                                                                        Expanded(
                                                                            child:
                                                                                MyText(
                                                                          text:
                                                                              '${languages[choosenLanguage]['text_chatwithdriver']} ${userRequestData['driverDetail']['data']['name'].toString()}',
                                                                          size: media.width *
                                                                              fourteen,
                                                                          color:
                                                                              hintColor,
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ))
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                CallWhatsAppButton(
                                                                  phoneNumber: userRequestData[
                                                                              'driverDetail']
                                                                          [
                                                                          'data']
                                                                      [
                                                                      'mobile'],
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                InkWell(
                                                                  onTap: () {
                                                                    makingPhoneCall(userRequestData['driverDetail']
                                                                            [
                                                                            'data']
                                                                        [
                                                                        'mobile']);
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height: media
                                                                            .width *
                                                                        0.096,
                                                                    width: media
                                                                            .width *
                                                                        0.096,
                                                                    decoration: BoxDecoration(
                                                                        border: Border.all(
                                                                            color: const Color(
                                                                                0xff5BDD0A),
                                                                            width:
                                                                                1),
                                                                        shape: BoxShape
                                                                            .circle),
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Image
                                                                        .asset(
                                                                      'assets/images/call.png',
                                                                      color: const Color(
                                                                          0xff5BDD0A),
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.05,
                                                    ),
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                        controller: _cont,
                                                        physics: (addressBottom !=
                                                                    null &&
                                                                addressBottom <=
                                                                    (media.height *
                                                                        0.25))
                                                            ? const BouncingScrollPhysics()
                                                            : const NeverScrollableScrollPhysics(),
                                                        child: Column(
                                                          children: [
                                                            if (userRequestData[
                                                                    'transport_type'] ==
                                                                'delivery')
                                                              Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    child: Text(
                                                                      '${userRequestData['goods_type']} - ${userRequestData['goods_type_quantity']}',
                                                                      style: GoogleFonts.notoSans(
                                                                          fontSize: media.width *
                                                                              fourteen,
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          color:
                                                                              buttonColor),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                ],
                                                              ),
                                                            (userRequestData[
                                                                            'is_rental'] !=
                                                                        true &&
                                                                    userRequestData[
                                                                            'drop_address'] !=
                                                                        null)
                                                                ? Column(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.03),
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                Colors.grey.withOpacity(0.1),
                                                                            borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              height: media.width * 0.05,
                                                                              width: media.width * 0.05,
                                                                              alignment: Alignment.center,
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.4)
                                                                                  // color: online.withOpacity(0.4)
                                                                                  ),
                                                                              child: Container(
                                                                                height: media.width * 0.025,
                                                                                width: media.width * 0.025,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.4)
                                                                                    // color: online
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.03,
                                                                            ),
                                                                            Expanded(
                                                                                child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_pick_up_location'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w600,
                                                                                ),
                                                                                MyText(
                                                                                  text: userRequestData['pick_address'],
                                                                                  size: media.width * twelve,
                                                                                  color: greyText,
                                                                                  // maxLines: 1,
                                                                                ),
                                                                              ],
                                                                            )),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.02,
                                                                      ),
                                                                      (tripStops
                                                                              .isNotEmpty)
                                                                          ? Column(
                                                                              children: tripStops
                                                                                  .asMap()
                                                                                  .map((i, value) {
                                                                                    return MapEntry(
                                                                                        i,
                                                                                        (i < tripStops.length - 1)
                                                                                            ? Container(
                                                                                                padding: EdgeInsets.all(media.width * 0.03),
                                                                                                margin: EdgeInsets.only(bottom: media.width * 0.02),
                                                                                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                                  children: [
                                                                                                    Container(
                                                                                                      height: media.width * 0.05,
                                                                                                      width: media.width * 0.05,
                                                                                                      alignment: Alignment.center,
                                                                                                      child: MyText(
                                                                                                        text: (i + 1).toString(),
                                                                                                        size: media.width * fourteen,
                                                                                                        color: verifyDeclined,
                                                                                                        fontweight: FontWeight.w600,
                                                                                                      ),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.03,
                                                                                                    ),
                                                                                                    Expanded(
                                                                                                        child: MyText(
                                                                                                      text: tripStops[i]['address'],
                                                                                                      size: media.width * twelve,
                                                                                                      color: greyText,
                                                                                                    )),
                                                                                                  ],
                                                                                                ),
                                                                                              )
                                                                                            : Container());
                                                                                  })
                                                                                  .values
                                                                                  .toList(),
                                                                            )
                                                                          : Container(),
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.03),
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                Colors.grey.withOpacity(0.1),
                                                                            borderRadius: BorderRadius.circular(media.width * 0.02)),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.start,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              height: media.width * 0.05,
                                                                              width: media.width * 0.05,
                                                                              alignment: Alignment.center,
                                                                              child: const Icon(Icons.location_on,
                                                                                  // color: verifyDeclined,
                                                                                  color: Color(0xffF52D56)),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.03,
                                                                            ),
                                                                            Expanded(
                                                                                child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_drop'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w600,
                                                                                ),
                                                                                MyText(
                                                                                  text: userRequestData['drop_address'],
                                                                                  size: media.width * twelve,
                                                                                  color: greyText,
                                                                                  // maxLines: 1,
                                                                                ),
                                                                              ],
                                                                            )),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Container(
                                                                    padding: EdgeInsets.all(
                                                                        media.width *
                                                                            0.03),
                                                                    decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .grey
                                                                            .withOpacity(
                                                                                0.1),
                                                                        borderRadius:
                                                                            BorderRadius.circular(media.width *
                                                                                0.02)),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.05,
                                                                          width:
                                                                              media.width * 0.05,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: Colors.green.withOpacity(0.4)
                                                                              // color: online.withOpacity(0.4)
                                                                              ),
                                                                          child:
                                                                              Container(
                                                                            height:
                                                                                media.width * 0.025,
                                                                            width:
                                                                                media.width * 0.025,
                                                                            decoration: BoxDecoration(
                                                                                shape: BoxShape.circle,
                                                                                color: Colors.green.withOpacity(0.4)
                                                                                // color: online
                                                                                ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.03,
                                                                        ),
                                                                        Expanded(
                                                                            child:
                                                                                Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            MyText(
                                                                              text: languages[choosenLanguage]['text_pick_up_location'],
                                                                              size: media.width * fourteen,
                                                                              fontweight: FontWeight.w600,
                                                                            ),
                                                                            MyText(
                                                                              text: userRequestData['pick_address'],
                                                                              size: media.width * twelve,
                                                                              color: greyText,
                                                                              // maxLines: 1,
                                                                            ),
                                                                          ],
                                                                        )),
                                                                      ],
                                                                    ),
                                                                  ),
                                                            if (widget.type !=
                                                                2)
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media
                                                                            .width *
                                                                        0.02),
                                                                padding: EdgeInsets
                                                                    .all(media
                                                                            .width *
                                                                        0.03),
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .grey
                                                                        .withOpacity(
                                                                            0.1),
                                                                    borderRadius:
                                                                        BorderRadius.circular(media.width *
                                                                            0.02)),
                                                                child: Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                            child:
                                                                                MyText(
                                                                          text: languages[choosenLanguage]
                                                                              [
                                                                              'text_payingvia'],
                                                                          size: media.width *
                                                                              fourteen,
                                                                          fontweight:
                                                                              FontWeight.w600,
                                                                        )),
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              (userRequestData['payment_opt'] == '1')
                                                                                  ? Image.asset(
                                                                                      'assets/images/cash.png',
                                                                                      width: media.width * 0.07,
                                                                                      height: media.width * 0.07,
                                                                                      fit: BoxFit.contain,
                                                                                    )
                                                                                  : (userRequestData['payment_opt'] == '2')
                                                                                      ? Image.asset(
                                                                                          'assets/images/wallet.png',
                                                                                          width: media.width * 0.07,
                                                                                          height: media.width * 0.07,
                                                                                          fit: BoxFit.contain,
                                                                                        )
                                                                                      : (userRequestData['payment_opt'] == '0')
                                                                                          ? Image.asset(
                                                                                              'assets/images/card.png',
                                                                                              width: media.width * 0.07,
                                                                                              height: media.width * 0.07,
                                                                                              fit: BoxFit.contain,
                                                                                            )
                                                                                          : Container(),
                                                                              SizedBox(
                                                                                width: media.width * 0.02,
                                                                              ),
                                                                              MyText(
                                                                                text: (userRequestData['payment_opt'] == '1')
                                                                                    ? languages[choosenLanguage]['text_cash']
                                                                                    : (userRequestData['payment_opt'] == '2')
                                                                                        ? languages[choosenLanguage]['text_wallet']
                                                                                        : languages[choosenLanguage]['text_card'],
                                                                                size: media.width * sixteen,
                                                                                fontweight: FontWeight.w600,
                                                                                color: (isDarkTheme == true) ? Colors.white : Colors.black,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.end,
                                                                          children: [
                                                                            InkWell(
                                                                              onTap: () {},
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  (userRequestData['is_bid_ride'] == 1)
                                                                                      ? MyText(
                                                                                          textAlign: TextAlign.end,
                                                                                          text: userRequestData['requested_currency_symbol'] + ' ' + userRequestData['accepted_ride_fare'].toString(),
                                                                                          size: media.width * sixteen,
                                                                                          fontweight: FontWeight.w500,
                                                                                          color: textColor,
                                                                                        )
                                                                                      : (userRequestData['discounted_total'] != null)
                                                                                          ? MyText(
                                                                                              textAlign: TextAlign.end,
                                                                                              text: userRequestData['requested_currency_symbol'] + ' ' + userRequestData['discounted_total'].toString(),
                                                                                              size: media.width * sixteen,
                                                                                              fontweight: FontWeight.w500,
                                                                                              color: textColor,
                                                                                              maxLines: 1,
                                                                                            )
                                                                                          : MyText(
                                                                                              textAlign: TextAlign.end,
                                                                                              text: userRequestData['requested_currency_symbol'] + ' ' + userRequestData['request_eta_amount'].toString(),
                                                                                              size: media.width * sixteen,
                                                                                              fontweight: FontWeight.w500,
                                                                                              color: textColor,
                                                                                              maxLines: 1,
                                                                                            ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.05,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'عند إلغاء الطلب سيتم خصم 2.5 دل',
                                                                  style: GoogleFonts.notoSans(
                                                                      fontSize:
                                                                          media.width *
                                                                              sixteen,
                                                                      color: Colors
                                                                          .grey,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                            (userRequestData[
                                                                        'is_trip_start'] !=
                                                                    1)
                                                                ? Column(
                                                                    children: [
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.05,
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          (userRequestData['is_trip_start'] != 1)
                                                                              ? InkWell(
                                                                                  onTap: () async {
                                                                                    setState(() {
                                                                                      isLoading = true;
                                                                                    });
                                                                                    var reason = await cancelReason((userRequestData['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                                    if (reason == true) {
                                                                                      setState(() {
                                                                                        _cancellingError = '';
                                                                                        _cancelReason = '';
                                                                                        _cancelling = true;
                                                                                      });
                                                                                    }
                                                                                    setState(() {
                                                                                      isLoading = false;
                                                                                    });
                                                                                  },
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Image.asset(
                                                                                        'assets/images/cancelimage.png',
                                                                                        height: media.width * 0.064,
                                                                                        width: media.width * 0.064,
                                                                                        fit: BoxFit.contain,
                                                                                        color: verifyDeclined,
                                                                                      ),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.025,
                                                                                      ),
                                                                                      MyText(
                                                                                        text: languages[choosenLanguage]['text_cancel_booking'],
                                                                                        size: media.width * twelve,
                                                                                        fontweight: FontWeight.w400,
                                                                                        color: verifyDeclined,
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              : Container(),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Container(),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.25,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )),
                                          ))
                                      : Container(),

                                  // cancel request
                                  (_cancelling == true)
                                      ? CancellationSheet(
                                          reasons: cancelReasonsList
                                              .map((item) =>
                                                  item['reason'].toString())
                                              .toList(),
                                          selectedReason: _cancelReason,
                                          otherValue: 'others',
                                          copy: Map<String, dynamic>.from(
                                              languages[choosenLanguage]),
                                          errorText: _cancellingError,
                                          onReasonSelected: (reason) {
                                            setState(() {
                                              _cancelReason = reason;
                                              _cancellingError = '';
                                            });
                                          },
                                          onCustomReasonChanged: (reason) {
                                            _cancelCustomReason = reason;
                                            if (_cancellingError.isNotEmpty) {
                                              setState(() {
                                                _cancellingError = '';
                                              });
                                            }
                                          },
                                          onKeepRide: () {
                                            setState(() {
                                              _cancelling = false;
                                              _cancellingError = '';
                                            });
                                          },
                                          onConfirmCancellation:
                                              _confirmCancellation,
                                        )
                                      : Container(),

                                  //date picker for ride later
                                  (_dateTimePicker)
                                      ? RideDatePickerOverlay(
                                          minimumDate: DateTime.now().add(
                                            Duration(
                                              minutes: int.parse(
                                                userDetails[
                                                    'user_can_make_a_ride_after_x_miniutes'],
                                              ),
                                            ),
                                          ),
                                          maximumDate: DateTime.now().add(
                                            const Duration(days: 4),
                                          ),
                                          confirmText:
                                              languages[choosenLanguage]
                                                  ['text_confirm'],
                                          onChanged: (value) {
                                            choosenDateTime = value;
                                          },
                                          onClose: () {
                                            setState(() {
                                              _dateTimePicker = false;
                                            });
                                          },
                                          onConfirm: () {
                                            setState(() {
                                              _dateTimePicker = false;
                                            });
                                          },
                                        )
                                      : const SizedBox.shrink(),

                                  (_isDateTimebottom >= 0)
                                      ? RideScheduleSheet(
                                          height: _dateTimeHeight,
                                          isOneWay: isOneWayTrip,
                                          isSelectingOutbound: isFromDate,
                                          outboundDate: fromDate,
                                          returnDate: toDate,
                                          minimumOutboundDate:
                                              DateTime.now().add(
                                            Duration(
                                              minutes: int.parse(
                                                userDetails[
                                                    'user_can_make_a_ride_after_x_miniutes'],
                                              ),
                                            ),
                                          ),
                                          copy: languages[choosenLanguage],
                                          onDismiss: () {
                                            setState(() {
                                              _dateTimeHeight = 0;
                                            });
                                            Future.delayed(
                                              const Duration(milliseconds: 220),
                                              () {
                                                if (mounted) {
                                                  setState(() {
                                                    _isDateTimebottom = -1000;
                                                  });
                                                }
                                              },
                                            );
                                          },
                                          onSelectOutbound: () {
                                            setState(() {
                                              isFromDate = true;
                                              toDate = null;
                                            });
                                          },
                                          onSelectReturn: () {
                                            setState(() {
                                              isFromDate = false;
                                              toDate = fromDate.add(
                                                const Duration(
                                                  days: 1,
                                                  minutes: 10,
                                                ),
                                              );
                                            });
                                          },
                                          onOutboundChanged: (value) {
                                            fromDate = value;
                                          },
                                          onReturnChanged: (value) {
                                            toDate = value;
                                          },
                                          onContinue: () {
                                            if (!isOneWayTrip &&
                                                toDate == null) {
                                              setState(() {
                                                isFromDate = false;
                                                toDate = fromDate.add(
                                                  const Duration(
                                                    days: 1,
                                                    minutes: 10,
                                                  ),
                                                );
                                              });
                                              return;
                                            }

                                            setState(() {
                                              nofromdate = true;
                                              _dateTimeHeight = 0;
                                            });
                                            if (toDate != null) {
                                              dateDifference =
                                                  toDate!.difference(fromDate);
                                              daysDifferenceRoundedUp =
                                                  (dateDifference.inHours / 24)
                                                      .ceil();
                                            }
                                            Future.delayed(
                                              const Duration(milliseconds: 220),
                                              () {
                                                if (mounted) {
                                                  setState(() {
                                                    _isDateTimebottom = -1000;
                                                  });
                                                }
                                              },
                                            );
                                          },
                                        )
                                      : const SizedBox.shrink(),

                                  //sos popup
                                  (showSos)
                                      ? SosSheet(
                                          copy: languages[choosenLanguage],
                                          contacts: sosData,
                                          notificationSent: notifyCompleted,
                                          onClose: () {
                                            setState(() {
                                              notifyCompleted = false;
                                              showSos = false;
                                            });
                                          },
                                          onNotifyAdmin: () async {
                                            setState(() {
                                              notifyCompleted = false;
                                            });
                                            final sent = await notifyAdmin();
                                            if (mounted && sent == true) {
                                              setState(() {
                                                notifyCompleted = true;
                                              });
                                            }
                                          },
                                          onCall: makingPhoneCall,
                                        )
                                      : const SizedBox.shrink(),

                                  (_locationDenied)
                                      ? LocationPermissionSheet(
                                          message: languages[choosenLanguage]
                                              ['text_open_loc_settings'],
                                          openSettingsText:
                                              languages[choosenLanguage]
                                                  ['text_open_settings'],
                                          doneText: languages[choosenLanguage]
                                              ['text_done'],
                                          onClose: () {
                                            setState(() {
                                              _locationDenied = false;
                                            });
                                          },
                                          onOpenSettings: perm.openAppSettings,
                                          onDone: () {
                                            setState(() {
                                              _locationDenied = false;
                                              isLoading = true;
                                            });
                                            if (locationAllowed &&
                                                (positionStream == null ||
                                                    positionStream!.isPaused)) {
                                              positionStreamData();
                                            }
                                          },
                                        )
                                      : const SizedBox.shrink(),

                                  //displaying address details for edit
                                  ((!_chooseGoodsType &&
                                              userRequestData.isEmpty &&
                                              addressList.isNotEmpty &&
                                              choosenTransportType == 1) ||
                                          (!dropConfirmed &&
                                              userRequestData.isEmpty))
                                      ? TripDetailsSheet(
                                          addresses: addressList,
                                          copy: languages[choosenLanguage],
                                          isRtl: languageDirection == 'rtl',
                                          canAddStop: addressList.length < 5 &&
                                              widget.type != 1,
                                          onAddStop: () {
                                            _editTripLocation('add stop');
                                          },
                                          onEdit: (index) {
                                            _editTripLocation(index);
                                          },
                                          onDelete: _deleteDestination,
                                          onReorder: _reorderDestinations,
                                          onConfirm: _confirmTripDetails,
                                        )
                                      : const SizedBox.shrink(),

                                  //edit pick user contact

                                  (_editUserDetails)
                                      ? RiderContactSheet(
                                          copy: languages[choosenLanguage],
                                          nameController: pickerName,
                                          numberController: pickerNumber,
                                          instructionsController: instructions,
                                          onClose: () {
                                            setState(() {
                                              _editUserDetails = false;
                                            });
                                          },
                                          onPickContact: () async {
                                            final picked = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PickContact(
                                                        from: '1'),
                                              ),
                                            );
                                            if (mounted && picked == true) {
                                              setState(() {
                                                pickerName.text = pickedName;
                                                pickerNumber.text =
                                                    pickedNumber;
                                              });
                                            }
                                          },
                                          onConfirm: () {
                                            setState(() {
                                              addressList[0].name =
                                                  pickerName.text.trim();
                                              addressList[0].number =
                                                  pickerNumber.text.trim();
                                              addressList[0].instructions =
                                                  instructions.text
                                                          .trim()
                                                          .isEmpty
                                                      ? null
                                                      : instructions.text
                                                          .trim();
                                              _editUserDetails = false;
                                            });
                                          },
                                        )
                                      : const SizedBox.shrink(),

                                  if (_cancel)
                                    BookingStatusSheet(
                                      title: languages[choosenLanguage]
                                          ['text_cancel_confirmation'],
                                      actionLabel: languages[choosenLanguage]
                                          ['text_confirm'],
                                      secondaryActionLabel:
                                          languages[choosenLanguage]
                                              ['text_cancel'],
                                      icon: Icons.cancel_outlined,
                                      onSecondaryAction: () {
                                        setState(() {
                                          _cancel = false;
                                        });
                                      },
                                      onAction: () async {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        final result = await cancelRequest();
                                        updateAmount.clear();
                                        if (!mounted) return;
                                        if (result == 'logout') {
                                          navigateLogout();
                                          return;
                                        }
                                        setState(() {
                                          isLoading = false;
                                          _cancel = false;
                                        });
                                      },
                                    ),

                                  // driver cancelled request
                                  (requestCancelledByDriver == true)
                                      ? BookingStatusSheet(
                                          title: languages[choosenLanguage]
                                              ['text_drivercancelled'],
                                          actionLabel:
                                              languages[choosenLanguage]
                                                  ['text_ok'],
                                          icon: Icons.event_busy_rounded,
                                          onAction: () async {
                                            setState(() {
                                              requestCancelledByDriver = false;
                                              if (userRequestData['is_bid_ride']
                                                      .toString() ==
                                                  '1') {
                                                userRequestData = {};
                                              }
                                            });
                                            if (!context.mounted) return;
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const Maps(),
                                              ),
                                              (_) => false,
                                            );
                                          },
                                        )
                                      : Container(),

                                  //loader
                                  (isLoading == true)
                                      ? const Positioned(
                                          top: 0, child: Loading())
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
                                      : Container(),

                                  //pick drop marker
                                  Positioned(
                                    top: media.height * 1.6,
                                    child: RepaintBoundary(
                                        key: iconKey,
                                        child: Column(
                                          children: [
                                            Container(
                                                decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: [
                                                          (isDarkTheme == true)
                                                              ? const Color(
                                                                  0xff000000)
                                                              : const Color(
                                                                  0xffFFFFFF),
                                                          (isDarkTheme == true)
                                                              ? const Color(
                                                                  0xff808080)
                                                              : const Color(
                                                                  0xffEFEFEF),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                width: (platform ==
                                                        TargetPlatform.android)
                                                    ? media.width * 0.4
                                                    : media.width * 0.5,
                                                padding:
                                                    const EdgeInsets.all(5),
                                                child: (userRequestData
                                                        .isNotEmpty)
                                                    ? Text(
                                                        userRequestData[
                                                            'pick_address'],
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.fade,
                                                        softWrap: false,
                                                        style: GoogleFonts.notoSans(
                                                            color: textColor,
                                                            fontSize: (platform ==
                                                                    TargetPlatform
                                                                        .android)
                                                                ? media.width *
                                                                    twelve
                                                                : media.width *
                                                                    sixteen),
                                                      )
                                                    : (addressList
                                                            .where((element) =>
                                                                element.type ==
                                                                'pickup')
                                                            .isNotEmpty)
                                                        ? Text(
                                                            addressList
                                                                .firstWhere(
                                                                    (element) =>
                                                                        element
                                                                            .type ==
                                                                        'pickup')
                                                                .address,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
                                                            softWrap: false,
                                                            style: GoogleFonts.notoSans(
                                                                color:
                                                                    textColor,
                                                                fontSize: (platform ==
                                                                        TargetPlatform
                                                                            .android)
                                                                    ? media.width *
                                                                        twelve
                                                                    : media.width *
                                                                        sixteen),
                                                          )
                                                        : Container()),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/pick_icon.png'),
                                                      fit: BoxFit.contain)),
                                              height: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                              width: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                            ),
                                          ],
                                        )),
                                  ),
                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: Column(
                                            children: addressList
                                                .asMap()
                                                .map((i, value) {
                                                  iconDropKeys[i] = GlobalKey();
                                                  return MapEntry(
                                                    i,
                                                    (i > 0)
                                                        ? RepaintBoundary(
                                                            key:
                                                                iconDropKeys[i],
                                                            child: Column(
                                                              children: [
                                                                (i ==
                                                                        addressList.length -
                                                                            1)
                                                                    ? Column(
                                                                        children: [
                                                                          Container(
                                                                            decoration: BoxDecoration(
                                                                                gradient: LinearGradient(colors: [
                                                                                  (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                                                  (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                                                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                                borderRadius: BorderRadius.circular(5)),
                                                                            width: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.5
                                                                                : media.width * 0.7,
                                                                            padding:
                                                                                const EdgeInsets.all(5),
                                                                            child: (addressList[i].address.isNotEmpty)
                                                                                ? Text(
                                                                                    addressList[i].address,
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.fade,
                                                                                    softWrap: false,
                                                                                    style: GoogleFonts.notoSans(fontSize: (platform == TargetPlatform.android) ? media.width * twelve : media.width * sixteen, color: textColor),
                                                                                  )
                                                                                : Container(),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage('assets/images/drop_icon.png'), fit: BoxFit.contain)),
                                                                            height: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                            width: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Text(
                                                                        (i).toString(),
                                                                        style: GoogleFonts.notoSans(
                                                                            fontSize: media.width *
                                                                                sixteen,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: Colors.red),
                                                                      ),
                                                              ],
                                                            ))
                                                        : Container(),
                                                  );
                                                })
                                                .values
                                                .toList(),
                                          ))
                                      : Container(),

                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: RepaintBoundary(
                                              key: iconDistanceKey,
                                              child: Stack(
                                                children: [
                                                  Icon(Icons.chat_bubble,
                                                      size: media.width * 0.2,
                                                      color: page,
                                                      shadows: [
                                                        BoxShadow(
                                                            spreadRadius: 2,
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2))
                                                      ]),
                                                  if (etaDetails.isNotEmpty)
                                                    if (etaDetails[0]
                                                            ['distance'] !=
                                                        null)
                                                      Positioned(
                                                          left: media.width *
                                                              0.03,
                                                          top: media.width *
                                                              0.03,
                                                          child: Container(
                                                              width:
                                                                  media.width *
                                                                      0.14,
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                "${etaDetails[0]['distance'].toString()} ${etaDetails[0]['unit_in_words'].toString()} ",
                                                                style: GoogleFonts.notoSans(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              )))
                                                ],
                                              )),
                                        )
                                      : Container()
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
