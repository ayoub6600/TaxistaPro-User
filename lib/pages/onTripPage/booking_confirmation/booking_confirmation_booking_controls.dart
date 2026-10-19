part of '../booking_confirmation.dart';

mixin _BookingConfirmationBookingControls
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationRequestAction {
  String _selectedPaymentType({required bool rental}) {
    final source = rental ? rentalOption : etaDetails;
    if (choosenVehicle == null ||
        choosenVehicle < 0 ||
        choosenVehicle >= source.length) {
      return '';
    }
    final methods = source[choosenVehicle]['payment_type']
        .toString()
        .split(',')
        .map((method) => method.trim())
        .toList();
    return payingVia >= 0 && payingVia < methods.length
        ? methods[payingVia]
        : '';
  }

  String _selectedPaymentLabel({required bool rental}) {
    final method = _selectedPaymentType(rental: rental);
    final key = switch (method) {
      'cash' => 'text_cash',
      'wallet' => 'text_wallet',
      'wallet_and_cash' => 'text_wallet',
      'card' => 'text_card',
      _ => 'text_upi',
    };
    return languages[choosenLanguage][key];
  }

  Widget buildBookingControls(Size media, GeoHasher geo) {
    // NOT Theme.of(context).colorScheme here - see bookingBrandColorScheme()
    // doc comment in booking_confirmation.dart for why that silently misses
    // this screen's brand color override in a plain mixin method like this.
    final colors = bookingBrandColorScheme();
    return Container(
      width: media.width,
      padding: EdgeInsets.fromLTRB(
          media.width * 0.05, 14.h, media.width * 0.05, 12.h),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              blurRadius: 24,
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -6))
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
                          var val = await guardedPush(
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
          Row(
            textDirection: ui.TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (choosenTransportType == 0 &&
                  (userDetails['enable_driver_preference_for_user'] == '1' ||
                      userDetails['enable_pet_preference_for_user'] == '1' ||
                      userDetails['enable_luggage_preference_for_user'] == '1'))
                Tooltip(
                  message: languages[choosenLanguage]['text_ride_preference'],
                  child: InkWell(
                    onTap: () {
                      choosePets = addPetPreferences;
                      chooseLuggages = addLuggagePreferences;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => ChoosePreferencesContainer(
                          type: widget.type,
                          onTap: () {
                            setState(() {
                              addPetPreferences = choosePets;
                              addLuggagePreferences = chooseLuggages;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 42.w,
                      height: 42.h,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.09),
                        border: Border.all(
                            color: colors.primary.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: colors.primary, size: 20.sp),
                    ),
                  ),
                )
              else
                const SizedBox(width: 42),
              if (choosenVehicle != null)
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => ChoosePaymentMethodContainer(
                        type: widget.type,
                        onTap: () {
                          setState(() => payingVia = choosenInPopUp);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: media.width * 0.38),
                    height: 42.h,
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.09),
                      border: Border.all(
                          color: colors.primary.withValues(alpha: 0.18)),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _selectedPaymentType(rental: widget.type == 1) ==
                                    'cash'
                                ? Icons.payments_outlined
                                : Icons.account_balance_wallet_outlined,
                            color: colors.primary,
                            size: 18.sp),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            _selectedPaymentLabel(rental: widget.type == 1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                                color: colors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: colors.primary, size: 17.sp),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          (selectedGoodsId == '' && choosenTransportType == 1)
              ? Button(
                  width: media.width * 0.9,
                  onTap: () async {
                    var val = await guardedPush(
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
                              (widget.type != null ||
                                  etaDetails[choosenVehicle]
                                          ['ride_later_supported'] !=
                                      false) &&
                              isOutStation == false)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final eta = etaDetails[choosenVehicle];
                                      final service = rentalOption.isEmpty
                                          ? eta
                                          : rentalOption[choosenVehicle];
                                      final fare = (rentalOption.isEmpty
                                              ? quotedFareForPayment(eta,
                                                  scheduled:
                                                      choosenTransportType ==
                                                              0 &&
                                                          widget.type == null,
                                                  discounted:
                                                      eta['has_discount'] ==
                                                          true)
                                              : (double.tryParse((service[
                                                                      'has_discount'] ==
                                                                  true
                                                              ? service[
                                                                  'discounted_totel']
                                                              : service[
                                                                  'fare_amount'])
                                                          ?.toString() ??
                                                      '') ??
                                                  0))
                                          .toDouble();
                                      final walletBalance = rentalOption.isEmpty
                                          ? (double.tryParse(
                                                  eta['user_wallet_balance']
                                                          ?.toString() ??
                                                      '') ??
                                              0)
                                          : (double.tryParse(etaDetails[0][
                                                          'user_wallet_balance']
                                                      ?.toString() ??
                                                  '') ??
                                              0);
                                      if ((widget.type == null &&
                                              choosenTransportType == 0 &&
                                              rentalOption.isEmpty) ||
                                          walletCanCoverOrSplit(service,
                                              fare: fare,
                                              walletBalance: walletBalance)) {
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
                                              color: colors.primary
                                                  .withValues(alpha: 0.08),
                                              border: Border.all(
                                                  color: colors.primary
                                                      .withValues(alpha: 0.16)),
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
                                                        color: colors.primary,
                                                      ),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_ride_later'],
                                                        size: media.width *
                                                            twelve,
                                                        color: colors.primary,
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
                                              color: colors.primary
                                                  .withValues(alpha: 0.08),
                                              border: Border.all(
                                                  color: colors.primary
                                                      .withValues(alpha: 0.16)),
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
                                                      color: colors.primary,
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
                                                      color: colors.primary,
                                                    )),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                (choosenVehicle != null &&
                                        (widget.type == 1 ||
                                            etaDetails[choosenVehicle]
                                                    ['coupon_supported'] !=
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
                                                color: colors.primary
                                                    .withValues(alpha: 0.08),
                                                border: Border.all(
                                                    color: colors.primary
                                                        .withValues(
                                                            alpha: 0.16)),
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
                                                    color: colors.primary,
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
