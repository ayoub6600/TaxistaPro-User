import 'package:flutter/material.dart';

import 'daily_gift_model.dart';
import 'gift_box.dart';

/// Tapping the bar: the terms in three short lines.
Future<void> showDailyGiftSheet(BuildContext context, DailyGiftOffer offer) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _Sheet(offer),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet(this.offer);

  final DailyGiftOffer offer;

  @override
  Widget build(BuildContext context) {
    final lines = [
      'كل يوم ${offer.amount} من ${offer.startLabel} إلى ${offer.endLabel}',
      'تنخصم تلقائيًا من مشوار واحد في اليوم',
      'الأجرة ${offer.minFare} فأكثر، للرحلات بسعر ثابت',
    ];
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
            Row(children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: giftPale, borderRadius: BorderRadius.circular(20)),
                child: const GiftBox(size: 50),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text('${offer.headline} ${offer.amount}',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: giftInk, height: 1.35)),
              ),
            ]),
            const SizedBox(height: 12),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: const EdgeInsets.only(top: 8, left: 9), width: 7, height: 7, decoration: const BoxDecoration(color: giftSkyDeep, shape: BoxShape.circle)),
                  Expanded(child: Text(line, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF334155), height: 1.6))),
                ]),
              ),
            const SizedBox(height: 6),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: giftBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.pop(context),
                child: const Text('اطلب مشوارك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
