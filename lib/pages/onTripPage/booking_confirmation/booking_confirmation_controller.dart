part of '../booking_confirmation.dart';

mixin _BookingConfirmationController
    on State<BookingConfirmation>, WidgetsBindingObserver, TickerProvider {
  void handleBookingBack(BuildContext context) {
    if (userRequestData.isNotEmpty &&
        userRequestData['accepted_at'] != null &&
        userDetails['rider_active_ride_limit']?.toString() != '2') {
      return;
    }
    noDriverFound = false;
    stillSearchingForDriver = false;
    pendingRecoveryDriverOffer = null;
    tripReqError = false;
    serviceNotAvailable = false;

    if (widget.type == null && dropConfirmed) {
      setState(() {
        dropConfirmed = false;
        promoStatus = false;
        addCoupon = false;
        promoKey.clear();
      });
      return;
    }

    isRentalRide = false;
    if (userRequestData['accepted_at'] != null &&
        userDetails['rider_active_ride_limit']?.toString() == '2') {
      userRequestData.clear();
      rideStreamUpdate?.cancel();
      rideStreamStart?.cancel();
      rideStreamUpdate = null;
      rideStreamStart = null;
    }
    ismulitipleride = false;
    isOutStation = false;
    etaDetails.clear();
    promoKey.clear();
    promoStatus = false;
    addCoupon = false;
    rentalOption.clear();
    myMarker.clear();
    dropStopList.clear();
    addressList.removeWhere((element) => element.id == 'drop');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Maps()),
      (_) => false,
    );
  }

  TextEditingController updateAmount = TextEditingController();
  TextEditingController pickerName = TextEditingController();
  TextEditingController pickerNumber = TextEditingController();
  TextEditingController instructions = TextEditingController();
  final ScrollController _cont = ScrollController();
  final Map minutes = {};
  final Map<int, double> _fareOffers = {};
  final Map<int, double> _offerFairQuotes = {};
  bool? _offerScheduledMode;

  bool canAdjustSelectedFare(int index) {
    if (widget.type != null ||
        choosenTransportType != 0 ||
        rentalOption.isNotEmpty ||
        isOutStation ||
        !addressList.any((entry) => entry.type == 'drop') ||
        index >= etaDetails.length) return false;
    final eta = etaDetails[index];
    if (eta['has_discount'] == true || eta['enable_bidding'] == true)
      return false;
    // Backend capability gate: the rider fare offer needs the server's signed
    // fare quote (immediate rides) or its scheduled flexible-offer flag. A
    // backend that does not send them cannot accept a proposal, so the
    // stepper stays hidden and booking behaves exactly as before.
    return confirmRideLater
        ? eta['scheduled_flexible_offer'] == true
        : eta['fare_quote_token'] != null;
  }

  double fairFareForService(int index) {
    final eta = etaDetails[index];
    if (confirmRideLater) return scheduledQuotedFare(eta).toDouble();
    return double.tryParse(eta['total']?.toString() ?? '') ?? 0;
  }

  double minimumFareForService(int index) {
    final fair = fairFareForService(index);
    final eta = etaDetails[index];
    if (confirmRideLater) {
      final discount = double.tryParse(
              eta['scheduled_offer_discount_amount']?.toString() ?? '') ??
          0;
      return ((fair - discount).clamp(0.01, fair) * 100).round() / 100;
    }
    final limit = double.tryParse(
            eta['rider_offer_max_discount_percent']?.toString() ?? '') ??
        10;
    return minimumRiderOffer(fair, limit);
  }

  double? maximumFareForService(int index) {
    if (!confirmRideLater) return null;
    final fair = fairFareForService(index);
    final percent = double.tryParse(
            etaDetails[index]['scheduled_offer_markup_percent']?.toString() ??
                '') ??
        0;
    return (fair * (1 + percent / 100) * 100).round() / 100;
  }

  double chosenFareForService(int index) {
    final fair = fairFareForService(index);
    if (_offerScheduledMode != confirmRideLater) {
      _fareOffers.clear();
      _offerFairQuotes.clear();
      _offerScheduledMode = confirmRideLater;
    }
    if (_offerFairQuotes[index] != fair) {
      _fareOffers.remove(index);
      _offerFairQuotes[index] = fair;
    }
    final minimum = minimumFareForService(index);
    final maximum = maximumFareForService(index);
    return (_fareOffers[index] ?? fair)
        .clamp(minimum, maximum ?? double.infinity)
        .toDouble();
  }

  void changeFareOffer(int index, int direction) {
    final current = chosenFareForService(index);
    final minimum = minimumFareForService(index);
    final maximum = maximumFareForService(index);
    setState(() => _fareOffers[index] =
        steppedFareOffer(current, direction, minimum, maximum));
  }

  double payableFareForSelectedService(Map eta,
      {required bool scheduled, required bool discounted}) {
    if (choosenVehicle is int && canAdjustSelectedFare(choosenVehicle)) {
      return chosenFareForService(choosenVehicle);
    }
    return quotedFareForPayment(eta,
            scheduled: scheduled, discounted: discounted)
        .toDouble();
  }

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
  int _pendingRequestRefreshTick = 0;
  bool pendingRecoveryOfferDialogShown = false;
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
  String? _lastRouteCameraSignature;
  bool _routeCameraFitScheduled = false;

  DateTime fromDate = DateTime.now().add(Duration(
      minutes:
          int.parse(userDetails['user_can_make_a_ride_after_x_miniutes'])));
  DateTime? toDate;
  double _isDateTimebottom = -1000;
  dynamic _dateTimeHeight = 0;
  bool nofromdate = false;

  void scheduleRouteCameraFit(Size media) {
    if (_controller == null || mapType != 'google' || widget.type == 1) return;

    final points = _routeCameraPoints();
    if (points.length < 2) return;

    final minLatitude = points.map((point) => point.latitude).reduce(min);
    final maxLatitude = points.map((point) => point.latitude).reduce(max);
    final minLongitude = points.map((point) => point.longitude).reduce(min);
    final maxLongitude = points.map((point) => point.longitude).reduce(max);
    final signature = [
      minLatitude.toStringAsFixed(5),
      maxLatitude.toStringAsFixed(5),
      minLongitude.toStringAsFixed(5),
      maxLongitude.toStringAsFixed(5),
      mapPadding.round(),
    ].join(':');

    if (_lastRouteCameraSignature == signature || _routeCameraFitScheduled) {
      return;
    }
    _routeCameraFitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (dropConfirmed || userRequestData.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 260));
      }
      _routeCameraFitScheduled = false;
      if (!mounted || _controller == null) return;

      try {
        final latitudeSpan = maxLatitude - minLatitude;
        final longitudeSpan = maxLongitude - minLongitude;
        if (max(latitudeSpan.abs(), longitudeSpan.abs()) < 0.015) {
          final span = max(latitudeSpan.abs(), longitudeSpan.abs());
          await _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng((minLatitude + maxLatitude) / 2,
                  (minLongitude + maxLongitude) / 2),
              span < 0.003 ? 15 : 14,
            ),
          );
        } else {
          await _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLatitude, minLongitude),
                northeast: LatLng(maxLatitude, maxLongitude),
              ),
              36,
            ),
          );
        }
        _lastRouteCameraSignature = signature;
      } catch (error) {
        debugPrint('Unable to fit booking route: $error');
      }
    });
  }

  List<LatLng> _routeCameraPoints() {
    // polyList is global and can still be the previous trip both before and
    // after booking. Fit the current booking's saved stops instead.
    return bookingRequestCameraPoints(
        userRequestData, addressList.map((address) => address.latlng).toList());
  }

  CameraPosition initialBookingCameraPosition() {
    final endpoints = bookingRequestCameraPoints(
        userRequestData, addressList.map((address) => address.latlng).toList());
    return initialBookingCameraForRoute(endpoints, _center, dropConfirmed);
  }

  bool _leavingToHome = false;

  /// Replaces the whole stack with Home, once. Called from build(), so it has
  /// to tolerate being asked on every rebuild while the cancel flag is set.
  void _goHomeOnce() {
    if (_leavingToHome) return;
    _leavingToHome = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
          (route) => false);
    });
  }

  @override
  void initState() {
    fmpoly.clear();
    WidgetsBinding.instance.addObserver(this);
    // Weak or lost internet: when the connection comes back, reconcile the
    // ride once (shared with any resume in flight) instead of waiting for the
    // next poll tick.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online && mounted && userRequestData.isNotEmpty) {
        unawaited(_resume.run(_reconcileAfterResume));
      }
    });
    promoCode = '';
    mapPadding = 0.0;
    promoStatus = null;
    serviceNotAvailable = false;
    tripReqError = false;
    myBearings.clear();
    noDriverFound = false;
    stillSearchingForDriver = false;
    pendingRecoveryDriverOffer = null;
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

  final ResumeReconciler _resume = ResumeReconciler();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _appliedMapStyleKey;
  bool _resumeRetryScheduled = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // No search countdown or GPS work while in the background; both restart
      // (once) when the app returns.
      timers?.cancel();
      timers = null;
      positionStream?.cancel();
      positionStream = null;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }

  /// Coming back to the app (for example after using the Driver app):
  /// 1. make the screen alive again straight away - locks released, polling
  ///    and GPS restarted - without waiting for the network;
  /// 2. reconcile with the server once, under a hard deadline;
  /// 3. if that keeps failing, rebuild the screen from the server instead of
  ///    leaving the rider on a frozen view.
  Future<void> _onResumed() async {
    _restoreAfterResume();
    final outcome = await _resume.run(_reconcileAfterResume);
    if (!mounted) return;
    switch (outcome) {
      case ResumeOutcome.reconciled:
        break;
      case ResumeOutcome.softFailure:
        _restoreAfterResume();
        _scheduleResumeRetry();
        break;
      case ResumeOutcome.needsReset:
        _controlledStateReset();
        break;
    }
  }

  /// Instant, network-free part of a resume. Safe to run repeatedly: every
  /// step is idempotent (one timer, one location stream, no stacked dialogs).
  void _restoreAfterResume() {
    if (!mounted) return;
    // Busy flags left over from before the app was backgrounded would keep
    // buttons disabled; a real in-flight cancel is single-flight anyway.
    _cancelling = false;
    if (pendingRecoveryOfferDialogShown && !_recoveryDialogOnTop) {
      pendingRecoveryOfferDialogShown = false;
    }
    if (timers == null &&
        userRequestData.isNotEmpty &&
        userRequestData['accepted_at'] == null) {
      timer();
    }
    if (locationAllowed == true &&
        (positionStream == null || positionStream!.isPaused)) {
      positionStreamData();
    }
    setState(() {});
  }

  bool get _recoveryDialogOnTop {
    final route = ModalRoute.of(context);
    return route != null && !route.isCurrent;
  }

  void _scheduleResumeRetry() {
    if (_resumeRetryScheduled) return;
    _resumeRetryScheduled = true;
    Future<void>.delayed(const Duration(seconds: 3), () {
      _resumeRetryScheduled = false;
      if (mounted) unawaited(_onResumed());
    });
  }

  /// The last resort: the server could not be reached or understood twice in a
  /// row, so nothing on this screen can be trusted. Drop every timer and
  /// listener and start over from the same place a cold start does, which
  /// puts the rider on the right screen (Home, the active trip, or the
  /// invoice) from whatever the server says. The app is never restarted.
  void _controlledStateReset() {
    timers?.cancel();
    timers = null;
    positionStream?.cancel();
    positionStream = null;
    requestStreamStart?.cancel();
    requestStreamEnd?.cancel();
    rideStreamStart?.cancel();
    rideStreamUpdate?.cancel();
    requestStreamStart = null;
    requestStreamEnd = null;
    rideStreamStart = null;
    rideStreamUpdate = null;
    _cancelling = false;
    pendingRecoveryOfferDialogShown = false;
    if (_leavingToHome) return;
    _leavingToHome = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoadingPage()),
          (route) => false);
    });
  }

  /// One authoritative refresh of the ride from the server when the app comes
  /// back, then the UI follows the server: a ride that was cancelled or taken
  /// while away ends the search screen instead of "searching" on stale flags.
  Future<void> _reconcileAfterResume() async {
    if (!mounted) return;
    final key = isDarkTheme == true ? 'assets/dark.json' : 'assets/map_style_black.json';
    if (key != _appliedMapStyleKey) {
      mapStyle = await rootBundle.loadString(key);
      _appliedMapStyleKey = key;
      _controller?.setMapStyle(mapStyle);
    }
    final wasSearching = userRequestData.isNotEmpty &&
        userRequestData['accepted_at'] == null;
    if (userRequestData.isNotEmpty) {
      await refreshUserRequestState(userRequestData['id']?.toString());
    } else {
      await getUserDetails();
    }
    if (!mounted) return;
    if (wasSearching && userRequestData.isEmpty) {
      // The server no longer has this ride (cancelled, expired): stop
      // searching and go Home once, instead of "searching" on stale flags.
      timers?.cancel();
      timers = null;
      _goHomeOnce();
      return;
    }
    if (timers == null &&
        userRequestData.isNotEmpty &&
        userRequestData['accepted_at'] == null) {
      timer();
    }
    if (locationAllowed == true &&
        (positionStream == null || positionStream!.isPaused)) {
      positionStreamData();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    if (timers != null) {
      timers?.cancel();
      timers = null;
    }

    _controller?.dispose();
    _controller = null;
    animationController?.dispose();

    super.dispose();
  }

//running timer
  timer() {
    _pendingRequestRefreshTick = 0;
    if (isLegacyBiddingSearchRequest(userRequestData, userDetails)) {
      timers?.cancel();
      timers = Timer.periodic(const Duration(seconds: 1), (timer) {
        valueNotifierTimer.incrementNotifier();
      });
    } else {
      timers?.cancel();
      final configuredDuration =
          userRequestData['maximum_time_for_find_drivers_for_regular_ride'] ??
              userDetails['maximum_time_for_find_drivers_for_regular_ride'];
      timing = int.tryParse(configuredDuration?.toString() ?? '') ?? 0;
      // The backend's own no-driver-found dispatch doesn't fire until the
      // dispatch-retry cron has ticked PAST this same duration (it cancels
      // once attempts exceed it, one attempt per ~1-minute tick - so it can
      // take up to a minute longer than this raw duration). Without this
      // margin, whenever recovery is enabled this client timer reaches 0
      // and self-cancels the ride before the backend has even had a chance
      // to flip recovery_active, defeating recovery every time.
      final recoveryEnabled = (int.tryParse(
              userDetails['missed_ride_recovery_window_seconds']
                      ?.toString() ??
                  '') ??
          0) >
          0;
      if (recoveryEnabled && timing > 0) {
        timing = timing + 90;
      }
      if (mounted) {
        timers = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (timing != null) {
            if (userRequestData.isNotEmpty &&
                userRequestData['accepted_at'] == null &&
                timing > 0) {
              timing--;
              _pendingRequestRefreshTick++;
              if (_pendingRequestRefreshTick % 4 == 0) {
                final requestId = userRequestData['id']?.toString();
                if (requestId != null && requestId.isNotEmpty) {
                  unawaited(refreshUserRequestState(requestId));
                  if (stillSearchingForDriver) {
                    unawaited(_checkForRecoveryDriverOffer(requestId));
                  }
                }
              }
              valueNotifierBook.incrementNotifier();
            } else if (userRequestData.isNotEmpty &&
                userRequestData['accepted_at'] == null &&
                timing == 0) {
              // Missed-ride recovery: before giving up client-side, check
              // whether the backend already kept this ride open for a
              // recovery window instead of cancelling it (see
              // NoDriverFoundNotifyJob/MissedRideRecoveryService). Without
              // this check, this timer would cancel the ride out from under
              // that recovery window every time, regardless of the backend.
              final requestId = userRequestData['id']?.toString();
              if (requestId != null && requestId.isNotEmpty) {
                await refreshUserRequestState(requestId);
              }
              final recoveryWindowSeconds = int.tryParse(userDetails[
                              'missed_ride_recovery_window_seconds']
                          ?.toString() ??
                      '') ??
                  0;
              if (userRequestData['recovery_active'] == true &&
                  recoveryWindowSeconds > 0 &&
                  !stillSearchingForDriver) {
                timing = recoveryWindowSeconds;
                setState(() {
                  stillSearchingForDriver = true;
                });
                valueNotifierBook.incrementNotifier();
                return;
              }

              var val = await cancelRequest();

              setState(() {
                noDriverFound = true;
                stillSearchingForDriver = false;
              });

              timer.cancel();
              timers = null;
              timing = null;
              if (val == 'logout') {
                navigateLogout();
              }
            } else {
              timer.cancel();
              timers = null;
              timing = null;
            }
          } else {
            timer.cancel();
            timers = null;
            timing = null;
          }
        });
      }
    }
  }

  /// One driver going "ready" during a recovery window is a proposal, not
  /// an assignment - the rider must confirm before anyone is actually
  /// assigned (see RideRecoveryController::confirmDriver). This surfaces
  /// that choice as soon as it appears; a dialog already open is left alone
  /// rather than stacking a second one on top.
  Future<void> _checkForRecoveryDriverOffer(String requestId) async {
    if (pendingRecoveryOfferDialogShown) return;
    final result = await fetchPendingRecoveryOffers(requestId);
    if (result != 'success' || !mounted) return;
    if (pendingRecoveryOffers.isEmpty) return;

    final offer = pendingRecoveryOffers.first;
    pendingRecoveryOfferDialogShown = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(choosenLanguage == 'ar' ? 'لقينالك سواق' : 'We found a driver'),
        content: Text(choosenLanguage == 'ar'
            ? 'السواق ${offer['driver_name'] ?? ''} مستعد يوصلك. تأكده؟'
            : 'Driver ${offer['driver_name'] ?? ''} is ready to pick you up. Confirm?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await rejectRecoveryDriver(offer['offer_id']);
            },
            child: Text(choosenLanguage == 'ar' ? 'لا، رفض' : 'No, decline'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final requestId = userRequestData['id']?.toString();
              await confirmRecoveryDriver(offer['offer_id']);
              if (requestId != null) {
                await refreshUserRequestState(requestId);
              }
              if (mounted) setState(() {});
            },
            child: Text(choosenLanguage == 'ar' ? 'نعم، أكد' : 'Yes, confirm'),
          ),
        ],
      ),
    );
    pendingRecoveryOfferDialogShown = false;
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

    // ETA may finish while marker assets are loading. Never clear the chosen
    // default service after the quote has already selected it.
    if (etaDetails.isEmpty) choosenVehicle = null;
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
    final changed = await guardedPush(
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
    if (isLoading) return;
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
        // A specific backend error (tripReqError) already explains what went
        // wrong; only fall back to the generic "no service" message when
        // nothing more specific was reported.
        if (!tripReqError) {
          serviceNotAvailable = true;
        }
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
