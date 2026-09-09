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
                      SizedBox(
                          width: media.width * 0.9,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              (userRequestData['is_trip_start'] != 1 &&
                                      userRequestData['show_otp_feature'] ==
                                          true)
                                  ? Container(
                                      width: media.width * 0.3,
                                      height: media.width * 0.1,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              media.width * 0.02),
                                          color: Colors.grey.withOpacity(0.2)),
                                      child:
                                          (userRequestData['is_trip_start'] !=
                                                      1 &&
                                                  userRequestData[
                                                          'show_otp_feature'] ==
                                                      true)
                                              ? MyText(
                                                  text:
                                                      'Otp : ${userRequestData['ride_otp']}',
                                                  size: media.width * fourteen,
                                                  textAlign: TextAlign.end,
                                                  fontweight: FontWeight.bold,
                                                  maxLines: 1,
                                                )
                                              : Container(),
                                    )
                                  : Container(),
                            ],
                          )),
                      SizedBox(
                        height: media.width * 0.025,
                      ),
                      if (fare != null) ...[
                        SizedBox(
                          width: media.width * 0.9,
                          child: _RideFareBadge(
                            fare: fare,
                            isRtl: languageDirection == 'rtl',
                            expanded: true,
                          ),
                        ),
                        SizedBox(height: media.width * 0.025),
                      ],
                      ((widget.type == null ||
                                  (widget.type != 1 || widget.type != 2) &&
                                      userRequestData['is_trip_start'] == 0) &&
                              userRequestData['waiting_charge'].toString() !=
                                  '0')
                          ? Container(
                              width: media.width * 0.9,
                              padding: EdgeInsets.all(media.width * 0.05),
                              color: borderColor.withOpacity(0.1),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MyText(
                                      text: ((userRequestData['accepted_at'] !=
                                                  null &&
                                              userRequestData['arrived_at'] ==
                                                  null &&
                                              userRequestData['is_trip_start'] ==
                                                  0))
                                          ? languages[choosenLanguage]
                                              ['text_captain_arrive']
                                          : (userRequestData['accepted_at'] != null &&
                                                  userRequestData['arrived_at'] !=
                                                      null &&
                                                  userRequestData['is_trip_start'] ==
                                                      0)
                                              ? (userRequestData['is_bid_ride'] ==
                                                      1)
                                                  ? languages[choosenLanguage]
                                                      ['text_captain_arrived']
                                                  : '${languages[choosenLanguage]['text_captain_arrived']}, ${languages[choosenLanguage]['text_waiting_time_text'].toString().replaceAll('5', userRequestData['free_waiting_time_in_mins_before_trip_start'].toString()).replaceAll('**', (userRequestData['requested_currency_symbol'].toString() + userRequestData['waiting_charge'].toString()))}'
                                              : (_dist != null)
                                                  ? languages[choosenLanguage][
                                                          'text_reaching_destination']
                                                      .toString()
                                                      .replaceAll(
                                                          '1111',
                                                          double.parse(((_dist * 2))
                                                                  .toString())
                                                              .round()
                                                              .toString())
                                                  : languages[choosenLanguage]
                                                      ['text_onride'],
                                      size: media.width * fourteen,
                                      color: greyText,
                                    ),
                                  ),
                                  if ((userRequestData['accepted_at'] != null &&
                                          userRequestData['arrived_at'] !=
                                              null &&
                                          userRequestData['is_trip_start'] ==
                                              0) &&
                                      (waitingTime / 60).toStringAsFixed(0) !=
                                          '0')
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.025),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: const Color(0xff5BDD0A)
                                              .withOpacity(0.24)),
                                      child: Column(
                                        children: [
                                          MyText(
                                            text: languages[choosenLanguage]
                                                ['text_waiting_time'],
                                            size: media.width * twelve,
                                            color: greyText,
                                          ),
                                          MyText(
                                            text:
                                                '${(waitingTime / 60).toStringAsFixed(0)} ${languages[choosenLanguage]['text_mins']}',
                                            size: media.width * twelve,
                                            fontweight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Container(),
                      SizedBox(
                        height: media.height * 0.01,
                      ),
                      Container(
                        padding: EdgeInsets.all(media.width * 0.025),
                        width: media.width * 0.9,
                        color: borderColor.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: media.width * 0.02,
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            height: media.width * 0.15,
                                            width: media.width * 0.15,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                    userRequestData[
                                                                'driverDetail']
                                                            ['data']
                                                        ['profile_picture'],
                                                  ),
                                                  fit: BoxFit.cover),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.03,
                                          ),
                                          SizedBox(
                                            height: media.width * 0.01,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.025,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: media.width * 0.05,
                                          ),
                                          SizedBox(
                                            width: media.width * 0.005,
                                          ),
                                          Expanded(
                                            child: MyText(
                                              color: greyText,
                                              text: (userRequestData[
                                                              'driverDetail']
                                                          ['data']['rating'] ==
                                                      0)
                                                  ? languages[choosenLanguage]
                                                      ['text_no_rating']
                                                  : userRequestData[
                                                              'driverDetail']
                                                          ['data']['rating']
                                                      .toString(),
                                              size: media.width * fourteen,
                                              fontweight: FontWeight.w600,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.01,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: MyText(
                                                text: userRequestData[
                                                            'driverDetail']
                                                        ['data']['name']
                                                    .toString(),
                                                size: media.width * fourteen,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                fontweight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: MyText(
                                            text:
                                                '${userRequestData['driverDetail']['data']['car_color']} | ${userRequestData['driverDetail']['data']['car_make_name']} | ${userRequestData['driverDetail']['data']['car_model_name']}',
                                            size: media.width * twelve,
                                            maxLines: 2,
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: Column(
                                  children: [
                                    SizedBox(
                                      height: media.width * 0.3,
                                      width: media.width * 0.3,
                                      child: Image.network(
                                          userRequestData['vehicle_type_image']
                                              .toString()),
                                    ),
                                    Text(
                                      languages[choosenLanguage]
                                          ['text_car_number'],
                                      style: TextStyle(
                                          fontSize: media.width * sixteen,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.only(
                                              left: media.width * 0.025,
                                              right: media.width * 0.025),
                                          width: media.width * 0.3,
                                          height: media.width * 0.1,
                                          decoration: BoxDecoration(
                                              color: Colors.yellow[700],
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 2)),
                                          child: FittedBox(
                                              fit: BoxFit.fitWidth,
                                              child: Text(
                                                  '${userRequestData['driverDetail']['data']['car_number']}')),
                                        ),
                                      ],
                                    ),
                                  ],
                                ))
                              ],
                            ),
                            SizedBox(
                              height: media.width * 0.03,
                            ),
                            Container(
                              child: Row(
                                children: [
                                  Text(
                                    "عدد الطلبات المكتملة للسائق",
                                    style: GoogleFonts.notoSans(
                                      fontSize: media.width * fourteen,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    width: media.width * 0.04,
                                  ),
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    radius: media.width * 0.04,
                                    child: Text(
                                      (userRequestData[
                                                  'driver_completed_rides_count'] ??
                                              0)
                                          .toString(),
                                      style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: media.width * 0.03,
                            ),
                            if (userRequestData['is_trip_start'] == 0)
                              Row(
                                children: [
                                  Expanded(
                                      child: InkWell(
                                    onTap: () async {
                                      var result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ChatPage()));
                                      if (result) {
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      height: media.width * 0.12,
                                      padding: EdgeInsets.only(
                                          left: media.width * 0.05,
                                          right: media.width * 0.05),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            media.width * 0.07),
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              SizedBox(
                                                width: media.width * 0.1,
                                                child: const Icon(
                                                  Icons.message,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              if (chatList
                                                  .where((element) =>
                                                      element['from_type'] ==
                                                          2 &&
                                                      element['seen'] == 0)
                                                  .isNotEmpty)
                                                Positioned(
                                                    top: media.width * 0.01,
                                                    right: media.width * 0.01,
                                                    child: Container(
                                                      height:
                                                          media.width * 0.02,
                                                      width: media.width * 0.02,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              verifyDeclined),
                                                    ))
                                            ],
                                          ),
                                          SizedBox(
                                            width: media.width * 0.03,
                                          ),
                                          Expanded(
                                              child: MyText(
                                            text:
                                                '${languages[choosenLanguage]['text_chatwithdriver']} ${userRequestData['driverDetail']['data']['name'].toString()}',
                                            size: media.width * fourteen,
                                            color: hintColor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ))
                                        ],
                                      ),
                                    ),
                                  )),
                                  SizedBox(
                                    width: media.width * 0.05,
                                  ),
                                  CallWhatsAppButton(
                                    phoneNumber: userRequestData['driverDetail']
                                        ['data']['mobile'],
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      makingPhoneCall(
                                          userRequestData['driverDetail']
                                              ['data']['mobile']);
                                    },
                                    child: Container(
                                      height: media.width * 0.096,
                                      width: media.width * 0.096,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xff5BDD0A),
                                              width: 1),
                                          shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'assets/images/call.png',
                                        color: const Color(0xff5BDD0A),
                                        height: media.width * 0.05,
                                        width: media.width * 0.05,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
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
                                                      ? languages[
                                                              choosenLanguage]
                                                          ['text_cash']
                                                      : (userRequestData[
                                                                  'payment_opt'] ==
                                                              '2')
                                                          ? languages[
                                                                  choosenLanguage]
                                                              ['text_wallet']
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
                                                    (userRequestData[
                                                                'is_bid_ride'] ==
                                                            1)
                                                        ? MyText(
                                                            textAlign:
                                                                TextAlign.end,
                                                            text: userRequestData[
                                                                    'requested_currency_symbol'] +
                                                                ' ' +
                                                                userRequestData[
                                                                        'accepted_ride_fare']
                                                                    .toString(),
                                                            size: media.width *
                                                                sixteen,
                                                            fontweight:
                                                                FontWeight.w500,
                                                            color: textColor,
                                                          )
                                                        : (userRequestData[
                                                                    'discounted_total'] !=
                                                                null)
                                                            ? MyText(
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                text: userRequestData[
                                                                        'requested_currency_symbol'] +
                                                                    ' ' +
                                                                    userRequestData[
                                                                            'discounted_total']
                                                                        .toString(),
                                                                size: media
                                                                        .width *
                                                                    sixteen,
                                                                fontweight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    textColor,
                                                                maxLines: 1,
                                                              )
                                                            : MyText(
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                text: userRequestData[
                                                                        'requested_currency_symbol'] +
                                                                    ' ' +
                                                                    userRequestData[
                                                                            'request_eta_amount']
                                                                        .toString(),
                                                                size: media
                                                                        .width *
                                                                    sixteen,
                                                                fontweight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    textColor,
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
}
