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

  /// «أمتعة، حيوانات» from what is chosen; «اختر» when nothing is
  String _preferencesSummary() {
    final rtl = languageDirection == 'rtl';
    final picked = <String>[
      if (addLuggagePreferences == true) rtl ? 'أمتعة' : 'Luggage',
      if (addPetPreferences == true) rtl ? 'حيوان أليف' : 'Pet',
    ];
    return picked.isEmpty ? (rtl ? 'اختر' : 'Choose') : picked.join(rtl ? '، ' : ', ');
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
          // "سواقيني": a favourite driver free and near for this car type (ride now only)
          if (choosenTransportType == 0 &&
              widget.type != 1 &&
              isOutStation != true &&
              choosenVehicle != null &&
              addressList.any((e) => e.type == 'pickup'))
            FavoriteDriverChoice(
              pickLat: addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
              pickLng: addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude,
              zoneTypeId: etaDetails[choosenVehicle]['zone_type_id']?.toString(),
            ),
          // a Taxista gift: what it takes off this fare, before «تأكيد الطلب» (the server's rule)
          if (choosenTransportType == 0 && widget.type != 1 && isOutStation != true && choosenVehicle != null)
            GiftPreviewLine(
              zoneTypeId: etaDetails[choosenVehicle]['zone_type_id']?.toString(),
              fare: double.tryParse(etaDetails[choosenVehicle]['total']?.toString() ?? '') ?? 0,
              pricingMode: RidePricingMode.fromService(etaDetails[choosenVehicle]) == RidePricingMode.fixedFare ? 'fixed' : 'bidding',
              coupon: etaDetails[choosenVehicle]['has_discount'] == true,
            ),
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
          // design v2: «الدفع» and «التفضيلات» as two tiles, caption over the current choice
          // (the payment first on the reading side)
          Row(
            textDirection: languageDirection == 'rtl' ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            children: [
              if (choosenTransportType == 0 &&
                  (userDetails['enable_driver_preference_for_user'] == '1' ||
                      userDetails['enable_pet_preference_for_user'] == '1' ||
                      userDetails['enable_luggage_preference_for_user'] == '1'))
                Expanded(child: Tooltip(
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
                    borderRadius: BorderRadius.circular(16),
                    child: BookingTile(
                      icon: Icons.luggage_outlined,
                      caption: languageDirection == 'rtl' ? 'التفضيلات' : 'Preferences',
                      value: _preferencesSummary(),
                      color: colors.primary,
                    ),
                  ),
                )),
              if (choosenVehicle != null) ...[
                if (choosenTransportType == 0 &&
                    (userDetails['enable_driver_preference_for_user'] == '1' ||
                        userDetails['enable_pet_preference_for_user'] == '1' ||
                        userDetails['enable_luggage_preference_for_user'] == '1'))
                  const SizedBox(width: 10),
                Expanded(child: InkWell(
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
                  borderRadius: BorderRadius.circular(16),
                  child: BookingTile(
                    icon: _selectedPaymentType(rental: widget.type == 1) == 'cash'
                        ? Icons.payments_outlined
                        : Icons.account_balance_wallet_outlined,
                    caption: languageDirection == 'rtl' ? 'الدفع' : 'Payment',
                    value: _selectedPaymentLabel(rental: widget.type == 1),
                    color: colors.primary,
                  ),
                )),
              ],
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
                                    borderRadius: BorderRadius.circular(16),
                                    child: BookingTile(
                                      icon: Icons.schedule_rounded,
                                      caption: languageDirection == 'rtl' ? 'الوقت' : 'Time',
                                      value: !confirmRideLater
                                          ? (languageDirection == 'rtl' ? 'الآن · احجز لوقت لاحق' : 'Now · book for later')
                                          : scheduleRelativeLabel(choosenDateTime, isRtl: languageDirection == 'rtl'),
                                      color: colors.primary,
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
                                    ? Padding(
                                        padding: const EdgeInsetsDirectional.only(start: 10),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
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
                                          child: SizedBox(
                                            width: media.width * 0.36,
                                            child: BookingTile(
                                              icon: Icons.local_offer_outlined,
                                              caption: languages[choosenLanguage]['text_coupons'] ?? 'كوبونات الخصم',
                                              value: languageDirection == 'rtl' ? 'أضف' : 'Add',
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
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
