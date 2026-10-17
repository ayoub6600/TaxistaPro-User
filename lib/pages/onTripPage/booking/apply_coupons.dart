part of '../bookingwidgets.dart';

class ApplyCouponsContainer extends StatefulWidget {
  final dynamic type;
  const ApplyCouponsContainer({super.key, this.type});

  @override
  State<ApplyCouponsContainer> createState() => _ApplyCouponsContainerState();
}

class _ApplyCouponsContainerState extends State<ApplyCouponsContainer> {
  double? _appliedCouponSavings() {
    if (promoStatus != 1 || choosenVehicle is! int) return null;
    final services = widget.type == 1 ? rentalOption : etaDetails;
    final index = choosenVehicle as int;
    if (index < 0 || index >= services.length || services[index] is! Map) {
      return null;
    }
    final service = services[index] as Map;
    final direct =
        double.tryParse(service['discount_amount']?.toString() ?? '');
    if (direct != null && direct > 0) return direct;
    final total = double.tryParse(service['total']?.toString() ?? '');
    final discounted = double.tryParse(
      service['discounted_totel']?.toString() ??
          service['scheduled_discounted_total']?.toString() ??
          '',
    );
    if (total != null && discounted != null && total > discounted) {
      return total - discounted;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Container(
      padding: MediaQuery.of(context).viewInsets,
      decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(media.width * 0.05),
              topRight: Radius.circular(media.width * 0.05))),
      // padding:
      //     EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Container(
        padding: EdgeInsets.all(media.width * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MyText(
                textAlign: TextAlign.center,
                text: '${languages[choosenLanguage]['text_apply']} '
                    '${languages[choosenLanguage]['text_coupons']}',
                size: media.width * sixteen,
                fontweight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              height: media.width * 0.06,
            ),
            Container(
              width: media.width * 0.8,
              height: 50.sp,
              padding: EdgeInsets.fromLTRB(media.width * 0.025,
                  media.width * 0.01, media.width * 0.025, media.width * 0.01),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(
                    color: textColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(media.width * 0.02)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      textAlign: TextAlign.right,
                      controller: promoKey,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: languages[choosenLanguage]['text_enterpromo'],
                        hintStyle: GoogleFonts.cairo(
                            color: hintColor, fontSize: media.width * fourteen),
                      ),
                      style: GoogleFonts.notoSans(color: textColor),
                      onChanged: (val) {
                        setState(() {
                          promoCode = val;
                          couponerror = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            if (promoStatus == 1) ...[
              SizedBox(height: media.width * 0.025),
              Builder(builder: (context) {
                final savings = _appliedCouponSavings();
                final displaySavings = savings == null
                    ? null
                    : savings == savings.roundToDouble()
                        ? savings.toStringAsFixed(0)
                        : savings.toStringAsFixed(2);
                final message = savings == null
                    ? languages[choosenLanguage]['text_promoaccepted']
                    : choosenLanguage == 'ar'
                        ? 'تم الخصم، وفّرت $displaySavings دينار في هذه الرحلة'
                        : 'Coupon applied — you saved ${userDetails['currency_code'] ?? 'LYD'} $displaySavings on this ride';
                return MyText(
                  text: message,
                  size: media.width * twelve,
                  color: online,
                );
              }),
            ],
            if (promoStatus != null && promoStatus == 2 && couponerror == true)
              Container(
                width: media.width * 0.9,
                padding: EdgeInsets.only(top: media.width * 0.025),
                child: Center(
                  child: MyText(
                    text: languages[choosenLanguage]['text_promorejected'],
                    size: 14.sp,
                    color: Colors.red,
                  ),
                ),
              ),
            SizedBox(
              height: media.width * 0.04,
            ),
            SizedBox(
              // width: media.width * 0.8,
              // height: media.width * 0.1,
              child: Button(
                text: (promoStatus == 1)
                    ? languages[choosenLanguage]['text_remove']
                    : languages[choosenLanguage]['text_apply'],
                fontweight: FontWeight.w500,
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    isLoading = true;
                  });

                  // promoStatus = null;)
                  if (promoStatus != 1 && promoCode != '') {
                    setState(() {
                      promoStatus = null;
                    });
                    if (widget.type != 1 && promoCode != '') {
                      await etaRequestWithPromo();
                    } else if (widget.type == 1 && promoCode != '') {
                      await rentalRequestWithPromo();
                    }
                  } else {
                    if (promoKey.text != '') {
                      if (promoStatus != 2) {
                        if (widget.type != 1) {
                          await etaRequest();
                        } else if (widget.type == 1) {
                          await rentalEta();
                        }
                        promoKey.text = '';
                        promoCode = '';
                      }
                      if (promoStatus == 1) {
                        // promoKey.text = '';
                        promoStatus = null;
                        // if (widget.type != 1) {
                        //   await etaRequest();
                        // } else if (widget.type == 1) {
                        //   await rentalEta();
                        // }
                      }
                    }
                  }
                  setState(() {
                    isLoading = false;
                  });
                },
                color: (promoKey.text == '') ? Colors.grey : Colors.blue,
                textcolor: (!isDarkTheme) ? Colors.white : Colors.black,
                borderRadius: 12.0,
              ),
            ),
            (choosenVehicle != null)
                ? SizedBox(
                    height: media.width * 0.025,
                  )
                : Container(),
            SizedBox(
              height: 8.h,
            ),
            InkWell(
                onTap: () {
                  if (widget.type == 1
                      ? (rentalOption[choosenVehicle]['has_discount'] == true)
                      : etaDetails[choosenVehicle]['has_discount'] == true) {
                    setState(() {
                      promoStatus = 1;
                      addCoupon = false;
                      // promoKey.clear();
                    });
                  } else {
                    setState(() {
                      promoStatus = null;
                      addCoupon = false;
                      promoKey.clear();
                    });
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  height: 40.h,
                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: verifyDeclined,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  // width: media.width * 0.8,
                  child: MyText(
                    text: languages[choosenLanguage]['text_cancel'],
                    size: media.width * sixteen,
                    color: Colors.white,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
