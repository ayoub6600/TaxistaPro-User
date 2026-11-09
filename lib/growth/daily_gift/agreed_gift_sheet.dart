import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../functions/functions.dart';
import '../growth_api.dart';
import 'gift_box.dart';

/// Once per ride, when a negotiated fare is agreed and a gift came off it: what the rider now pays.
class AgreedGiftWatcher extends StatefulWidget {
  const AgreedGiftWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<AgreedGiftWatcher> createState() => _AgreedGiftWatcherState();
}

class _AgreedGiftWatcherState extends State<AgreedGiftWatcher> {
  static const _lastKey = 'agreed_gift_shown_ride';
  String? _checked;

  @override
  void initState() {
    super.initState();
    valueNotifierBook.value.addListener(_look);
    _look();
  }

  @override
  void dispose() {
    valueNotifierBook.value.removeListener(_look);
    super.dispose();
  }

  Future<void> _look() async {
    final id = userRequestData['id']?.toString();
    final accepted = userRequestData['accepted_at'] != null;
    final gifted = (double.tryParse(userRequestData['platform_coupon_subsidy']?.toString() ?? '') ?? 0) > 0;
    if (id == null || !accepted || !gifted || userRequestData['pricing_mode'] != 'bidding' || _checked == id) return;
    _checked = id;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_lastKey) == id) return;
    final d = await GrowthApi.rideGift(id);
    if (!mounted || d == null || ((d['gift_minor'] as num?)?.toInt() ?? 0) <= 0) return;
    await prefs.setString(_lastKey, id);
    if (!mounted) return;
    showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (_) => AgreedGiftSheet(agreed: '${d['agreed']}', gift: '${d['gift']}', payable: '${d['payable']}'));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AgreedGiftSheet extends StatelessWidget {
  const AgreedGiftSheet({super.key, required this.agreed, required this.gift, required this.payable});

  final String agreed;
  final String gift;
  final String payable;

  Widget _row(String k, String v, {Color color = const Color(0xFF334155), FontWeight weight = FontWeight.w700}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Flexible(child: Text(k, style: TextStyle(fontSize: 16, fontWeight: weight, color: color))), const SizedBox(width: 10), Text(v, style: TextStyle(fontSize: 16, fontWeight: weight, color: color))],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 12),
            const Row(children: [GiftBox(size: 44), SizedBox(width: 12), Expanded(child: Text('اتفقت مع السائق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: giftInk)))]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF7F9FD), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _row('السعر المتفق عليه', agreed),
                const SizedBox(height: 10),
                _row('🎁 هدية اليوم', '− $gift', color: const Color(0xFF047857), weight: FontWeight.w900),
                const Divider(height: 22, color: Color(0xFFE2E8F0)),
                _row('تدفع للسائق', payable, color: giftInk, weight: FontWeight.w900),
              ]),
            ),
            const SizedBox(height: 10),
            const Text('السائق يأخذ أجرته كاملة، والهدية على تاكسيستا.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ]),
        ),
      ),
    );
  }
}
