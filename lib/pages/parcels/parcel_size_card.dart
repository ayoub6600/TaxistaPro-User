import 'package:flutter/material.dart';

import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';
import '../../functions/money_label.dart';

/// «شن تبعت؟»: one size with its price for this distance (or the size's own start before the places).
class ParcelSizeCard extends StatelessWidget {
  const ParcelSizeCard({super.key, required this.size, required this.selected, required this.currency, required this.onTap, this.price, this.from});

  final String size;
  final bool selected;
  final String currency;
  final VoidCallback onTap;
  final num? price;
  final num? from;

  static final labels = {'small': tr('صغير', 'Small'), 'medium': tr('متوسط', 'Medium'), 'large': tr('كبير', 'Large')};
  static final hints = {
    'small': tr('ظرف أو علبة', 'An envelope or a box'),
    'medium': tr('شنطة أو كرتونة', 'A bag or a carton'),
    'large': tr('الكرسي الخلفي', 'The back seat')
  };
  static const icons = {'small': '✉️', 'medium': '👜', 'large': '📦'};

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: labels[size],
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xffF5F9FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? IcStyle.blue : IcStyle.line, width: selected ? 2 : 1.5),
            ),
            child: Column(children: [
              Text(icons[size]!, style: const TextStyle(fontSize: 24)),
              Text(labels[size]!, style: IcStyle.t(14.5, w: FontWeight.w900)),
              Text(hints[size]!, textAlign: TextAlign.center, style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
              if (price != null)
                Text(moneyText(price!, currency, arabic: appRtl), style: IcStyle.t(12.5, w: FontWeight.w900, c: IcStyle.blue))
              else if (from != null)
                Text(tr('من ${moneyText(from!, currency, arabic: appRtl)}', 'From ${moneyText(from!, currency, arabic: appRtl)}'),
                    style: IcStyle.t(11.5, w: FontWeight.w800, c: IcStyle.blue)),
            ]),
          ),
        ),
      );
}
