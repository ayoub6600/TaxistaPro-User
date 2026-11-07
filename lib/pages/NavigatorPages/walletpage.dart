import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/translations/translation.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';
import '../../payments/moamalat/moamalat_app_env.dart';
import '../../payments/moamalat/moamalat_env.dart';
import '../../payments/moamalat/add_money_sheet.dart';
import '../../community/rewards_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

dynamic addMoney;
TextEditingController phonenumber = TextEditingController();
TextEditingController amount = TextEditingController();
bool isLoading = false;
bool showtoast = false;

class _WalletPageState extends State<WalletPage> {
  TextEditingController addMoneyController = TextEditingController();
  dynamic _shimmer;
  bool _addPayment = false;
  bool _addingMoney = false;
  int ischeckmoneytransfer = 0;
  ScrollController custom = ScrollController();
  late final MoamalatEnv _moamalatEnv = buildMoamalatEnv(onWalletChanged: () {
    if (mounted) getWallet();
  });

  @override
  void initState() {
    getWallet();
    _shimmer = AnimationController.unbounded(vsync: MyTickerProvider())
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
    custom.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  //get wallet details
  getWallet() async {
    walletHistory.clear();
    for (var i = 0; i < 10; i++) {
      walletHistory.add({});
    }
    var val = await getWalletHistory();
    await getCountryCode();
    if (val == 'success') {
      setState(() {
        isLoading = false;
        valueNotifierBook.incrementNotifier();
      });
    }
  }

  showToast() {
    setState(() {
      showtoast = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showtoast = false;
      });
    });
  }

  navigateLogout() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false);
    });
  }

  bool error = false;
  String errortext = '';
  bool ispop = false;

  //show toast for copy

  /// "Add money": the customer picks how - Qareeb recharge cards or the bank
  /// card - from the methods THEIR market offers (asked of the server).
  void _startAddMoney() {
    showAddMoneySheet(
      context,
      env: _moamalatEnv,
      onQareeb: _openQareebRecharge,
    );
  }

  /// The existing recharge-card code entry, unchanged.
  void _openQareebRecharge() {
    if (!mounted) return;
    final media = MediaQuery.of(context).size;
    setState(() {
      addMoneyController.text = '';
      addMoney = null;
    });
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            // width: media.width * 1,
            // padding: MediaQuery.of(context)
            //     .viewInsets,
            decoration: BoxDecoration(
                color: page,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(media.width * 0.05),
                    topRight: Radius.circular(media.width * 0.05))),
            // padding:
            //     EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
            child: Container(
              //  width: media.width * 1,
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
                        text: languages[choosenLanguage]
                            ['text_add_money_wallet'],
                        size: media.width * sixteen,
                        fontweight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.06,
                    ),
                    Container(
                      height: media.width * 0.128,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderLines, width: 1.2),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Container(
                              width: media.width * 0.1,
                              height: media.width * 0.128,
                              decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  color: Color(0xffF0F0F0)),
                              alignment: Alignment.center,
                              child: MyText(
                                text: walletBalance['currency_symbol'],
                                size: media.width * twelve,
                                fontweight: FontWeight.w600,
                                color: (isDarkTheme == true)
                                    ? Colors.black
                                    : textColor,
                              )),
                        ),
                        SizedBox(
                          width: media.width * 0.05,
                        ),
                        Expanded(
                          child: Container(
                            height: media.width * 0.128,
                            width: media.width * 0.6,
                            alignment: Alignment.center,
                            child: TextField(
                              controller: addMoneyController,
                              onChanged: (val) {
                                setState(() {
                                  addMoney = int.parse(val);
                                });
                              },
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "ادخل رقم الكود",
                                hintStyle: GoogleFonts.notoSans(
                                  fontSize: media.width * fourteen,
                                  fontWeight: FontWeight.normal,
                                  color: textColor.withOpacity(0.4),
                                ),
                              ),
                              style: GoogleFonts.notoSans(
                                  fontSize: media.width * fourteen,
                                  fontWeight: FontWeight.normal,
                                  color: textColor),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    SizedBox(
                      height: media.width * 0.1,
                    ),
                    Button(
                      onTap: () async {
                        if (_addingMoney) {
                          return;
                        }
                        _addingMoney = true;
                        var result = await addBalance(addMoneyController.text);
                        _addingMoney = false;
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pop(context);
                        result == 'Money added successfully'
                            ? showSuccessToast(
                                msg: languages[choosenLanguage]
                                    ['text_money_added'],
                              )
                            : showErrorToast(msg: result);
                        await getWallet();
                        debugPrint('drops $result');
                      },
                      text: languages[choosenLanguage]['text_addmoney'],
                      // width:
                      //     media.width * 0.4,
                    ),
                    SizedBox(
                      height: media.width * 0.02,
                    ),
                    Button(
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          addMoney = null;
                          FocusManager.instance.primaryFocus?.unfocus();
                          addMoneyController.clear();
                          Navigator.pop(context);
                        });
                      },
                      text: languages[choosenLanguage]['text_cancel'],
                    ),
                  ]),
            ),
          );
        });
  }

  /// the balance, big, on the app's blue card; «إضافة فلوس» and «مكافآتي» under it
  Widget _balanceCard() {
    final symbol = '${walletBalance['currency_symbol'] ?? ''}';
    final balance = walletBalance.isEmpty ? '—' : '${walletBalance['wallet_balance']}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff0873FF), Color(0xff1965BF)], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xff0873FF).withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(languages[choosenLanguage]['text_availablebalance'] ?? 'الرصيد المتاح',
            style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: .85), fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(balance, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text(symbol, style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: .85), fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _action(Icons.add_rounded, languages[choosenLanguage]['text_addmoney'] ?? 'إضافة فلوس', _startAddMoney),
          const SizedBox(width: 10),
          _action(Icons.emoji_events_outlined, 'مكافآتي',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsPage()))),
        ]),
      ]),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      );

  Widget _entry(Map e) {
    final credit = e['is_credit'] == 1;
    final title = languages[choosenLanguage][e['remarks'].toString()] ?? e['remarks'].toString();
    final trip = (e['request_number'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: textColor.withValues(alpha: .06)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: (credit ? online : verifyDeclined).withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
          child: Icon(credit ? Icons.south_west_rounded : Icons.north_east_rounded, color: credit ? online : verifyDeclined, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(color: textColor, fontSize: 14, fontWeight: FontWeight.w800, height: 1.35)),
            Text(
              [
                '${e['created_at'] ?? ''}',
                if (trip.isNotEmpty) 'رحلة $trip',
                if ((e['transaction_id'] ?? '').toString().startsWith('CR-')) '${e['transaction_id']}',
              ].join(' · '),
              style: GoogleFonts.cairo(color: textColor.withValues(alpha: .5), fontSize: 11.5),
            ),
          ]),
        ),
        Text('${credit ? '+' : '-'}${e['amount']}',
            textDirection: TextDirection.ltr,
            style: GoogleFonts.notoSans(color: credit ? online : textColor, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _entryPlaceholder() => AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
                  colors: shaderColor,
                  stops: shaderStops,
                  begin: shaderBegin,
                  end: shaderEnd,
                  tileMode: TileMode.clamp,
                  transform: SlidingGradientTransform(slidePercent: _shimmer.value))
              .createShader(bounds),
          child: Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: hintColor.withValues(alpha: .25), borderRadius: BorderRadius.circular(18)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                body: Stack(
                  alignment: Alignment.center,
                  children: [
                    // design v2: the balance on the app's blue card with its actions, then the entries
                    Container(
                      color: page,
                      child: SafeArea(
                        bottom: false,
                        child: CustomScrollView(
                          controller: custom,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                                child: Row(children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                                    style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(languages[choosenLanguage]['text_enable_wallet'] ?? 'المحفظة',
                                      style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800)),
                                ]),
                              ),
                            ),
                            SliverToBoxAdapter(child: _balanceCard()),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                                child: Text(languages[choosenLanguage]['text_recenttransactions'] ?? 'آخر المعاملات',
                                    style: GoogleFonts.cairo(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            if (walletHistory.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((context, i) {
                                    final e = walletHistory[i];
                                    final last = walletPages.isNotEmpty && i == walletHistory.length - 1 &&
                                        walletPages['current_page'] < walletPages['total_pages'];
                                    return Column(children: [
                                      if (e is! Map || e.isEmpty) _entryPlaceholder() else _entry(e),
                                      if (last)
                                        TextButton(
                                          onPressed: () async {
                                            setState(() {
                                              for (var k = 0; k < 10; k++) {
                                                walletHistory.add({});
                                              }
                                            });
                                            final val = await getWalletHistoryPage((walletPages['current_page'] + 1).toString());
                                            if (val == 'logout') navigateLogout();
                                            if (mounted) setState(() => isLoading = false);
                                          },
                                          child: Text(languages[choosenLanguage]['text_loadmore'] ?? 'المزيد',
                                              style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                                        ),
                                    ]);
                                  }, childCount: walletHistory.length),
                                ),
                              )
                            else
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Column(children: [
                                    Image.asset(isDarkTheme ? 'assets/images/no_transactiondark.gif' : 'assets/images/no_transaction.gif',
                                        width: media.width * 0.4, height: media.width * 0.4, fit: BoxFit.contain),
                                    Text(languages[choosenLanguage]['text_noDataFound'] ?? '',
                                        style: GoogleFonts.cairo(color: textColor.withValues(alpha: .6), fontSize: 15, fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    //add payment
                    (_addPayment == true)
                        ? Positioned(
                            bottom: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                        bottom: media.width * 0.05),
                                    width: media.width * 0.9,
                                    padding:
                                        EdgeInsets.all(media.width * 0.025),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: borderLines, width: 1.2),
                                        color: page),
                                    child: Column(children: [
                                      Container(
                                        height: media.width * 0.128,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: borderLines, width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                                width: media.width * 0.1,
                                                height: media.width * 0.128,
                                                decoration: const BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12),
                                                      bottomLeft:
                                                          Radius.circular(12),
                                                    ),
                                                    color: Color(0xffF0F0F0)),
                                                alignment: Alignment.center,
                                                child: MyText(
                                                  text: walletBalance[
                                                      'currency_symbol'],
                                                  size: media.width * twelve,
                                                  fontweight: FontWeight.w600,
                                                  color: (isDarkTheme == true)
                                                      ? Colors.black
                                                      : textColor,
                                                )),
                                            SizedBox(
                                              width: media.width * 0.05,
                                            ),
                                            Container(
                                                height: media.width * 0.128,
                                                width: media.width * 0.6,
                                                alignment: Alignment.center,
                                                child: MyTextField(
                                                  textController:
                                                      addMoneyController,
                                                  hinttext:
                                                      languages[choosenLanguage]
                                                          ['text_enteramount'],
                                                  onTap: (val) {
                                                    setState(() {
                                                      addMoney = int.parse(val);
                                                    });
                                                  },
                                                  maxline: 1,
                                                ))
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '100';
                                                addMoney = 100;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: MyText(
                                                text: walletBalance[
                                                        'currency_symbol'] +
                                                    '100',
                                                size: media.width * twelve,
                                                fontweight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text = '500';
                                                addMoney = 500;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: MyText(
                                                text: walletBalance[
                                                        'currency_symbol'] +
                                                    '500',
                                                size: media.width * twelve,
                                                fontweight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: media.width * 0.05,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                addMoneyController.text =
                                                    '1000';
                                                addMoney = 1000;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.11,
                                              width: media.width * 0.17,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  color: page,
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              alignment: Alignment.center,
                                              child: MyText(
                                                text: walletBalance[
                                                        'currency_symbol'] +
                                                    '1000',
                                                size: media.width * twelve,
                                                fontweight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: media.width * 0.1,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Button(
                                            onTap: () async {
                                              setState(() {
                                                _addPayment = false;
                                                addMoney = null;
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                                addMoneyController.clear();
                                              });
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_cancel'],
                                            width: media.width * 0.4,
                                          ),
                                          Button(
                                            onTap: () async {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              if (addMoney != 0 &&
                                                  addMoney != null) {
                                                setState(() {
                                                  _addPayment = false;
                                                });
                                              }
                                            },
                                            text: languages[choosenLanguage]
                                                ['text_addmoney'],
                                            width: media.width * 0.4,
                                          ),
                                        ],
                                      )
                                    ]),
                                  ),
                                ],
                              ),
                            ))
                        : Container(),

                    //loader
                    (isLoading)
                        ? const Positioned(top: 0, child: Loading())
                        : Container(),
                    (showtoast == true)
                        ? PaymentSuccess(
                            onTap: () async {
                              setState(() {
                                showtoast = false;
                                // Navigator.pop(context, true);
                              });
                            },
                            transfer: true,
                          )
                        : Container(),
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(
                              onTap: () {
                                setState(() {
                                  internetTrue();
                                  // _complete = false;
                                  isLoading = true;
                                  getWallet();
                                });
                              },
                            ))
                        : Container(),
                  ],
                ),
              ),
            );
          }),
    );
  }
}

