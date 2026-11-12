import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final name = '${parcel['receiver_name'] ?? 'المستلم'}';
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
            child: Text(picked ? 'الطرد مع الكابتن، في الطريق لـ$name' : 'طرد ${parcel['size_label'] ?? ''} لـ$name',
                style: GoogleFonts.cairo(color: const Color(0xff102A56), fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('كود التسليم: $name يعطيه للكابتن', style: GoogleFonts.cairo(color: const Color(0xff55678A), fontSize: 12, fontWeight: FontWeight.w700)),
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
            onPressed: () => shareText(ctx, 'كود استلام طردك من تاكسيستا: $code\nاعطيه للكابتن لما يوصلك الطرد.'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff0873FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text('ابعت الكود لـ$name', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }
}
