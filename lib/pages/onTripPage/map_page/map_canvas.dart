part of '../map_page.dart';

extension _MapCanvas on _MapsState {
  Widget buildLiveMapCanvas(Size media) {
    return SizedBox(
      height: media.height * 0.96,
      width: media.width * 1,
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('drivers')
            .orderByChild('g')
            .startAt(lower)
            .endAt(higher)
            .onValue
            .asBroadcastStream(),
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
          }
          if (mapType == 'google') {
            return StreamBuilder<List<Marker>>(
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
                    onCameraMove: (CameraPosition position) async {
                      if (addressList.isEmpty) {
                        _centerLocation = position.target;
                      } else {
                        _centerLocation = position.target;
                      }
                    },
                    onCameraIdle: () async {
                      if (_lastRequestedLocation != null &&
                          _lastRequestedLocation!.latitude ==
                              _centerLocation.latitude &&
                          _lastRequestedLocation!.longitude ==
                              _centerLocation.longitude) {
                        return;
                      }

                      _lastRequestedLocation = _centerLocation;

                      if (userDetails[
                              'enable_map_location_icon_drag_and_drop_feature'] ==
                          '0') {
                        if ((_bottom == 0 &&
                            !_pickaddress &&
                            addressList
                                .where((e) => e.type == 'pickup')
                                .isNotEmpty)) {
                          setState(() {});
                        }

                        if (addressList
                            .where((e) => e.type == 'pickup')
                            .isEmpty) {
                          if (_bottom == 0 && !_pickaddress) {
                            String? val = await geoCoding(
                                _centerLocation.latitude,
                                _centerLocation.longitude);

                            setState(() {
                              if (addressList
                                  .where((e) => e.type == 'pickup')
                                  .isNotEmpty) {
                                var add = addressList
                                    .firstWhere((e) => e.type == 'pickup');
                                add.address = val ?? '';
                                add.latlng = LatLng(_centerLocation.latitude,
                                    _centerLocation.longitude);
                              } else {
                                addressList.add(AddressList(
                                  id: '1',
                                  type: 'pickup',
                                  address: val ?? '',
                                  latlng: LatLng(_centerLocation.latitude,
                                      _centerLocation.longitude),
                                  name: userDetails['name'],
                                  number: userDetails['mobile'],
                                  pickup: true,
                                ));
                              }

                              _lastCenter = _centerLocation;
                            });
                          } else if (_pickaddress) {
                            setState(() {
                              _pickaddress = false;
                            });
                          }
                        } else if (_pickaddress) {
                          setState(() {
                            _pickaddress = false;
                          });
                        }
                      } else if (userDetails[
                              'enable_map_location_icon_drag_and_drop_feature'] ==
                          '1') {
                        String? val = await geoCoding(_centerLocation.latitude,
                            _centerLocation.longitude);

                        setState(() {
                          if (addressList
                              .where((e) => e.type == 'pickup')
                              .isNotEmpty) {
                            var add = addressList
                                .firstWhere((e) => e.type == 'pickup');
                            add.address = val ?? '';
                            add.latlng = LatLng(_centerLocation.latitude,
                                _centerLocation.longitude);
                          } else {
                            addressList.add(AddressList(
                              id: '1',
                              type: 'pickup',
                              address: val ?? '',
                              pickup: true,
                              latlng: LatLng(_centerLocation.latitude,
                                  _centerLocation.longitude),
                              name: userDetails['name'],
                              number: userDetails['mobile'],
                            ));
                          }

                          _lastCenter = _centerLocation;
                          ischanged = false;
                        });
                      }
                    },
                    minMaxZoomPreference: const MinMaxZoomPreference(8.0, 20.0),
                    myLocationButtonEnabled: false,
                    markers: Set<Marker>.from(myMarkers),
                    buildingsEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                  );
                });
          }
          return StreamBuilder<List<Marker>>(
              stream: carMarkerStream,
              builder: (context, snapshot) {
                return fm.FlutterMap(
                  mapController: _fmController,
                  options: fm.MapOptions(
                      onMapEvent: (v) async {
                        _centerLocation = LatLng(v.camera.center.latitude,
                            v.camera.center.longitude);

                        if (_lastRequestedLocation != null &&
                            _lastRequestedLocation!.latitude ==
                                _centerLocation.latitude &&
                            _lastRequestedLocation!.longitude ==
                                _centerLocation.longitude) {
                          return;
                        }

                        _lastRequestedLocation = _centerLocation;

                        if (v.source ==
                                fm.MapEventSource.nonRotatedSizeChange &&
                            addressList.isEmpty) {
                          setState(() {});
                          String? val = await geoCoding(
                              _centerLocation.latitude,
                              _centerLocation.longitude);

                          if (val != null && val.isNotEmpty) {
                            setState(() {
                              if (addressList
                                  .where((element) => element.type == 'pickup')
                                  .isNotEmpty) {
                                var add = addressList.firstWhere(
                                    (element) => element.type == 'pickup');
                                add.address = val;
                                add.latlng = _centerLocation;
                              } else {
                                addressList.add(AddressList(
                                  id: '1',
                                  type: 'pickup',
                                  address: val,
                                  pickup: true,
                                  latlng: _centerLocation,
                                  name: userDetails['name'],
                                  number: userDetails['mobile'],
                                ));
                              }
                            });

                            _lastCenter = _centerLocation;
                            ischanged = false;
                          }
                        }

                        if (v.source == fm.MapEventSource.dragEnd) {
                          setState(() {});
                          if (userDetails[
                                  'enable_map_location_icon_drag_and_drop_feature'] ==
                              '0') {
                            String? val = await geoCoding(
                                _centerLocation.latitude,
                                _centerLocation.longitude);

                            if (val != null && val.isNotEmpty) {
                              lowerLat =
                                  _centerLocation.latitude - (lat * 1.24);
                              lowerLon =
                                  _centerLocation.longitude - (lon * 1.24);
                              greaterLat =
                                  _centerLocation.latitude + (lat * 1.24);
                              greaterLon =
                                  _centerLocation.longitude + (lon * 1.24);

                              lower = geo.encode(lowerLon, lowerLat);
                              higher = geo.encode(greaterLon, greaterLat);

                              fdb = FirebaseDatabase.instance
                                  .ref('drivers')
                                  .orderByChild('g')
                                  .startAt(lower)
                                  .endAt(higher);

                              setState(() {
                                if (addressList
                                    .where(
                                        (element) => element.type == 'pickup')
                                    .isNotEmpty) {
                                  var add = addressList.firstWhere(
                                      (element) => element.type == 'pickup');
                                  add.address = val;
                                  add.latlng = _centerLocation;
                                } else {
                                  addressList.add(AddressList(
                                    id: '1',
                                    type: 'pickup',
                                    address: val,
                                    pickup: true,
                                    latlng: _centerLocation,
                                    name: userDetails['name'],
                                    number: userDetails['mobile'],
                                  ));
                                }

                                _lastCenter = _centerLocation;
                                ischanged = false;
                              });
                            }
                          }
                        }
                      },
                      onPositionChanged: (p, l) async {
                        if (l == false) {
                          if (addressList.isEmpty) {
                            _centerLocation =
                                LatLng(p.center.latitude, p.center.longitude);

                            if (_lastRequestedLocation != null &&
                                _lastRequestedLocation!.latitude ==
                                    _centerLocation.latitude &&
                                _lastRequestedLocation!.longitude ==
                                    _centerLocation.longitude) {
                              return;
                            }

                            _lastRequestedLocation = _centerLocation;

                            setState(() {});

                            String? val = await geoCoding(
                                _centerLocation.latitude,
                                _centerLocation.longitude);

                            lowerLat = _centerLocation.latitude - (lat * 1.24);

                            if (val != null && val.isNotEmpty) {
                              setState(() {
                                if (addressList
                                    .where((e) => e.type == 'pickup')
                                    .isNotEmpty) {
                                  var add = addressList
                                      .firstWhere((e) => e.type == 'pickup');
                                  add.address = val;
                                  add.latlng = _centerLocation;
                                } else {
                                  addressList.add(AddressList(
                                    id: '1',
                                    type: 'pickup',
                                    address: val,
                                    pickup: true,
                                    latlng: _centerLocation,
                                    name: userDetails['name'],
                                    number: userDetails['mobile'],
                                  ));
                                }

                                _lastCenter = _centerLocation;
                                ischanged = false;
                              });
                            }
                          }
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
                      userAgentPackageName: 'com.example.app',
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
