import 'package:flutter/material.dart';

import '../../../functions/tr.dart';
import '../../intercity/intercity_style.dart';
import '../parcel_pins.dart';
import 'errand_stop_card.dart';

/// one stop as the summary says it
class ErrandSummaryStop {
  const ErrandSummaryStop({required this.place, required this.item, required this.pays, this.contact = ''});
  final String place;
  final String item;
  final String pays;
  final String contact;
}

class ErrandSummary {
  const ErrandSummary({required this.name, required this.stops, required this.to, required this.price, required this.pay, required this.wait});
  final String name;
  final List<ErrandSummaryStop> stops;
  final String to;
  final String price;
  final String pay;
  final String wait;
}

/// The errand line by line before anything leaves the phone: each stop with what is taken there,
/// where he gets them, the price, how he pays. Only «أكّد الطلب» sends it (as for a parcel).
class ErrandConfirmSheet extends StatelessWidget {
  const ErrandConfirmSheet({super.key, required this.summary});

  final ErrandSummary summary;

  /// true only when he taps «أكّد الطلب»
  static Future<bool> show(BuildContext context, ErrandSummary s) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr, child: ErrandConfirmSheet(summary: s)),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return IcSheet(children: [
      Text(tr('راجع مشوارك 🛍️', 'Check your errand 🛍️'), textAlign: TextAlign.center, style: IcStyle.t(20, w: FontWeight.w900)),
      Text(s.name, textAlign: TextAlign.center, style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
      const SizedBox(height: 10),
      for (var i = 0; i < s.stops.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ErrandStopCard.number(i + 1, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.stops[i].item, style: IcStyle.t(14.5, w: FontWeight.w900)),
                Text(s.stops[i].place, maxLines: 2, overflow: TextOverflow.ellipsis, style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
                if (s.stops[i].contact.isNotEmpty) Text(s.stops[i].contact, style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
                Text(s.stops[i].pays, style: IcStyle.t(12.5, w: FontWeight.w800, c: const Color(0xff16803C))),
              ]),
            ),
          ]),
        ),
      _line(Icons.flag_rounded, ParcelPin.pickColor, tr('يجيبهم لـ', 'Brought to'), s.to),
      _line(Icons.payments_rounded, IcStyle.blue, tr('السعر', 'Price'), s.price, strong: true),
      _line(Icons.timer_outlined, IcStyle.navy, tr('الانتظار', 'Waiting'), s.wait),
      _line(Icons.account_balance_wallet_rounded, IcStyle.navy, tr('الدفع', 'Payment'), s.pay),
      const SizedBox(height: 14),
      IcButton(key: const ValueKey('errand-confirm'), text: tr('أكّد الطلب', 'Confirm the order'), onTap: () => Navigator.of(context).pop(true)),
      const SizedBox(height: 6),
      IcButton(text: tr('رجوع للتعديل', 'Back to edit'), ghost: true, onTap: () => Navigator.of(context).pop(false)),
    ]);
  }

  Widget _line(IconData icon, Color color, String label, String text, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: IcStyle.t(13, w: FontWeight.w800, c: IcStyle.muted))),
          Expanded(child: Text(text, style: IcStyle.t(strong ? 17 : 14, w: strong ? FontWeight.w900 : FontWeight.w800, c: strong ? IcStyle.blue : IcStyle.navy))),
        ]),
      );
}
