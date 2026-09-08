part of '../booking_confirmation.dart';

mixin _BookingConfirmationController
    on State<BookingConfirmation>, WidgetsBindingObserver, TickerProvider {
  TextEditingController updateAmount = TextEditingController();
  TextEditingController pickerName = TextEditingController();
  TextEditingController pickerNumber = TextEditingController();
  TextEditingController instructions = TextEditingController();
  final ScrollController _cont = ScrollController();
  final Map minutes = {};
  dynamic addressBottom;
  dynamic _addressBottom;
  List myMarker = [];
  Map myBearings = {};
  String _cancelReason = '';
  dynamic _controller;
  late PermissionStatus permission;
  bool bottomChooseMethod = false;
  bool fmPolyGot = false;
  bool islowwalletbalance = false;
  List gesture = [];
  dynamic start;
  final fm.MapController _fmController = fm.MapController();

  late Duration dateDifference;
  int daysDifferenceRoundedUp = 0;

  Location location = Location();
  bool _locationDenied = false;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  dynamic pinLocationIcon;
  dynamic pinLocationIcon2;
  dynamic animationController;
  bool _ontripBottom = false;
  bool _cancelling = false;
  bool _choosePayment = false;
  String _cancelCustomReason = '';
  dynamic timers;
  bool _dateTimePicker = false;
  bool showSos = false;
  bool notifyCompleted = false;
  bool _chooseGoodsType = false;
  dynamic _showInfoInt;
  dynamic _dist;
  bool _editUserDetails = false;
  String _cancellingError = '';
  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();
  GlobalKey iconDistanceKey = GlobalKey();
  var iconDropKeys = {};
  bool _cancel = false;
  List driverBck = [];
  bool currentpage = true;
  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
  bool dropConfirmed = false;

  bool isOneWayTrip = true;
  bool isFromDate = true;

  DateTime fromDate = DateTime.now().add(Duration(
      minutes:
          int.parse(userDetails['user_can_make_a_ride_after_x_miniutes'])));
  DateTime? toDate;
  double _isDateTimebottom = -1000;
  dynamic _dateTimeHeight = 0;
  bool nofromdate = false;
  @override
  void initState() {
    fmpoly.clear();
    WidgetsBinding.instance.addObserver(this);
    promoCode = '';
    mapPadding = 0.0;
    promoStatus = null;
    serviceNotAvailable = false;
    tripReqError = false;
    myBearings.clear();
    noDriverFound = false;
    etaDetails.clear();
    rentalOption.clear();
    currentpage = true;
    selectedGoodsId = '';
    addCoupon = false;
    choosenDateTime = null;
    confirmRideLater = false;
    promoKey.text = '';
    addPetPreferences = false;
    addLuggagePreferences = false;
    if (widget.type == 1 || widget.type == 2) {
      setState(() {
        dropConfirmed = true;
      });
    } else {
      setState(() {
        dropConfirmed = false;
      });
    }
    if (!ismulitipleride && userRequestData['accepted_at'] != null) {
      userRequestData.clear();
    }
    getLocs();

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (isDarkTheme == true) {
        await rootBundle.loadString('assets/dark.json').then((value) {
          mapStyle = value;
        });
      } else {
        await rootBundle
            .loadString('assets/map_style_black.json')
            .then((value) {
          mapStyle = value;
        });
      }
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      if (userRequestData.isNotEmpty) {
        ismulitipleride = true;
        getUserDetails(id: userRequestData['id']);
      } else {
        getUserDetails();
      }

      if (timers == null &&
          userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        timer();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    if (timers != null) {
      timers?.cancel;
    }

    _controller?.dispose();
    _controller = null;
    animationController?.dispose();

    super.dispose();
  }

//running timer
  timer() {
    if (userRequestData['is_bid_ride'] == 1) {
      timers = Timer.periodic(const Duration(seconds: 1), (timer) {
        valueNotifierTimer.incrementNotifier();
      });
    } else {
      timing =
          userRequestData['maximum_time_for_find_drivers_for_regular_ride'];
      if (mounted) {
        timers = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (timing != null) {
            if (userRequestData.isNotEmpty &&
                userDetails['accepted_at'] == null &&
                timing > 0) {
              timing--;
              valueNotifierBook.incrementNotifier();
            } else if (userRequestData.isNotEmpty &&
                userRequestData['accepted_at'] == null &&
                timing == 0) {
              var val = await cancelRequest();

              setState(() {
                noDriverFound = true;
              });

              timer.cancel();
              timing = null;
              if (val == 'logout') {
                navigateLogout();
              }
            } else {
              timer.cancel();
              timing = null;
            }
          } else {
            timer.cancel();
            timing = null;
          }
        });
      }
    }
  }

