import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/functions.dart';
import '../../functions/invite_message.dart';
import '../../functions/share_text.dart';
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

  @override
  void initState() {
    super.initState();
    _getReferral();
  }

  // get referral code
  Future<void> _getReferral() async {
    await getReferral(); // تأكد أن getReferral() لا تحتوي على أخطاء
    if (!mounted) return;
    setState(() => _isLoading = false);
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
    final opened = await shareText(context, inviteMessage('${myReferralCode['refferal_code'] ?? ''}', friendReward: myReferralCode['friend_reward']?.toString()));
    if (!opened && mounted) showToast(); // the message is on the clipboard instead
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(color: const Color(0xff0EA5E9).withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(value, style: GoogleFonts.notoSans(color: textColor, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .65), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

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
                          const SizedBox(height: 12),
                          Row(children: [
                            _stat('${myReferralCode['invites_waiting'] ?? 0}', _rtl ? 'ينتظرون أول مشوار' : 'Waiting for a first ride'),
                            const SizedBox(width: 10),
                            _stat('${myReferralCode['invites_done'] ?? 0}', _rtl ? 'أكملوا وكسبت' : 'Completed'),
                          ]),
                          const SizedBox(height: 18),
                          Text(_rtl ? 'كيف تشتغل؟' : 'How it works',
                              style: GoogleFonts.cairo(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          for (final (i, line) in [
                            _rtl ? 'ابعت الرابط لصاحبك' : 'Send your link to a friend',
                            _rtl ? 'يحمّل تاكسيستا ويسجّل' : 'They download Taxista and sign up',
                            _rtl ? 'يكمّل أول مشوار، ومكافأتك توصل محفظتك' : 'After their first completed ride, your reward reaches your wallet',
                            if (myReferralCode['friend_reward'] != null)
                              _rtl ? 'وهو كمان ياخذ ${myReferralCode['friend_reward']} في محفظته' : 'They get ${myReferralCode['friend_reward']} too',
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
                    child: Button(onTap: _share, text: _rtl ? 'إرسال' : 'Send'),
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
