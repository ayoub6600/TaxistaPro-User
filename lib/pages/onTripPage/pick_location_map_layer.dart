part of 'pick_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _PickLocSections0 on _PickupLocationState {
  Widget _pickMapLayer(Size media) {
    return SizedBox(
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
                    //pick current location
                    _centerLocation = position.target;
                    if (!_isPickingLocation) {
                      setState(() {
                        _isPickingLocation = true;
                      });
                    }
                  },

                  onCameraIdle: () async {
                    // ✅ تجاهل لو نفس الموقع لتقليل الطلبات
                    if (_lastRequestedLocation != null &&
                        _lastRequestedLocation!.latitude == _centerLocation.latitude &&
                        _lastRequestedLocation!.longitude == _centerLocation.longitude) {
                      setState(() {
                        _isPickingLocation = false;
                      });
                      return;
                    }

                    _lastRequestedLocation = _centerLocation;

                    if (userDetails['enable_map_location_icon_drag_and_drop_feature'] == '0') {
                      if (pickupAddressConfirmation != '') {
                        setState(() {
                          _isPickingLocation = false;
                        });
                      } else {
                        if (!useMyAddress) {
                          String val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude) ?? '';
                          setState(() {
                            _center = _centerLocation;
                            pickupAddressConfirmation = val;
                            _isPickingLocation = false;
                          });
                        } else {
                          setState(() {
                            useMyAddress = false;
                            _isPickingLocation = false;
                          });
                        }
                      }
                    } else {
                      if (!useMyAddress) {
                        String val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude) ?? '';
                        setState(() {
                          _center = _centerLocation;
                          pickupAddressConfirmation = val;
                          _isPickingLocation = false;
                        });
                      } else {
                        setState(() {
                          useMyAddress = false;
                          _isPickingLocation = false;
                        });
                      }
                    }
                  },

                  // onCameraIdle: () async {
                  //   if (userDetails[
                  //           'enable_map_location_icon_drag_and_drop_feature'] ==
                  //       '0') {
                  //     if (pickupAddressConfirmation != '') {
                  //       setState(() {});
                  //     } else {
                  //       if (useMyAddress == false) {
                  //         var val = await geoCoding(
                  //             _centerLocation.latitude,
                  //             _centerLocation.longitude);
                  //         setState(() {
                  //           _center = _centerLocation;
                  //           pickupAddressConfirmation = val;
                  //         });
                  //       }
                  //       if (useMyAddress == true) {
                  //         setState(() {
                  //           useMyAddress = false;
                  //         });
                  //       }
                  //     }
                  //   } else {
                  //     if (useMyAddress == false) {
                  //       var val = await geoCoding(
                  //           _centerLocation.latitude,
                  //           _centerLocation.longitude);
                  //       setState(() {
                  //         _center = _centerLocation;
                  //         pickupAddressConfirmation = val;
                  //       });
                  //     }
                  //     if (useMyAddress == true) {
                  //       setState(() {
                  //         useMyAddress = false;
                  //       });
                  //     }
                  //   }
                  // },

                  minMaxZoomPreference: const MinMaxZoomPreference(8.0, 20.0),
                  myLocationButtonEnabled: false,
                  buildingsEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                )
              : fm.FlutterMap(
                  mapController: _fmController,
                  options: fm.MapOptions(
                      onMapEvent: (v) async {
                        _centerLocation = LatLng(
                          v.camera.center.latitude,
                          v.camera.center.longitude,
                        );

                        if (_lastRequestedLocation != null &&
                            _lastRequestedLocation!.latitude == _centerLocation.latitude &&
                            _lastRequestedLocation!.longitude == _centerLocation.longitude) {
                          return;
                        }

                        _lastRequestedLocation = _centerLocation;

                        if (v.source == fm.MapEventSource.nonRotatedSizeChange && addressList.isEmpty) {
                          setState(() {});
                          String val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude) ?? '';
                          if (val.isNotEmpty) {
                            setState(() {
                              _center = _centerLocation;
                              pickupAddressConfirmation = val;
                            });
                          }
                        }

                        if (v.source == fm.MapEventSource.dragEnd) {
                          if (userDetails['enable_map_location_icon_drag_and_drop_feature'] == '1') {
                            String val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude) ?? '';
                            if (val.isNotEmpty) {
                              setState(() {
                                _center = _centerLocation;
                                dropAddressConfirmation = val;
                              });
                            }
                          }
                        }
                      },
                      onPositionChanged: (p, l) async {
                        if (l == false) {
                          _centerLocation = LatLng(p.center.latitude, p.center.longitude);
                          setState(() {});

                          var val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude);
                          if (val != '') {}
                        }
                      },
                      // interactiveFlags:
                      //     ~fm.InteractiveFlag.doubleTapZoom,
                      initialCenter: fmlt.LatLng(center.latitude, center.longitude),
                      initialZoom: 16,
                      onTap: (P, L) {
                        setState(() {});
                      }),
                  children: [
                    fm.TileLayer(
                      // minZoom: 10,
                      urlTemplate:
                          // 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          (isDarkTheme == false)
                              ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.taxistapro.user',
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
                    padding: EdgeInsets.all(media.width * 0.05),
                    width: media.width * 0.6,
                    height: media.width * 0.3,
                    decoration: BoxDecoration(
                        color: page,
                        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.1), spreadRadius: 2)],
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languages[choosenLanguage]['text_loc_permission'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                _state = '';
                              });
                              await location.requestPermission();
                              getLocs();
                            },
                            child: Text(
                              languages[choosenLanguage]['text_ok'],
                              style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold, fontSize: media.width * twenty, color: buttonColor),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : Container(),
    );
  }
}
