part of '../map_page.dart';

extension _MapHomeOverlays on _MapsState {
  List<Widget> buildMapHomeOverlays(Size media) {
    return <Widget>[
      buildRecoveryOfferCard(media),
      Positioned(
          top: 0,
          child: Container(
              height: media.height * 1,
              width: media.width * 1,
              alignment: Alignment.center,
              // The recovery card takes visual priority and sits in the
              // same vertical band as the idle mascot - showing both at
              // once reads as broken, not busy.
              child: (_dropLocationMap == false &&
                      pendingRecoveryOfferForRider == null)
                  ? Column(
                      children: [
                        SizedBox(
                          height: (media.height / 2) -
                              riderMascotHeight -
                              riderMascotBubbleAllowance,
                        ),
                        RiderMascotBubble(
                          text: _isPickingLocation
                              ? (languageDirection == 'rtl'
                                  ? 'يحدد نقطة اللقاء'
                                  : 'Choosing the meeting point')
                              : _riderFirstName(),
                        ),
                        const SizedBox(height: 4),
                        Image.asset(
                          riderMascotAsset,
                          width: riderMascotWidth,
                          height: riderMascotHeight,
                          cacheWidth: (riderMascotWidth *
                                  MediaQuery.of(context).devicePixelRatio)
                              .round(),
                          fit: BoxFit.contain,
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
                  : (_dropLocationMap
                      ? Image.asset('assets/images/dropmarker.png')
                      : const SizedBox()))),
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
      // A booking belongs to the rider, not to the current map camera. Route
      // preview/back changes _centerLocation and used to hide this card until
      // a cold restart, even though the scheduled ride was still active.
      (_bottom == 0 &&
              (activeRiderBookings.isNotEmpty ||
                  userDetails['has_ongoing_ride'] == true))
          ? Positioned(
              bottom: ((userDetails['show_rental_ride'] == true ||
                      userDetails['enable_modules_for_applications'] == 'both'))
                  ? media.width * 0.85
                  : media.width * 0.67,
              child: InkWell(
                onTap: () async {
                  await guardedPush(
                      context,
                      MaterialPageRoute(
                          builder: (context) => activeRiderBookings.isNotEmpty
                              ? const ActiveRiderBookingsPage()
                              : const OnGoingRides()));
                  await getActiveRiderBookings();
                },
                child: Container(
                  width: media.width - 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xff102A56), Color(0xff1965BF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeRiderBookings.isNotEmpty &&
                                      activeRiderBookings.every((item) => item is Map && (item['is_later'] == true || item['is_later'] == 1))
                                  ? (languageDirection == 'rtl' ? 'رحلتك المجدولة' : 'Your scheduled ride')
                                  : (languageDirection == 'rtl' ? 'حجوزاتك القائمة' : 'Your bookings'),
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              activeRiderBookings.length == 1 && activeRiderBookings.first is Map &&
                                      (activeRiderBookings.first['is_later'] == true || activeRiderBookings.first['is_later'] == 1)
                                  ? '${activeRiderBookings.first['trip_start_time'] ?? ''} · ${activeRiderBookings.first['driver_id'] == null ? (languageDirection == 'rtl' ? 'متاحة للسائقين' : 'Available to drivers') : (languageDirection == 'rtl' ? 'أكدها السائق' : 'Driver confirmed')}'
                                  : (languageDirection == 'rtl' ? '${activeRiderBookings.length} حجوزات · عرض التفاصيل' : '${activeRiderBookings.length} bookings · View details'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xffDCEBFF), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 17),
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