//create icon

  _capturePng(GlobalKey iconKeys) async {
    dynamic bitmap;

    try {
      RenderRepaintBoundary boundary =
          iconKeys.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      bitmap = BitmapDescriptor.fromBytes(pngBytes);
      // return pngBytes;
    } catch (e) {
      debugPrint(e.toString());
    }
    return bitmap;
  }

  addDropMarker() async {
    for (var i = 1; i < addressList.length; i++) {
      var testIcon = await _capturePng(iconDropKeys[i]);
      if (testIcon != null) {
        setState(() {
          myMarker.add(Marker(
              markerId: MarkerId((i + 1).toString()),
              icon: testIcon,
              position: addressList[i].latlng));
        });
      }
    }

    if (widget.type != 1) {
      LatLngBounds bound;
      if (userRequestData.isNotEmpty) {
        if (userRequestData['pick_lat'] > userRequestData['drop_lat'] &&
            userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lat'] > userRequestData['drop_lat']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']));
        } else {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']));
        }
      } else {
        if (addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .latitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .latitude &&
            addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .longitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .longitude) {
          bound = LatLngBounds(
              southwest: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng,
              northeast: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng);
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .longitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude));
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .latitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude));
        } else {
          bound = LatLngBounds(
              southwest: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng,
              northeast: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng);
        }
      }
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 50);
      _controller!.animateCamera(cameraUpdate);
      // CameraUpdate.newCameraPosition(CameraPosition(target: target))
    }
  }

  addMarker() async {
    var testIcon = await _capturePng(iconKey);
    if (testIcon != null) {
      setState(() {
        myMarker.add(Marker(
            markerId: const MarkerId('1'),
            icon: testIcon,
            position: (userRequestData.isEmpty)
                ? addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                : LatLng(
                    userRequestData['pick_lat'], userRequestData['pick_lng'])));
      });
    }
  }

  getPoly(change, lat, lng) async {
    fmpoly.clear();
    final Box cacheBox = Hive.box('geocoding_cache');

    if ((userRequestData.isEmpty ||
            userRequestData['accepted_at'] == null ||
            userRequestData['is_driver_arrived'] == 1) &&
        lat == '') {
      for (var i = 1; i < addressList.length; i++) {
        String cacheKey =
            'osrm_polyline_${addressList[i - 1].latlng.latitude},${addressList[i - 1].latlng.longitude}|${addressList[i].latlng.latitude},${addressList[i].latlng.longitude}';

        if (cacheBox.containsKey(cacheKey)) {
          List polyData = List.from(cacheBox.get(cacheKey));
          for (var step in polyData) {
            decodeEncodedPolyline(step);
          }
        } else {
          var api = await http.get(Uri.parse(
              'https://routing.openstreetmap.de/routed-car/route/v1/driving/${addressList[i - 1].latlng.longitude},${addressList[i - 1].latlng.latitude};${addressList[i].latlng.longitude},${addressList[i].latlng.latitude}?overview=false&geometries=polyline&steps=true'));

          if (api.statusCode == 200) {
            List _poly = jsonDecode(api.body)['routes'][0]['legs'][0]['steps'];
            List<String> encodedSteps = [];

            polyline.clear();
            for (var e in _poly) {
              decodeEncodedPolyline(e['geometry']);
              encodedSteps.add(e['geometry']);
            }

            cacheBox.put(cacheKey, encodedSteps);

            double lat = (addressList[0].latlng.latitude +
                    addressList[addressList.length - 1].latlng.latitude) /
                2;
            double lon = (addressList[0].latlng.longitude +
                    addressList[addressList.length - 1].latlng.longitude) /
                2;
            var val = LatLng(lat, lon);
            _fmController.move(fmlt.LatLng(val.latitude, val.longitude), 13);

            setState(() {});
          }
        }
      }
    } else {
      String cacheKey =
          'osrm_polyline_driver_$lat,$lng|${addressList[0].latlng.latitude},${addressList[0].latlng.longitude}';

      if (cacheBox.containsKey(cacheKey)) {
        List polyData = List.from(cacheBox.get(cacheKey));
        for (var step in polyData) {
          decodeEncodedPolyline(step);
        }
      } else {
        var api = await http.get(Uri.parse(
            'https://routing.openstreetmap.de/routed-car/route/v1/driving/$lng,$lat;${addressList[0].latlng.longitude},${addressList[0].latlng.latitude}?overview=false&geometries=polyline&steps=true'));

        if (api.statusCode == 200) {
          List _poly = jsonDecode(api.body)['routes'][0]['legs'][0]['steps'];
          List<String> encodedSteps = [];

          polyline.clear();
          for (var e in _poly) {
            decodeEncodedPolyline(e['geometry']);
            encodedSteps.add(e['geometry']);
          }

          cacheBox.put(cacheKey, encodedSteps);

          double _lat = (addressList[0].latlng.latitude + lat) / 2;
          double _lon = (addressList[0].latlng.longitude + lng) / 2;
          var val = LatLng(_lat, _lon);
          _fmController.move(fmlt.LatLng(val.latitude, val.longitude), 15);

          setState(() {});
        }
      }
    }

    fmPolyGot = false;
  }

  // getPoly(change, lat, lng) async {
  //   fmpoly.clear();
  //   if ((userRequestData.isEmpty ||
  //           userRequestData['accepted_at'] == null ||
  //           userRequestData['is_driver_arrived'] == 1) &&
  //       lat == '') {
  //     for (var i = 1; i < addressList.length; i++) {
  //       var api = await http.get(Uri.parse(
  //           'https://routing.openstreetmap.de/routed-car/route/v1/driving/${addressList[i - 1].latlng.longitude},${addressList[i - 1].latlng.latitude};${addressList[i].latlng.longitude},${addressList[i].latlng.latitude}?overview=false&geometries=polyline&steps=true'));
  //       if (api.statusCode == 200) {
  //         List _poly = jsonDecode(api.body)['routes'][0]['legs'][0]['steps'];
  //         polyline.clear();
  //         for (var e in _poly) {
  //           decodeEncodedPolyline(e['geometry']);
  //         }

  //         double lat = (addressList[0].latlng.latitude +
  //                 addressList[addressList.length - 1].latlng.latitude) /
  //             2;
  //         double lon = (addressList[0].latlng.longitude +
  //                 addressList[addressList.length - 1].latlng.longitude) /
  //             2;
  //         var val = LatLng(lat, lon);
  //         // if(change == true){
  //         _fmController.move(fmlt.LatLng(val.latitude, val.longitude), 13);

  //         setState(() {});
  //       }
  //     }
  //   } else {
  //     var api = await http.get(Uri.parse(
  //         'https://routing.openstreetmap.de/routed-car/route/v1/driving/$lng,$lat;${addressList[0].latlng.longitude},${addressList[0].latlng.latitude}?overview=false&geometries=polyline&steps=true'));
  //     if (api.statusCode == 200) {
  //       List _poly = jsonDecode(api.body)['routes'][0]['legs'][0]['steps'];
  //       polyline.clear();
  //       for (var e in _poly) {
  //         decodeEncodedPolyline(e['geometry']);
  //       }
  //       double _lat = (addressList[0].latlng.latitude + lat) / 2;
  //       double _lon = (addressList[0].latlng.longitude + lng) / 2;
  //       var val = LatLng(_lat, _lon);
  //       // if(change == true){
  //       _fmController.move(fmlt.LatLng(val.latitude, val.longitude), 15);
  //       // }
  //       setState(() {});
  //     } else {}
  //   }
  //   fmPolyGot = false;
  // }

