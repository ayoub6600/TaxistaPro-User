part of '../booking_confirmation.dart';

mixin _BookingConfirmationActiveRide
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildActiveRideSheet(Size media) {
    final fare = _resolveRideFare(userRequestData);
    return (userRequestData.isNotEmpty &&
            userRequestData['accepted_at'] != null)
        ? AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: addressBottom != null
                ? -addressBottom
                : -(media.height - media.width),
            child: GestureDetector(
              onVerticalDragStart: (v) {
                _cont.jumpTo(0.0);
                start = v.globalPosition.dy;
                if (addressBottom != null) {
                  _addressBottom = addressBottom;
                } else {
                  addressBottom = (media.height - media.width);
                  _addressBottom = addressBottom;
                }
                gesture.clear();
              },
              onVerticalDragUpdate: (v) {
                if ((_addressBottom + (v.globalPosition.dy - start)) >
                        media.height * 0.2 &&
                    (_addressBottom + (v.globalPosition.dy - start)) <
                        ((media.height * 1.2) - media.width)) {
                  addressBottom =
                      _addressBottom + (v.globalPosition.dy - start);
                }
                setState(() {});
              },
              onVerticalDragEnd: (v) {},
              child: Container(
                  padding: EdgeInsets.fromLTRB(media.width * 0.025,
                      media.width * 0.02, media.width * 0.025, 0),
                  width: media.width * 1,
                  height: media.height * 1.2,
                  decoration: BoxDecoration(
                      color: page,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 5,
                            width: media.width * 0.2,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: hintColor),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.height * 0.01,
                      ),
                      // design v2: what is happening now, big; the ride code beside it
                      SizedBox(
                        width: media.width * 0.9,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_activeRideTitle(),
                                  style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800, height: 1.25)),
                              Text(_activeRideLine(),
                                  maxLines: 3,
                                  style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 13, height: 1.45)),
                            ]),
                          ),
                          if (userRequestData['is_trip_start'] != 1 && userRequestData['show_otp_feature'] == true)
                            Container(
                              margin: const EdgeInsetsDirectional.only(start: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(children: [
                                Text(languageDirection == 'rtl' ? 'رمز الرحلة' : 'Ride code',
                                    style: GoogleFonts.cairo(color: theme, fontSize: 11, fontWeight: FontWeight.w700)),
                                Text('${userRequestData['ride_otp']}',
                                    style: GoogleFonts.notoSans(color: theme, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                              ]),
                            ),
                        ]),
                      ),
                      if (userRequestData['accepted_at'] != null &&
                          userRequestData['arrived_at'] != null &&
                          userRequestData['is_trip_start'] == 0 &&
                          (waitingTime / 60).toStringAsFixed(0) != '0')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: media.width * 0.9,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xffFFF4DB), borderRadius: BorderRadius.circular(14)),
                            child: Text(
                              '${languages[choosenLanguage]['text_waiting_time']}: ${(waitingTime / 60).toStringAsFixed(0)} ${languages[choosenLanguage]['text_mins']}',
                              style: GoogleFonts.cairo(color: const Color(0xffB7791F), fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      SizedBox(height: media.width * 0.03),
                      if (fare != null) ...[
                        SizedBox(
                          width: media.width * 0.9,
                          child: _RideFareBadge(
                            fare: fare,
                            isRtl: languageDirection == 'rtl',
                            expanded: true,
                          ),
                        ),
                        SizedBox(height: media.width * 0.03),
                      ],
                      _activeDriverCard(media),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _cont,
                          physics: (addressBottom != null &&
                                  addressBottom <= (media.height * 0.25))
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              if (userRequestData['transport_type'] ==
                                  'delivery')
                                Column(
                                  children: [
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Text(
                                        '${userRequestData['goods_type']} - ${userRequestData['goods_type_quantity']}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600,
                                            color: buttonColor),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                  ],
                                ),
                              (userRequestData['is_rental'] != true &&
                                      userRequestData['drop_address'] != null)
                                  ? Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.03),
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      media.width * 0.02)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: media.width * 0.05,
                                                width: media.width * 0.05,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.green
                                                        .withOpacity(0.4)),
                                                child: Container(
                                                  height: media.width * 0.025,
                                                  width: media.width * 0.025,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.green
                                                          .withOpacity(0.4)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: media.width * 0.03,
                                              ),
                                              Expanded(
                                                  child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_pick_up_location'],
                                                    size:
                                                        media.width * fourteen,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                  MyText(
                                                    text: userRequestData[
                                                        'pick_address'],
                                                    size: media.width * twelve,
                                                    color: greyText,
                                                  ),
                                                ],
                                              )),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.02,
                                        ),
                                        (tripStops.isNotEmpty)
                                            ? Column(
                                                children: tripStops
                                                    .asMap()
                                                    .map((i, value) {
                                                      return MapEntry(
                                                          i,
                                                          (i <
                                                                  tripStops
                                                                          .length -
                                                                      1)
                                                              ? Container(
                                                                  padding: EdgeInsets
                                                                      .all(media
                                                                              .width *
                                                                          0.03),
                                                                  margin: EdgeInsets.only(
                                                                      bottom: media
                                                                              .width *
                                                                          0.02),
                                                                  decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.1),
                                                                      borderRadius:
                                                                          BorderRadius.circular(media.width *
                                                                              0.02)),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        height: media.width *
                                                                            0.05,
                                                                        width: media.width *
                                                                            0.05,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child:
                                                                            MyText(
                                                                          text:
                                                                              (i + 1).toString(),
                                                                          size: media.width *
                                                                              fourteen,
                                                                          color:
                                                                              verifyDeclined,
                                                                          fontweight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.03,
                                                                      ),
                                                                      Expanded(
                                                                          child:
                                                                              MyText(
                                                                        text: tripStops[i]
                                                                            [
                                                                            'address'],
                                                                        size: media.width *
                                                                            twelve,
                                                                        color:
                                                                            greyText,
                                                                      )),
                                                                    ],
                                                                  ),
                                                                )
                                                              : Container());
                                                    })
                                                    .values
                                                    .toList(),
                                              )
                                            : Container(),
                                        Container(
                                          padding: EdgeInsets.all(
                                              media.width * 0.03),
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      media.width * 0.02)),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: media.width * 0.05,
                                                width: media.width * 0.05,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.location_on,
                                                    color: Color(0xffF52D56)),
                                              ),
                                              SizedBox(
                                                width: media.width * 0.03,
                                              ),
                                              Expanded(
                                                  child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_drop'],
                                                    size:
                                                        media.width * fourteen,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                  MyText(
                                                    text: userRequestData[
                                                        'drop_address'],
                                                    size: media.width * twelve,
                                                    color: greyText,
                                                  ),
                                                ],
                                              )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.03),
                                      decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              media.width * 0.02)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: media.width * 0.05,
                                            width: media.width * 0.05,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green
                                                    .withOpacity(0.4)),
                                            child: Container(
                                              height: media.width * 0.025,
                                              width: media.width * 0.025,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green
                                                      .withOpacity(0.4)),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.03,
                                          ),
                                          Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_pick_up_location'],
                                                size: media.width * fourteen,
                                                fontweight: FontWeight.w600,
                                              ),
                                              MyText(
                                                text: userRequestData[
                                                    'pick_address'],
                                                size: media.width * twelve,
                                                color: greyText,
                                              ),
                                            ],
                                          )),
                                        ],
                                      ),
                                    ),
                              if (widget.type != 2)
                                Container(
                                  margin:
                                      EdgeInsets.only(top: media.width * 0.02),
                                  padding: EdgeInsets.all(media.width * 0.03),
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          media.width * 0.02)),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                              child: MyText(
                                            text: languages[choosenLanguage]
                                                ['text_payingvia'],
                                            size: media.width * fourteen,
                                            fontweight: FontWeight.w600,
                                          )),
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.025,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                (userRequestData[
                                                            'payment_opt'] ==
                                                        '1')
                                                    ? Image.asset(
                                                        'assets/images/cash.png',
                                                        width:
                                                            media.width * 0.07,
                                                        height:
                                                            media.width * 0.07,
                                                        fit: BoxFit.contain,
                                                      )
                                                    : (userRequestData[
                                                                'payment_opt'] ==
                                                            '2')
                                                        ? Image.asset(
                                                            'assets/images/wallet.png',
                                                            width: media.width *
                                                                0.07,
                                                            height:
                                                                media.width *
                                                                    0.07,
                                                            fit: BoxFit.contain,
                                                          )
                                                        : (userRequestData[
                                                                    'payment_opt'] ==
                                                                '3')
                                                            ? Image.asset(
                                                                'assets/images/wallet.png',
                                                                width: media
                                                                        .width *
                                                                    0.07,
                                                                height: media
                                                                        .width *
                                                                    0.07,
                                                                fit: BoxFit
                                                                    .contain,
                                                              )
                                                            : (userRequestData[
                                                                        'payment_opt'] ==
                                                                    '0')
                                                                ? Image.asset(
                                                                    'assets/images/card.png',
                                                                    width: media
                                                                            .width *
                                                                        0.07,
                                                                    height: media
                                                                            .width *
                                                                        0.07,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  )
                                                                : Container(),
                                                SizedBox(
                                                  width: media.width * 0.02,
                                                ),
                                                MyText(
                                                  text: (userRequestData[
                                                              'payment_opt'] ==
                                                          '1')
                                                      ? languages[choosenLanguage]
                                                          ['text_cash']
                                                      : (userRequestData[
                                                                  'payment_opt'] ==
                                                              '2')
                                                          ? languages[choosenLanguage]
                                                              ['text_wallet']
                                                          : (userRequestData['payment_opt']
                                                                      .toString() ==
                                                                  '3')
                                                              ? languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  userRequestData['wallet_split_is_estimate'] ==
                                                                          true
                                                                      ? 'text_cash_expected'
                                                                      : 'text_cash_due']
                                                              : languages[
                                                                      choosenLanguage]
                                                                  ['text_card'],
                                                  size: media.width * sixteen,
                                                  fontweight: FontWeight.w600,
                                                  color: (isDarkTheme == true)
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              InkWell(
                                                onTap: () {},
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    MyText(
                                                      textAlign: TextAlign.end,
                                                      text: userRequestData[
                                                                      'payment_opt']
                                                                  .toString() ==
                                                              '3'
                                                          ? '${userRequestData['requested_currency_symbol'] ?? 'LYD'} ${userRequestData['cash_due_amount'] ?? 0}'
                                                          : _resolvedRideFareText(
                                                              userRequestData,
                                                            ),
                                                      size:
                                                          media.width * sixteen,
                                                      fontweight:
                                                          FontWeight.w500,
                                                      color: textColor,
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              if (userRequestData['payment_opt'].toString() ==
                                  '3') ...[
                                SizedBox(height: media.width * 0.015),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyText(
                                      text:
                                          '${languages[choosenLanguage][userRequestData['wallet_split_is_estimate'] == true ? 'text_wallet_expected' : 'text_wallet_paid']}: ${userRequestData['requested_currency_symbol'] ?? 'LYD'} ${userRequestData['wallet_paid_amount'] ?? 0}',
                                      size: media.width * twelve,
                                      color: greyText,
                                    ),
                                  ],
                                ),
                              ],
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'عند إلغاء الطلب سيتم خصم 2.5 دل',
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * sixteen,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              (userRequestData['is_trip_start'] != 1)
                                  ? Column(
                                      children: [
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            (userRequestData['is_trip_start'] !=
                                                    1)
                                                ? InkWell(
                                                    onTap: () async {
                                                      setState(() {
                                                        isLoading = true;
                                                      });
                                                      var reason =
                                                          await cancelReason(
                                                              (userRequestData[
                                                                          'is_driver_arrived'] ==
                                                                      0)
                                                                  ? 'before'
                                                                  : 'after');
                                                      if (reason == true) {
                                                        setState(() {
                                                          _cancellingError = '';
                                                          _cancelReason = '';
                                                          _cancelling = true;
                                                        });
                                                      }
                                                      setState(() {
                                                        isLoading = false;
                                                      });
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Image.asset(
                                                          'assets/images/cancelimage.png',
                                                          height: media.width *
                                                              0.064,
                                                          width: media.width *
                                                              0.064,
                                                          fit: BoxFit.contain,
                                                          color: verifyDeclined,
                                                        ),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.025,
                                                        ),
                                                        MyText(
                                                          text: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_cancel_booking'],
                                                          size: media.width *
                                                              twelve,
                                                          fontweight:
                                                              FontWeight.w400,
                                                          color: verifyDeclined,
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container(),
                              SizedBox(
                                height: media.height * 0.25,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ))
        : Container();
  }

  /// «يوصلك خلال 4 دقائق», «وصل السائق», «في الطريق إلى وجهتك»
  String _activeRideTitle() {
    final rtl = languageDirection == 'rtl';
    final d = userRequestData;
    if (d['is_trip_start'] == 1) return rtl ? 'في الطريق إلى وجهتك' : 'On the way to your destination';
    if (d['arrived_at'] != null) return rtl ? 'وصل السائق' : 'Your driver has arrived';
    if (_dist != null) {
      final m = double.parse((_dist * 2).toString()).round();
      if (m > 0) return rtl ? 'يوصلك خلال $m ${m <= 10 && m > 2 ? 'دقائق' : 'دقيقة'}' : 'Arrives in $m min';
    }
    return rtl ? 'السائق في الطريق إليك' : 'Your driver is on the way';
  }

  /// the same words as before under the title (arrival, waiting charge, on the ride)
  String _activeRideLine() {
    final d = userRequestData;
    final l = languages[choosenLanguage];
    if (d['accepted_at'] != null && d['arrived_at'] == null && d['is_trip_start'] == 0) return '${l['text_captain_arrive']}';
    if (d['accepted_at'] != null && d['arrived_at'] != null && d['is_trip_start'] == 0) {
      if (d['is_bid_ride'] == 1 || d['waiting_charge'].toString() == '0') return '${l['text_captain_arrived']}';
      return '${l['text_captain_arrived']}, ${l['text_waiting_time_text'].toString().replaceAll('5', d['free_waiting_time_in_mins_before_trip_start'].toString()).replaceAll('**', (d['requested_currency_symbol'].toString() + d['waiting_charge'].toString()))}';
    }
    return '${l['text_onride']}';
  }

  /// the driver as one card: photo and rating, name, the car without empty fields, the plate, rides done;
  /// then «رسالة» and «اتصال» (the same chat page and call button as before)
  Widget _activeDriverCard(Size media) {
    final rtl = languageDirection == 'rtl';
    // the games keep listening after the driver accepts (same round, same controller)
    RideGamesHost.sync(context,
        distanceKm: _dist is num ? (_dist as num).toDouble() : null,
        onCall: null,
        onChat: () => guardedPush(context, MaterialPageRoute(builder: (context) => const ChatPage())),
        onBackToTrip: () {});
    final drv = userRequestData['driverDetail']['data'];
    bool real(dynamic v) => v != null && '$v'.trim().isNotEmpty && '$v' != 'null' && '$v' != '-';
    final car = [drv['car_make_name'], drv['car_model_name'], drv['car_color']].where(real).join(' · ');
    final rides = userRequestData['driver_completed_rides_count'] ?? 0;
    final rating = drv['rating'];
    final unread = chatList.where((e) => e['from_type'] == 2 && e['seen'] == 0).isNotEmpty;
    return Container(
      width: media.width * 0.9,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: textColor.withValues(alpha: .07)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: NetworkImage('${drv['profile_picture']}'), fit: BoxFit.cover),
              ),
            ),
            PositionedDirectional(
              bottom: -6,
              start: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 4)]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Color(0xffF5A524), size: 14),
                  Text(rating == 0 || rating == null ? '—' : '$rating',
                      style: GoogleFonts.notoSans(color: const Color(0xff10213F), fontSize: 11.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${drv['name'] ?? ''}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(color: textColor, fontSize: 16.5, fontWeight: FontWeight.w800)),
              if (car.isNotEmpty)
                Text(car, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 12.5)),
              Text(rtl ? '$rides رحلة مكتملة' : '$rides rides', style: GoogleFonts.cairo(color: textColor.withValues(alpha: .5), fontSize: 12)),
            ]),
          ),
          if (real(drv['car_number']))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffFFD54F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff10213F), width: 1.6),
              ),
              child: Text('${drv['car_number']}',
                  textDirection: ui.TextDirection.ltr,
                  style: GoogleFonts.notoSans(color: const Color(0xff10213F), fontSize: 15, fontWeight: FontWeight.w800)),
            ),
        ]),
        if (userRequestData['is_trip_start'] == 0) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Material(
                color: theme.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final result = await guardedPush(context, MaterialPageRoute(builder: (context) => const ChatPage()));
                    if (result == true) setState(() {});
                  },
                  child: SizedBox(
                    height: 48,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: theme, size: 21),
                        if (unread)
                          const PositionedDirectional(
                            top: -2,
                            end: -3,
                            child: CircleAvatar(radius: 4.5, backgroundColor: Color(0xffE0243A)),
                          ),
                      ]),
                      const SizedBox(width: 8),
                      Text(rtl ? 'رسالة' : 'Message', style: GoogleFonts.cairo(color: theme, fontSize: 14.5, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (RideGamesHost.enabled && userRequestData['arrived_at'] == null) ...[
              Material(
                color: const Color(0xff102A56).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => WaitingGamesFullScreen.open(context, controller: RideGamesHost.controller, status: RideGamesHost.status),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.sports_esports_rounded, color: Color(0xff102A56)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            // one «اتصال»: the free call through Taxista, WhatsApp or the phone
            CallOptionsButton(
              peerName: '${drv['name']}',
              mobile: drv['mobile']?.toString(),
              freeCall: () => AdminCallController.instance.callDriver(requestId: userRequestData['id']?.toString()),
            ),
          ]),
        ],
      ]),
    );
  }
}
