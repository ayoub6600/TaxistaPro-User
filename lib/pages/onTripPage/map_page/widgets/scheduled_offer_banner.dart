import 'package:flutter/material.dart';

import '../../../../utils/scheduled_offers.dart';

/// Home indicator: a driver has priced one of the rider's scheduled rides.
/// One tap opens the scheduled rides page where the offer can be answered.
class ScheduledOfferBanner extends StatelessWidget {
  const ScheduledOfferBanner({
    super.key,
    required this.summary,
    required this.onTap,
    required this.rtl,
  });

  final ScheduledOfferSummary summary;
  final VoidCallback onTap;
  final bool rtl;

  /// "2026-09-26T07:45:00" (the ride's market wall clock) -> "2026-09-26  07:45".
  static String whenLabel(String? raw) {
    final parsed = raw == null ? null : DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}  ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  String get title {
    if (summary.offerCount > 1) {
      return rtl
          ? 'لديك ${summary.offerCount} عروض جديدة لرحلاتك المجدولة'
          : 'You have ${summary.offerCount} new offers for your scheduled rides';
    }
    return rtl ? 'لديك عرض جديد لرحلتك المجدولة' : 'You have a new offer for your scheduled ride';
  }

  @override
  Widget build(BuildContext context) {
    final when = whenLabel(summary.firstTripStart);
    final amount = summary.lowestFare == null
        ? ''
        : '${moneyLabel(summary.lowestFare)} ${summary.currency}'.trim();
    final detail = [when, amount].where((part) => part.isNotEmpty).join('   ·   ');
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Semantics(
        button: true,
        label: title,
        child: Material(
          key: const ValueKey('scheduled-offer-banner'),
          color: const Color(0xFF0B6E4F),
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      if (detail.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(detail,
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                        ),
                    ],
                  ),
                ),
                Icon(rtl ? Icons.chevron_left : Icons.chevron_right, color: Colors.white),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