//add distance marker
  addDistanceMarker(length) async {
    var testIcon = await _capturePng(iconDistanceKey);
    if (testIcon != null) {
      setState(() {
        if (polyList.isNotEmpty) {
          myMarker.add(Marker(
              markerId: const MarkerId('pointdistance'),
              icon: testIcon,
              position: polyList[length],
              anchor: const Offset(0.0, 1.0)));
        }
      });
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

//add drop marker
  addPickDropMarker() async {
    if (mapType == 'google') {
      addMarker();
      // Future.delayed(const Duration(milliseconds: 200), () async {
      if (userRequestData.isNotEmpty &&
          userRequestData['is_rental'] != true &&
          userRequestData['drop_address'] != null) {
        addDropMarker();

        if (userRequestData.isEmpty) {
          polyline.add(
            Polyline(
                polylineId: const PolylineId('1'),
                color: buttonColor,
                points: [
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng,
                  addressList
                      .firstWhere((element) => element.id == 'pickup')
                      .latlng
                ],
                geodesic: false,
                width: 5),
          );
          getPolylines('', '', '', '');
        } else {
          polyGot = false;
        }
      } else if (widget.type == null) {
        addDropMarker();
        if (userRequestData.isEmpty) {
          polyline.add(
            Polyline(
                polylineId: const PolylineId('1'),
                color: buttonColor,
                points: [
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                ],
                geodesic: false,
                width: 5),
          );
          await getPolylines('', '', '', '');
        } else {
          polyGot = false;
        }
      } else {
        if (userRequestData.isNotEmpty) {
          CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
              LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']));
          _controller!.animateCamera(cameraUpdate);
        } else {
          CameraUpdate cameraUpdate = CameraUpdate.newLatLng(addressList
              .firstWhere((element) => element.type == 'pickup')
              .latlng);
          _controller!.animateCamera(cameraUpdate);
        }
        polyGot = false;
      }
    } else {
      if (addressList.length > 1 &&
          fmPolyGot == false &&
          userRequestData.isEmpty) {
        fmPolyGot = true;
        double lat = (addressList[0].latlng.latitude +
                addressList[addressList.length - 1].latlng.latitude) /
            2;
        double lon = (addressList[0].latlng.longitude +
                addressList[addressList.length - 1].latlng.longitude) /
            2;
        _center = LatLng(lat, lon);
        _fmController.move(
            fmlt.LatLng(_center.latitude, _center.longitude), 13);
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//get location permission and location details
  getLocs() async {
    if (signKey == '' || packageName == '') {
      PackageInfo buildKeys = await PackageInfo.fromPlatform();
      signKey = buildKeys.buildSignature;
      packageName = buildKeys.packageName;
    }
    setState(() {
      polyGot = true;
      _center = (userRequestData.isEmpty)
          ? addressList.firstWhere((element) => element.type == 'pickup').latlng
          : LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']);
    });
    if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      serviceEnabled = true;
    } else {
      serviceEnabled = false;
    }
    final Uint8List markerIcon;
    final Uint8List markerIcon2;
    if (choosenTransportType == 0) {
      markerIcon = await getBytesFromAsset('assets/images/top-taxi.png', 80);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
      markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
      pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);
    } else {
      markerIcon =
          await getBytesFromAsset('assets/images/deliveryicon.png', 40);
      pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
      markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
      pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);
    }

    choosenVehicle = null;
    _dist = null;

    if (widget.type == 2 || isOutStation == true) {
      var val = await etaRequest(outstation: isOutStation);
      if (val == 'logout') {
        navigateLogout();
      }
    }
    if (widget.type == 1) {
      var val = await rentalEta();
      if (val == 'logout') {
        navigateLogout();
      }
    }

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        locationAllowed = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      locationAllowed = true;
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
      setState(() {});
    }
// polyGot = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      await addPickDropMarker();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  Future<void> _confirmCancellation() async {
    final reason = _cancelReason == 'others'
        ? _cancelCustomReason.trim()
        : _cancelReason.trim();
    if (reason.isEmpty) {
      setState(() {
        _cancellingError = _cancelReason == 'others'
            ? languages[choosenLanguage]['text_add_cancel_reason']
            : languages[choosenLanguage]['text_cancel_reason'];
      });
      return;
    }

    setState(() {
      isLoading = true;
      _cancellingError = '';
    });
    final result = await cancelRequestWithReason(reason);
    if (!mounted) return;
    if (result == 'logout') {
      navigateLogout();
      return;
    }
    setState(() {
      isLoading = false;
      _cancelling = false;
    });
  }

  Future<void> _editTripLocation(dynamic from) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DropLocation(from: from)),
    );
    if (!mounted || changed != true) return;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await addPickDropMarker();
    }
  }

  void _reorderDestinations(int oldIndex, int newIndex) {
    setState(() {
      final moved = addressList.removeAt(oldIndex + 1);
      addressList.insert(newIndex + 1, moved);
    });
    addPickDropMarker();
  }

  void _deleteDestination(int index) {
    setState(() {
      addressList.removeAt(index);
      myMarker.removeWhere(
        (element) => !element.markerId.toString().contains('car'),
      );
    });
    addPickDropMarker();
  }

  Future<void> _confirmTripDetails() async {
    choosePets = false;
    chooseLuggages = false;
    setState(() {
      isLoading = true;
      dropStopList.clear();
    });

    for (var i = 1; i < addressList.length; i++) {
      final address = addressList[i];
      dropStopList.add(
        DropStops(
          order: '$i',
          latitude: address.latlng.latitude,
          longitude: address.latlng.longitude,
          pocName: address.name?.toString(),
          pocNumber: address.number?.toString(),
          pocInstruction: address.instructions,
          address: address.address,
        ),
      );
    }

    final result = widget.type == 1
        ? await rentalEta()
        : await etaRequest(outstation: isOutStation);
    if (!mounted) return;
    if (result == 'logout') {
      navigateLogout();
      return;
    }

    setState(() {
      isLoading = false;
      if (etaDetails.isEmpty) {
        dropConfirmed = false;
        serviceNotAvailable = true;
      } else {
        dropConfirmed = true;
        if (choosenTransportType == 1) {
          selectedGoodsId = '';
          _chooseGoodsType = true;
        }
      }
    });
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
          mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
          provider, //Ticker provider of the widget. This is used for animation

      // GoogleMapController controller, //Google map controller of our widget

      markerid,
      markerBearing,
      icon) async {
    final double bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
        markerId: MarkerId(markerid),
        position: LatLng(fromLat, fromLong),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        draggable: false);

    myMarker.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarker).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarker
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        carMarker = Marker(
            markerId: MarkerId(markerid),
            position: newPos,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.

        myMarker.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarker).toList());

        mapMarkerSink.add(Set<Marker>.from(myMarker).toList());
      });
    //Starting the animation

    animationController.forward();
    if (userRequestData.isNotEmpty && userRequestData['accepted_at'] != null) {
      if (mapType == 'google') {
        LatLngBounds l2 = await _controller.getVisibleRegion();
        if (l2.contains(LatLng(toLat, toLong))) {
        } else {
          _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(toLat, toLong), 18.0));
        }
      } else {
        if (_fmController.camera.visibleBounds
                .contains(fmlt.LatLng(toLat, toLong)) ==
            false) {
          _fmController.move(fmlt.LatLng(toLat, toLong), 16);
        }
      }
    }
  }
}
