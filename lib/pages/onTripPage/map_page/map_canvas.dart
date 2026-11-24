// ignore_for_file: invalid_use_of_protected_member
part of '../map_page.dart';

extension _MapCanvas on _MapsState {
  Widget buildLiveMapCanvas(Size media) {
    return SizedBox(
      height: media.height * 0.96,
      width: media.width * 1,
      child: StreamBuilder<DatabaseEvent>(
        // A stable, shared stream: creating a query here made every rebuild
        // tear the native listener down and open a new one (see LiveQueries).
        stream: LiveQueries.watchQuery(
          'drivers-near:$lower:$higher',
          () => FirebaseDatabase.instance
              .ref('drivers')
              .orderByChild('g')
              .startAt(lower)
              .endAt(higher),
          coalesce: const Duration(milliseconds: 800),
        ),
        builder: (context, AsyncSnapshot<DatabaseEvent> event) {
          if (event.hasData) {
            List driverData = [];
            event.data!.snapshot.children
                // ignore: avoid_function_literals_in_foreach_calls
                .forEach((element) {
              driverData.add(element.value);
            });
            // ignore: avoid_function_literals_in_foreach_calls
            driverData.forEach((element) {
              // a captain's car is drawn near his spot, never exactly on it (city setting)
              if (element is Map && element['l'] is List && (element['l'] as List).length >= 2) {
                element['l'] = MapPrivacy.blur(element['id'], element['l'] as List, homeCarPrivacyMeters);
              }
              if (element['is_active'] == 1 &&
                  element['is_available'] == true) {
                if ((choosenTransportType == 0 &&
                        element['transport_type'] == 'taxi') ||
                    choosenTransportType == 0 &&
                        element['transport_type'] == 'both') {
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                      element['updated_at']);

                  if (DateTime.now().difference(dt).inMinutes <= 2) {
                    if (myMarkers
                        .where((e) => e.markerId.toString().contains(
                            'car#${element['id']}#${element['vehicle_type_icon']}'))
                        .isEmpty) {
                      myMarkers.add(Marker(
                        markerId: MarkerId(
                            'car#${element['id']}#${element['vehicle_type_icon']}'),
                        rotation: (myBearings[element['id'].toString()] != null)
                            ? myBearings[element['id'].toString()]
                            : 0.0,
                        position: LatLng(element['l'][0], element['l'][1]),
                        icon: (element['vehicle_type_icon'] == 'taxi')
                            ? pinLocationIcon
                            : bikeIcon,
                      ));
                    } else {
                      if (myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .latitude !=
                              element['l'][0] ||
                          myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .longitude !=
                              element['l'][1]) {
                        var dist = calculateDistance(
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .latitude,
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .longitude,
                            element['l'][0],
                            element['l'][1]);
                        if (dist > 100) {
                          animationController = AnimationController(
                            duration: const Duration(
                                milliseconds:
                                    1500), //Animation duration of marker

                            vsync: this, //From the widget
                          );

                          animateCar(
                              myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .latitude,
                              myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .longitude,
                              element['l'][0],
                              element['l'][1],
                              _mapMarkerSink,
                              this,
                              'car#${element['id']}#${element['vehicle_type_icon']}',
                              element['id'],
                              (element['vehicle_type_icon'] == 'taxi')
                                  ? pinLocationIcon
                                  : bikeIcon);
                        }
                      }
                    }
                  }
                } else if ((choosenTransportType == 1 &&
                        element['transport_type'] == 'delivery') ||
                    (choosenTransportType == 1 &&
                        element['transport_type'] == 'both')) {
                  DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                      element['updated_at']);

                  if (DateTime.now().difference(dt).inMinutes <= 2) {
                    if (myMarkers
                        .where((e) => e.markerId.toString().contains(
                            'car#${element['id']}#${element['vehicle_type_icon']}'))
                        .isEmpty) {
                      myMarkers.add(Marker(
                        markerId: MarkerId(
                            'car#${element['id']}#${element['vehicle_type_icon']}'),
                        rotation: (myBearings[element['id'].toString()] != null)
                            ? myBearings[element['id'].toString()]
                            : 0.0,
                        position: LatLng(element['l'][0], element['l'][1]),
                        icon: (element['vehicle_type_icon'] == 'truck')
                            ? deliveryIcon
                            : bikeIcon,
                      ));
                    } else {
                      if (myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .latitude !=
                              element['l'][0] ||
                          myMarkers
                                  .lastWhere((e) => e.markerId.toString().contains(
                                      'car#${element['id']}#${element['vehicle_type_icon']}'))
                                  .position
                                  .longitude !=
                              element['l'][1]) {
                        var dist = calculateDistance(
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .latitude,
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .longitude,
                            element['l'][0],
                            element['l'][1]);
                        if (dist > 100) {
                          animationController = AnimationController(
                            duration: const Duration(
                                milliseconds:
                                    1500), //Animation duration of marker

                            vsync: this, //From the widget
                          );

                          animateCar(
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .latitude,
                            myMarkers
                                .lastWhere((e) => e.markerId.toString().contains(
                                    'car#${element['id']}#${element['vehicle_type_icon']}'))
                                .position
                                .longitude,
                            element['l'][0],
                            element['l'][1],
                            _mapMarkerSink,
                            this,
                            'car#${element['id']}#${element['vehicle_type_icon']}',
                            element['id'],
                            (element['vehicle_type_icon'] == 'truck')
                                ? deliveryIcon
                                : bikeIcon,
                          );
                        }
                      }
                    }
                  }
                }
              } else {
                if (myMarkers
                    .where((e) => e.markerId.toString().contains(
                        'car#${element['id']}#${element['vehicle_type_icon']}'))
                    .isNotEmpty) {
                  myMarkers.removeWhere((e) => e.markerId.toString().contains(
                      'car#${element['id']}#${element['vehicle_type_icon']}'));
                }
              }
            });
            HomeMapCars.settle(myMarkers, _carsCenter ?? _homePickupPoint,
                present: driverData.map((e) => e is Map ? e['id']?.toString() : null).whereType<String>().toSet());
          }
          if (mapType == 'google') {
            _ensureMascotIcon();
            unawaited(ServiceZones.load());
            return ValueListenableBuilder<Set<Polygon>>(
                valueListenable: ServiceZones.polygons,
                builder: (context, _, __) => StreamBuilder<List<Marker>>(
                stream: carMarkerStream,
                builder: (context, snapshot) {
                  return GoogleMap(
                    onMapCreated: _onMapCreated,
                    compassEnabled: false,
                    initialCameraPosition: CameraPosition(
                      target: center,
                      zoom: widget.animateColdLaunch
                          ? MapLaunchCoordinator.regionalZoom
                          : 15.0,
                    ),
                    // panning or zooming the home map changes nothing and asks nobody for an
                    // address; only «من أين» (pickup-adjust mode) moves the pickup with the map
                    onCameraMove: (CameraPosition position) {
                      _centerLocation = position.target;
                      if (_pickupAdjust && !_isPickingLocation) {
                        setState(() => _isPickingLocation = true);
                      }
                    },
                    onCameraIdle: () {
                      if (_pickupAdjust) unawaited(_settlePickupAdjust());
                    },
                    minMaxZoomPreference: const MinMaxZoomPreference(8.0, 20.0),
                    myLocationButtonEnabled: false,
                    // the cars, and the mascot on the pickup (the phone's place on the home screen)
                    markers: _withPickupMarker(myMarkers.whereType<Marker>()),
                    // where Taxista works (the market's zones), drawn softly under everything else
                    polygons: ServiceZones.polygons.value,
                    buildingsEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                  );
                }));
          }
          return StreamBuilder<List<Marker>>(
              stream: carMarkerStream,
              builder: (context, snapshot) {
                return fm.FlutterMap(
                  mapController: _fmController,
                  options: fm.MapOptions(
                      // the same rule as the Google map: only «من أين» moves the pickup, and the
                      // address is asked once when the map stops
                      onMapEvent: (v) {
                        _centerLocation = LatLng(v.camera.center.latitude, v.camera.center.longitude);
                        if (!_pickupAdjust) return;
                        // a move made by the app (to the pickup, «موقعي») lands at once: no end event follows
                        if (v.source == fm.MapEventSource.mapController ||
                            v is fm.MapEventMoveEnd ||
                            v is fm.MapEventFlingAnimationEnd ||
                            v is fm.MapEventFlingAnimationNotStarted ||
                            v is fm.MapEventDoubleTapZoomEnd ||
                            v is fm.MapEventRotateEnd) {
                          unawaited(_settlePickupAdjust());
                        } else if (v is fm.MapEventWithMove && !_isPickingLocation) {
                          setState(() => _isPickingLocation = true);
                        }
                      },
                      initialCenter:
                          fmlt.LatLng(center.latitude, center.longitude),
                      initialZoom: 16,
                      onTap: (P, L) {}),
                  children: [
                    fm.TileLayer(
                      urlTemplate: (isDarkTheme == false)
                          ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                          : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.taxistapro.user',
                    ),
                    fm.MarkerLayer(
                      markers: myMarkers
                          .asMap()
                          .map(
                            (k, value) => MapEntry(
                              k,
                              fm.Marker(
                                alignment: Alignment.topCenter,
                                point: fmlt.LatLng(
                                    myMarkers[k].position.latitude,
                                    myMarkers[k].position.longitude),
                                width: media.width * 0.7,
                                height: 50,
                                child: RotationTransition(
                                  turns: AlwaysStoppedAnimation(
                                      myMarkers[k].rotation / 360),
                                  child: Image.asset(
                                    (myMarkers[k]
                                                .markerId
                                                .toString()
                                                .replaceAll('MarkerId(', '')
                                                .replaceAll(')', '')
                                                .split('#')[2]
                                                .toString() ==
                                            'taxi')
                                        ? 'assets/images/top-taxi.png'
                                        : (myMarkers[k]
                                                    .markerId
                                                    .toString()
                                                    .replaceAll('MarkerId(', '')
                                                    .replaceAll(')', '')
                                                    .split('#')[2]
                                                    .toString() ==
                                                'truck')
                                            ? 'assets/images/deliveryicon.png'
                                            : 'assets/images/bike.png',
                                  ),
                                ),
                              ),
                            ),
                          )
                          .values
                          .toList(),
                    ),
                    if (_pickupMarkerPoint != null)
                      fm.MarkerLayer(markers: [
                        fm.Marker(
                          point: fmlt.LatLng(_pickupMarkerPoint!.latitude, _pickupMarkerPoint!.longitude),
                          width: 160,
                          height: riderMascotHeight + 40,
                          alignment: Alignment.topCenter,
                          // the feet on the point
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            RiderMascotBubble(text: _riderFirstName()),
                            Image.asset(riderMascotAsset, width: riderMascotWidth, height: riderMascotHeight, fit: BoxFit.contain),
                          ]),
                        ),
                      ]),
                    const fm.RichAttributionWidget(
                      attributions: [],
                    ),
                  ],
                );
              });
        },
      ),
    );
  }
}
