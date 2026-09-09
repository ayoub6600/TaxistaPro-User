part of '../map_page.dart';

extension _MapModeSheet on _MapsState {
  Widget buildMapModeSheet(Size media) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1),
      bottom: _isbottom,
      child: InkWell(
        onTap: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              isOutStation = false;
              choosenTransportType = 0;
              _isbottom = -1000;
              isRentalRide = false;
            });
          });
          setState(() {});
        },
        child: Container(
          width: media.width * 1,
          color: Colors.black.withOpacity(0.3),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            padding: EdgeInsets.all(media.width * 0.05),
            duration: const Duration(milliseconds: 200),
            width: media.width * 1,
            color: page,
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: languages[choosenLanguage]
                        ['text_chooe_transport_type'],
                    size: media.width * sixteen,
                    fontweight: FontWeight.w600,
                    color: textColor,
                  ),
                  SizedBox(
                    height: media.width * 0.02,
                  ),
                  InkWell(
                    onTap: () {
                      if (choosenTransportType == 3) {
                        if (addressList.isNotEmpty) {
                          isOutStation = false;
                          choosenTransportType = 0;
                          ismulitipleride = false;
                          rentalRide = true;
                          rideWithoutDestination = false;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PickupLocation()));
                        }
                      } else {
                        _isbottom = -1000;
                        transportType = 'taxi';
                        isOutStation = true;

                        choosenTransportType = 0;

                        Future.delayed(const Duration(milliseconds: 200), () {
                          setState(() {
                            _bottom = 1;
                            _dropaddress = true;
                          });
                        });
                        setState(() {});
                      }
                    },
                    child: Container(
                      height: media.width * 0.15,
                      width: media.width * 0.9,
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(media.width * 0.02),
                          color: page,
                          border: Border.all(color: hintColor)),
                      child: Row(
                        children: [
                          (isRentalRide == false)
                              ? Container(
                                  height: media.width * 0.12,
                                  width: media.width * 0.15,
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.only(
                                      left: media.width * 0.02,
                                      right: media.width * 0.02),
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/Outstation.png')),
                                  ),
                                )
                              : Container(
                                  height: media.width * 0.12,
                                  width: media.width * 0.15,
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.only(
                                      left: media.width * 0.02,
                                      right: media.width * 0.02),
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/rental.png')),
                                  ),
                                ),
                          SizedBox(
                            width: media.width * 0.02,
                          ),
                          Expanded(
                            child: MyText(
                                text: languages[choosenLanguage]['text_taxi_'],
                                size: media.width * sixteen),
                          ),
                          RotatedBox(
                              quarterTurns: 4,
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: media.width * 0.05,
                              ))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.02,
                  ),
                  InkWell(
                    onTap: () {
                      if (choosenTransportType == 3) {
                        if (addressList.isNotEmpty) {
                          choosenTransportType = 1;
                          ismulitipleride = false;
                          isOutStation = false;
                          rentalRide = true;
                          rideWithoutDestination = false;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PickupLocation()));
                        }
                      } else {
                        setState(() {
                          _isbottom = -1000;
                          transportType = 'delivery';
                          choosenTransportType = 1;
                          isOutStation = true;
                        });
                        Future.delayed(const Duration(milliseconds: 200), () {
                          setState(() {
                            _bottom = 1;
                            _dropaddress = true;
                          });
                        });
                      }
                    },
                    child: Container(
                      height: media.width * 0.15,
                      width: media.width * 0.9,
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(media.width * 0.02),
                          color: page,
                          border: Border.all(color: hintColor)),
                      child: Row(
                        children: [
                          (isRentalRide == false)
                              ? Container(
                                  height: media.width * 0.1,
                                  width: media.width * 0.15,
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.only(
                                      left: media.width * 0.02,
                                      right: media.width * 0.02),
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/delivery_outstation.png')),
                                  ),
                                )
                              : Container(
                                  height: media.width * 0.12,
                                  width: media.width * 0.15,
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.only(
                                      left: media.width * 0.02,
                                      right: media.width * 0.02),
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/delivery_package_ride.png')),
                                  ),
                                ),
                          SizedBox(
                            width: media.width * 0.02,
                          ),
                          Expanded(
                            child: MyText(
                                text: languages[choosenLanguage]
                                    ['text_delivery'],
                                size: media.width * sixteen),
                          ),
                          RotatedBox(
                              quarterTurns: 4,
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: media.width * 0.05,
                              ))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
