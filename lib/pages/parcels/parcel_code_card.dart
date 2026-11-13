import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/tr.dart';

import '../../functions/share_text.dart';

/// On the sender's ride screen: «كود التسليم» the receiver gives the driver, and one tap to send it.
/// Shown only for a parcel, and only to the sender (the server never gives the driver the code).
class ParcelCodeCard extends StatelessWidget {
  const ParcelCodeCard({super.key, required this.parcel});

  final Map parcel;

  static Widget? of(Map ride) {
    final p = ride['parcel'];
    if (p is! Map || '${p['code'] ?? ''}'.length != 4 || p['delivered'] == true) return null;
    return ParcelCodeCard(parcel: p);
  }

  @override
  Widget build(BuildContext context) {
    final code = '${parcel['code']}';
    final name = '${parcel['receiver_name'] ?? tr('المستلم', 'The receiver')}';
    final picked = parcel['picked_up'] == true;
    return Container(
      key: const ValueKey('parcel-code-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('📦', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(picked ? tr('الطرد مع الكابتن، في الطريق لـ$name', 'The parcel is with the captain, on its way to $name') : tr('طرد ${parcel['size_label'] ?? ''} لـ$name', 'A parcel for $name'),
                style: GoogleFonts.cairo(color: const Color(0xff102A56), fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(tr('كود التسليم: $name يعطيه للكابتن', 'Delivery code: $name gives it to the captain'), style: GoogleFonts.cairo(color: const Color(0xff55678A), fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        // the digits read left to right, whatever the page direction
        Row(mainAxisAlignment: MainAxisAlignment.center, textDirection: TextDirection.ltr, children: [
          for (final d in code.split(''))
            Container(
              width: 38,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
              child: Text(d, style: GoogleFonts.notoSans(color: const Color(0xff102A56), fontSize: 22, fontWeight: FontWeight.w900)),
            ),
        ]),
        const SizedBox(height: 8),
        Builder(
          builder: (ctx) => FilledButton.icon(
            onPressed: () => shareText(ctx, tr('كود استلام طردك من تاكسيستا: $code\nاعطيه للكابتن لما يوصلك الطرد.', 'Your Taxista parcel code: $code\nGive it to the captain when the parcel reaches you.')),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff0873FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(tr('ابعت الكود لـ$name', 'Send the code to $name'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}
