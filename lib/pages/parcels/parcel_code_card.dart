import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/tr.dart';

import '../../functions/share_text.dart';

/// On the sender's ride screen: «كود التسليم» the receiver gives the driver, one tap to send it and
/// one to copy it, and who pays how (the server's plain line). Shown only for a parcel, and only to the
/// sender (the server never gives the driver the code). A parcel sent without a code says so instead.
class ParcelCodeCard extends StatelessWidget {
  const ParcelCodeCard({super.key, required this.parcel});

  final Map parcel;

  static Widget? of(Map ride) {
    final p = ride['parcel'];
    if (p is! Map || p['delivered'] == true) return null;
    // no code asked: the card still says who pays and that he answers for the hand-over
    if (p['needs_code'] == false) return ParcelCodeCard(parcel: p);
    if ('${p['code'] ?? ''}'.length != 4) return null;
    return ParcelCodeCard(parcel: p);
  }

  /// «تدفع 12 LYD كاش للكابتن لما ياخذ الطرد» — the server's words for the sender
  static String? payLine(Map parcel) {
    final pay = parcel['pay'];
    final s = pay is Map ? '${pay['sender'] ?? ''}'.trim() : '';
    return s.isEmpty ? null : s;
  }

  static TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = const Color(0xff102A56)}) => GoogleFonts.cairo(color: c, fontSize: s, fontWeight: w);

  @override
  Widget build(BuildContext context) {
    final code = '${parcel['code'] ?? ''}';
    final withCode = parcel['needs_code'] != false && code.length == 4;
    final name = '${parcel['receiver_name'] ?? tr('المستلم', 'The receiver')}';
    final picked = parcel['picked_up'] == true;
    final pay = payLine(parcel);
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
                style: _t(14, w: FontWeight.w800)),
          ),
        ]),
        if (pay != null) ...[
          const SizedBox(height: 2),
          Text('💵 $pay', key: const ValueKey('parcel-pay-line'), style: _t(12.5, w: FontWeight.w800, c: const Color(0xff16803C))),
        ],
        const SizedBox(height: 6),
        if (!withCode)
          Text(tr('🔓 بدون كود: الكابتن يسلّم الطرد لـ$name، وأنت المسؤول عن التسليم.', '🔓 No code: the captain hands the parcel to $name, and you answer for the hand-over.'),
              style: _t(12.5, w: FontWeight.w800, c: const Color(0xffB42318)))
        else ...[
          Text(tr('كود التسليم: $name يعطيه للكابتن', 'Delivery code: $name gives it to the captain'), style: _t(12, c: const Color(0xff55678A))),
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
            builder: (ctx) => Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => shareText(ctx, tr('كود استلام طردك من تاكسيستا: $code\nاعطيه للكابتن لما يوصلك الطرد.', 'Your Taxista parcel code: $code\nGive it to the captain when the parcel reaches you.')),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xff0873FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(tr('ابعت الكود لـ$name', 'Send the code to $name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('parcel-copy-code'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(
                      content: Text(tr('نسخنا الكود $code', 'Code $code copied'), textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr)));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff0873FF),
                  side: const BorderSide(color: Color(0xff0873FF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(tr('نسخ الكود', 'Copy code'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
