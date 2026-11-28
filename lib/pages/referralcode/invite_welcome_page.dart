import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/functions.dart';
import '../../functions/invite_link.dart';
import '../onTripPage/map_page.dart';
import 'referral_code.dart';

/// The app recognised who invited this new rider (board «سفراء تاكسيستا» · Invitee): one tap, no code
/// to type; his first-ride discount said plainly, and «مش هو؟ اكتب الكود» when the guess is wrong.
class InviteWelcomePage extends StatefulWidget {
  const InviteWelcomePage({super.key, required this.match, this.onAccept, this.onOtherCode});

  final InviteMatch match;

  /// tests replace what the two buttons do
  final Future<void> Function()? onAccept;
  final VoidCallback? onOtherCode;

  @override
  State<InviteWelcomePage> createState() => _InviteWelcomePageState();
}

class _InviteWelcomePageState extends State<InviteWelcomePage> {
  static const _blue = Color(0xFF0B5CFF);
  static const _ink = Color(0xFF0F172A);
  bool _busy = false;

  TextStyle _t(double size, {FontWeight w = FontWeight.w600, Color color = _ink, double? h}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: w, color: color, height: h);

  void _go(Widget page) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => page), (_) => false);

  Future<void> _accept() async {
    setState(() => _busy = true);
    if (widget.onAccept != null) {
      await widget.onAccept!();
      if (mounted) setState(() => _busy = false);
      return;
    }
    referalController.text = widget.match.code;
    final result = await updateReferral();
    if (!mounted) return;
    _go(result == 'true' ? const Maps() : const Referral()); // anything wrong: the code page, as before
  }

  void _otherCode() => widget.onOtherCode != null ? widget.onOtherCode!() : _go(const Referral());

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final name = m.name.trim();
    final who = name.isEmpty ? 'صاحبك' : name;
    final letter = name.isEmpty ? null : name.characters.first;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF8A93A3),
        body: Stack(children: [
          // the home map, dimmed, waits behind the sheet
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE9EEF6))),
          Positioned.fill(child: ColoredBox(color: const Color(0xFF0F172A).withValues(alpha: .35))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              // a short phone (320×568) scrolls the sheet instead of cutting its last line
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 12),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(
                      child: Container(
                          width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(3)))),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
                      child: letter != null
                          ? Text(letter, style: _t(38, w: FontWeight.w800, color: const Color(0xFF1E3A8A)))
                          : const Icon(Icons.person_rounded, size: 44, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('دعاك $who لتاكسيستا', textAlign: TextAlign.center, style: _t(22, w: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Container(
                    key: const ValueKey('invite-discount'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.card_giftcard_rounded, size: 26, color: Color(0xFF047857)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('عندك خصم ${inviteeDiscount(m.reward)} على أول مشوار', style: _t(15, w: FontWeight.w800, h: 1.5)),
                          Text('ينحسب وحده، ما تكتب حتى حاجة', style: _t(12.5, color: const Color(0xFF065F46))),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text('لقيناه وحدنا من الرابط اللي فتحته. لو مش هو، اكتب كود اللي دعاك.',
                      textAlign: TextAlign.center, style: _t(13.5, color: const Color(0xFF475569), h: 1.7)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : _accept,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        disabledBackgroundColor: _blue.withValues(alpha: .75),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text('تمام، يلا نطلب', style: _t(17, w: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _busy ? null : _otherCode,
                    child: Text('مش هو؟ اكتب الكود', style: _t(14, w: FontWeight.w700, color: _blue)),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
