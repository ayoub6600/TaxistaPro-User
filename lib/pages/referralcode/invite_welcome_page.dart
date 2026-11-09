import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../../functions/invite_link.dart';
import '../../growth/daily_gift/gift_box.dart';
import '../onTripPage/map_page.dart';
import 'referral_code.dart';

/// The app recognised who invited this new rider: one tap, no code to type.
class InviteWelcomePage extends StatefulWidget {
  const InviteWelcomePage({super.key, required this.match});

  final InviteMatch match;

  @override
  State<InviteWelcomePage> createState() => _InviteWelcomePageState();
}

class _InviteWelcomePageState extends State<InviteWelcomePage> {
  bool _busy = false;

  void _go(Widget page) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => page), (_) => false);

  Future<void> _accept() async {
    setState(() => _busy = true);
    referalController.text = widget.match.code;
    final result = await updateReferral();
    if (!mounted) return;
    _go(result == 'true' ? const Maps() : const Referral()); // anything wrong: the code page, as before
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final line = m.reward != null
        ? 'بعد ما تكمّل أول مشوار: تاخذ ${m.reward} في محفظتك، و${m.name} ياخذ مكافأته.'
        : 'مكافأة ${m.name} توصله لما تكمّل أول مشوار لك على تاكسيستا.';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Center(child: GiftBox(size: 96)),
              const SizedBox(height: 18),
              Text('دعاك ${m.name} ✓', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: giftInk)),
              const SizedBox(height: 10),
              Text(line, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.7, color: Color(0xFF55678A))),
              const SizedBox(height: 28),
              SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed: _busy ? null : _accept,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0873FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: const Text('احجز مشوارك الأول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => _go(const Referral()),
                child: Text('مش ${m.name}؟ أدخل كود آخر', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0873FF))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
