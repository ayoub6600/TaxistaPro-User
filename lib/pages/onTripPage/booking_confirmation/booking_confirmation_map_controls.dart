part of '../booking_confirmation.dart';

mixin _BookingConfirmationMapControls
    on State<BookingConfirmation>, _BookingConfirmationController {
  List<Widget> buildMapControls(Size media) {
    return [
      Positioned(
        bottom: media.width * 1.25,
        child: SizedBox(
          width: media.width * 0.9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (userRequestData.isNotEmpty &&
                  userRequestData['accepted_at'] != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(media.width * 0.02),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2)
                          ],
                          color: page),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(media.width * 0.02),
                        child: InkWell(
                          onTap: () async {
                            await Share.share(
                                'Your Driver is ${userRequestData['driverDetail']['data']['name']}. ${userRequestData['driverDetail']['data']['car_color']} ${userRequestData['driverDetail']['data']['car_make_name']} ${userRequestData['driverDetail']['data']['car_model_name']}, Vehicle Number: ${userRequestData['driverDetail']['data']['car_number']}. Track with link: ${url}track/request/${userRequestData['id']}');
                          },
                          child: Container(
                              height: media.width * 0.1,
                              width: media.width * 0.1,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.share,
                                size: media.width * sixteen,
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
                      userRequestData['is_trip_start'] == 1)
                  ? Container(
                      decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2)
                          ],
                          color: page,
                          borderRadius:
                              BorderRadius.circular(media.width * 0.02)),
                      child: Material(
                        borderRadius: BorderRadius.circular(media.width * 0.02),
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () async {
                              setState(() {
                                showSos = true;
                              });
                            },
                            child: Container(
                              height: media.width * 0.1,
                              width: media.width * 0.1,
                              alignment: Alignment.center,
                              child: Text(
                                'SOS',
                                style: GoogleFonts.notoSans(
                                    fontSize: media.width * fourteen,
                                    color: textColor),
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
                              BorderRadius.circular(media.width * 0.02),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2)
                          ],
                          color: page),
                      child: Material(
                        borderRadius: BorderRadius.circular(media.width * 0.02),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (locationAllowed == true) {
                              if (mapType == 'google') {
                                if (currentLocation != null) {
                                  _controller?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          currentLocation, 18.0));
                                  center = currentLocation;
                                } else {
                                  _controller?.animateCamera(
                                      CameraUpdate.newLatLngZoom(center, 18.0));
                                }
                              } else {
                                if (currentLocation != null) {
                                  _controller?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          currentLocation, 18.0));
                                  _fmController.move(
                                      fmlt.LatLng(currentLocation.latitude,
                                          currentLocation.longitude),
                                      14);
                                  center = currentLocation;
                                } else {
                                  _fmController.move(
                                      fmlt.LatLng(
                                          center.latitude, center.longitude),
                                      14);
                                }
                              }
                            } else {
                              if (serviceEnabled == true) {
                                setState(() {
                                  _locationDenied = true;
                                });
                              } else {
                                await geolocs.Geolocator.getCurrentPosition(
                                    desiredAccuracy:
                                        geolocs.LocationAccuracy.low);
                                if (await geolocs.GeolocatorPlatform.instance
                                    .isLocationServiceEnabled()) {
                                  setState(() {
                                    _locationDenied = true;
                                  });
                                }
                              }
                            }
                          },
                          child: SizedBox(
                            height: media.width * 0.1,
                            width: media.width * 0.1,
                            child:
                                Icon(Icons.my_location_sharp, color: textColor),
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
              duration: const Duration(milliseconds: 500),
              right: media.width * 0.05,
              top: (_ontripBottom) ? media.width * 0.2 : media.width * 0.8,
              child: InkWell(
                onTap: () async {
                  if (_ontripBottom) {
                    if (userRequestData['is_trip_start'] == 1) {
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
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2)
                      ],
                      color: page,
                      borderRadius: BorderRadius.circular(media.width * 0.02)),
                  child: Icon(
                    (_ontripBottom) ? Icons.zoom_in_map : Icons.zoom_out_map,
                    color: textColor,
                  ),
                ),
              ))
          : Container(),
    ];
  }
}
