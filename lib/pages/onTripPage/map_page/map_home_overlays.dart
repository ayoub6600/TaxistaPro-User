part of '../map_page.dart';

extension _MapHomeOverlays on _MapsState {
  List<Widget> buildMapHomeOverlays(Size media) {
    return <Widget>[
      Positioned(
          top: 0,
          child: Container(
              height: media.height * 1,
              width: media.width * 1,
              alignment: Alignment.center,
              child: (_dropLocationMap == false)
                  ? Column(
                      children: [
                        SizedBox(
                          height: (media.height / 2) - media.width * 0.08,
                        ),
                        Image.asset(
                          "assets/images/gps.png",
                          width: 38.w,
                          height: 38.h,
                        ),
                        if (userDetails[
                                'enable_map_location_icon_drag_and_drop_feature'] ==
                            '0')
                          Button(
                              width: media.width * 0.5,
                              onTap: () async {
                                if (_lastRequestedLocation != null &&
                                    _lastRequestedLocation!.latitude ==
                                        _centerLocation.latitude &&
                                    _lastRequestedLocation!.longitude ==
                                        _centerLocation.longitude) {
                                  return;
                                }

                                _lastRequestedLocation = _centerLocation;

                                String? val = await geoCoding(
                                    _centerLocation.latitude,
                                    _centerLocation.longitude);

                                if (val != null && val.isNotEmpty) {
                                  setState(() {
                                    if (addressList
                                        .where((e) => e.type == 'pickup')
                                        .isNotEmpty) {
                                      var add = addressList.firstWhere(
                                          (e) => e.type == 'pickup');
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
                              },
                              text: languages[choosenLanguage]['text_confirm'])
                      ],
                    )
                  : Image.asset('assets/images/dropmarker.png'))),
      (contactus == true)
          ? Positioned(
              right: 10,
              top: 120 + media.width * 0.1,
              child: InkWell(
                onTap: () async {},
                child: Container(
                    padding: const EdgeInsets.all(10),
                    height: media.width * 0.3,
                    width: media.width * 0.45,
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
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            makingPhoneCall(userDetails['contact_us_mobile1']);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(
                                    Icons.call,
                                    color: textColor,
                                  )),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    userDetails['contact_us_mobile1'],
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            makingPhoneCall(userDetails['contact_us_mobile1']);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(Icons.call, color: textColor)),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    userDetails['contact_us_mobile2'],
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            openBrowser(
                                userDetails['contact_us_link'].toString());
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(Icons.vpn_lock_rounded,
                                      color: textColor)),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    languages[choosenLanguage]['text_goto_url'],
                                    maxLines: 1,
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        )
                      ],
                    )),
              ),
            )
          : const SizedBox(),
      Positioned(
        right: 18,
        bottom: 246 + MediaQuery.paddingOf(context).bottom,
        child: MapRecenterButton(onTap: recenterMap),
      ),
      ((_lastCenter == _centerLocation &&
              !ischanged &&
              userDetails['has_ongoing_ride'] == true))
          ? Positioned(
              bottom: ((userDetails['show_rental_ride'] == true ||
                      userDetails['enable_modules_for_applications'] == 'both'))
                  ? media.width * 0.6
                  : media.width * 0.4,
              child: InkWell(
                onTap: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OnGoingRides()));
                },
                child: Container(
                  padding: EdgeInsets.all(media.width * 0.03),
                  width: media.width * 1,
                  decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(media.width * 0.02)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: media.width * 0.05,
                      ),
                      Column(
                        children: [
                          MyText(
                            text: languages[choosenLanguage]
                                ['text_ongoing_rides'],
                            size: media.width * fourteen,
                            color: Colors.black,
                          ),
                          SizedBox(
                            height: 10.h,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: MyText(
                              text: languages[choosenLanguage]
                                  ['text_view_rides'],
                              size: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                          child: Container(
                        alignment: Alignment.centerLeft,
                        height: media.width * 0.07,
                        child: SlideTransition(
                          position: _offsetAnimation,
                          child: SizedBox(
                            child: Image.asset(
                              'assets/images/taxia.png',
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(),
      (_bottom == 0)
          ? Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 18,
              right: 18,
              child: SizedBox(
                width: media.width - 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) => MapFloatingMenuButton(
                        onTap: Scaffold.of(context).openDrawer,
                      ),
                    ),
                    if (banners.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: const MapAdvertisementBanner(compact: true),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ))
          : const SizedBox(),
    ];
  }

  Widget buildPickupConfirmationOverlay(Size media) {
    if (_lastCenter != 0) return const SizedBox();

    return Positioned(
      bottom: 0,
      child: Container(
        color: page,
        padding: EdgeInsets.all(media.width * 0.05),
        height: media.width * 0.35,
        width: media.width,
        child: Column(
          children: [
            InkWell(
              onTap: () {
                if (addressList
                    .where((element) => element.type == 'pickup')
                    .isNotEmpty) {
                  setState(() {
                    _pickaddress = true;
                    _dropaddress = false;
                    addAutoFill.clear();
                  });

                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (!mounted) return;
                    setState(() => _bottom = 1);
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(media.width * 0.01),
                decoration: BoxDecoration(
                  color: page,
                  borderRadius: BorderRadius.circular(media.width * 0.01),
                  border: Border.all(color: hintColor),
                ),
                height: media.width * 0.1,
                width: media.width * 0.9,
                child: Row(
                  children: [
                    Container(
                      height: media.width * 0.05,
                      width: media.width * 0.05,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: Container(
                        height: media.width * 0.02,
                        width: media.width * 0.02,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: MyText(
                        text: addressList
                                .where((element) => element.type == 'pickup')
                                .isNotEmpty
                            ? addressList
                                .firstWhere(
                                  (element) => element.type == 'pickup',
                                  orElse: () => AddressList(
                                    id: '',
                                    address: '',
                                    pickup: true,
                                    latlng: const LatLng(0.0, 0.0),
                                  ),
                                )
                                .address
                            : languages[choosenLanguage]['text_4letterpickup'],
                        size: media.width * fourteen,
                        color: textColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: media.width * 0.02),
            ShowUpWidget(
              delay: 100,
              child: Button(
                borderRadius: 0.0,
                height: media.width * 0.1,
                onTap: () async {
                  setState(() {
                    _lastCenter = _centerLocation;
                    ischanged = false;
                  });
                },
                text: languages[choosenLanguage]['text_confirm'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