class MonetTransferBottomSheet extends StatefulWidget {
  const MonetTransferBottomSheet({super.key});

  @override
  State<MonetTransferBottomSheet> createState() =>
      _MonetTransferBottomSheetState();
}

class _MonetTransferBottomSheetState extends State<MonetTransferBottomSheet> {
  List<DropdownMenuItem<String>> get dropdownItems {
    List<DropdownMenuItem<String>> menuItems = const [
      DropdownMenuItem(value: "user", child: Text("User")),
      DropdownMenuItem(value: "driver", child: Text("Driver")),
    ];
    return menuItems;
  }

  String dropdownValue = 'user';
  bool error = false;
  String errortext = '';

  @override
  void initState() {
    setState(() {
      amount.text = '';
      phonenumber.text = '';
      dropdownValue = 'user';
    });
    super.initState();
  }

  getWallet() async {
    var val = await getWalletHistory();
    await getCountryCode();
    if (val == 'success') {
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: EdgeInsets.all(media.width * 0.05),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    filled: false,
                    fillColor: page,
                  ),
                  dropdownColor: page,
                  value: dropdownValue,
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                    });
                  },
                  items: dropdownItems,
                  style: GoogleFonts.notoSans(
                    fontSize: media.width * sixteen,
                    color: textColor,
                  ),
                ),
                TextFormField(
                  controller: amount,
                  style: GoogleFonts.notoSans(
                    fontSize: media.width * sixteen,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: languages[choosenLanguage]['text_enteramount'],
                    counterText: '',
                    hintStyle: GoogleFonts.notoSans(
                      fontSize: media.width * sixteen,
                      color: textColor.withOpacity(0.7),
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: (isDarkTheme == true)
                          ? textColor.withOpacity(0.2)
                          : inputfocusedUnderline,
                      width: 1.2,
                      style: BorderStyle.solid,
                    )),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: (isDarkTheme == true)
                          ? textColor.withOpacity(0.1)
                          : inputUnderline,
                      width: 1.2,
                      style: BorderStyle.solid,
                    )),
                  ),
                ),
                TextFormField(
                  controller: phonenumber,
                  onChanged: (val) {},
                  style: GoogleFonts.notoSans(
                    fontSize: media.width * sixteen,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: languages[choosenLanguage]['text_phone_number'],
                    counterText: '',
                    hintStyle: GoogleFonts.notoSans(
                      fontSize: media.width * sixteen,
                      color: textColor.withOpacity(0.7),
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: (isDarkTheme == true)
                          ? textColor.withOpacity(0.2)
                          : inputfocusedUnderline,
                      width: 1.2,
                      style: BorderStyle.solid,
                    )),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: (isDarkTheme == true)
                          ? textColor.withOpacity(0.1)
                          : inputUnderline,
                      width: 1.2,
                      style: BorderStyle.solid,
                    )),
                  ),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                (error == true)
                    ? Text(
                        errortext,
                        style: const TextStyle(color: Colors.red),
                      )
                    : Container(),
                SizedBox(
                  height: media.width * 0.05,
                ),
                (isLoading == false)
                    ? Button(
                        onTap: () async {
                          // Navigator.pop(context);
                          setState(() {
                            isLoading = true;
                          });
                          if (phonenumber.text == '' || amount.text == '') {
                            setState(() {
                              error = true;
                              errortext = languages[choosenLanguage]
                                  ['text_fill_fileds'];
                              isLoading = false;
                            });
                          } else {
                            // Navigator.pop(context);
                            var result = await sharewalletfun(
                                amount: amount.text,
                                mobile: phonenumber.text,
                                role: dropdownValue);
                            if (result == 'success') {
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                              setState(() {
                                dropdownValue = 'user';
                                error = false;
                                errortext = '';

                                getWallet();
                                showtoast = true;
                              });
                            } else {
                              setState(() {
                                error = true;
                                errortext = result.toString();
                                isLoading = false;
                              });
                            }
                          }
                        },
                        text: languages[choosenLanguage]['text_credit_trans'],
                        width: media.width * 0.9,
                      )
                    : Container(
                        height: media.width * 0.12,
                        width: media.width * 0.9,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius:
                                BorderRadius.circular(media.width * 0.02)),
                        child: SizedBox(
                          height: media.width * 0.06,
                          width: media.width * 0.07,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        ),
                      ),
                SizedBox(
                  height: media.width * 0.02,
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(media.width * 0.02),
                    child: MyText(
                      textAlign: TextAlign.center,
                      text: languages[choosenLanguage]['text_cancel'],
                      size: media.width * sixteen,
                      color: verifyDeclined,
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}
