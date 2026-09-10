part of '../booking_confirmation.dart';

mixin _BookingConfirmationPendingRequest
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildPendingRequestOverlay(Size media) {
    return (userRequestData.isNotEmpty &&
            userRequestData['accepted_at'] == null &&
            (userRequestData['is_later'] == null ||
                userRequestData['is_later'] == 0))
        ? userRequestData.isNotEmpty && userRequestData['is_bid_ride'] == 1
            ? Positioned(
                bottom: 0,
                child: StreamBuilder<Object>(
                    stream: FirebaseDatabase.instance
                        .ref()
                        .child('bid-meta/${userRequestData["id"]}')
                        .onValue
                        .asBroadcastStream(),
                    builder: (context, AsyncSnapshot event) {
                      List driverList = [];
                      Map rideList = {};
                      if (event.data != null) {
                        DataSnapshot snapshots = event.data!.snapshot;
                        if (snapshots.value != null) {
                          rideList = jsonDecode(jsonEncode(snapshots.value));
                          if (updateAmount.text.isEmpty) {
                            updateAmount.text = rideList['price'].toString();
                          }
                          if (rideList['drivers'] != null) {
                            Map driver = rideList['drivers'];
                            driver.forEach((key, value) {
                              if (driver[key]['is_rejected'] == 'none') {
                                driverList.add(value);

                                if (driverList.isNotEmpty) {
                                  audioPlayers.play(AssetSource(audio));
                                }
                              }
                            });

                            if (driverList.isNotEmpty) {
                              if (driverBck.isNotEmpty &&
                                  driverList[0]['user_id'] !=
                                      driverBck[0]['user_id']) {
                                driverBck = driverList;
                              } else if (driverBck.isEmpty) {
                                driverBck = driverList;
                              }
                            } else {
                              driverBck = driverList;
                            }
                          } else {
                            driverBck = driverList;
                          }
                        }
                      }
                      if (rideList == {}) {
                        userRequestData = {};
                        setState(() {});
                      }

                      return Container(
                        width: media.width * 1,
                        height: media.height * 1,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: media.width * 1,
                          height: (driverList.isNotEmpty)
                              ? media.height * 1
                              : media.width * 0.72,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                            color: page,
                          ),
                          padding: (driverList.isNotEmpty)
                              ? EdgeInsets.fromLTRB(
                                  0,
                                  media.width * 0.1 +
                                      MediaQuery.of(context).padding.top,
                                  0,
                                  0)
                              : EdgeInsets.fromLTRB(
                                  0, media.width * 0.05, 0, media.width * 0.05),
                          child: Column(
                            children: [
                              Container(
                                width: media.width * 0.9,
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _cancel = true;
                                    });
                                  },
                                  child: Text(
                                    languages[choosenLanguage]['text_cancel'],
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * sixteen,
                                        color: Colors.red),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Text(
                                languages[choosenLanguage]
                                    ['text_findingdriver'],
                                style: GoogleFonts.notoSans(
                                    fontSize: media.width * sixteen,
                                    color: textColor,
                                    fontWeight: FontWeight.w600),
                              ),
                              (driverList.isNotEmpty)
                                  ? Expanded(
                                      child: Container(
                                        width: media.width * 1,
                                        padding: EdgeInsets.fromLTRB(
                                            media.width * 0.05,
                                            media.width * 0.05 +
                                                MediaQuery.of(context)
                                                    .padding
                                                    .top,
                                            media.width * 0.05,
                                            media.width * 0.05),
                                        child: SingleChildScrollView(
                                          child: Column(
                                              children: driverList
                                                  .asMap()
                                                  .map((key, value) {
                                                    return MapEntry(
                                                        key,
                                                        ValueListenableBuilder(
                                                            valueListenable:
                                                                valueNotifierTimer
                                                                    .value,
                                                            builder: (context,
                                                                value, child) {
                                                              var val = DateTime
                                                                      .now()
                                                                  .difference(DateTime.fromMillisecondsSinceEpoch(
                                                                      driverList[
                                                                              key]
                                                                          [
                                                                          'bid_time']))
                                                                  .inSeconds;
                                                              var calcDistance = calculateDistance(
                                                                  userRequestData[
                                                                      'pick_lat'],
                                                                  userRequestData[
                                                                      'pick_lng'],
                                                                  double.parse(driverList[
                                                                              key]
                                                                          [
                                                                          'lat']
                                                                      .toString()),
                                                                  double.parse(
                                                                      driverList[key]
                                                                              [
                                                                              'lng']
                                                                          .toString()));
                                                              if (int.parse(val
                                                                      .toString()) >=
                                                                  int.parse(userDetails[
                                                                              'maximum_time_for_find_drivers_for_bitting_ride']
                                                                          .toString()) +
                                                                      5) {
                                                                FirebaseDatabase
                                                                    .instance
                                                                    .ref()
                                                                    .child(
                                                                        'bid-meta/${userRequestData["id"]}/drivers/driver_${driverList[key]["driver_id"]}')
                                                                    .update({
                                                                  "is_rejected":
                                                                      'by_user'
                                                                });
                                                              }
                                                              return Container(
                                                                margin: EdgeInsets.only(
                                                                    bottom: media
                                                                            .width *
                                                                        0.025),
                                                                decoration:
                                                                    BoxDecoration(
                                                                        color:
                                                                            page,
                                                                        boxShadow: [
                                                                      BoxShadow(
                                                                          blurRadius:
                                                                              2,
                                                                          spreadRadius:
                                                                              2,
                                                                          color: Colors
                                                                              .black
                                                                              .withOpacity(0.2))
                                                                    ]),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: 5,
                                                                      width: (val <
                                                                              int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride']
                                                                                  .toString()))
                                                                          ? (media.width * 0.85 / int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString())) *
                                                                              (int.parse(userDetails['maximum_time_for_find_drivers_for_bitting_ride'].toString()) - double.parse(val.toString()))
                                                                          : 0,
                                                                      color:
                                                                          buttonColor,
                                                                    ),
                                                                    Container(
                                                                      padding: EdgeInsets.all(
                                                                          media.width *
                                                                              0.05),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            children: [
                                                                              Container(
                                                                                width: media.width * 0.1,
                                                                                height: media.width * 0.1,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(driverList[key]['driver_img']), fit: BoxFit.cover)),
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.05,
                                                                              ),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      driverList[key]['driver_name'],
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      textAlign: TextAlign.left,
                                                                                      maxLines: 1,
                                                                                    ),
                                                                                    SizedBox(
                                                                                      height: media.width * 0.025,
                                                                                    ),
                                                                                    Text(
                                                                                      '${driverList[key]['vehicle_make']} ${driverList[key]['vehicle_model']}',
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      textAlign: TextAlign.left,
                                                                                      maxLines: 1,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.01,
                                                                              ),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      rideList['currency'] + driverList[key]['price'],
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: textColor, fontWeight: FontWeight.w600),
                                                                                      textAlign: TextAlign.center,
                                                                                      maxLines: 1,
                                                                                    ),
                                                                                    SizedBox(
                                                                                      height: media.width * 0.025,
                                                                                    ),
                                                                                    Text(
                                                                                      (calcDistance != null) ? '${double.parse((calcDistance / 1000).toString()).toStringAsFixed(0)} km' : '',
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                      textAlign: TextAlign.center,
                                                                                      maxLines: 1,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.05,
                                                                          ),
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Button(
                                                                                onTap: () async {
                                                                                  setState(() {
                                                                                    isLoading = true;
                                                                                  });
                                                                                  var val = await acceptRequest(jsonEncode({
                                                                                    'driver_id': driverList[key]['driver_id'],
                                                                                    'request_id': userRequestData['id'],
                                                                                    'accepted_ride_fare': driverList[key]['price'].toString(),
                                                                                    'offerred_ride_fare': rideList['price'],
                                                                                  }));
                                                                                  if (val == 'success') {
                                                                                    await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}').remove();
                                                                                  }
                                                                                  setState(() {
                                                                                    isLoading = false;
                                                                                  });
                                                                                },
                                                                                text: languages[choosenLanguage]['text_accept'],
                                                                                width: media.width * 0.35,
                                                                                color: online,
                                                                                borcolor: online,
                                                                                textcolor: page,
                                                                              ),
                                                                              Button(
                                                                                onTap: () async {
                                                                                  setState(() {
                                                                                    isLoading = true;
                                                                                  });
                                                                                  await FirebaseDatabase.instance.ref().child('bid-meta/${userRequestData["id"]}/drivers/driver_${driverList[key]["driver_id"]}').update({
                                                                                    "is_rejected": 'by_user'
                                                                                  });
                                                                                  setState(() {
                                                                                    isLoading = false;
                                                                                  });
                                                                                },
                                                                                text: languages[choosenLanguage]['text_decline'],
                                                                                width: media.width * 0.35,
                                                                                color: verifyDeclined,
                                                                                borcolor: verifyDeclined,
                                                                                textcolor: page,
                                                                              )
                                                                            ],
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }));
                                                  })
                                                  .values
                                                  .toList()),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              if (driverList.isEmpty)
                                Column(
                                  children: [
                                    SizedBox(
                                      height: media.width * 0.01,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Text(
                                        '${languages[choosenLanguage]['text_offered_fare']} : ${rideList['currency']} ${rideList['price']}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * sixteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.01,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_current_fare'],
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * eighteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Container(
                                      width: media.width * 0.9,
                                      padding: EdgeInsets.only(
                                          top: media.width * 0.02),
                                      child: (updateAmount.text.isNotEmpty &&
                                              updateAmount.text != 'null')
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (updateAmount
                                                            .text.isNotEmpty &&
                                                        (userRequestData['bidding_low_percentage'] ==
                                                                0 ||
                                                            (double.parse(updateAmount
                                                                        .text
                                                                        .toString()) -
                                                                    ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.'))
                                                                        ? double.parse(userDetails['bidding_amount_increase_or_decrease']
                                                                            .toString())
                                                                        : int.parse(userDetails['bidding_amount_increase_or_decrease']
                                                                            .toString()))) >=
                                                                (double.parse(userRequestData['request_eta_amount'].toString()) -
                                                                    ((double.parse(userRequestData['bidding_low_percentage'].toString()) /
                                                                            100) *
                                                                        double.parse(userRequestData['request_eta_amount'].toString()))))) {
                                                      setState(() {
                                                        updateAmount.text = (updateAmount
                                                                .text.isEmpty)
                                                            ? (rideList['price']
                                                                    .toString()
                                                                    .contains(
                                                                        '.'))
                                                                ? (double.parse(rideList['price'].toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : (int.parse(rideList['price'].toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toString()
                                                            : (updateAmount.text
                                                                    .toString()
                                                                    .contains(
                                                                        '.'))
                                                                ? (double.parse(updateAmount.text.toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : (int.parse(updateAmount.text.toString()) -
                                                                        ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.'))
                                                                            ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())
                                                                            : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toString();
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    width: media.width * 0.2,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        color: (updateAmount
                                                                    .text
                                                                    .isNotEmpty &&
                                                                (userRequestData['bidding_low_percentage'] ==
                                                                        0 ||
                                                                    (double.parse(updateAmount.text.toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) >=
                                                                        (double.parse(userRequestData['request_eta_amount'].toString()) -
                                                                            ((double.parse(userRequestData['bidding_low_percentage'].toString()) / 100) *
                                                                                double.parse(userRequestData['request_eta_amount']
                                                                                    .toString())))))
                                                            ? (isDarkTheme)
                                                                ? Colors.white
                                                                : Colors.black
                                                            : borderLines,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                media.width *
                                                                    0.04)),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.025),
                                                    child: Text(
                                                      (userDetails[
                                                                  'bidding_amount_increase_or_decrease']
                                                              .toString()
                                                              .contains('.'))
                                                          ? '-${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}'
                                                          : '-${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                                      style: GoogleFonts.notoSans(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: (isDarkTheme)
                                                              ? Colors.black
                                                              : Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.4,
                                                  child: TextField(
                                                    enabled: false,
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    controller: updateAmount,
                                                    decoration: InputDecoration(
                                                      hintText: (rideList
                                                              .isNotEmpty)
                                                          ? rideList['price']
                                                              .toString()
                                                          : '',
                                                      hintStyle:
                                                          GoogleFonts.notoSans(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              color: textColor),
                                                      border: UnderlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color:
                                                                  hintColor)),
                                                    ),
                                                    style: GoogleFonts.notoSans(
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (userRequestData['bidding_high_percentage'] ==
                                                              0 ||
                                                          (double.parse(updateAmount
                                                                      .text
                                                                      .toString()) +
                                                                  ((userDetails['bidding_amount_increase_or_decrease']
                                                                          .toString()
                                                                          .contains(
                                                                              '.'))
                                                                      ? double.parse(userDetails['bidding_amount_increase_or_decrease']
                                                                          .toString())
                                                                      : int.parse(
                                                                          userDetails['bidding_amount_increase_or_decrease']
                                                                              .toString()))) <=
                                                              (double.parse(userRequestData['request_eta_amount'].toString()) +
                                                                  ((double.parse(userRequestData['bidding_high_percentage'].toString()) /
                                                                          100) *
                                                                      double.parse(userRequestData['request_eta_amount'].toString())))) {
                                                        updateAmount.text = (updateAmount
                                                                .text.isEmpty)
                                                            ? (rideList['price']
                                                                    .toString()
                                                                    .contains(
                                                                        '.'))
                                                                ? (double.parse(rideList['price'].toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : (int.parse(rideList['price'].toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toString()
                                                            : (updateAmount.text
                                                                    .toString()
                                                                    .contains(
                                                                        '.'))
                                                                ? (double.parse(updateAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : (int.parse(updateAmount.text.toString()) +
                                                                        ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.'))
                                                                            ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())
                                                                            : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                                    .toString();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    width: media.width * 0.2,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        color: (userRequestData[
                                                                        'bidding_high_percentage'] ==
                                                                    0 ||
                                                                (double.parse(updateAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))) <=
                                                                    (double.parse(userRequestData['request_eta_amount']
                                                                            .toString()) +
                                                                        ((double.parse(userRequestData['bidding_high_percentage'].toString()) / 100) *
                                                                            double.parse(userRequestData['request_eta_amount']
                                                                                .toString()))))
                                                            ? (isDarkTheme)
                                                                ? Colors.white
                                                                : Colors.black
                                                            : borderLines,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                media.width *
                                                                    0.04)),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.025),
                                                    child: Text(
                                                      (userDetails[
                                                                  'bidding_amount_increase_or_decrease']
                                                              .toString()
                                                              .contains('.'))
                                                          ? '+${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}'
                                                          : '+${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                                      style: GoogleFonts.notoSans(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: (isDarkTheme)
                                                              ? Colors.black
                                                              : Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Container(),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.02,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Button(
                                        onTap: () async {
                                          if (updateAmount.text.isNotEmpty) {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            await FirebaseDatabase.instance
                                                .ref()
                                                .child(
                                                    'bid-meta/${userRequestData["id"]}')
                                                .update({
                                              'price': updateAmount.text,
                                              'updated_at':
                                                  ServerValue.timestamp,
                                            });
                                            await FirebaseDatabase.instance
                                                .ref()
                                                .child(
                                                    'bid-meta/${userRequestData["id"]}/drivers')
                                                .remove();
                                            setState(() {
                                              updateAmount.clear();
                                              isLoading = false;
                                            });
                                          }
                                        },
                                        text: languages[choosenLanguage]
                                            ['text_update'],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
              )
            : _buildRegularDriverSearchOverlay(media)
        : Container();
  }

  Widget _buildRegularDriverSearchOverlay(Size media) {
    final requestId = userRequestData['id']?.toString();
    if (requestId == null || requestId.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: StreamBuilder<DatabaseEvent>(
        stream:
            FirebaseDatabase.instance.ref('request-meta/$requestId').onValue,
        builder: (context, snapshot) {
          return StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('bid-meta/$requestId/drivers')
                .onValue,
            builder: (context, offersSnapshot) {
              return _buildRegularDriverSearchContent(
                media,
                snapshot.data?.snapshot.value,
                offersSnapshot.data?.snapshot.value,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRegularDriverSearchContent(
    Size media,
    dynamic requestMetadata,
    dynamic counterOfferMetadata,
  ) {
    final pickupLatitude =
        double.tryParse(userRequestData['pick_lat']?.toString() ?? '') ?? 0;
    final pickupLongitude =
        double.tryParse(userRequestData['pick_lng']?.toString() ?? '') ?? 0;
    final serviceType = etaDetails.isNotEmpty && choosenVehicle != null
        ? etaDetails[choosenVehicle]['type_id']
        : userRequestData['vehicle_type_id'] ?? userRequestData['vehicle_type'];
    final configuredDuration = int.tryParse(
          (userRequestData['maximum_time_for_find_drivers_for_regular_ride'] ??
                  userDetails[
                      'maximum_time_for_find_drivers_for_regular_ride'] ??
                  0)
              .toString(),
        ) ??
        0;
    final remaining =
        int.tryParse(timing?.toString() ?? '') ?? configuredDuration;
    final nearbyCandidates = nearbySearchCandidates(
      source: List<dynamic>.from(driversData),
      serviceType: serviceType,
      transportType: choosenTransportType,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      distanceBetween: (lat1, lon1, lat2, lon2) =>
          calculateDistance(lat1, lon1, lat2, lon2) as double,
    );
    final candidates = prioritizeTargetedDrivers(
      nearbyCandidates,
      requestMetadata,
      counterOfferMetadata,
    );

    return _SearchingDriverOverlay(
      drivers: candidates,
      fare: _resolveRideFare(userRequestData),
      remainingSeconds: max(remaining, 0),
      totalSeconds: max(configuredDuration, 1),
      isRtl: languageDirection == 'rtl',
      onMenu: _showSearchingRequestMenu,
      onSupport: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupportPage()),
        );
      },
      onAcceptOffer: _acceptRegularCounterOffer,
    );
  }

  Future<bool> _acceptRegularCounterOffer(
    NearbyDriverCandidate driver,
  ) async {
    final offeredFare = driver.counterOffer;
    final requestId = userRequestData['id']?.toString();
    if (offeredFare == null || requestId == null || requestId.isEmpty) {
      return false;
    }
    final originalFare = double.tryParse(
          userRequestData['request_eta_amount']?.toString() ?? '',
        ) ??
        double.tryParse(
          _resolveRideFare(userRequestData)?.amount ?? '',
        ) ??
        offeredFare;
    final result = await acceptRequest(jsonEncode({
      'driver_id': driver.driverId,
      'request_id': requestId,
      'accepted_ride_fare': offeredFare,
      'offerred_ride_fare': originalFare,
    }));
    if (result == 'success') {
      await FirebaseDatabase.instance.ref('bid-meta/$requestId').remove();
      return true;
    }
    if (mounted) {
      final message = result == 'no internet'
          ? (languageDirection == 'rtl'
              ? 'تحقق من اتصال الإنترنت وحاول مجددًا'
              : 'Check your internet connection and try again')
          : (languageDirection == 'rtl'
              ? 'تعذر قبول عرض السائق. حاول مرة أخرى'
              : 'Unable to accept the driver offer. Please try again');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }

  void _showSearchingRequestMenu() {
    final isRtl = languageDirection == 'rtl';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: page,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xffFFF0F0),
                      child:
                          Icon(Icons.close_rounded, color: Color(0xffE44747)),
                    ),
                    title: Text(
                      isRtl ? 'إلغاء الطلب' : 'Cancel request',
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      isRtl
                          ? 'أوقف البحث عن سائق لهذا الطلب'
                          : 'Stop searching for a driver',
                      style: GoogleFonts.cairo(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _confirmAndCancelSearchingRequest();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndCancelSearchingRequest() async {
    final isRtl = languageDirection == 'rtl';
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Directionality(
            textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                isRtl ? 'إلغاء الطلب؟' : 'Cancel request?',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
              content: Text(
                isRtl
                    ? 'سيتوقف البحث الحالي عن سائق.'
                    : 'The current driver search will stop.',
                style: GoogleFonts.cairo(color: Colors.grey.shade700),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(isRtl ? 'متابعة البحث' : 'Keep searching'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffE44747),
                  ),
                  child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed) return;
    final result = await cancelRequest();
    if (result == 'logout') navigateLogout();
  }
}
