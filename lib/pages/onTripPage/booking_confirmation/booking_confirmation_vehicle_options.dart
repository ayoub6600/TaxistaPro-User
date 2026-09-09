part of '../booking_confirmation.dart';

mixin _BookingConfirmationVehicleOptions
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationVehicleServices {
  List<Widget> buildVehicleOptions(Size media, Query fdb) {
    return [
      (isOutStation == true)
          ? SizedBox(
              height: media.width * 0.02,
            )
          : const SizedBox(),
      (isOutStation == true)
          ? Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(media.width * 0.02),
              child: Container(
                width: media.width * 0.9,
                decoration: BoxDecoration(
                  color: page,
                  borderRadius: BorderRadius.circular(media.width * 0.02),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isOneWayTrip = true;
                            toDate = null;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(media.width * 0.03),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: isOneWayTrip ? Colors.orange : page),
                              borderRadius:
                                  BorderRadius.circular(media.width * 0.02)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  MyText(
                                    text: languages[choosenLanguage]
                                        ['text_one_way_trip'],
                                    size: media.width * fourteen,
                                    fontweight: FontWeight.bold,
                                  ),
                                  (isOneWayTrip)
                                      ? Container(
                                          height: media.width * 0.04,
                                          width: media.width * 0.04,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.orange),
                                          child: Icon(
                                            Icons.done,
                                            size: media.width * 0.03,
                                            color: page,
                                          ),
                                        )
                                      : Container()
                                ],
                              ),
                              MyText(
                                text: languages[choosenLanguage]
                                    ['text_get_drop_off'],
                                size: media.width * twelve,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isOneWayTrip = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(media.width * 0.03),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      (!isOneWayTrip) ? Colors.orange : page),
                              borderRadius:
                                  BorderRadius.circular(media.width * 0.02)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: MyText(
                                      text: languages[choosenLanguage]
                                          ['text_round_trip'],
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.bold,
                                      maxLines: 1,
                                    ),
                                  ),
                                  (!isOneWayTrip)
                                      ? Container(
                                          height: media.width * 0.04,
                                          width: media.width * 0.04,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.orange),
                                          child: Icon(
                                            Icons.done,
                                            size: media.width * 0.03,
                                            color: page,
                                          ),
                                        )
                                      : Container()
                                ],
                              ),
                              MyText(
                                text: languages[choosenLanguage]
                                    ['text_car_return'],
                                size: media.width * twelve,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      (isOutStation == true)
          ? SizedBox(
              height: media.width * 0.02,
            )
          : const SizedBox(),
      (isOutStation == true)
          ? InkWell(
              onTap: () {
                setState(() {
                  _isDateTimebottom = 0;
                });
                Future.delayed(const Duration(milliseconds: 200), () {
                  setState(() {
                    if (isOneWayTrip) {
                      _dateTimeHeight = media.height * 0.45;
                    } else {
                      _dateTimeHeight = media.height * 0.5;
                    }
                  });
                });
              },
              child: SizedBox(
                width: media.width * 0.9,
                child: Row(
                  children: [
                    MyText(
                      text: languages[choosenLanguage]['text_booking_for'],
                      size: media.width * twelve,
                      fontweight: FontWeight.w500,
                    ),
                    SizedBox(
                      width: media.width * 0.07,
                    ),
                    MyText(
                      text: (fromDate != null)
                          ? DateFormat('d MMM, h:mm a')
                              .format(fromDate)
                              .toString()
                          : DateFormat('d MMM, h:mm a')
                              .format(DateTime.now().add(Duration(
                                  minutes: int.parse(userDetails[
                                      'user_can_make_a_ride_after_x_miniutes']))))
                              .toString(),
                      size: media.width * twelve,
                      color: Colors.orange,
                    ),
                    (!isOneWayTrip)
                        ? MyText(
                            text:
                                ' -- ${(toDate != null) ? DateFormat('d MMM, h:mm a').format(toDate!).toString() : languages[choosenLanguage]['text_select']}',
                            size: media.width * twelve,
                            color: Colors.orange,
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            )
          : Container(),
      SizedBox(
        height: media.width * 0.02,
      ),
      if (etaDetails.isNotEmpty && widget.type != 1)
        Expanded(
          child: VehicleServicesSection(
            title: languages[choosenLanguage]['text_availablerides'],
            children: uniqueServices(etaDetails)
                .map((i, value) => MapEntry(
                      i,
                      buildVehicleServiceOption(
                        context: context,
                        driverQuery: fdb,
                        media: media,
                        index: i,
                        isOneWay: isOneWayTrip,
                        bookingType: widget.type,
                      ),
                    ))
                .values
                .toList(),
          ),
        )
      else
        (etaDetails.isNotEmpty && widget.type == 1)
            ? Expanded(
                child: SizedBox(
                    width: media.width * 1,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              media.width * 0.05,
                              media.width * 0.0,
                              media.width * 0.05,
                              media.width * 0.025),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: MyText(
                                      text: languages[choosenLanguage]
                                          ['text_select_package'],
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: media.width * 0.025,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          color:
                                              Colors.orange.withOpacity(0.14)),
                                      padding: EdgeInsets.fromLTRB(
                                          media.width * 0.05,
                                          media.width * 0.025,
                                          media.width * 0.05,
                                          media.width * 0.025),
                                      child: MyText(
                                          text: etaDetails[rentalChoosenOption]
                                                  ['package_name']
                                              .toString(),
                                          size: media.width * fifteen,
                                          fontweight: FontWeight.w500)),
                                  InkWell(
                                      onTap: () {
                                        setState(() {
                                          isRentalRide = true;
                                        });
                                      },
                                      child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_edit'],
                                          size: media.width * fifteen,
                                          fontweight: FontWeight.w500)),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: media.width * 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    isRentalRide = true;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                      left: media.width * 0.05,
                                      right: media.width * 0.05),
                                  width: media.width * 0.9,
                                  child: MyText(
                                    text: languages[choosenLanguage]
                                        ['text_availablerides'],
                                    size: media.width * fourteen,
                                    fontweight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Expanded(
                          child: SizedBox(
                            width: media.width * 0.9,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: rentalOption
                                          .asMap()
                                          .map((i, value) {
                                            return MapEntry(
                                                i,
                                                StreamBuilder<DatabaseEvent>(
                                                    stream: fdb.onValue,
                                                    builder: (context,
                                                        AsyncSnapshot event) {
                                                      if (event.data != null) {
                                                        minutes[rentalOption[i]
                                                            ['type_id']] = '';
                                                        List vehicleList = [];
                                                        List vehicles = [];
                                                        List<double> minsList =
                                                            [];
                                                        event.data!.snapshot
                                                            .children
                                                            .forEach((e) {
                                                          vehicleList
                                                              .add(e.value);
                                                        });
                                                        if (vehicleList
                                                            .isNotEmpty) {
                                                          vehicleList.forEach(
                                                            (e) async {
                                                              if (e['is_active'] ==
                                                                      1 &&
                                                                  e['is_available'] ==
                                                                      true &&
                                                                  ((e['vehicle_types'] !=
                                                                              null &&
                                                                          e['vehicle_types'].contains(rentalOption[i]
                                                                              [
                                                                              'type_id'])) ||
                                                                      e['vehicle_type'] ==
                                                                          rentalOption[i]
                                                                              [
                                                                              'type_id'])) {
                                                                DateTime dt = DateTime
                                                                    .fromMillisecondsSinceEpoch(
                                                                        e['updated_at']);
                                                                if (DateTime.now()
                                                                        .difference(
                                                                            dt)
                                                                        .inMinutes <=
                                                                    2) {
                                                                  vehicles
                                                                      .add(e);
                                                                  if (vehicles
                                                                      .isNotEmpty) {
                                                                    var dist = calculateDistance(
                                                                        addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .latitude,
                                                                        addressList
                                                                            .firstWhere((e) =>
                                                                                e.type ==
                                                                                'pickup')
                                                                            .latlng
                                                                            .longitude,
                                                                        e['l']
                                                                            [0],
                                                                        e['l'][
                                                                            1]);

                                                                    minsList.add(double.parse((dist /
                                                                            1000)
                                                                        .toString()));
                                                                    var minDist =
                                                                        minsList
                                                                            .reduce(min);
                                                                    if (minDist >
                                                                            0 &&
                                                                        minDist <=
                                                                            1) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '2 mins';
                                                                    } else if (minDist >
                                                                            1 &&
                                                                        minDist <=
                                                                            3) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '5 mins';
                                                                    } else if (minDist >
                                                                            3 &&
                                                                        minDist <=
                                                                            5) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '8 mins';
                                                                    } else if (minDist >
                                                                            5 &&
                                                                        minDist <=
                                                                            7) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '11 mins';
                                                                    } else if (minDist >
                                                                            7 &&
                                                                        minDist <=
                                                                            10) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '14 mins';
                                                                    } else if (minDist >
                                                                        10) {
                                                                      minutes[rentalOption[i]
                                                                              [
                                                                              'type_id']] =
                                                                          '15 mins';
                                                                    }
                                                                  } else {
                                                                    minutes[rentalOption[
                                                                            i][
                                                                        'type_id']] = '';
                                                                  }
                                                                }
                                                              }
                                                            },
                                                          );
                                                        } else {
                                                          minutes[rentalOption[
                                                                  i]
                                                              ['type_id']] = '';
                                                        }
                                                      } else {
                                                        minutes[rentalOption[i]
                                                            ['type_id']] = '';
                                                      }
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                          top: 10,
                                                        ),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            onTap: () {
                                                              if (choosenVehicle !=
                                                                  i) {
                                                                setState(() {
                                                                  choosenVehicle =
                                                                      i;
                                                                });
                                                              } else {
                                                                showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    isScrollControlled:
                                                                        true,
                                                                    builder:
                                                                        (context) {
                                                                      return Container(
                                                                        width: media
                                                                            .width,
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.05),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              page,
                                                                          borderRadius: BorderRadius.only(
                                                                              topLeft: Radius.circular(media.width * 0.08),
                                                                              topRight: Radius.circular(media.width * 0.08)),
                                                                        ),
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            Image.network(
                                                                              rentalOption[choosenVehicle]['icon'],
                                                                              width: media.width * 0.4,
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.02,
                                                                            ),
                                                                            MyText(
                                                                              text: '${rentalOption[choosenVehicle]['name']} (${etaDetails[rentalChoosenOption]['package_name']})',
                                                                              size: media.width * sixteen,
                                                                              fontweight: FontWeight.bold,
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.03,
                                                                            ),
                                                                            MyText(
                                                                              text: rentalOption[choosenVehicle]['short_description'],
                                                                              size: media.width * fourteen,
                                                                            ),
                                                                            SizedBox(
                                                                              height: media.width * 0.05,
                                                                            ),
                                                                            Container(
                                                                              width: media.width * 0.9,
                                                                              padding: EdgeInsets.all(media.width * 0.02),
                                                                              decoration: BoxDecoration(
                                                                                color: hintColor.withOpacity(0.1).withOpacity(0.1),
                                                                              ),
                                                                              child: Column(
                                                                                children: [
                                                                                  Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                    children: [
                                                                                      MyText(text: 'Fare', size: media.width * fourteen),
                                                                                      (rentalOption[choosenVehicle]['has_discount'] != true)
                                                                                          ? Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              children: [
                                                                                                Text(rentalOption[choosenVehicle]['currency'] + rentalOption[choosenVehicle]['fare_amount'].toString(),
                                                                                                    style: GoogleFonts.notoSans(
                                                                                                      fontSize: media.width * fourteen,
                                                                                                      fontWeight: FontWeight.w700,
                                                                                                      color: (choosenVehicle != i)
                                                                                                          ? (isDarkTheme == true)
                                                                                                              ? Colors.white
                                                                                                              : textColor
                                                                                                          : textColor,
                                                                                                    )),
                                                                                              ],
                                                                                            )
                                                                                          : Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              children: [
                                                                                                Text(rentalOption[choosenVehicle]['currency'],
                                                                                                    style: GoogleFonts.notoSans(
                                                                                                      fontSize: media.width * fourteen,
                                                                                                      fontWeight: FontWeight.w700,
                                                                                                      color: (choosenVehicle != i)
                                                                                                          ? (isDarkTheme == true)
                                                                                                              ? Colors.white
                                                                                                              : textColor
                                                                                                          : textColor,
                                                                                                    )),
                                                                                                Column(
                                                                                                  children: [
                                                                                                    Text(rentalOption[choosenVehicle]['fare_amount'].toString(),
                                                                                                        style: GoogleFonts.notoSans(
                                                                                                            fontSize: media.width * fourteen,
                                                                                                            fontWeight: FontWeight.w700,
                                                                                                            color: (choosenVehicle != i)
                                                                                                                ? (isDarkTheme == true)
                                                                                                                    ? Colors.white
                                                                                                                    : textColor
                                                                                                                : textColor,
                                                                                                            decoration: TextDecoration.lineThrough)),
                                                                                                    Text(rentalOption[choosenVehicle]['discounted_totel'].toString(),
                                                                                                        style: GoogleFonts.notoSans(
                                                                                                          fontSize: media.width * fourteen,
                                                                                                          fontWeight: FontWeight.w700,
                                                                                                          color: (choosenVehicle != i)
                                                                                                              ? (isDarkTheme == true)
                                                                                                                  ? Colors.white
                                                                                                                  : textColor
                                                                                                              : textColor,
                                                                                                        )),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            )
                                                                                    ],
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.05,
                                                                                  ),
                                                                                  FareBreakupDetails(width: media.width * 0.9, heading: 'Time Price', value: '${rentalOption[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['time_price_per_min'].toString()} / min'),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.05,
                                                                                  ),
                                                                                  FareBreakupDetails(width: media.width * 0.9, heading: 'Distance Price', value: '${rentalOption[choosenVehicle]['currency']} ${rentalOption[choosenVehicle]['distance_price_per_km'].toString()} / ${rentalOption[choosenVehicle]['unit_in_words']}'),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.05,
                                                                                  ),
                                                                                  FareBreakupDetails(width: media.width * 0.9, heading: 'Payment Types', value: rentalOption[choosenVehicle]['payment_type'].toString()),
                                                                                ],
                                                                              ),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      );
                                                                    });
                                                              }
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.02),
                                                              height:
                                                                  media.width *
                                                                      0.157,
                                                              decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(media.width * 0.01),
                                                                  border: Border.all(
                                                                      color: (choosenVehicle != i)
                                                                          ? (isDarkTheme == true)
                                                                              ? Colors.white
                                                                              : hintColor
                                                                          : Colors.orange),
                                                                  color: choosenVehicle == i ? Colors.orange.withOpacity(0.2) : null),
                                                              child: Row(
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.12,
                                                                    child: (rentalOption[i]['icon'] !=
                                                                            null)
                                                                        ? Image
                                                                            .network(
                                                                            rentalOption[i]['icon'],
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          )
                                                                        : Container(),
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.02,
                                                                  ),
                                                                  Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceEvenly,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.3,
                                                                            child: Text(rentalOption[i]['name'],
                                                                                style: GoogleFonts.notoSans(
                                                                                    fontSize: media.width * fourteen,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    color: (choosenVehicle != i)
                                                                                        ? (isDarkTheme == true)
                                                                                            ? hintColor
                                                                                            : textColor
                                                                                        : textColor)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              (minutes[rentalOption[i]['type_id']] != null && minutes[rentalOption[i]['type_id']] != '')
                                                                                  ? Text(
                                                                                      minutes[rentalOption[i]['type_id']].toString(),
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                    )
                                                                                  : Text(
                                                                                      '--',
                                                                                      style: GoogleFonts.notoSans(
                                                                                          fontSize: media.width * twelve,
                                                                                          color: (choosenVehicle != i)
                                                                                              ? (isDarkTheme == true)
                                                                                                  ? hintColor
                                                                                                  : const Color(0xff8A8A8A)
                                                                                              : const Color(0xff8A8A8A)),
                                                                                    ),
                                                                              SizedBox(
                                                                                width: media.width * 0.02,
                                                                              ),
                                                                              Icon(
                                                                                Icons.person,
                                                                                size: media.width * 0.04,
                                                                                color: const Color(0xff8A8A8A),
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.4,
                                                                                child: Text(
                                                                                  rentalOption[i]['capacity'].toString(),
                                                                                  maxLines: 1,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: GoogleFonts.notoSans(
                                                                                      fontSize: media.width * twelve,
                                                                                      color: (choosenVehicle != i)
                                                                                          ? (isDarkTheme == true)
                                                                                              ? hintColor
                                                                                              : const Color(0xff8A8A8A)
                                                                                          : const Color(0xff8A8A8A)),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                                  (widget.type !=
                                                                          2)
                                                                      ? Expanded(
                                                                          child: (rentalOption[i]['has_discount'] != true || rentalOption[i]['enable_bidding'] == true)
                                                                              ? (isOneWayTrip)
                                                                                  ? Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                                                      children: [
                                                                                        Text(
                                                                                          rentalOption[i]['currency'] + rentalOption[i]['fare_amount'].toString(),
                                                                                          style: GoogleFonts.notoSans(
                                                                                              fontSize: media.width * fourteen,
                                                                                              fontWeight: FontWeight.w700,
                                                                                              color: (choosenVehicle != i)
                                                                                                  ? (isDarkTheme == true)
                                                                                                      ? Colors.white
                                                                                                      : textColor
                                                                                                  : textColor),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  : Container()
                                                                              : Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      rentalOption[i]['currency'] + ' ',
                                                                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    Column(
                                                                                      children: [
                                                                                        Text(
                                                                                          rentalOption[i]['fare_amount'].toString(),
                                                                                          style: GoogleFonts.notoSans(
                                                                                              fontSize: media.width * fourteen,
                                                                                              color: (choosenVehicle != i)
                                                                                                  ? (isDarkTheme == true)
                                                                                                      ? Colors.white
                                                                                                      : textColor
                                                                                                  : Colors.black,
                                                                                              fontWeight: FontWeight.w600,
                                                                                              decoration: TextDecoration.lineThrough),
                                                                                        ),
                                                                                        Text(
                                                                                          rentalOption[i]['discounted_totel'].toString(),
                                                                                          style: GoogleFonts.notoSans(
                                                                                              fontSize: media.width * fourteen,
                                                                                              color: (choosenVehicle != i)
                                                                                                  ? (isDarkTheme == true)
                                                                                                      ? Colors.white
                                                                                                      : textColor
                                                                                                  : Colors.black,
                                                                                              fontWeight: FontWeight.w700),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  ],
                                                                                ))
                                                                      : Container()
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }));
                                          })
                                          .values
                                          .toList()),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
              )
            : Container(),
    ];
  }
}
