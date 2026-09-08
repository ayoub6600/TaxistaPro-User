part of '../bookingwidgets.dart';

int choosenInPopUp = 0;

class ChoosePaymentMethodContainer extends StatefulWidget {
  final dynamic type;
  final dynamic onTap;
  const ChoosePaymentMethodContainer(
      {super.key, this.type, required this.onTap});

  @override
  State<ChoosePaymentMethodContainer> createState() =>
      _ChoosePaymentMethodContainerState();
}

class _ChoosePaymentMethodContainerState
    extends State<ChoosePaymentMethodContainer> {
  @override
  void initState() {
    // choosenInPopUp = 0;
    choosenInPopUp = payingVia;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      height: media.height * 0.5,
      width: media.width * 1,
      padding: EdgeInsets.all(media.width * 0.05),
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      child: Column(
        children: [
          MyText(
            text: languages[choosenLanguage]['text_choose_payment'],
            size: 16.sp,
            fontweight: FontWeight.w500,
            color: Colors.blue,
          ),
          SizedBox(
            height: 20.h,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: (choosenVehicle != null && widget.type != 1)
                  ? Column(
                      children: etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()
                          .asMap()
                          .map((i, value) {
                            return MapEntry(
                                i,
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      choosenInPopUp = i;
                                    });
                                  },
                                  child: SizedBox(
                                    height: media.height * 0.106,
                                    width: media.width * 0.9,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: (etaDetails[choosenVehicle]
                                                            ['payment_type']
                                                        .toString()
                                                        .split(',')
                                                        .toList()[i] ==
                                                    'cash')
                                                ? Image.asset(
                                                    'assets/images/cash-on-delivery.png',
                                                    width: media.width * 0.06,
                                                    height: media.width * 0.06,
                                                    fit: BoxFit.contain,
                                                  )
                                                : (etaDetails[choosenVehicle]
                                                                ['payment_type']
                                                            .toString()
                                                            .split(',')
                                                            .toList()[i] ==
                                                        'wallet')
                                                    ? Image.asset(
                                                        'assets/images/wallet (1).png',
                                                        width:
                                                            media.width * 0.1,
                                                        height:
                                                            media.width * 0.1,
                                                        fit: BoxFit.contain,
                                                      )
                                                    : Image.asset(
                                                        'assets/images/debit-card.png',
                                                        width:
                                                            media.width * 0.1,
                                                        height:
                                                            media.width * 0.1,
                                                        fit: BoxFit.contain,
                                                      )),
                                        SizedBox(
                                          width: media.width * 0.02,
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: MyText(
                                            text: _getTranslatedPaymentType(
                                                etaDetails[choosenVehicle]
                                                        ['payment_type']
                                                    .toString()
                                                    .split(',')
                                                    .toList()[i]),
                                            size: media.width * fourteen,
                                            color: (isDarkTheme == true)
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        Expanded(
                                            child: Container(
                                          height: media.width * 0.05,
                                          width: media.width * 0.05,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Container(
                                            height: media.width * 0.03,
                                            width: media.width * 0.03,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (choosenInPopUp == i)
                                                    // ? const Color(0xffFF0000)
                                                    ? theme
                                                    : page),
                                          ),
                                        ))
                                      ],
                                    ),
                                  ),
                                ));
                          })
                          .values
                          .toList(),
                    )
                  : Column(
                      children: rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()
                          .asMap()
                          .map((i, value) {
                            return MapEntry(
                                i,
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      choosenInPopUp = i;
                                    });
                                  },
                                  child: SizedBox(
                                    height: media.width * 0.106,
                                    width: media.width * 0.9,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: (rentalOption[choosenVehicle]
                                                          ['payment_type']
                                                      .toString()
                                                      .split(',')
                                                      .toList()[i] ==
                                                  'cash')
                                              ? Image.asset(
                                                  'assets/images/cash.png',
                                                  width: media.width * 0.05,
                                                  height: media.width * 0.05,
                                                  fit: BoxFit.contain,
                                                )
                                              : (rentalOption[choosenVehicle]
                                                              ['payment_type']
                                                          .toString()
                                                          .split(',')
                                                          .toList()[i] ==
                                                      'wallet')
                                                  ? Image.asset(
                                                      'assets/images/wallet.png',
                                                      width: media.width * 0.1,
                                                      height: media.width * 0.1,
                                                      fit: BoxFit.contain,
                                                    )
                                                  : (rentalOption[choosenVehicle]
                                                                  [
                                                                  'payment_type']
                                                              .toString()
                                                              .split(',')
                                                              .toList()[i] ==
                                                          'card')
                                                      ? Image.asset(
                                                          'assets/images/card.png',
                                                          width:
                                                              media.width * 0.1,
                                                          height:
                                                              media.width * 0.1,
                                                          fit: BoxFit.contain,
                                                        )
                                                      : (rentalOption[choosenVehicle]
                                                                      [
                                                                      'payment_type']
                                                                  .toString()
                                                                  .split(',')
                                                                  .toList()[i] ==
                                                              'upi')
                                                          ? Image.asset(
                                                              'assets/images/upi.png',
                                                              width:
                                                                  media.width *
                                                                      0.1,
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              fit: BoxFit
                                                                  .contain,
                                                            )
                                                          : Container(),
                                        ),
                                        SizedBox(
                                          width: media.width * 0.02,
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: MyText(
                                            text: rentalOption[choosenVehicle]
                                                    ['payment_type']
                                                .toString()
                                                .split(',')
                                                .toList()[i],
                                            size: media.width * fourteen,
                                            color:
                                                // (choosenInPopUp == i)
                                                //     ? const Color(0xffFF0000)
                                                //     :
                                                (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        Expanded(
                                            child: Container(
                                          height: media.width * 0.05,
                                          width: media.width * 0.05,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                color: (isDarkTheme == true)
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              shape: BoxShape.circle),
                                          child: Container(
                                            height: media.width * 0.03,
                                            width: media.width * 0.03,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (choosenInPopUp == i)
                                                    // ? const Color(0xffFF0000)
                                                    ? theme
                                                    : page),
                                          ),
                                        ))
                                      ],
                                    ),
                                  ),
                                ));
                          })
                          .values
                          .toList(),
                    ),
            ),
          ),
          SizedBox(
            height: 20.h,
          ),
          Button(
              onTap: widget.onTap,
              text: languages[choosenLanguage]['text_confirm'])
        ],
      ),
    );
  }

  String _getTranslatedPaymentType(String paymentType) {
    switch (paymentType) {
      case 'cash':
        return languages[choosenLanguage]['text_cash'];
      case 'wallet':
        return languages[choosenLanguage]['text_wallet'];
      case 'card':
        return languages[choosenLanguage]['text_card'];
      case 'upi':
        return languages[choosenLanguage]['text_upi'];
      default:
        return paymentType; // Fallback to original text if no translation found
    }
  }
}

bool confirmRideLater = false;
