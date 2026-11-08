part of 'invoice.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// The large blocks of this screen, each on its own.
extension _InvoiceSections on _InvoiceState {
  Widget _invoiceOverlayA(Size media) {
    return (_choosePayment == true)
        ? Positioned(
            child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: Colors.transparent.withOpacity(0.6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: media.width * 0.8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _choosePayment = false;
                          });
                        },
                        child: Container(
                          height: media.height * 0.05,
                          width: media.height * 0.05,
                          decoration: BoxDecoration(
                            color: page,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cancel, color: buttonColor),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.025),
                Container(
                  padding: EdgeInsets.all(media.width * 0.05),
                  width: media.width * 0.8,
                  height: media.height * 0.6,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: page),
                  child: Column(
                    children: [
                      SizedBox(
                          width: media.width * 0.7,
                          child: Text(
                            languages[choosenLanguage]['text_choose_payment'],
                            style: GoogleFonts.notoSans(fontSize: media.width * eighteen, fontWeight: FontWeight.w600),
                          )),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: paymentGateways
                                .map((i, value) {
                                  return MapEntry(
                                      i,
                                      (paymentGateways[i]['enabled'] == true)
                                          ? InkWell(
                                              onTap: () async {
                                                addMoney = double.parse(userRequestData['requestBill']['data']
                                                        ['total_amount']
                                                    .toStringAsFixed(2));
                                                var val = await guardedPush(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => PaymentGatwaysPage(
                                                            from: '1', url: paymentGateways[i]['url'])));

                                                if (val != null) {
                                                  if (val) {
                                                    setState(() {
                                                      _isLoading = true;
                                                      _choosePayment = false;
                                                    });
                                                    ismulitipleride = true;
                                                    var val = await getUserDetails(id: userRequestData['id']);
                                                    if (val == 'logout') {
                                                      navigateLogout();
                                                    }
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  }
                                                }
                                              },
                                              child: Container(
                                                height: media.width * 0.15,
                                                width: media.width * 0.6,
                                                margin: EdgeInsets.only(bottom: media.width * 0.02),
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        image: NetworkImage(paymentGateways[i]['image']))),
                                              ),
                                            )
                                          : Container());
                                })
                                .values
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ))
        : Container();
  }

  Widget _invoiceOverlayB(Size media) {
    return (_choosePaymentMethod == true)
        ? Positioned(
            top: 0,
            child: Container(
                height: media.height * 1,
                width: media.width * 1,
                color: Colors.transparent.withOpacity(0.6),
                child: SizedBox(
                    height: media.height * 1,
                    width: media.width * 1,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: media.width * 0.9,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _choosePaymentMethod = false;
                                    });
                                  },
                                  child: Container(
                                    height: media.width * 0.1,
                                    width: media.width * 0.1,
                                    decoration: BoxDecoration(
                                        border: Border.all(color: borderLines.withOpacity(0.5)),
                                        shape: BoxShape.circle,
                                        color: page),
                                    child: Icon(
                                      Icons.cancel_outlined,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Container(
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                border: Border.all(color: borderLines.withOpacity(0.5)),
                                color: page,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(media.width * 0.05),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  languages[choosenLanguage]['text_paymentmethod'],
                                  style: GoogleFonts.notoSans(
                                      fontSize: media.width * twenty, fontWeight: FontWeight.w600, color: textColor),
                                ),
                                SizedBox(
                                  height: media.height * 0.015,
                                ),
                                Column(
                                  children: userRequestData['payment_type']
                                      .toString()
                                      .split(',')
                                      .toList()
                                      .asMap()
                                      .map((i, value) {
                                        return MapEntry(
                                            i,
                                            (userRequestData['payment_type'].toString().split(',').toList()[i] !=
                                                    'wallet')
                                                ? InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        payingVia = i;
                                                        myPaymentMethod = userRequestData['payment_type']
                                                            .toString()
                                                            .split(',')
                                                            .toList()[i]
                                                            .toString();
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(media.width * 0.02),
                                                      width: media.width * 0.9,
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              SizedBox(
                                                                width: media.width * 0.06,
                                                                child: (userRequestData['payment_type']
                                                                            .toString()
                                                                            .split(',')
                                                                            .toList()[i] ==
                                                                        'cash')
                                                                    ? Image.asset(
                                                                        'assets/images/cash.png',
                                                                        fit: BoxFit.contain,
                                                                      )
                                                                    : (userRequestData['payment_type']
                                                                                .toString()
                                                                                .split(',')
                                                                                .toList()[i] ==
                                                                            'wallet')
                                                                        ? Image.asset(
                                                                            'assets/images/wallet.png',
                                                                            fit: BoxFit.contain,
                                                                          )
                                                                        : (userRequestData['payment_type']
                                                                                    .toString()
                                                                                    .split(',')
                                                                                    .toList()[i] ==
                                                                                'card')
                                                                            ? Image.asset(
                                                                                'assets/images/card.png',
                                                                                fit: BoxFit.contain,
                                                                              )
                                                                            : (userRequestData['payment_type']
                                                                                        .toString()
                                                                                        .split(',')
                                                                                        .toList()[i] ==
                                                                                    'upi')
                                                                                ? Image.asset(
                                                                                    'assets/images/upi.png',
                                                                                    fit: BoxFit.contain,
                                                                                  )
                                                                                : Container(),
                                                              ),
                                                              SizedBox(
                                                                width: media.width * 0.05,
                                                              ),
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    userRequestData['payment_type']
                                                                        .toString()
                                                                        .split(',')
                                                                        .toList()[i]
                                                                        .toString(),
                                                                    style: GoogleFonts.notoSans(
                                                                        fontSize: media.width * fourteen,
                                                                        fontWeight: FontWeight.w600,
                                                                        color: textColor),
                                                                  ),
                                                                  Text(
                                                                    (userRequestData['payment_type']
                                                                                .toString()
                                                                                .split(',')
                                                                                .toList()[i] ==
                                                                            'cash')
                                                                        ? languages[choosenLanguage]['text_paycash']
                                                                        : (userRequestData['payment_type']
                                                                                    .toString()
                                                                                    .split(',')
                                                                                    .toList()[i] ==
                                                                                'wallet')
                                                                            ? languages[choosenLanguage]
                                                                                ['text_paywallet']
                                                                            : (userRequestData['payment_type']
                                                                                        .toString()
                                                                                        .split(',')
                                                                                        .toList()[i] ==
                                                                                    'card')
                                                                                ? languages[choosenLanguage]
                                                                                    ['text_paycard']
                                                                                : (userRequestData['payment_type']
                                                                                            .toString()
                                                                                            .split(',')
                                                                                            .toList()[i] ==
                                                                                        'upi')
                                                                                    ? languages[choosenLanguage]
                                                                                        ['text_payupi']
                                                                                    : '',
                                                                    style: GoogleFonts.notoSans(
                                                                        fontSize: media.width * ten, color: textColor),
                                                                  )
                                                                ],
                                                              ),
                                                              Expanded(
                                                                  child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                children: [
                                                                  Container(
                                                                    height: media.width * 0.05,
                                                                    width: media.width * 0.05,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape.circle,
                                                                        color: page,
                                                                        border:
                                                                            Border.all(color: textColor, width: 1.2)),
                                                                    alignment: Alignment.center,
                                                                    child: (myPaymentMethod ==
                                                                            userRequestData['payment_type']
                                                                                .toString()
                                                                                .split(',')
                                                                                .toList()[i]
                                                                                .toString())
                                                                        ? Container(
                                                                            height: media.width * 0.03,
                                                                            width: media.width * 0.03,
                                                                            decoration: BoxDecoration(
                                                                                color: textColor,
                                                                                shape: BoxShape.circle))
                                                                        : Container(),
                                                                  )
                                                                ],
                                                              ))
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Container());
                                      })
                                      .values
                                      .toList(),
                                ),
                                SizedBox(
                                  height: media.height * 0.02,
                                ),
                                if (_error != '')
                                  Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.only(bottom: media.height * 0.02),
                                    child: Text(
                                      _error,
                                      style: GoogleFonts.notoSans(fontSize: media.width * fourteen, color: Colors.red),
                                      maxLines: 1,
                                    ),
                                  ),
                                Button(
                                    onTap: () async {
                                      if ((myPaymentMethod == 'cash' && userRequestData['payment_opt'] != '1') ||
                                          (myPaymentMethod == 'card' && userRequestData['payment_opt'] != '0')) {
                                        if (myPaymentMethod != '') {
                                          setState(() {
                                            _isLoading = true;
                                            _error = '';
                                          });
                                          var val = await paymentMethod(myPaymentMethod);
                                          if (val == 'logout') {
                                            navigateLogout();
                                          } else if (val == 'success') {
                                            if (myPaymentMethod == 'card') {
                                              if (walletBalance.isEmpty) {
                                                var val = await getWalletHistory();
                                                if (val == 'logout') {
                                                  navigateLogout();
                                                }
                                              }
                                              setState(() {
                                                _isLoading = false;
                                                _choosePayment = true;
                                                _choosePaymentMethod = false;
                                              });
                                            } else {
                                              _choosePaymentMethod = false;
                                            }
                                          } else {
                                            _error = val.toString();
                                          }

                                          setState(() {
                                            myPaymentMethod = '';
                                            _isLoading = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          _choosePaymentMethod = false;
                                        });
                                      }
                                    },
                                    text: languages[choosenLanguage]['text_confirm']),
                              ]))
                        ]))))
        : Container();
  }
}
