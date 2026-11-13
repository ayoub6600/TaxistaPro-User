import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import '../intercity/intercity_fare_page.dart' show IcFareBar;
import '../intercity/intercity_style.dart';

/// «طريقة السعر», as the admin set it for the service: a fixed price (nothing to show), offers (his
/// own price from the suggested one, captains answer with theirs), or he chooses between the two.
class PriceModeBox extends StatelessWidget {
  const PriceModeBox({
    super.key,
    required this.mode,
    required this.offers,
    required this.onOffers,
    required this.suggested,
    required this.fare,
    required this.onFare,
    required this.minPercent,
    required this.maxPercent,
    required this.currency,
  });

  final String mode;
  final bool offers;
  final ValueChanged<bool> onOffers;
  final num suggested;
  final num? fare;
  final ValueChanged<num> onFare;
  final int minPercent;
  final int maxPercent;
  final String currency;

  /// whole dinars, as the server checks them
  static (num, num) range(num suggested, int minPercent, int maxPercent) {
    final lo = (suggested * minPercent / 100).floor();
    final hi = (suggested * maxPercent / 100).ceil();
    return (lo < 1 ? 1 : lo, hi < 1 ? 1 : hi);
  }

  /// where his price starts: the suggested one, whole
  static num start(num suggested) => suggested.round() < 1 ? 1 : suggested.round();

  @override
  Widget build(BuildContext context) {
    if (mode != 'offers' && mode != 'choice') return const SizedBox.shrink();
    final (lo, hi) = range(suggested, minPercent, maxPercent);
    final step = suggested >= 100 ? 5 : 1;
    final f = fare ?? start(suggested);
    return Column(key: const ValueKey('price-mode'), crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (mode == 'choice') ...[
        Text(tr('كيف تحب السعر؟', 'How do you want the price?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: IcChip(text: tr('سعر ثابت · $currency ${IcStyle.money(suggested)}', 'Fixed · $currency ${IcStyle.money(suggested)}'), selected: !offers, onTap: () => onOffers(false))),
          const SizedBox(width: 8),
          Expanded(child: IcChip(text: tr('اطلب عروض', 'Ask for offers'), selected: offers, onTap: () => onOffers(true))),
        ]),
        const SizedBox(height: 8),
      ],
      if (offers) ...[
        Text(tr('سعرك (الكباتن يقبلوه أو يبعتوا عروضهم)', 'Your price (captains accept it or send theirs)'),
            style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
        const SizedBox(height: 4),
        IcFareBar(
          value: f,
          onPlus: f + step <= hi ? () => onFare(f + step) : null,
          onMinus: f - step >= lo ? () => onFare(f - step) : null,
        ),
        const SizedBox(height: 4),
        Text(tr('المقترح ${IcStyle.money(suggested)} · من ${IcStyle.money(lo)} إلى ${IcStyle.money(hi)}', 'Suggested ${IcStyle.money(suggested)} · from ${IcStyle.money(lo)} to ${IcStyle.money(hi)}'),
            textAlign: TextAlign.center, style: IcStyle.t(11.5, w: FontWeight.w600, c: IcStyle.muted)),
        const SizedBox(height: 8),
      ],
    ]);
  }
}
