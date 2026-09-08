part of '../bookingwidgets.dart';

class CreateRequestBottomSheet extends StatefulWidget {
  final dynamic type;
  final dynamic showInfoInt;
  final dynamic fromDate;
  final dynamic toDate;
  final dynamic isOneWayTrip;
  final dynamic geo;
  final dynamic amount;
  const CreateRequestBottomSheet(
      {super.key,
      this.type,
      this.showInfoInt,
      this.fromDate,
      this.toDate,
      this.isOneWayTrip,
      this.geo,
      this.amount});

  @override
  State<CreateRequestBottomSheet> createState() =>
      _CreateRequestBottomSheetState();
}

bool rideLaterSuccess = false;

class _CreateRequestBottomSheetState extends State<CreateRequestBottomSheet>
    with _CreateRequestActions {
  @override
  void initState() {
    yourAmount.text = widget.amount;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      padding: MediaQuery.of(context).viewInsets,
      width: media.width * 1,
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      child: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: media.width * 0.05),
            Container(
              width: media.width * 0.95,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: page),
              padding: EdgeInsets.all(media.width * 0.05),
              child: (widget.type != 1)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etaDetails[widget.showInfoInt]['name'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen,
                              color: textColor,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Text(
                          etaDetails[widget.showInfoInt]['description'],
                          style: GoogleFonts.notoSans(
                            fontSize: media.width * fourteen,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                        Text(
                          languages[choosenLanguage]['text_supported_vehicles'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen,
                              color: textColor,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Text(
                          etaDetails[widget.showInfoInt]['supported_vehicles'],
                          style: GoogleFonts.notoSans(
                            fontSize: media.width * fourteen,
                            color: textColor,
                          ),
                        ),
                        (isOutStation && widget.isOneWayTrip == false)
                            ? Container()
                            : SizedBox(height: media.width * 0.05),
                        (isOutStation && widget.isOneWayTrip == false)
                            ? Container()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.4,
                                    child: Text(
                                      languages[choosenLanguage]
                                          ['text_recommended_fare'],
                                      style: GoogleFonts.notoSans(
                                          fontSize: media.width * sixteen,
                                          color: textColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  (etaDetails[widget.showInfoInt]
                                                  ['has_discount'] !=
                                              true ||
                                          etaDetails[widget.showInfoInt]
                                                  ['enable_bidding'] ==
                                              true ||
                                          isOutStation)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${etaDetails[widget.showInfoInt]['total'].toStringAsFixed(2)} ${etaDetails[widget.showInfoInt]['currency']}'
                                              // etaDetails[_showInfoInt]['currency'] + ' ' + etaDetails[_showInfoInt]['total'].toStringAsFixed(2),
                                              ,
                                              style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              etaDetails[widget.showInfoInt]
                                                      ['currency'] +
                                                  ' ',
                                              style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              etaDetails[widget.showInfoInt]
                                                      ['total']
                                                  .toStringAsFixed(2),
                                              style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration
                                                      .lineThrough),
                                            ),
                                            Text(
                                              ' ${etaDetails[widget.showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                              style: GoogleFonts.notoSans(
                                                  fontSize:
                                                      media.width * fourteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            )
                                          ],
                                        )
                                ],
                              ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        MyText(
                            text: languages[choosenLanguage]
                                ['text_offer_your_fare'],
                            size: media.width * fourteen,
                            color: textColor,
                            fontweight: FontWeight.w600),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                if (yourAmount.text.isNotEmpty &&
                                    (etaDetails[choosenVehicle]
                                                ['bidding_low_percentage'] ==
                                            0 ||
                                        (double.parse(yourAmount.text.toString()) -
                                                ((userDetails['bidding_amount_increase_or_decrease']
                                                        .toString()
                                                        .contains('.'))
                                                    ? double.parse(
                                                        userDetails['bidding_amount_increase_or_decrease']
                                                            .toString())
                                                    : int.parse(
                                                        userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()))) >=
                                            (double.parse(etaDetails[choosenVehicle]['total'].toString()) -
                                                ((double.parse(etaDetails[choosenVehicle]['bidding_low_percentage'].toString()) /
                                                        100) *
                                                    double.parse(etaDetails[choosenVehicle]['total'].toString()))))) {
                                  setState(() {
                                    yourAmount.text = (yourAmount.text.isEmpty)
                                        ? (etaDetails[choosenVehicle]['total']
                                                .toString()
                                                .contains('.'))
                                            ? (double.parse(etaDetails[choosenVehicle]['total'].toString()) -
                                                    ((userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()
                                                            .contains('.'))
                                                        ? double.parse(
                                                            userDetails['bidding_amount_increase_or_decrease']
                                                                .toString())
                                                        : int.parse(userDetails['bidding_amount_increase_or_decrease']
                                                            .toString())))
                                                .toStringAsFixed(2)
                                            : (int.parse(etaDetails[choosenVehicle]['total'].toString()) -
                                                    ((userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()
                                                            .contains('.'))
                                                        ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())
                                                        : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                .toString()
                                        : (yourAmount.text.toString().contains('.'))
                                            ? (double.parse(yourAmount.text.toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toStringAsFixed(2)
                                            : (int.parse(yourAmount.text.toString()) - ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toString();
                                    // updateAmount.text = (updateAmount.text.isEmpty) ? (double.parse(rideList['price'].toString()) - 10).toStringAsFixed(2) : (double.parse(updateAmount.text.toString()) - 10).toStringAsFixed(2);
                                  });
                                }
                              },
                              child: Container(
                                width: media.width * 0.2,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: (yourAmount.text.isNotEmpty &&
                                            (etaDetails[choosenVehicle]['bidding_low_percentage'] == 0 ||
                                                (double.parse(yourAmount.text.toString()) -
                                                        ((userDetails['bidding_amount_increase_or_decrease']
                                                                .toString()
                                                                .contains('.'))
                                                            ? double.parse(
                                                                userDetails['bidding_amount_increase_or_decrease']
                                                                    .toString())
                                                            : int.parse(userDetails['bidding_amount_increase_or_decrease']
                                                                .toString()))) >=
                                                    (double.parse(etaDetails[choosenVehicle]['total'].toString()) -
                                                        ((double.parse(etaDetails[choosenVehicle]['bidding_low_percentage'].toString()) /
                                                                100) *
                                                            double.parse(etaDetails[choosenVehicle]['total'].toString())))))
                                        // double.parse(updateAmount.text.toString()) > double.parse(rideList['price'].toString()))
                                        ? (isDarkTheme)
                                            ? Colors.white
                                            : Colors.black
                                        : borderLines,
                                    borderRadius: BorderRadius.circular(media.width * 0.04)),
                                padding: EdgeInsets.all(media.width * 0.025),
                                child: Text(
                                  // '-10',
                                  (userDetails[
                                              'bidding_amount_increase_or_decrease']
                                          .toString()
                                          .contains('.'))
                                      ? '-${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}'
                                      : '-${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                  style: GoogleFonts.notoSans(
                                      fontSize: media.width * fourteen,
                                      fontWeight: FontWeight.w600,
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
                                keyboardType: TextInputType.number,
                                controller: yourAmount,
                                decoration: InputDecoration(
                                  hintText: etaDetails[choosenVehicle]['price']
                                      .toString(),
                                  hintStyle: GoogleFonts.notoSans(
                                      fontSize: media.width * sixteen,
                                      color: textColor),
                                  border: UnderlineInputBorder(
                                      borderSide: BorderSide(color: hintColor)),
                                ),
                                style: GoogleFonts.notoSans(
                                  color: textColor,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (etaDetails[choosenVehicle]
                                              ['bidding_high_percentage'] ==
                                          0 ||
                                      (double.parse(yourAmount.text.toString()) +
                                              ((userDetails['bidding_amount_increase_or_decrease']
                                                      .toString()
                                                      .contains('.'))
                                                  ? double.parse(
                                                      userDetails['bidding_amount_increase_or_decrease']
                                                          .toString())
                                                  : int.parse(
                                                      userDetails['bidding_amount_increase_or_decrease']
                                                          .toString()))) <=
                                          (double.parse(etaDetails[choosenVehicle]['total'].toString()) +
                                              ((double.parse(etaDetails[choosenVehicle]['bidding_high_percentage'].toString()) / 100) *
                                                  double.parse(
                                                      etaDetails[choosenVehicle]['total'].toString())))) {
                                    yourAmount.text = (yourAmount.text.isEmpty)
                                        ? (etaDetails[choosenVehicle]['price']
                                                .toString()
                                                .contains('.'))
                                            ? (double.parse(etaDetails[choosenVehicle]['price'].toString()) +
                                                    ((userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()
                                                            .contains('.'))
                                                        ? double.parse(
                                                            userDetails['bidding_amount_increase_or_decrease']
                                                                .toString())
                                                        : int.parse(userDetails['bidding_amount_increase_or_decrease']
                                                            .toString())))
                                                .toStringAsFixed(2)
                                            : (int.parse(etaDetails[choosenVehicle]['price'].toString()) +
                                                    ((userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()
                                                            .contains('.'))
                                                        ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())
                                                        : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())))
                                                .toString()
                                        : (yourAmount.text.toString().contains('.'))
                                            ? (double.parse(yourAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toStringAsFixed(2)
                                            : (int.parse(yourAmount.text.toString()) + ((userDetails['bidding_amount_increase_or_decrease'].toString().contains('.')) ? double.parse(userDetails['bidding_amount_increase_or_decrease'].toString()) : int.parse(userDetails['bidding_amount_increase_or_decrease'].toString()))).toString();
                                  }
                                });
                              },
                              child: Container(
                                width: media.width * 0.2,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: (etaDetails[choosenVehicle]['bidding_high_percentage'] == 0 ||
                                            (double.parse(yourAmount.text.toString()) +
                                                    ((userDetails['bidding_amount_increase_or_decrease']
                                                            .toString()
                                                            .contains('.'))
                                                        ? double.parse(
                                                            userDetails['bidding_amount_increase_or_decrease']
                                                                .toString())
                                                        : int.parse(
                                                            userDetails['bidding_amount_increase_or_decrease']
                                                                .toString()))) <=
                                                (double.parse(etaDetails[choosenVehicle]['total'].toString()) +
                                                    ((double.parse(etaDetails[choosenVehicle]['bidding_high_percentage'].toString()) /
                                                            100) *
                                                        double.parse(etaDetails[choosenVehicle]['total'].toString()))))
                                        ? (isDarkTheme)
                                            ? Colors.white
                                            : Colors.black
                                        : borderLines,
                                    borderRadius: BorderRadius.circular(media.width * 0.04)),
                                padding: EdgeInsets.all(media.width * 0.025),
                                child: Text(
                                  // '+10',
                                  (userDetails[
                                              'bidding_amount_increase_or_decrease']
                                          .toString()
                                          .contains('.'))
                                      ? '+${double.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}'
                                      : '+${int.parse(userDetails['bidding_amount_increase_or_decrease'].toString())}',
                                  style: GoogleFonts.notoSans(
                                      fontSize: media.width * fourteen,
                                      fontWeight: FontWeight.w600,
                                      color: (isDarkTheme)
                                          ? Colors.black
                                          : Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        (fareError != '')
                            ? MyText(
                                text: fareError,
                                size: media.width * fourteen,
                                color: verifyDeclined,
                                textAlign: TextAlign.center,
                              )
                            : Container(),
                        SizedBox(
                          height: media.width * 0.02,
                        ),
                        (isLoading)
                            ? Container(
                                height: media.width * 0.12,
                                width: media.width * 0.9,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(
                                        media.width * 0.02)),
                                child: SizedBox(
                                  height: media.width * 0.06,
                                  width: media.width * 0.07,
                                  child: const CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : Button(
                                onTap: _submitRegularRequest,
                                text: languages[choosenLanguage]
                                    ['text_create_request'],
                                // color: (yourAmount.text.isNotEmpty)
                                //     ? (isDarkTheme)
                                //         ? Colors.white
                                //         : Colors.black
                                //     : Colors.grey,
                              )
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rentalOption[widget.showInfoInt]['name'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen,
                              color: textColor,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Text(
                          rentalOption[widget.showInfoInt]['description'],
                          style: GoogleFonts.notoSans(
                            fontSize: media.width * fourteen,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                        Text(
                          languages[choosenLanguage]['text_supported_vehicles'],
                          style: GoogleFonts.notoSans(
                              fontSize: media.width * sixteen,
                              color: textColor,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: media.width * 0.025,
                        ),
                        Text(
                          rentalOption[widget.showInfoInt]
                              ['supported_vehicles'],
                          style: GoogleFonts.notoSans(
                            fontSize: media.width * fourteen,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languages[choosenLanguage]
                                  ['text_estimated_amount'],
                              style: GoogleFonts.notoSans(
                                  fontSize: media.width * sixteen,
                                  color: textColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            (rentalOption[widget.showInfoInt]['has_discount'] !=
                                    true)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${rentalOption[widget.showInfoInt]['currency']} '
                                        '${rentalOption[widget.showInfoInt]['fare_amount'].toStringAsFixed(2)}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        rentalOption[widget.showInfoInt]
                                            ['currency'],
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        ' ${rentalOption[widget.showInfoInt]['fare_amount'].toStringAsFixed(2)}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.lineThrough),
                                      ),
                                      Text(
                                        ' ${rentalOption[widget.showInfoInt]['discounted_totel'].toStringAsFixed(2)}',
                                        style: GoogleFonts.notoSans(
                                            fontSize: media.width * fourteen,
                                            color: textColor,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                          ],
                        )
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}
