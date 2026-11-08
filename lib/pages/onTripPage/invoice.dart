import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/pages/NavigatorPages/paymentgateways.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../growth/gift_widgets.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/walletpage.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import 'booking_confirmation.dart';
import 'map_page.dart';
import 'review_page.dart';
import '../../community/ride_wrap_up.dart';
import '../../navigation/guarded_navigation.dart';
part 'invoice_sections.dart';

class Invoice extends StatefulWidget {
  const Invoice({super.key});

  @override
  State<Invoice> createState() => _InvoiceState();
}

class _InvoiceState extends State<Invoice> {
  bool _choosePayment = false;
  bool _isLoading = false;
  bool _choosePaymentMethod = false;
  String _error = '';
  String myPaymentMethod = '';

  /// «دفعت كمان X رصيد سابق»: the rider's earlier negative balance settled in cash on this ride
  /// (the server's bill line prior_balance_collected); nothing when there was none
  Widget _priorBalanceNote(Size media) {
    final bill = userRequestData['requestBill']?['data'];
    final prior = double.tryParse('${bill?['prior_balance_collected'] ?? 0}') ?? 0;
    if (prior <= 0) return const SizedBox.shrink();
    final rtl = languageDirection == 'rtl';
    final cur = rtl ? 'دينار' : (userRequestData['requested_currency_symbol']?.toString() ?? 'LYD');
    return Container(
      width: media.width * 0.9,
      margin: EdgeInsets.only(bottom: media.width * 0.04),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffFFF4DB), borderRadius: BorderRadius.circular(14)),
      child: Text(
        rtl
            ? 'مع الأجرة دفعت ${prior.toStringAsFixed(2)} $cur رصيد سابق كان عليك، ومحفظتك رجعت بنفس المبلغ.'
            : 'With the fare you paid ${prior.toStringAsFixed(2)} $cur of your earlier balance; your wallet went up by the same.',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSans(
            fontSize: media.width * fourteen, color: const Color(0xff8A5A00), fontWeight: FontWeight.w600, height: 1.5),
      ),
    );
  }

  Widget _bidRidePaymentSummary(Size media) {
    final bill = userRequestData['requestBill']?['data'];
    final estimated = userRequestData['wallet_split_is_estimate'] == true;
    final currency =
        choosenLanguage == 'ar' ? 'دينار' : (userRequestData['requested_currency_symbol']?.toString() ?? 'LYD');
    final gross = double.tryParse(((estimated ? null : bill?['total_amount']) ??
                    userRequestData['accepted_ride_fare'] ??
                    bill?['total_amount'])
                ?.toString() ??
            '') ??
        0;
    final wallet = double.tryParse(((estimated ? null : bill?['wallet_paid_amount']) ??
                    userRequestData['wallet_paid_amount'] ??
                    bill?['wallet_paid_amount'])
                ?.toString() ??
            '') ??
        0;
    final cash = double.tryParse(((estimated ? null : bill?['cash_due_amount']) ??
                    userRequestData['cash_due_amount'] ??
                    bill?['cash_due_amount'])
                ?.toString() ??
            '') ??
        0;
    final split = userRequestData['payment_opt'].toString() == '3';

    if (!split) {
      final payment = userRequestData['payment_opt'].toString() == '1'
          ? languages[choosenLanguage]['text_cash']
          : userRequestData['payment_opt'].toString() == '2'
              ? languages[choosenLanguage]['text_wallet']
              : languages[choosenLanguage]['text_card'];
      return Column(children: [
        Text(payment,
            style: GoogleFonts.notoSans(
                fontSize: media.width * twentyeight, color: buttonColor, fontWeight: FontWeight.bold)),
        SizedBox(height: media.width * 0.05),
        Text('${gross.toStringAsFixed(2)} $currency',
            style:
                GoogleFonts.notoSans(fontSize: media.width * twentysix, color: textColor, fontWeight: FontWeight.bold)),
      ]);
    }

    final walletLabel = userRequestData['wallet_split_is_estimate'] == true
        ? (choosenLanguage == 'ar' ? 'سيُخصم من محفظتك' : 'From your wallet at trip completion')
        : (choosenLanguage == 'ar' ? 'دُفع من محفظتك' : 'Paid from your wallet');
    return Column(children: [
      Text(
        choosenLanguage == 'ar' ? 'ادفع للسائق نقدًا' : 'Pay the driver cash',
        style:
            GoogleFonts.notoSans(fontSize: media.width * twentyeight, color: buttonColor, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: media.width * 0.025),
      Text('$currency ${cash.toStringAsFixed(2)}',
          style:
              GoogleFonts.notoSans(fontSize: media.width * twentysix, color: textColor, fontWeight: FontWeight.bold)),
      SizedBox(height: media.width * 0.025),
      Text('$walletLabel: $currency ${wallet.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style:
              GoogleFonts.notoSans(fontSize: media.width * fourteen, color: buttonColor, fontWeight: FontWeight.w600)),
      SizedBox(height: media.width * 0.015),
      Text(
          choosenLanguage == 'ar'
              ? 'إجمالي الأجرة: $currency ${gross.toStringAsFixed(2)}'
              : 'Total fare: $currency ${gross.toStringAsFixed(2)}',
          style: GoogleFonts.notoSans(fontSize: media.width * twelve, color: textColor)),
    ]);
  }

  Widget billAdjustmentRow(Size media, String field) {
    final bill = userRequestData['requestBill']?['data'];
    final value = double.tryParse(bill?[field]?.toString() ?? '') ?? 0;
    if (value == 0) return const SizedBox.shrink();
    final isArabic = choosenLanguage == 'ar';
    final label = field == 'fare_floor_adjustment'
        ? (isArabic ? 'حماية التسعيرة الأصلية' : 'Upfront fare protection')
        : value < 0
            ? (isArabic ? 'خصم السعر المتفق عليه' : 'Agreed fare discount')
            : (isArabic ? 'تعديل السعر المتفق عليه' : 'Agreed fare adjustment');
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        MyText(text: label, size: media.width * twelve, color: value < 0 ? Colors.red : null),
        MyText(
            text: '${bill['requested_currency_symbol']} ${value.toStringAsFixed(2)}',
            size: media.width * twelve,
            color: value < 0 ? Colors.red : null),
      ]),
      Container(
          margin: EdgeInsets.symmetric(vertical: media.width * 0.03), height: 1.5, color: const Color(0xffE0E0E0)),
    ]);
  }

  bool isShow = false;
  @override
  void initState() {
    myMarkers.clear();
    promoCode = '';
    payingVia = 0;
    timing = null;
    promoStatus = null;
    super.initState();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Login()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              final distanceKm = double.tryParse(userRequestData['total_distance']?.toString() ?? '');
              final distanceLabel = distanceKm == null || distanceKm <= 0
                  ? '— ${userRequestData['unit'] ?? ''}'.trim()
                  : '${distanceKm.toStringAsFixed(2)} ${userRequestData['unit'] ?? ''}'.trim();
              return Stack(
                children: [
                  if (userRequestData.isNotEmpty)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                          media.width * 0.05,
                          MediaQuery.of(context).padding.top + media.width * 0.05,
                          media.width * 0.05,
                          media.width * 0.05),
                      height: media.height * 1,
                      width: media.width * 1,
                      color: page,
                      //invoice details
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                          onTap: () async {
                                            if (_isLoading) return;
                                            setState(() => _isLoading = true);
                                            await refreshUserRequestState();
                                            if (!mounted) return;
                                            dropStopList.clear();
                                            addressList.clear();
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(builder: (context) => const Maps()),
                                                (route) => false);
                                          },
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            size: media.width * 0.07,
                                          )),
                                      MyText(
                                        text: languages[choosenLanguage]['text_tripsummary'],
                                        size: media.width * sixteen,
                                        fontweight: FontWeight.bold,
                                      ),
                                      SizedBox(width: media.width * 0.05)
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.04,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: media.width * 0.13,
                                        width: media.width * 0.13,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    userRequestData['driverDetail']['data']['profile_picture']),
                                                fit: BoxFit.cover)),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.05,
                                      ),
                                      MyText(
                                        text: userRequestData['driverDetail']['data']['name'],
                                        size: media.width * eighteen,
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.05,
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.04),
                                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1)),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                MyText(
                                                  text: languages[choosenLanguage]['text_reference'],
                                                  size: media.width * fourteen,
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                MyText(
                                                  text: userRequestData['request_number'],
                                                  size: media.width * twelve,
                                                  fontweight: FontWeight.w700,
                                                )
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                MyText(
                                                  text: languages[choosenLanguage]['text_rideType'],
                                                  size: media.width * fourteen,
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                MyText(
                                                  text: (userRequestData['is_rental'] == false)
                                                      ? languages[choosenLanguage]['text_regular']
                                                      : languages[choosenLanguage]['text_rental'],
                                                  size: media.width * twelve,
                                                  fontweight: FontWeight.w700,
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: media.height * 0.02,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                MyText(
                                                  text: languages[choosenLanguage]['text_distance'],
                                                  size: media.width * fourteen,
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                MyText(
                                                  text: distanceLabel,
                                                  size: media.width * twelve,
                                                  fontweight: FontWeight.w700,
                                                )
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                MyText(
                                                  text: languages[choosenLanguage]['text_duration'],
                                                  size: media.width * fourteen,
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                MyText(
                                                  text:
                                                      '${userRequestData['total_time']} ${languages[choosenLanguage]['text_mins']}',
                                                  size: media.width * twelve,
                                                  fontweight: FontWeight.w700,
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.height * 0.03,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: media.width * 0.05,
                                        width: media.width * 0.05,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                                        child: Container(
                                          height: media.width * 0.025,
                                          width: media.width * 0.025,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.06,
                                      ),
                                      Expanded(
                                        child: MyText(
                                          text: userRequestData['pick_address'],
                                          size: media.width * twelve,
                                          // maxLines: 1,
                                        ),
                                      ),
                                    ],
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
                                                    (i < tripStops.length - 1)
                                                        ? Container(
                                                            padding: EdgeInsets.only(
                                                                top: media.width * 0.02, bottom: media.width * 0.02),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: [
                                                                Container(
                                                                  height: media.width * 0.06,
                                                                  width: media.width * 0.06,
                                                                  alignment: Alignment.center,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape.circle,
                                                                      color: Colors.red.withOpacity(0.1)),
                                                                  child: MyText(
                                                                    text: (i + 1).toString(),
                                                                    // maxLines: 1,
                                                                    color: const Color(0xFFFF0000),
                                                                    fontweight: FontWeight.w600,
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: media.width * 0.05,
                                                                ),
                                                                Expanded(
                                                                  child: MyText(
                                                                    text: tripStops[i]['address'],
                                                                    // maxLines: 1,
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : Container());
                                              })
                                              .values
                                              .toList(),
                                        )
                                      : Container(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: media.width * 0.05,
                                        width: media.width * 0.05,
                                        alignment: Alignment.center,
                                        decoration:
                                            BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                        child: Icon(
                                          Icons.location_on_outlined,
                                          size: media.width * 0.03,
                                          color: const Color(0xFFFF0000),
                                        ),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.05,
                                      ),
                                      Expanded(
                                        child: MyText(
                                          text: userRequestData['drop_address'],
                                          size: media.width * twelve,
                                          // maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.03,
                                  ),
                                  _priorBalanceNote(media),
                                  userRequestData['is_bid_ride'] == 1
                                      ? _bidRidePaymentSummary(media)
                                      : (userRequestData['requestBill'] != null)
                                          ? Column(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      isShow = !isShow;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(20.r),
                                                      color: Colors.blue,
                                                    ),
                                                    child: MyText(
                                                      text: languages[choosenLanguage]['text_tripfare'],
                                                      size: media.width * fourteen,
                                                      fontweight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                isShow == true
                                                    ? Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          SizedBox(
                                                            height: media.height * 0.03,
                                                          ),
                                                          (userRequestData['is_rental'] == true)
                                                              ? Container(
                                                                  padding: EdgeInsets.only(bottom: media.width * 0.05),
                                                                  child: Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        languages[choosenLanguage]['text_ride_type'],
                                                                        style: GoogleFonts.notoSans(
                                                                            fontSize: media.width * fourteen,
                                                                            color: textColor),
                                                                      ),
                                                                      Text(
                                                                        userRequestData['rental_package_name'],
                                                                        style: GoogleFonts.notoSans(
                                                                            fontSize: media.width * fourteen,
                                                                            color: textColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                              : Container(),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]['text_baseprice'],
                                                                    size: media.width * twelve,
                                                                  ),
                                                                  MyText(
                                                                    text: (userRequestData.isNotEmpty &&
                                                                            userRequestData['requestBill'] != null)
                                                                        ? userRequestData['requestBill']['data']
                                                                                ['requested_currency_symbol'] +
                                                                            ' ' +
                                                                            userRequestData['requestBill']['data']
                                                                                    ['base_price']
                                                                                .toString()
                                                                        : '',
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media.width * 0.03,
                                                                    bottom: media.width * 0.03),
                                                                height: 1.5,
                                                                color: const Color(0xffE0E0E0),
                                                              ),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]['text_distprice'],
                                                                    size: media.width * twelve,
                                                                  ),
                                                                  MyText(
                                                                    text: (userRequestData.isNotEmpty &&
                                                                            userRequestData['requestBill'] != null)
                                                                        ? userRequestData['requestBill']['data']
                                                                                ['requested_currency_symbol'] +
                                                                            ' ' +
                                                                            userRequestData['requestBill']['data']
                                                                                    ['distance_price']
                                                                                .toString()
                                                                        : '',
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media.width * 0.03,
                                                                    bottom: media.width * 0.03),
                                                                height: 1.5,
                                                                color: const Color(0xffE0E0E0),
                                                              ),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]['text_timeprice'],
                                                                    size: media.width * twelve,
                                                                  ),
                                                                  MyText(
                                                                    text: (userRequestData.isNotEmpty &&
                                                                            userRequestData['requestBill'] != null)
                                                                        ? userRequestData['requestBill']['data']
                                                                                ['requested_currency_symbol'] +
                                                                            ' ' +
                                                                            userRequestData['requestBill']['data']
                                                                                    ['time_price']
                                                                                .toString()
                                                                        : '',
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media.width * 0.03,
                                                                    bottom: media.width * 0.03),
                                                                height: 1.5,
                                                                color: const Color(0xffE0E0E0),
                                                              ),
                                                            ],
                                                          ),
                                                          billAdjustmentRow(media, 'negotiated_fare_adjustment'),
                                                          billAdjustmentRow(media, 'fare_floor_adjustment'),
                                                          (userRequestData['requestBill'] != null &&
                                                                  userRequestData['requestBill']['data']
                                                                          ['cancellation_fee'] !=
                                                                      0)
                                                              ? Column(
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        MyText(
                                                                          text: languages[choosenLanguage]
                                                                              ['text_cancelfee'],
                                                                          size: media.width * twelve,
                                                                        ),
                                                                        MyText(
                                                                          text: (userRequestData.isNotEmpty &&
                                                                                  userRequestData['requestBill'] !=
                                                                                      null)
                                                                              ? userRequestData['requestBill']['data']
                                                                                      ['requested_currency_symbol'] +
                                                                                  ' ' +
                                                                                  userRequestData['requestBill']['data']
                                                                                          ['cancellation_fee']
                                                                                      .toString()
                                                                              : '',
                                                                          size: media.width * twelve,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      margin: EdgeInsets.only(
                                                                          top: media.width * 0.03,
                                                                          bottom: media.width * 0.03),
                                                                      height: 1.5,
                                                                      color: const Color(0xffE0E0E0),
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                          (userRequestData['requestBill'] != null &&
                                                                  userRequestData['requestBill']['data']
                                                                          ['airport_surge_fee'] !=
                                                                      0)
                                                              ? Column(
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        MyText(
                                                                          text: languages[choosenLanguage]
                                                                              ['text_surge_fee'],
                                                                          size: media.width * twelve,
                                                                        ),
                                                                        MyText(
                                                                          text: (userRequestData.isNotEmpty &&
                                                                                  userRequestData['requestBill'] !=
                                                                                      null)
                                                                              ? userRequestData['requestBill']['data']
                                                                                      ['requested_currency_symbol'] +
                                                                                  ' ' +
                                                                                  userRequestData['requestBill']['data']
                                                                                          ['airport_surge_fee']
                                                                                      .toString()
                                                                              : '',
                                                                          size: media.width * twelve,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      margin: EdgeInsets.only(
                                                                          top: media.width * 0.03,
                                                                          bottom: media.width * 0.03),
                                                                      height: 1.5,
                                                                      color: const Color(0xffE0E0E0),
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]
                                                                            ['text_waiting_price'] +
                                                                        ' (' +
                                                                        userRequestData['requestBill']['data']
                                                                            ['requested_currency_symbol'] +
                                                                        ' ' +
                                                                        userRequestData['requestBill']['data']
                                                                                ['waiting_charge_per_min']
                                                                            .toString() +
                                                                        ' x ' +
                                                                        userRequestData['requestBill']['data']
                                                                                ['calculated_waiting_time']
                                                                            .toString() +
                                                                        ' ' +
                                                                        languages[choosenLanguage]['text_mins'] +
                                                                        ')',
                                                                    size: media.width * twelve,
                                                                  ),
                                                                  MyText(
                                                                    text: userRequestData['requestBill']['data']
                                                                            ['requested_currency_symbol'] +
                                                                        ' ' +
                                                                        userRequestData['requestBill']['data']
                                                                                ['waiting_charge']
                                                                            .toString(),
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media.width * 0.03,
                                                                    bottom: media.width * 0.03),
                                                                height: 1.5,
                                                                color: const Color(0xffE0E0E0),
                                                              ),
                                                            ],
                                                          ),
                                                          (userRequestData['requestBill'] != null &&
                                                                  userRequestData['requestBill']['data']
                                                                          ['admin_commision'] !=
                                                                      0)
                                                              ? Column(
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        MyText(
                                                                          text: languages[choosenLanguage]
                                                                              ['text_convfee'],
                                                                          size: media.width * twelve,
                                                                        ),
                                                                        MyText(
                                                                          text: userRequestData['requestBill']['data']
                                                                                  ['requested_currency_symbol'] +
                                                                              ' ' +
                                                                              userRequestData['requestBill']['data']
                                                                                      ['admin_commision']
                                                                                  .toString(),
                                                                          size: media.width * twelve,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      margin: EdgeInsets.only(
                                                                          top: media.width * 0.03,
                                                                          bottom: media.width * 0.03),
                                                                      height: 1.5,
                                                                      color: const Color(0xffE0E0E0),
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                          (userRequestData['requestBill'] != null &&
                                                                  userRequestData['requestBill']['data']
                                                                          ['promo_discount'] !=
                                                                      null)
                                                              ? Column(
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      children: [
                                                                        MyText(
                                                                          text: languages[choosenLanguage]
                                                                              ['text_discount'],
                                                                          size: media.width * twelve,
                                                                          color: Colors.red,
                                                                        ),
                                                                        MyText(
                                                                          text: userRequestData['requestBill']['data']
                                                                                  ['requested_currency_symbol'] +
                                                                              ' ' +
                                                                              userRequestData['requestBill']['data']
                                                                                      ['promo_discount']
                                                                                  .toString(),
                                                                          size: media.width * twelve,
                                                                          color: Colors.red,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    // a Taxista gift is part of the discount above: named here
                                                                    if (userRequestData['id'] != null)
                                                                      RideGiftLine(
                                                                          requestId: userRequestData['id'].toString(),
                                                                          style: TextStyle(
                                                                              fontSize: media.width * twelve)),
                                                                    Container(
                                                                      margin: EdgeInsets.only(
                                                                          top: media.width * 0.03,
                                                                          bottom: media.width * 0.03),
                                                                      height: 1.5,
                                                                      color: const Color(0xffE0E0E0),
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]['text_taxes'],
                                                                    size: media.width * twelve,
                                                                  ),
                                                                  MyText(
                                                                    text: userRequestData['requestBill']['data']
                                                                            ['requested_currency_symbol'] +
                                                                        ' ' +
                                                                        userRequestData['requestBill']['data']
                                                                                ['service_tax']
                                                                            .toString(),
                                                                    size: media.width * twelve,
                                                                  ),
                                                                ],
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media.width * 0.03,
                                                                    bottom: media.width * 0.03),
                                                                height: 1.5,
                                                                color: const Color(0xffE0E0E0),
                                                              ),
                                                            ],
                                                          ),
                                                          Column(
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  MyText(
                                                                    text: languages[choosenLanguage]['text_totalfare'],
                                                                    size: 16.sp,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 10.w,
                                                                  ),
                                                                  MyText(
                                                                    text: userRequestData['requestBill']['data']
                                                                            ['requested_currency_symbol'] +
                                                                        ' ' +
                                                                        userRequestData['requestBill']['data']
                                                                                ['total_amount']
                                                                            .toString(),
                                                                    size: 16.sp,
                                                                    fontweight: FontWeight.w700,
                                                                    color: Colors.blue,
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 20.h,
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      )
                                                    : Padding(
                                                        padding: EdgeInsets.symmetric(
                                                          vertical: 20.h,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            //تم الدفع عبر

                                                            Text(
                                                              (userRequestData['payment_opt'] == '2' ||
                                                                      userRequestData['payment_opt'] == '3')
                                                                  ? languages[choosenLanguage]['text_paid_via']
                                                                  : "ادفع للسائق",
                                                              style: GoogleFonts.cairo(
                                                                  fontSize: media.width * sixteen,
                                                                  color: textColor,
                                                                  fontWeight: FontWeight.w600),
                                                            ),
                                                            SizedBox(
                                                              width: 5.w,
                                                            ),
                                                            Text(
                                                              (userRequestData['payment_opt'] == '1' ||
                                                                      userRequestData['payment_opt'] == '3')
                                                                  ? languages[choosenLanguage]['text_cash']
                                                                  : (userRequestData['payment_opt'] == '2')
                                                                      ? languages[choosenLanguage]['text_wallet']
                                                                      : languages[choosenLanguage]['text_card'],
                                                              style: GoogleFonts.cairo(
                                                                  fontSize: media.width * sixteen,
                                                                  color: Colors.blue,
                                                                  fontWeight: FontWeight.bold),
                                                            ),
                                                            SizedBox(
                                                              width: 5.w,
                                                            ),
                                                            MyText(
                                                              text:
                                                                  ' ${userRequestData['requestBill']['data']['requested_currency_symbol']}',
                                                              size: media.width * fourteen,
                                                              color: Colors.blue,
                                                            ),
                                                            MyText(
                                                              text: userRequestData['payment_opt'] == '3'
                                                                  ? ' ${userRequestData['requestBill']['data']['cash_due_amount'] ?? 0}'
                                                                  : ' ${userRequestData['requestBill']['data']['total_amount']}',
                                                              size: media.width * twenty,
                                                              fontweight: FontWeight.bold,
                                                              color: Colors.blue,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                if (userRequestData['payment_opt'] == '3')
                                                  Padding(
                                                    padding: EdgeInsets.only(bottom: 14.h),
                                                    child: Text(
                                                      '${languages[choosenLanguage]['text_wallet_paid']}: ${userRequestData['requestBill']['data']['requested_currency_symbol']} ${userRequestData['requestBill']['data']['wallet_paid_amount'] ?? 0}',
                                                      style: GoogleFonts.cairo(
                                                        fontSize: media.width * twelve,
                                                        color: textColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : Container()
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Button(
                                      onTap: () async {
                                        if (userRequestData['is_paid'] == 0 &&
                                            userRequestData['payment_opt'] != '2' &&
                                            userRequestData['payment_opt'] != '3') {
                                          setState(() {
                                            myPaymentMethod = userRequestData['payment_opt'] == '0'
                                                ? 'card'
                                                : userRequestData['payment_opt'] == '1'
                                                    ? 'cash'
                                                    : '';
                                            _choosePaymentMethod = true;
                                          });
                                        } else {
                                          // the rating card rises over the invoice
                                          guardedPush(context, RideWrapUp.route(const Review()));
                                        }
                                      },
                                      text: (userRequestData['is_paid'] == 0 &&
                                              userRequestData['payment_opt'] != '2' &&
                                              userRequestData['payment_opt'] != '3')
                                          ? languages[choosenLanguage]['text_choose_payment']
                                          : languages[choosenLanguage]['text_confirm'])),
                            ],
                          ),
                          if (userRequestData['is_paid'] == 0 && userRequestData['payment_opt'] == '0')
                            Column(
                              children: [
                                SizedBox(
                                  height: media.width * 0.025,
                                ),
                                Button(
                                    onTap: () async {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var val = await getWalletHistory();
                                      if (val == 'logout') {
                                        navigateLogout();
                                      }
                                      setState(() {
                                        _isLoading = false;
                                        _choosePayment = true;
                                      });
                                    },
                                    text: languages[choosenLanguage]['text_pay'])
                              ],
                            ),
                        ],
                      ),
                    ),
                  _invoiceOverlayA(media),
                  _invoiceOverlayB(media),
                  if (_isLoading == true) const Positioned(child: Loading()),
                ],
              );
            }),
      ),
    );
  }
}
