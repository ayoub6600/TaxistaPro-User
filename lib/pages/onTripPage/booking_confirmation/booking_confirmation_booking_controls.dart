part of '../booking_confirmation.dart';

mixin _BookingConfirmationBookingControls
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationRequestAction {
  Widget buildBookingControls(Size media, GeoHasher geo) {
    return Container(
      width: media.width,
      padding: EdgeInsets.all(media.width * 0.03),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2)
        ],
        color: page,
      ),
      child: Column(
        children: [
          (choosenTransportType == 1)
              ? Column(
                  children: [
                    InkWell(
                      onTap: () {
                        pickerName.text = addressList[0].name;
                        pickerNumber.text = addressList[0].number;
                        instructions.text =
                            (addressList[0].instructions != null)
                                ? addressList[0].instructions
                                : '';
                        _editUserDetails = true;
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: media.width * 0.9,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: media.width * 0.35,
                                  child: Text(
                                    addressList[0].name,
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * twelve,
                                        color: buttonColor,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: media.width * 0.35,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        addressList[0].number,
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * twelve,
                                            color: buttonColor,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                        width: media.width * 0.025,
                                      ),
                                      Icon(
                                        Icons.edit,
                                        size: media.width * 0.04,
                                        color: buttonColor,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.0,
                          ),
                          (addressList[0].instructions != null)
                              ? SizedBox(
                                  width: media.width * 0.9,
                                  child: Text(
                                    languages[choosenLanguage]
                                            ['text_instructions'] +
                                        ' : ' +
                                        addressList[0].instructions,
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * twelve,
                                        color: verifyDeclined,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ))
                              : Container()
                        ],
                      ),
                    ),
                  ],
                )
              : Container(),
          (selectedGoodsId != '')
              ? Container(
                  padding: EdgeInsets.only(top: media.width * 0.03),
                  width: media.width * 0.9,
                  child: Column(
                    children: [
                      SizedBox(
                        width: media.width * 0.9,
                        child: Text(
                          languages[choosenLanguage]['text_goods_type'],
                          style: GoogleFonts.notoSans(
                            color: textColor,
                            fontSize: media.width * fourteen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: media.width * 0.02),
                      InkWell(
                        onTap: () async {
                          var val = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChooseGoods()));
                          if (val) {
                            setState(() {});
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: media.width * 0.7,
                              child: Text(
                                goodsTypeList.firstWhere((e) =>
                                            e['id'] ==
                                            int.parse(selectedGoodsId))[
                                        'goods_type_name'] +
                                    ' (' +
                                    goodsSize +
                                    ')',
                                style: GoogleFonts.notoSans(
                                    fontSize: media.width * twelve,
                                    color: buttonColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: media.width * 0.04,
                              color: buttonColor,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              (choosenVehicle != null && widget.type != 1)
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: media.width * 0.035,
                        vertical: media.width * 0.015,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        color: buttonColor.withValues(alpha: 0.86),
                      ),
                      height: media.width * 0.10,
                      width: media.width * 0.52,
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) {
                                    return ChoosePaymentMethodContainer(
                                      type: widget.type,
                                      onTap: () {
                                        setState(() {
                                          payingVia = choosenInPopUp;
                                        });
                                        Navigator.pop(context);
                                      },
                                    );
                                  });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                (etaDetails[choosenVehicle]['payment_type']
                                            .toString()
                                            .split(',')
                                            .toList()[payingVia] ==
                                        'cash')
                                    ? Image.asset(
                                        'assets/images/cash-on-delivery.png',
                                        width: media.width * 0.07,
                                        height: media.width * 0.7,
                                        fit: BoxFit.contain,
                                      )
                                    : (etaDetails[choosenVehicle]
                                                    ['payment_type']
                                                .toString()
                                                .split(',')
                                                .toList()[payingVia] ==
                                            'wallet')
                                        ? Image.asset(
                                            'assets/images/wallet (1).png',
                                            width: media.width * 0.07,
                                            height: media.width * 0.07,
                                            fit: BoxFit.contain,
                                          )
                                        : (etaDetails[choosenVehicle]
                                                        ['payment_type']
                                                    .toString()
                                                    .split(',')
                                                    .toList()[payingVia] ==
                                                'card')
                                            ? Image.asset(
                                                "assets/images/debit-card.png",
                                                width: media.width * 0.07,
                                                height: media.width * 0.07,
                                                fit: BoxFit.contain,
                                              )
                                            : (etaDetails[choosenVehicle]
                                                            ['payment_type']
                                                        .toString()
                                                        .split(',')
                                                        .toList()[payingVia] ==
                                                    'upi')
                                                ? Image.asset(
                                                    'assets/images/upi.png',
                                                    width: media.width * 0.07,
                                                    height: media.width * 0.07,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Container(),
                                SizedBox(
                                  width: media.width * 0.02,
                                ),
                                MyText(
                                  text: (etaDetails[choosenVehicle]
                                                  ['payment_type']
                                              .toString()
                                              .split(',')
                                              .toList()[payingVia] ==
                                          'cash')
                                      ? languages[choosenLanguage]['text_cash']
                                      : (etaDetails[choosenVehicle]
                                                      ['payment_type']
                                                  .toString()
                                                  .split(',')
                                                  .toList()[payingVia] ==
                                              'wallet')
                                          ? languages[choosenLanguage]
                                              ['text_wallet']
                                          : (etaDetails[choosenVehicle]
                                                          ['payment_type']
                                                      .toString()
                                                      .split(',')
                                                      .toList()[payingVia] ==
                                                  'card')
                                              ? languages[choosenLanguage]
                                                  ['text_card']
                                              : languages[choosenLanguage]
                                                  ['text_upi'],
                                  size: media.width * sixteen,
                                  fontweight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: media.width * 0.03,
                                ),
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: media.width * 0.03,
                                  ),
                                )
                              ],
                            ),
                          )),
                    )
                  : (choosenVehicle != null && widget.type == 1)
                      ? InkWell(
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  return ChoosePaymentMethodContainer(
                                    type: widget.type,
                                    onTap: () {
                                      setState(() {
                                        payingVia = choosenInPopUp;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                });
                          },
                          child: SizedBox(
                            height: media.width * 0.106,
                            width: media.width * 0.4,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  (rentalOption[choosenVehicle]['payment_type']
                                              .toString()
                                              .split(',')
                                              .toList()[payingVia] ==
                                          'cash')
                                      ? Image.asset(
                                          'assets/images/cash.png',
                                          width: media.width * 0.07,
                                          height: media.width * 0.07,
                                          fit: BoxFit.contain,
                                        )
                                      : (rentalOption[choosenVehicle]
                                                      ['payment_type']
                                                  .toString()
                                                  .split(',')
                                                  .toList()[payingVia] ==
                                              'wallet')
                                          ? Image.asset(
                                              'assets/images/wallet.png',
                                              width: media.width * 0.07,
                                              height: media.width * 0.07,
                                              fit: BoxFit.contain,
                                            )
                                          : (rentalOption[choosenVehicle]
                                                          ['payment_type']
                                                      .toString()
                                                      .split(',')
                                                      .toList()[payingVia] ==
                                                  'card')
                                              ? Image.asset(
                                                  'assets/images/card.png',
                                                  width: media.width * 0.07,
                                                  height: media.width * 0.07,
                                                  fit: BoxFit.contain,
                                                )
                                              : (rentalOption[choosenVehicle]
                                                              ['payment_type']
                                                          .toString()
                                                          .split(',')
                                                          .toList()[payingVia] ==
                                                      'upi')
                                                  ? Image.asset(
                                                      'assets/images/upi.png',
                                                      width: media.width * 0.07,
                                                      height:
                                                          media.width * 0.07,
                                                      fit: BoxFit.contain,
                                                    )
                                                  : Container(),
                                  SizedBox(
                                    width: media.width * 0.02,
                                  ),
                                  MyText(
                                    text: (rentalOption[choosenVehicle]
                                                    ['payment_type']
                                                .toString()
                                                .split(',')
                                                .toList()[payingVia] ==
                                            'cash')
                                        ? languages[choosenLanguage]
                                            ['text_cash']
                                        : (rentalOption[choosenVehicle]
                                                        ['payment_type']
                                                    .toString()
                                                    .split(',')
                                                    .toList()[payingVia] ==
                                                'wallet')
                                            ? languages[choosenLanguage]
                                                ['text_wallet']
                                            : (rentalOption[choosenVehicle]
                                                            ['payment_type']
                                                        .toString()
                                                        .split(',')
                                                        .toList()[payingVia] ==
                                                    'card')
                                                ? languages[choosenLanguage]
                                                    ['text_card']
                                                : languages[choosenLanguage]
                                                    ['text_upi'],
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                    color: (isDarkTheme == true)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  SizedBox(
                                    width: media.width * 0.03,
                                  ),
                                  RotatedBox(
                                    quarterTurns: 1,
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: textColor,
                                      size: media.width * 0.03,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
            ],
          ),
          SizedBox(
            height: 10.h,
          ),
          ((userDetails['enable_driver_preference_for_user'] != '1' &&
                      userDetails['enable_pet_preference_for_user'] != '1' &&
                      userDetails['enable_luggage_preference_for_user'] !=
                          '1') ||
                  choosenTransportType == 1 ||
                  userDetails['enable_modules_for_applications'] == 'delivery')
              ? Container()
              : Container(
                  width: media.width * 0.56,
                  padding:
                      EdgeInsets.symmetric(vertical: 7.h, horizontal: 10.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    color: buttonColor.withValues(alpha: 0.86),
                  ),
                  alignment: Alignment.center,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                if (addPetPreferences == true) {
                                  choosePets = true;
                                } else {
                                  choosePets = false;
                                }
                                if (addLuggagePreferences == true) {
                                  chooseLuggages = true;
                                } else {
                                  chooseLuggages = false;
                                }
                                showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return ChoosePreferencesContainer(
                                        type: widget.type,
                                        onTap: () {
                                          setState(() {
                                            addLuggagePreferences =
                                                chooseLuggages;
                                            addPetPreferences = choosePets;
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: media.width * 0.05,
                                    width: media.width * 0.075,
                                    child: Image.asset(
                                      'assets/images/Tune.png',
                                      color: Colors.white,
                                    ),
                                  ),
                                  MyText(
                                    text: languages[choosenLanguage]
                                        ['text_ride_preference'],
                                    size: 14.sp,
                                    fontweight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  if (addPetPreferences == true ||
                                      addLuggagePreferences == true)
                                    MyText(
                                      text: ' :- ',
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  SizedBox(
                                    width: media.width * 0.025,
                                  ),
                                  if (addPetPreferences == true)
                                    MyText(
                                      text: languages[choosenLanguage]
                                          ['text_pets'],
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  if (addPetPreferences == true &&
                                      addLuggagePreferences == true)
                                    MyText(
                                      text: ', ',
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  if (addLuggagePreferences == true)
                                    MyText(
                                      text: languages[choosenLanguage]
                                          ['text_luggages'],
                                      size: media.width * fourteen,
                                      fontweight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  SizedBox(
                                    width: media.width * 0.025,
                                  ),
                                  (addPetPreferences == false &&
                                          addLuggagePreferences == false)
                                      ? Container()
                                      : Icon(
                                          Icons.edit,
                                          size: media.width * 0.03,
                                          color: Colors.grey,
                                        )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          SizedBox(
            height: 10.h,
          ),
          (selectedGoodsId == '' && choosenTransportType == 1)
              ? Button(
                  width: media.width * 0.9,
                  onTap: () async {
                    var val = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChooseGoods()));
                    if (val) {
                      setState(() {});
                    }
                  },
                  text: languages[choosenLanguage]['text_choose_goods'],
                )
              : SizedBox(
                  width: media.width * 0.9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (userDetails['show_ride_later_feature'] == true &&
                              ((widget.type == null)
                                  ? (etaDetails[choosenVehicle]
                                              ['enable_bidding'] ==
                                          null ||
                                      etaDetails[choosenVehicle]
                                              ['enable_bidding'] ==
                                          false)
                                  : true) &&
                              isOutStation == false)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      if (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) ||
                                                  (rentalOption.isEmpty &&
                                                      etaDetails[choosenVehicle]['has_discount'] ==
                                                          true &&
                                                      etaDetails[choosenVehicle]['user_wallet_balance'] >=
                                                          etaDetails[choosenVehicle][
                                                              'discounted_totel'])) ||
                                              (rentalOption.isEmpty &&
                                                  etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] !=
                                                      'wallet')) ||
                                          ((rentalOption.isNotEmpty &&
                                                  (etaDetails[0]['user_wallet_balance'] >=
                                                      rentalOption[choosenVehicle]
                                                          ['fare_amount']) &&
                                                  rentalOption[choosenVehicle]
                                                          ['has_discount'] ==
                                                      false) ||
                                              (rentalOption.isNotEmpty &&
                                                  rentalOption[choosenVehicle]['has_discount'] == true &&
                                                  etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['discounted_totel']) ||
                                              rentalOption.isNotEmpty && rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) {
                                        if (choosenVehicle != null) {
                                          setState(() {
                                            choosenDateTime = DateTime.now()
                                                .add(Duration(
                                                    minutes: int.parse(userDetails[
                                                        'user_can_make_a_ride_after_x_miniutes'])));
                                          });

                                          showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              builder: (context) {
                                                return RideLaterBottomSheet(
                                                  type: widget.type,
                                                );
                                              });
                                        }
                                      } else {
                                        setState(() {
                                          islowwalletbalance = true;
                                        });
                                      }
                                    },
                                    child: (!confirmRideLater)
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: buttonColor.withValues(
                                                  alpha: 0.78),
                                              borderRadius:
                                                  BorderRadius.circular(14.r),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.h,
                                            ),
                                            child: (confirmRideLater == false)
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: media.width *
                                                            sixteen,
                                                        color: Colors.white,
                                                      ),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_ride_later'],
                                                        size: media.width *
                                                            twelve,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  )
                                                : MyText(
                                                    text: DateFormat()
                                                        .format(choosenDateTime)
                                                        .toString(),
                                                    size: media.width * twelve,
                                                  ),
                                          )
                                        : Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14.w,
                                                vertical: 8.h),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14.r),
                                              color: buttonColor.withValues(
                                                  alpha: 0.78),
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                    DateFormat()
                                                            .format(
                                                                choosenDateTime)
                                                            .toString()
                                                            .split(" ")[1] +
                                                        DateFormat()
                                                            .format(
                                                                choosenDateTime)
                                                            .toString()
                                                            .split(" ")[2],
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white,
                                                    )),
                                                SizedBox(
                                                  width: 10.w,
                                                ),
                                                Text(
                                                    DateFormat()
                                                        .format(choosenDateTime)
                                                        .toString()
                                                        .split(" ")[3],
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white,
                                                    )),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                (choosenVehicle != null &&
                                        (widget.type == 1 ||
                                            etaDetails[choosenVehicle]
                                                    ['enable_bidding'] ==
                                                null ||
                                            etaDetails[choosenVehicle]
                                                    ['enable_bidding'] ==
                                                false) &&
                                        widget.type != 2 &&
                                        isOneWayTrip == true)
                                    ? Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder: (context) {
                                                    return ApplyCouponsContainer(
                                                      type: widget.type,
                                                    );
                                                  });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.h,
                                                  horizontal: 10.w),
                                              margin: EdgeInsets.symmetric(
                                                  horizontal:
                                                      media.width * 0.05),
                                              decoration: BoxDecoration(
                                                color: buttonColor.withValues(
                                                    alpha: 0.78),
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_coupons'],
                                                    size:
                                                        media.width * fourteen,
                                                    fontweight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ],
                            )
                          : Container(),
                      SizedBox(
                        height: 12.h,
                      ),
                      buildRideRequestButton(media, geo),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
