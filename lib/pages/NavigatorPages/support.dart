import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import 'adminchatpage.dart';
import 'faq.dart';
import '../../navigation/guarded_navigation.dart';

/// «دعم العملاء» (design v2): the chat with Taxista first, on the app's blue card with its unread
/// count, then the questions and the privacy policy. Same destinations as before.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool get _rtl => languageDirection == 'rtl';

  String _t(String key, String ar) => _rtl ? ar : (languages[choosenLanguage]?[key]?.toString() ?? ar);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: page,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: textColor),
                style: IconButton.styleFrom(backgroundColor: textColor.withValues(alpha: .05), fixedSize: const Size(44, 44)),
              ),
              const SizedBox(width: 8),
              Text(_t('text_support', 'دعم العملاء'), style: GoogleFonts.cairo(color: textColor, fontSize: 21, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: valueNotifierChat.value,
              builder: (context, value, child) {
                final unseen = int.tryParse(unSeenChatCount.toString()) ?? 0;
                return Material(
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => guardedPush(context, MaterialPageRoute(builder: (context) => const AdminChatPage())),
                    child: Ink(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff102A56), Color(0xff1965BF)])),
                      child: Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_t('text_chat_us', 'الدردشة معنا'),
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                            Text(_rtl ? 'اكتب لفريق تاكسيستا، والرد يوصلك هنا وفي الإشعارات' : 'Write to the Taxista team; replies come here',
                                style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: .8), fontSize: 12.5)),
                          ]),
                        ),
                        if (unseen > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 26),
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xffE0243A), borderRadius: BorderRadius.circular(99)),
                            child: Text('$unseen', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                          )
                        else
                          Icon(_rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.white),
                      ]),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _Row(
              icon: Icons.help_outline_rounded,
              text: _t('text_faq', 'الأسئلة الشائعة'),
              onTap: () => guardedPush(context, MaterialPageRoute(builder: (context) => const Faq())),
            ),
            _Row(
              icon: Icons.privacy_tip_outlined,
              text: _t('text_privacy', 'سياسة الخصوصية'),
              onTap: () => openBrowser('${url}privacy'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withValues(alpha: .07))),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: theme.withValues(alpha: .08), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: theme, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: GoogleFonts.cairo(color: textColor, fontSize: 15, fontWeight: FontWeight.w700))),
                Icon(languageDirection == 'rtl' ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: textColor.withValues(alpha: .4)),
              ]),
            ),
          ),
        ),
      );
}
