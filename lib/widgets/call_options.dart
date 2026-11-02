import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../functions/functions.dart';

/// "اتصال": one button for the other side of the ride, and a sheet with the three ways to reach
/// them - the free call through Taxista first (no credit, no number shown), then WhatsApp, then an
/// ordinary phone call. When the free call is not possible, the sheet comes back with the reason
/// so WhatsApp or the phone is one tap away.
class CallOptions {
  /// Opens a URL outside the app (WhatsApp, the phone dialer); replaced in tests.
  static Future<bool> Function(Uri uri) launch = (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  static bool get _ar => languageDirection != 'ltr';
  static String _t(String ar, String en) => _ar ? ar : en;

  /// The number for wa.me / tel: digits with the country code, without the trunk 0 a local number
  /// can keep after it ("+2180912..." -> "218912...", "+2001012..." -> "201012...").
  static String? digits(String? mobile) {
    var d = (mobile ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('2180')) d = '218${d.substring(4)}';
    if (d.startsWith('200')) d = '20${d.substring(3)}';
    return d.length >= 8 ? d : null;
  }

  /// [freeCall] starts the call inside the app and returns null, or the reason it cannot.
  static Future<void> show(
    BuildContext context, {
    required String peerName,
    required String? mobile,
    required Future<String?> Function() freeCall,
    String? notice,
  }) async {
    final number = digits(mobile);
    final choice = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      // sized to its content (the reason, then three options), scrolling on a small screen
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _Sheet(peerName: peerName, hasNumber: number != null, notice: notice),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'free':
        final problem = await freeCall();
        if (problem != null && context.mounted) {
          await show(context, peerName: peerName, mobile: mobile, freeCall: freeCall, notice: problem);
        }
        break;
      case 'whatsapp':
        await launch(Uri.parse('https://wa.me/$number'));
        break;
      case 'phone':
        await launch(Uri(scheme: 'tel', path: '+$number'));
        break;
    }
  }
}

class _Sheet extends StatelessWidget {
  final String peerName;
  final bool hasNumber;
  final String? notice;

  const _Sheet({required this.peerName, required this.hasNumber, this.notice});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF111827) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF0F172A);
    return Directionality(
      textDirection: CallOptions._ar ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(color: surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: ink.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(CallOptions._t('اتصال بـ$peerName', 'Call $peerName'),
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 4),
              Text(CallOptions._t('اختر طريقة الاتصال', 'Choose how to call'),
                  style: GoogleFonts.cairo(fontSize: 13.5, color: ink.withValues(alpha: 0.6))),
              if (notice != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(notice!, style: GoogleFonts.cairo(fontSize: 13.5, height: 1.45, color: const Color(0xFF92400E))),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 14),
              _Option(
                keyName: 'free',
                color: const Color(0xFF16A34A),
                leading: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
                title: CallOptions._t('اتصال مجاني', 'Free call'),
                subtitle:
                    CallOptions._t('عبر تاكسيستا · بدون رصيد ولا يظهر رقمك', 'Through Taxista · no credit, your number stays private'),
                badge: CallOptions._t('مجاني', 'Free'),
                ink: ink,
              ),
              if (hasNumber) ...[
                const SizedBox(height: 10),
                _Option(
                  keyName: 'whatsapp',
                  color: const Color(0xFF25D366),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/whatsapp.png', width: 26, height: 26),
                  ),
                  title: CallOptions._t('واتساب', 'WhatsApp'),
                  subtitle: CallOptions._t('مكالمة أو رسالة على واتساب', 'A WhatsApp call or message'),
                  ink: ink,
                ),
                const SizedBox(height: 10),
                _Option(
                  keyName: 'phone',
                  color: const Color(0xFF0873FF),
                  leading: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                  title: CallOptions._t('اتصال هاتفي', 'Phone call'),
                  subtitle: CallOptions._t('مكالمة عادية من رصيد هاتفك', 'An ordinary call from your phone plan'),
                  ink: ink,
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String keyName;
  final Color color;
  final Widget leading;
  final String title;
  final String subtitle;
  final String? badge;
  final Color ink;

  const _Option(
      {required this.keyName,
      required this.color,
      required this.leading,
      required this.title,
      required this.subtitle,
      this.badge,
      required this.ink});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('call-option-$keyName'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(keyName),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: keyName == 'whatsapp' ? Colors.white : color,
                  shape: BoxShape.circle,
                  border: keyName == 'whatsapp' ? Border.all(color: color.withValues(alpha: 0.4)) : null),
              child: leading,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title, style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.w800, color: ink))),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(badge!, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ],
                ]),
                Text(subtitle, style: GoogleFonts.cairo(fontSize: 12.5, color: ink.withValues(alpha: 0.6))),
              ]),
            ),
            Icon(CallOptions._ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.35)),
          ]),
        ),
      ),
    );
  }
}

/// The ride card's single "اتصال" button: opens [CallOptions].
class CallOptionsButton extends StatelessWidget {
  final String peerName;
  final String? mobile;
  final Future<String?> Function() freeCall;
  final Color color;

  const CallOptionsButton(
      {super.key, required this.peerName, required this.mobile, required this.freeCall, this.color = const Color(0xFF16A34A)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        key: const ValueKey('call-options-button'),
        borderRadius: BorderRadius.circular(40),
        onTap: () => CallOptions.show(context, peerName: peerName, mobile: mobile, freeCall: freeCall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.call_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(CallOptions._t('اتصال', 'Call'),
                style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
