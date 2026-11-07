import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/pages/login/login.dart';
import 'package:taxista/translations/translation.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../noInternet/nointernet.dart';
import 'historydetails.dart';
import '../../navigation/guarded_navigation.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

dynamic selectedHistory;

class _HistoryState extends State<History> {
  int _showHistory = 1;
  dynamic isCompleted;
  bool showFilter = false;
  dynamic _shimmer;

  @override
  void initState() {
    historyFiltter = 'is_completed=1';
    _getHistory();

    _shimmer = AnimationController.unbounded(vsync: MyTickerProvider())
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
    super.initState();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  navigateLogout() {
    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => const Login()),
            (route) => false);
      });
    }
  }

//get history
  _getHistory() async {
    if (mounted) {
      setState(() {
        myHistoryPage.clear();
        myHistory.clear();
      });
    }
    for (var i = 0; i < 10; i++) {
      myHistory.add({});
    }
    var val = await getHistory();
    if (val == 'logout') {
      navigateLogout();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      color: (isDarkTheme) ? Colors.black : Colors.white,
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 20.h,
                  ),
                  // design v2: «سجل الرحلات» with two tabs (the upcoming rides have their own page)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                    child: Row(children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded, color: textColor),
                        style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                      ),
                      const SizedBox(width: 8),
                      Text(languageDirection == 'rtl' ? 'سجل الرحلات' : (languages[choosenLanguage]['text_enable_history'] ?? 'History'),
                          style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: textColor.withValues(alpha: .05), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      for (final tab in const [1, 2])
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (_showHistory == tab) return;
                              setState(() {
                                myHistory.clear();
                                myHistoryPage.clear();
                                showFilter = false;
                                _showHistory = tab;
                                for (var i = 0; i < 10; i++) {
                                  myHistory.add({});
                                }
                              });
                              historyFiltter = tab == 1 ? 'is_completed=1' : 'is_cancelled=1';
                              await getHistory();
                              if (mounted) setState(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _showHistory == tab ? page : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _showHistory == tab ? [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                              ),
                              child: Text(
                                languages[choosenLanguage][tab == 1 ? 'text_completed' : 'text_cancelled'] ?? '',
                                style: GoogleFonts.cairo(color: textColor, fontSize: 14, fontWeight: _showHistory == tab ? FontWeight.w800 : FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  Expanded(
                      child: Container(
                    padding: const EdgeInsets.all(1),
                    width: media.width * 1,
                    color: page,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(
                            height: media.width * 0.02,
                          ),
                          (myHistory.isNotEmpty)
                              ? Column(
                                  children: myHistory
                                      .asMap()
                                      .map((i, value) {
                                        return MapEntry(
                                            i,
                                            (myHistory[i].isEmpty)
                                                ? AnimatedBuilder(
                                                    animation: _shimmer,
                                                    builder: (context, widget) {
                                                      return ShaderMask(
                                                          blendMode:
                                                              BlendMode.srcATop,
                                                          shaderCallback:
                                                              (bounds) {
                                                            return LinearGradient(
                                                                    colors:
                                                                        shaderColor,
                                                                    stops:
                                                                        shaderStops,
                                                                    begin:
                                                                        shaderBegin,
                                                                    end:
                                                                        shaderEnd,
                                                                    tileMode:
                                                                        TileMode
                                                                            .clamp,
                                                                    transform:
                                                                        SlidingGradientTransform(
                                                                            slidePercent: _shimmer
                                                                                .value))
                                                                .createShader(
                                                                    bounds);
                                                          },
                                                          child: Container(
                                                            margin: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.03),
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.03),
                                                            decoration: BoxDecoration(
                                                                color: page,
                                                                borderRadius: BorderRadius
                                                                    .circular(media
                                                                            .width *
                                                                        0.02)),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.15,
                                                                      color: hintColor
                                                                          .withOpacity(
                                                                              0.5),
                                                                    ),
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.15,
                                                                      color: hintColor
                                                                          .withOpacity(
                                                                              0.5),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.02,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.2,
                                                                      color: hintColor
                                                                          .withOpacity(
                                                                              0.5),
                                                                    ),
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.2,
                                                                      color: hintColor
                                                                          .withOpacity(
                                                                              0.5),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.02,
                                                                ),
                                                                const MySeparator(),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.02,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                      decoration: BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          color:
                                                                              hintColor.withOpacity(0.5)),
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Container(
                                                                        height: media.width *
                                                                            0.05,
                                                                        color: hintColor
                                                                            .withOpacity(0.5),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.03,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                      decoration: BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          color:
                                                                              hintColor.withOpacity(0.5)),
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.05,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Container(
                                                                        height: media.width *
                                                                            0.05,
                                                                        color: hintColor
                                                                            .withOpacity(0.5),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ));
                                                    })
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          selectedHistory = i;

                                                          guardedPush(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const HistoryDetails()));
                                                        },
                                                        child: Container(
                                                          width:
                                                              media.width * 1,
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                                  media.width *
                                                                      0.025,
                                                                  media.width *
                                                                      0.02,
                                                                  media.width *
                                                                      0.025,
                                                                  media.width *
                                                                      0.05),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
                                                            border: Border.all(color: textColor.withValues(alpha: .07)),
                                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 4))],
                                                          ),
                                                          margin: EdgeInsets.only(
                                                              bottom:
                                                                  media.width *
                                                                      0.02,
                                                              left:
                                                                  media.width *
                                                                      0.03,
                                                              right:
                                                                  media.width *
                                                                      0.03),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            5),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                      color: (myHistory[i]['is_completed'] ==
                                                                              1)
                                                                          ? online
                                                                          : (myHistory[i]['is_cancelled'] == 1)
                                                                              ? verifyDeclined
                                                                              : textColor,
                                                                    ),
                                                                    child: MyText(
                                                                        text: (myHistory[i]['is_completed'] == 1)
                                                                            ? languages[choosenLanguage]['text_completed']
                                                                            : (myHistory[i]['is_cancelled'] == 1)
                                                                                ? languages[choosenLanguage]['text_cancelled']
                                                                                : (myHistory[i]['is_later'] == 1)
                                                                                    ? (myHistory[i]['is_rental'] == false)
                                                                                        ? languages[choosenLanguage]['text_ridelater']
                                                                                        : (languages[choosenLanguage]['text_rental'] + ' - ' + myHistory[i]['rental_package_name'].toString())
                                                                                    : '',
                                                                        fontweight: FontWeight.w600,
                                                                        color: Colors.white,
                                                                        size: media.width * fourteen),
                                                                  ),
                                                                  MyText(
                                                                      text: myHistory[
                                                                              i]
                                                                          [
                                                                          'request_number'],
                                                                      color: Colors
                                                                          .grey,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .w600,
                                                                      size: media
                                                                              .width *
                                                                          fourteen),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 10.h,
                                                              ),
                                                              Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  if (myHistory[
                                                                              i]
                                                                          [
                                                                          'vehicle_type_image'] !=
                                                                      null)
                                                                    Container(
                                                                      height:
                                                                          80.h,
                                                                      width:
                                                                          80.w,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        image:
                                                                            DecorationImage(
                                                                          image:
                                                                              NetworkImage(myHistory[i]['vehicle_type_image'].toString()),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  SizedBox(
                                                                      width:
                                                                          16.w),
                                                                  if (myHistory[
                                                                              i]
                                                                          [
                                                                          'request_number'] !=
                                                                      null)
                                                                    Expanded(
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          SizedBox(
                                                                            height:
                                                                                8.h,
                                                                          ),
                                                                          if (myHistory[i]['vehicle_type_name'] !=
                                                                              null)
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                const Icon(
                                                                                  Icons.watch_later,
                                                                                  color: Colors.blue,
                                                                                ),
                                                                                // MyText(text: languages[choosenLanguage]['text_vehicle_type'], color: Colors.black, fontweight: FontWeight.w600, size: media.width * fourteen),
                                                                                MyText(
                                                                                    text: (myHistory[i]['later_ride'] == true)
                                                                                        ? myHistory[i]['trip_start_time']
                                                                                        : (myHistory[i]['cancelled_ride'] == true)
                                                                                            ? myHistory[i]['converted_cancelled_at']
                                                                                            : (myHistory[i]['completed_ride'] == true)
                                                                                                ? myHistory[i]['converted_completed_at'].toString()
                                                                                                : myHistory[i]['converted_created_at'].toString(),
                                                                                    color: Colors.grey,
                                                                                    fontweight: FontWeight.w600,
                                                                                    size: media.width * fourteen),
                                                                              ],
                                                                            ),
                                                                          //vehicle_type_name
                                                                          if (myHistory[i]['vehicle_type_name'] !=
                                                                              null)
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                const Icon(
                                                                                  Icons.directions_car,
                                                                                  color: Colors.blue,
                                                                                ),
                                                                                //MyText(text: languages[choosenLanguage]['text_vehicle_type'], color: Colors.black, fontweight: FontWeight.w600, size: media.width * fourteen),
                                                                                MyText(text: myHistory[i]['vehicle_type_name'], color: Colors.grey, fontweight: FontWeight.w600, size: media.width * fourteen),
                                                                              ],
                                                                            ),
                                                                        ],
                                                                      ),
                                                                      //text_vehicle_type
                                                                    ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 8.h,
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      const Icon(
                                                                        Icons
                                                                            .payment,
                                                                        color: Colors
                                                                            .blue,
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.02,
                                                                      ),
                                                                      MyText(
                                                                        text: languages[choosenLanguage]
                                                                            [
                                                                            'text_payment'],
                                                                        size: media.width *
                                                                            fourteen,
                                                                        color:
                                                                            textColor,
                                                                        fontweight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.02,
                                                                      ),
                                                                      MyText(
                                                                        text: (myHistory[i]['payment_opt'] ==
                                                                                '1')
                                                                            ? languages[choosenLanguage]['text_cash']
                                                                            : (myHistory[i]['payment_opt'] == '2')
                                                                                ? languages[choosenLanguage]['text_wallet']
                                                                                : (myHistory[i]['payment_opt'] == '0')
                                                                                    ? languages[choosenLanguage]['text_card']
                                                                                    : '',
                                                                        size: media.width *
                                                                            fourteen,
                                                                        color:
                                                                            textColor,
                                                                        fontweight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.02,
                                                                      ),
                                                                      MyText(
                                                                          text: (myHistory[i]['is_bid_ride'] == 1)
                                                                              ? myHistory[i]['requested_currency_symbol'] + ' ' + myHistory[i]['accepted_ride_fare'].toString()
                                                                              : (myHistory[i]['is_completed'] == 1)
                                                                                  ? myHistory[i]['requestBill']['data']['requested_currency_symbol'] + ' ' + myHistory[i]['requestBill']['data']['total_amount'].toString()
                                                                                  : myHistory[i]['requested_currency_symbol'] + ' ' + myHistory[i]['request_eta_amount'].toString(),
                                                                          fontweight: FontWeight.bold,
                                                                          size: media.width * fourteen),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.02,
                                                              ),
                                                              const MySeparator(),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.02,
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Container(
                                                                    height: media
                                                                            .width *
                                                                        0.08,
                                                                    width: media
                                                                            .width *
                                                                        0.08,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    decoration: BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Colors
                                                                            .green
                                                                            .withOpacity(0.4)),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .location_on_outlined,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        MyText(
                                                                      text: myHistory[
                                                                              i]
                                                                          [
                                                                          'pick_address'],
                                                                      maxLines:
                                                                          2,
                                                                      size: media
                                                                              .width *
                                                                          twelve,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.03,
                                                              ),
                                                              if (myHistory[i][
                                                                      'drop_address'] !=
                                                                  null)
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      height: media
                                                                              .width *
                                                                          0.08,
                                                                      width: media
                                                                              .width *
                                                                          0.08,
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      decoration:
                                                                          const BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color: Color(
                                                                            0xFFFF0000),
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .location_on,
                                                                        color: Colors
                                                                            .white,
                                                                        size: media.width *
                                                                            eighteen,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.03,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          MyText(
                                                                        text: myHistory[i]
                                                                            [
                                                                            'drop_address'],
                                                                        maxLines:
                                                                            1,
                                                                        size: media.width *
                                                                            twelve,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ));
                                      })
                                      .values
                                      .toList(),
                                )
                              : SizedBox(
                                  height: media.height * 0.6,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: media.width * 0.2,
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        height: media.width * 0.6,
                                        width: media.width * 0.6,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage((isDarkTheme)
                                                    ? 'assets/images/nodatafounddark.gif'
                                                    : 'assets/images/nodatafound.gif'),
                                                fit: BoxFit.contain)),
                                      ),
                                      SizedBox(
                                        width: media.width * 0.6,
                                        child: MyText(
                                            text: languages[choosenLanguage]
                                                ['text_noDataFound'],
                                            textAlign: TextAlign.center,
                                            fontweight: FontWeight.w800,
                                            size: media.width * sixteen),
                                      ),
                                    ],
                                  ),
                                ),

                          //load more button
                          (myHistoryPage['pagination'] != null)
                              ? (myHistoryPage['pagination']['current_page'] <
                                      myHistoryPage['pagination']
                                          ['total_pages'])
                                  ? InkWell(
                                      onTap: () async {
                                        setState(() {
                                          // _isLoading = true;
                                          for (var i = 0; i < 10; i++) {
                                            myHistory.add({});
                                          }
                                        });
                                        dynamic val;
                                        if (historyFiltter == '') {
                                          val = await getHistoryPages(
                                              'page=${myHistoryPage['pagination']['current_page'] + 1}');
                                        } else {
                                          if (_showHistory == 0) {
                                            val = await getHistoryPages(
                                                'is_later=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                          } else if (_showHistory == 1) {
                                            val = await getHistoryPages(
                                                'is_completed=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                          } else if (_showHistory == 2) {
                                            val = await getHistoryPages(
                                                'is_cancelled=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                          }
                                        }

                                        if (val == 'logout') {
                                          navigateLogout();
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        margin: EdgeInsets.only(
                                            bottom: media.width * 0.05),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: page,
                                            border: Border.all(
                                                color: borderLines,
                                                width: 1.2)),
                                        child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_loadmore'],
                                          size: media.width * sixteen,
                                        ),
                                      ),
                                    )
                                  : Container()
                              : Container()
                        ],
                      ),
                    ),
                  ))
                ],
              ),
            ),
            (showFilter)
                ? Positioned(
                    right: media.width * 0.05,
                    top: MediaQuery.of(context).padding.top + media.width * 0.1,
                    child: Material(
                      elevation: 10,
                      child: Container(
                        height: media.width * 0.31,
                        width: media.width * 0.35,
                        padding: EdgeInsets.all(media.width * 0.03),
                        color: page,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  myHistory.clear();
                                  myHistoryPage.clear();
                                  _showHistory = 0;
                                  showFilter = false;
                                  for (var i = 0; i < 10; i++) {
                                    myHistory.add({});
                                  }
                                });
                                historyFiltter = 'is_later=1';

                                await getHistory();
                                setState(() {});
                              },
                              child: Container(
                                width: media.width * 0.32,
                                padding: EdgeInsets.fromLTRB(
                                    media.width * 0.01,
                                    media.width * 0.01,
                                    media.width * 0.01,
                                    media.width * 0.02),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(color: hintColor))),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyText(
                                        text: languages[choosenLanguage]
                                            ['text_upcoming'],
                                        maxLines: 1,
                                        size: media.width * fourteen),
                                    Container(
                                      height: media.width * 0.04,
                                      width: media.width * 0.04,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all()),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.025,
                                        width: media.width * 0.025,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_showHistory == 0)
                                                ? textColor
                                                : page),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  myHistory.clear();
                                  myHistoryPage.clear();
                                  showFilter = false;
                                  _showHistory = 1;
                                  for (var i = 0; i < 10; i++) {
                                    myHistory.add({});
                                  }
                                });
                                historyFiltter = 'is_completed=1';
                                await getHistory();
                                setState(() {});
                              },
                              child: Container(
                                width: media.width * 0.32,
                                padding: EdgeInsets.fromLTRB(
                                    media.width * 0.01,
                                    media.width * 0.01,
                                    media.width * 0.01,
                                    media.width * 0.02),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(color: hintColor))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_completed'],
                                          maxLines: 1,
                                          size: media.width * fourteen),
                                    ),
                                    Container(
                                      height: media.width * 0.04,
                                      width: media.width * 0.04,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all()),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.025,
                                        width: media.width * 0.025,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_showHistory == 1)
                                                ? textColor
                                                : page),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  myHistory.clear();
                                  myHistoryPage.clear();
                                  _showHistory = 2;
                                  showFilter = false;
                                  for (var i = 0; i < 10; i++) {
                                    myHistory.add({});
                                  }
                                });
                                historyFiltter = 'is_cancelled=1';
                                await getHistory();
                                setState(() {});
                              },
                              child: Container(
                                width: media.width * 0.32,
                                padding: EdgeInsets.all(media.width * 0.01),
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(color: hintColor))),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_cancelled'],
                                          maxLines: 1,
                                          size: media.width * fourteen),
                                    ),
                                    Container(
                                      height: media.width * 0.04,
                                      width: media.width * 0.04,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all()),
                                      alignment: Alignment.center,
                                      child: Container(
                                        height: media.width * 0.025,
                                        width: media.width * 0.025,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_showHistory == 2)
                                                ? textColor
                                                : page),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ))
                : Container(),
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        setState(() {
                          internetTrue();
                        });
                      },
                    ))
                : Container(),
          ],
        ),
      ),
      // )
    );
  }
}
