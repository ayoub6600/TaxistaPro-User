import 'package:flutter/material.dart';

import '../../../functions/errand_api.dart';
import '../../../functions/tr.dart';
import '../../intercity/intercity_style.dart';
import '../../../functions/money_label.dart';

/// The errand's price as the server quoted it: the road, «3 وقفات × 2», the total, and the free wait
/// at each stop.
class ErrandPrice extends StatelessWidget {
  const ErrandPrice({super.key, required this.quote, required this.quoting, required this.config});

  /// {km, route_price, stops, stop_fees, price, currency}, or null before the stops are chosen
  final Map? quote;
  final bool quoting;
  final ErrandConfig config;

  /// «أول 5 دقايق في كل وقفة مجانية، بعدها 0.5 LYD للدقيقة»
  static String waitLine(ErrandConfig c) => tr(
      'أول ${c.freeWait} دقايق في كل وقفة مجانية، بعدها ${IcStyle.money(c.waitPerMin)} ${c.currency} للدقيقة',
      'The first ${c.freeWait} minutes at each stop are free, then ${IcStyle.money(c.waitPerMin)} ${c.currency} a minute');

  /// «4.2 كم · LYD 14» on the map, or what to do next
  static Widget chip({required Map? quote, required bool quoting, required bool hasStops, required String currency}) {
    final km = quote?['km'] as num?, price = quote?['price'] as num?;
    final text = !hasStops
        ? tr('زيد وقفاتك 👇', 'Add your stops 👇')
        : quoting
            ? tr('نحسبوا السعر…', 'Pricing…')
            : price == null
                ? null
                : '${km != null ? tr('${IcStyle.money(km)} كم · ', '${IcStyle.money(km)} km · ') : ''}${moneyText(price, currency, arabic: appRtl)}';
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: ValueKey(text),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x29102A56), blurRadius: 10)]),
      child: Text(text, style: IcStyle.t(13.5, w: FontWeight.w900, c: hasStops ? IcStyle.blue : IcStyle.navy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final cur = '${q?['currency'] ?? config.currency}';
    final route = q?['route_price'] as num?, price = q?['price'] as num?;
    final stops = (q?['stops'] as num?)?.toInt();
    final fees = q?['stop_fees'] as num?;
    // per stop: the quote's own when it has one, else the admin's
    final fee = stops != null && stops > 0 && fees != null ? fees / stops : config.stopFee;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (route != null) Text(tr('الطريق ${moneyText(route, cur, arabic: appRtl)}', 'The road ${moneyText(route, cur, arabic: appRtl)}'), style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
              if (stops != null)
                Text(tr('+ $stops وقفات × ${IcStyle.money(fee)}', '+ $stops stops × ${IcStyle.money(fee)}'),
                    key: const ValueKey('errand-stops-line'), style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
              if (q == null) Text(tr('السعر يبان لما تختار الوقفات', 'The price shows once the stops are chosen'), style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
            ]),
          ),
          quoting
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(price == null ? '—' : moneyText(price, cur, arabic: appRtl), key: const ValueKey('errand-price'), style: IcStyle.t(22, w: FontWeight.w900)),
        ]),
        const SizedBox(height: 4),
        Text('⏱️ ${waitLine(config)}', key: const ValueKey('errand-wait-line'), style: IcStyle.t(12, w: FontWeight.w700, c: IcStyle.navy)),
      ]),
    );
  }
}
