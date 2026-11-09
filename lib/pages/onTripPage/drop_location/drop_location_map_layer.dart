part of '../drop_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _DropLocationSections0 on _DropLocationView {
  Widget _dropMapLayer(Size media) {
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
                  polygons: ServiceZones.polygons.value,
                  minMaxZoomPreference: const MinMaxZoomPreference(8.0, 20.0),
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
                        final movementStarted = source == fm.MapEventSource.dragStart ||
                            source == fm.MapEventSource.multiFingerGestureStart;
                        final movementEnded =
                            source == fm.MapEventSource.dragEnd || source == fm.MapEventSource.multiFingerEnd;
                        if (movementStarted && !_isMapMoving && mounted) {
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
                        if (source == fm.MapEventSource.nonRotatedSizeChange && dropAddressConfirmation.isEmpty) {
                          _settleMapSelection();
                        }
                      },
                      initialCenter: fmlt.LatLng(_center.latitude, _center.longitude),
                      initialZoom: 16,
                      onTap: (P, L) {
                        setState(() {});
                      }),
                  children: [
                    fm.TileLayer(
                      // minZoom: 10,
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.Ayoub.Usertaxista',
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
