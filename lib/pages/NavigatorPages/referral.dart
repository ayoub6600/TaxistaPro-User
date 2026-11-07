import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isLoading = true;
  bool _showToast = false;
  PackageInfo? _package;
  String? androidUrl;
  String? iosUrl;

  @override
  void initState() {
    super.initState();
    _getReferral();
  }

  // get referral code
  Future<void> _getReferral() async {
    await getReferral(); // تأكد أن getReferral() لا تحتوي على أخطاء
    _package = await PackageInfo.fromPlatform();

    setState(() {
      androidUrl =
          'https://play.google.com/store/apps/details?id=${_package?.packageName}';
      iosUrl =
          'https://itunes.apple.com/lookup?bundleId=${_package?.packageName}';
      _isLoading = false;
    });
  }

  // show toast for copied
  void showToast() {
    setState(() {
      _showToast = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showToast = false;
      });
    });
  }

  bool get _rtl => languageDirection == 'rtl';

  Future<void> _share() async {
    final code = '${myReferralCode['refferal_code'] ?? ''}';
    await Share.share(
      // ignore: prefer_interpolation_to_compose_strings
      languages[choosenLanguage]['text_invitation_1'].toString().replaceAll('55', _package?.packageName ?? '') +
          ' ' +
          code +
          ' ' +
          languages[choosenLanguage]['text_invitation_2'] +
          ' \n \n ' +
          "https://play.google.com/store/apps/details?id=com.Ayoub.Usertaxista&pcampaignid=web_share" +
          '\n \n  ' +
          "https://apps.apple.com/us/app/taxista/id6739538467",
    );
  }

  // design v2: the code as the hero (big, copy on tap), how it works in three steps, one share button
  @override
  Widget build(BuildContext context) {
    final code = '${myReferralCode['refferal_code'] ?? ''}';
    return ValueListenableBuilder(
      valueListenable: valueNotifierHome.value,
      builder: (context, value, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: page,
          body: Stack(children: [
            SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                  child: Row(children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_rounded, color: textColor),
                      style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
                    ),
                    const SizedBox(width: 8),
                    Text(_rtl ? 'ادعُ صديقًا' : 'Invite a friend',
                        style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800)),
                  ]),
                ),
                Expanded(
                  child: myReferralCode.isEmpty
                      ? const SizedBox.shrink()
                      : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xff102A56), Color(0xff1965BF)]),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Column(children: [
                              Image.asset('assets/images/gift.png', width: 72, height: 72),
                              const SizedBox(height: 10),
                              Text('${myReferralCode['referral_comission_string'] ?? ''}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.45)),
                              const SizedBox(height: 16),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: code));
                                    HapticFeedback.selectionClick();
                                    showToast();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(children: [
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(_rtl ? 'كود الدعوة' : 'Your code',
                                              style: GoogleFonts.cairo(color: const Color(0xff7B8BA8), fontSize: 12, fontWeight: FontWeight.w700)),
                                          Text(code,
                                              textDirection: TextDirection.ltr,
                                              style: GoogleFonts.notoSans(color: const Color(0xff10213F), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                        ]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(color: const Color(0xff0873FF).withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.copy_rounded, size: 17, color: Color(0xff0873FF)),
                                          const SizedBox(width: 5),
                                          Text(_rtl ? 'نسخ' : 'Copy',
                                              style: GoogleFonts.cairo(color: const Color(0xff0873FF), fontSize: 13, fontWeight: FontWeight.w800)),
                                        ]),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 18),
                          Text(_rtl ? 'كيف تشتغل؟' : 'How it works',
                              style: GoogleFonts.cairo(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final (i, line) in [
                            _rtl ? 'ابعت الكود لصاحبك' : 'Send your code to a friend',
                            _rtl ? 'يحمّل تاكسيستا ويكتب الكود وقت التسجيل' : 'They sign up with your code',
                            _rtl ? 'تاخذ المكافأة حسب شروط الدعوة' : 'You get the reward per the rules',
                          ].indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: const Color(0xff0873FF).withValues(alpha: .1), shape: BoxShape.circle),
                                  child: Text('${i + 1}', style: GoogleFonts.notoSans(color: const Color(0xff0873FF), fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(line, style: GoogleFonts.cairo(color: textColor, fontSize: 14, fontWeight: FontWeight.w600))),
                              ]),
                            ),
                        ]),
                ),
                if (myReferralCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Button(onTap: _share, text: languages[choosenLanguage]['text_invite'] ?? (_rtl ? 'شارك الدعوة' : 'Share')),
                  ),
              ]),
            ),
            if (internet == false)
              Positioned(
                top: 0,
                child: NoInternet(onTap: () {
                  setState(() {
                    internetTrue();
                    _isLoading = true;
                    getReferral();
                  });
                }),
              ),
            if (_isLoading) const Positioned(top: 0, child: Loading()),
            if (_showToast)
              Positioned(
                left: 16,
                right: 16,
                bottom: 90 + MediaQuery.of(context).padding.bottom,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xff14A47B), borderRadius: BorderRadius.circular(14)),
                    child: Text(languages[choosenLanguage]['text_code_copied'] ?? '',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
