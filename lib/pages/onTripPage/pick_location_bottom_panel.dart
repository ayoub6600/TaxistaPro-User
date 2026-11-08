part of 'pick_loc_select.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension _PickLocSections1 on _PickupLocationState {
  Widget _pickBottomPanel(Size media) {
    return Positioned(
        bottom: 0 + MediaQuery.of(context).viewInsets.bottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 20, left: 20),
              child: InkWell(
                onTap: () async {
                  if (locationAllowed == true) {
                    if (currentLocation != null) {
                      _controller?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 18.0));
                      center = currentLocation;
                    } else {
                      _controller?.animateCamera(CameraUpdate.newLatLngZoom(center, 18.0));
                    }
                  } else {
                    if (serviceEnabled == true) {
                      setState(() {
                        _locationDenied = true;
                      });
                    } else {
                      // await location.requestService();
                      await geolocs.Geolocator.getCurrentPosition(desiredAccuracy: geolocs.LocationAccuracy.low);
                      if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
                        setState(() {
                          _locationDenied = true;
                        });
                      }
                    }
                  }
                },
                child: Container(
                  height: media.width * 0.1,
                  width: media.width * 0.1,
                  decoration: BoxDecoration(
                      boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black.withOpacity(0.2), spreadRadius: 2)],
                      color: page,
                      borderRadius: BorderRadius.circular(media.width * 0.02)),
                  child: Icon(Icons.my_location_sharp, color: textColor),
                ),
              ),
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Container(
              color: page,
              width: media.width * 1,
              padding: EdgeInsets.all(media.width * 0.05),
              child: Column(
                children: [
                  Container(
                      padding: EdgeInsets.fromLTRB(
                          media.width * 0.03, media.width * 0.01, media.width * 0.03, media.width * 0.01),
                      height: media.width * 0.1,
                      width: media.width * 0.9,
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(media.width * 0.02),
                          color: page),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            height: media.width * 0.04,
                            width: media.width * 0.04,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.3)),
                            child: Container(
                              height: media.width * 0.02,
                              width: media.width * 0.02,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                            ),
                          ),
                          SizedBox(width: media.width * 0.02),
                          Expanded(
                            child: (pickupAddressConfirmation == '')
                                ? Text(
                                    languages[choosenLanguage]['text_pickdroplocation'],
                                    style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: hintColor),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: media.width * 0.7,
                                        child: Text(
                                          pickupAddressConfirmation,
                                          style: GoogleFonts.notoSans(
                                            fontSize: media.width * twelve,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      )),
                  SizedBox(
                    height: media.width * 0.03,
                  ),
                  Button(
                      onTap: () async {
                        if (pickupAddressConfirmation != '') {
                          //remove in envato
                          if (rideWithoutDestination == true && rentalRide == false) {
                            if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                              addressList.add(AddressList(
                                  id: (addressList.length + 1).toString(),
                                  type: 'pickup',
                                  address: pickupAddressConfirmation,
                                  latlng: _center,
                                  pickup: true));
                            } else {
                              addressList.firstWhere((element) => element.type == 'pickup').address =
                                  pickupAddressConfirmation;
                              addressList.firstWhere((element) => element.type == 'pickup').latlng = _center;
                              choosenTransportType = 0;
                              ismulitipleride = false;
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BookingConfirmation(
                                            type: 2,
                                          )),
                                  (route) => false);
                            }
                          } else if ((rideWithoutDestination == false && rentalRide == true)) {
                            if ((choosenTransportType == 0 && widget.from == null)) {
                              if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                addressList.add(AddressList(
                                    id: (addressList.length + 1).toString(),
                                    type: 'pickup',
                                    address: pickupAddressConfirmation,
                                    latlng: _center,
                                    pickup: true));
                              } else {
                                addressList.firstWhere((element) => element.type == 'pickup').address =
                                    pickupAddressConfirmation;
                                addressList.firstWhere((element) => element.type == 'pickup').latlng = _center;
                                setState(() {
                                  if (rideWithoutDestination == true && rentalRide == false) {
                                    ismulitipleride = false;
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookingConfirmation(
                                                  type: 2,
                                                )),
                                        (route) => false);
                                  } else {
                                    ismulitipleride = false;
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookingConfirmation(
                                                  type: 1,
                                                )),
                                        (route) => false);
                                  }
                                });
                              }
                            } else if ((choosenTransportType == 1 && widget.from == null)) {
                              if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                addressList.add(AddressList(
                                    id: (addressList.length + 1).toString(),
                                    type: 'pickup',
                                    address: pickupAddressConfirmation,
                                    latlng: _center,
                                    pickup: true));
                              } else {
                                addressList.firstWhere((element) => element.type == 'pickup').address =
                                    pickupAddressConfirmation;
                                addressList.firstWhere((element) => element.type == 'pickup').latlng = _center;
                                setState(() {
                                  if (rideWithoutDestination == true && rentalRide == false) {
                                    ismulitipleride = false;
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookingConfirmation(
                                                  type: 2,
                                                )),
                                        (route) => false);
                                  } else {
                                    var val = rentalEta();
                                    if (val == 'logout') {
                                      navigateLogout();
                                    }
                                    selectedGoodsId = '';
                                    ismulitipleride = false;
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => BookingConfirmation(
                                                  type: 1,
                                                )),
                                        (route) => false);
                                  }
                                });
                              }
                            }
                          }
                        }
                      },
                      text: languages[choosenLanguage]['text_confirm'])
                ],
              ),
            ),
          ],
        ));
  }
}
