import 'dart:async';

import 'package:flutter/material.dart';

import '../community/community_kit.dart';
import 'growth_api.dart';
import 'my_gifts_page.dart';

/// The home-screen card: shown only while the rider has an active gift, with its server countdown.
class GiftBanner extends StatefulWidget {
  const GiftBanner({super.key});

  @override
  State<GiftBanner> createState() => _GiftBannerState();
}

class _GiftBannerState extends State<GiftBanner> {
  Map? _gift;
  String? _balance;
  DateTime _at = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await GrowthApi.gifts();
    if (!mounted || d == null) return;
    final live = [
      for (final g in (d['gifts'] is List ? d['gifts'] as List : const []))
        if (g is Map && (g['state'] == 'active' || g['state'] == 'partly_used') && (g['seconds_left'] ?? 0) > 0) g
    ]..sort((a, b) => (a['seconds_left'] as num).compareTo(b['seconds_left'] as num));
    setState(() {
      _gift = live.isEmpty ? null : live.first;
      _balance = d['balance']?.toString();
      _at = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = _gift;
    if (g == null) return const SizedBox.shrink();
    final p = CommunityLook.palette;
    final secs = (g['seconds_left'] as num).toInt() - DateTime.now().difference(_at).inSeconds;
    if (secs <= 0) return const SizedBox.shrink();
    final d = Duration(seconds: secs);
    final left = MyGiftsPageCountdown.text(Duration(hours: d.inHours, minutes: d.inDays > 0 ? 0 : d.inMinutes % 60));
    return Semantics(
      button: true,
      label: 'عندك هدية $_balance، $left',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyGiftsPage()));
          _load();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: CommunityLook.goldBackground(p), borderRadius: BorderRadius.circular(14)),
          child: Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.card_giftcard_rounded, color: CommunityLook.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('عندك هدية $_balance', textDirection: TextDirection.rtl, style: p.text(14, weight: FontWeight.w700)),
                Text('تنخصم تلقائيًا من رحلتك الاقتصادية · $left', textDirection: TextDirection.rtl, style: p.text(12, color: p.sub)),
              ]),
            ),
            Icon(Icons.chevron_left_rounded, color: p.sub),
          ]),
        ),
      ),
    );
  }
}

/// Under the fare before «تأكيد الطلب»: what the gift takes off this fare, from the server's own
/// rule (fixed fare, ride now, no coupon). Nothing shows when no gift applies.
class GiftPreviewLine extends StatefulWidget {
  final String? zoneTypeId;
  final double fare;
  final String pricingMode;
  final bool coupon;
  final bool later;

  const GiftPreviewLine(
      {super.key, required this.zoneTypeId, required this.fare, required this.pricingMode, this.coupon = false, this.later = false});

  @override
  State<GiftPreviewLine> createState() => _GiftPreviewLineState();
}

class _GiftPreviewLineState extends State<GiftPreviewLine> {
  String? _text;
  String _key = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _check();
  }

  @override
  void didUpdateWidget(covariant GiftPreviewLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  Future<void> _check() async {
    final key = '${widget.zoneTypeId}|${widget.fare}|${widget.pricingMode}|${widget.coupon}|${widget.later}';
    if (key == _key) return;
    _key = key;
    if (widget.zoneTypeId == null || widget.fare <= 0 || widget.pricingMode != 'fixed' || widget.coupon || widget.later) {
      setState(() => _text = null);
      return;
    }
    final d = await GrowthApi.preview(zoneTypeId: widget.zoneTypeId!, fare: widget.fare, pricingMode: widget.pricingMode);
    if (!mounted || key != _key) return;
    setState(() => _text = (d?['gift_minor'] ?? 0) > 0 ? d!['text']?.toString() : null);
  }

  @override
  Widget build(BuildContext context) {
    if (_text == null) return const SizedBox.shrink();
    final p = CommunityLook.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: CommunityLook.goldBackground(p), borderRadius: BorderRadius.circular(12)),
      child: Row(textDirection: TextDirection.rtl, children: [
        const Icon(Icons.card_giftcard_rounded, size: 18, color: CommunityLook.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(_text!, textDirection: TextDirection.rtl, style: p.text(13, weight: FontWeight.w700))),
      ]),
    );
  }
}

/// The receipt's "هدية تاكسيستا" line for a ride that used a gift (the bill's discount already holds it).
class RideGiftLine extends StatefulWidget {
  final String requestId;
  final TextStyle? style;

  const RideGiftLine({super.key, required this.requestId, this.style});

  @override
  State<RideGiftLine> createState() => _RideGiftLineState();
}

class _RideGiftLineState extends State<RideGiftLine> {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    GrowthApi.rideGift(widget.requestId).then((d) => mounted ? setState(() => _d = d) : null);
  }

  @override
  Widget build(BuildContext context) {
    if ((_d?['gift_minor'] ?? 0) <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('🎁 ${_d!['label']} (من الخصم أعلاه)', textDirection: TextDirection.rtl, style: widget.style),
        Text('-${_d!['gift']}', textDirection: TextDirection.rtl, style: widget.style?.copyWith(color: CommunityLook.good)),
      ]),
    );
  }
}

/// «أبلغني عند توفر سائق»: on the no-driver sheet. One notice if a free driver comes near within the
/// time chosen; nothing is booked by itself.
Future<void> showRescueSheet(BuildContext context) async {
  final p = CommunityLook.palette;
  int minutes = 30;
  bool busy = false;
  await showModalBottomSheet(
    context: context,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('أبلغني عند توفر سائق', style: p.text(17, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('نبعتلك إشعار واحد لو توفر سائق قريب منك خلال المدة. ما يتحجزش طلب تلقائيًا: أنت تطلب من جديد لو حبيت.',
                style: p.text(13, color: p.sub, height: 1.6)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, children: [
              for (final m in const [15, 30, 60])
                CommunityChip(label: '$m دقيقة', selected: minutes == m, onTap: () => set(() => minutes = m)),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: p.mine, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: busy
                    ? null
                    : () async {
                        set(() => busy = true);
                        final d = await GrowthApi.rescue(minutes);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        final msg = d == null
                            ? 'تعذر الطلب الآن، حاول مرة أخرى.'
                            : (d['_error'] ?? d['message'] ?? '').toString();
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));
                      },
                child: Text('أبلغني', style: p.text(15, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      );
    }),
  );
}

/// «ليش ألغيت؟» after a cancel while searching: optional, one tap, «تخطي» closes it. It never undoes
/// or delays the cancel, which is already done.
Future<void> showQuickCancelReason(BuildContext context) async {
  final p = CommunityLook.palette;
  await showModalBottomSheet(
    context: context,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تم الإلغاء. ليش ألغيت؟', style: p.text(17, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('اختياري، يساعدنا نحسّن الخدمة.', style: p.text(13, color: p.sub)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in quickCancelReasons)
              CommunityChip(
                label: r.$2,
                onTap: () {
                  Navigator.pop(ctx);
                  sendQuickCancelReason(r.$1);
                },
              ),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('تخطي', style: p.text(14, color: p.sub))),
          ),
        ]),
      ),
    ),
  );
}
