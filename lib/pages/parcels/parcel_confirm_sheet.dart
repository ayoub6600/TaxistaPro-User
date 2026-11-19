import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';
import 'parcel_pins.dart';

/// What he is about to send, line by line, before anything leaves the phone (owner 2026-11-19:
/// a tap on «أنا» must never send the order; only «أكّد الطلب» here does).
class ParcelSummary {
  const ParcelSummary({
    required this.from,
    required this.to,
    required this.receiver,
    required this.phone,
    required this.size,
    required this.price,
    required this.pay,
    required this.needsCode,
  });

  final String from;
  final String to;
  final String receiver;
  final String phone;
  final String size;
  final String price;
  final String pay;
  final bool needsCode;
}

class ParcelConfirmSheet extends StatelessWidget {
  const ParcelConfirmSheet({super.key, required this.summary});

  final ParcelSummary summary;

  /// true only when he taps «أكّد الطلب»
  static Future<bool> show(BuildContext context, ParcelSummary s) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr, child: ParcelConfirmSheet(summary: s)),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return IcSheet(children: [
      Text(tr('راجع طلبك 📦', 'Check your order 📦'), textAlign: TextAlign.center, style: IcStyle.t(20, w: FontWeight.w900)),
      const SizedBox(height: 10),
      _line(Icons.trip_origin_rounded, ParcelPin.pickColor, tr('من', 'From'), s.from),
      _line(Icons.location_on_rounded, ParcelPin.dropColor, tr('لوين', 'To'), s.to),
      _line(Icons.person_rounded, IcStyle.navy, tr('المستلم', 'Receiver'), '${s.receiver} · ', trailing: s.phone),
      _line(Icons.inventory_2_rounded, IcStyle.navy, tr('الحجم', 'Size'), s.size),
      _line(Icons.payments_rounded, IcStyle.blue, tr('السعر', 'Price'), s.price, strong: true),
      _line(Icons.account_balance_wallet_rounded, IcStyle.navy, tr('مين يدفع', 'Who pays'), s.pay),
      _line(
          s.needsCode ? Icons.lock_rounded : Icons.lock_open_rounded,
          s.needsCode ? const Color(0xff16803C) : const Color(0xffB42318),
          tr('التسليم', 'Hand-over'),
          s.needsCode
              ? tr('بكود: الكابتن ما يسلّمش إلا للي عنده الكود', 'With a code: only whoever has it gets the parcel')
              : tr('بدون كود: أنت المسؤول عن التسليم', 'No code: you answer for the hand-over')),
      const SizedBox(height: 14),
      IcButton(key: const ValueKey('parcel-confirm'), text: tr('أكّد الطلب', 'Confirm the order'), onTap: () => Navigator.of(context).pop(true)),
      const SizedBox(height: 6),
      IcButton(text: tr('رجوع للتعديل', 'Back to edit'), ghost: true, onTap: () => Navigator.of(context).pop(false)),
    ]);
  }

  Widget _line(IconData icon, Color color, String label, String text, {String? trailing, bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text(label, style: IcStyle.t(13, w: FontWeight.w800, c: IcStyle.muted))),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: text),
                // the number reads left to right inside the Arabic line
                if (trailing != null) TextSpan(text: '\u2066$trailing\u2069'),
              ]),
              style: IcStyle.t(strong ? 17 : 14, w: strong ? FontWeight.w900 : FontWeight.w800, c: strong ? IcStyle.blue : IcStyle.navy),
            ),
          ),
        ]),
      );
}
