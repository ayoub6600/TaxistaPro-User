part of '../booking_confirmation.dart';

class _RideFareData {
  const _RideFareData({required this.amount, required this.currency});

  final String amount;
  final String currency;
}

_RideFareData? _resolveRideFare(Map<dynamic, dynamic> request) {
  if (request.isEmpty) return null;

  final isBidRide =
      request['is_bid_ride'] == 1 || request['is_bid_ride']?.toString() == '1';
  final bill = request['requestBill'];
  final billData = bill is Map && bill['data'] is Map
      ? Map<dynamic, dynamic>.from(bill['data'] as Map)
      : const <dynamic, dynamic>{};
  final candidates = isBidRide
      ? <dynamic>[
          request['accepted_ride_fare'],
          request['offerred_ride_fare'],
          request['request_eta_amount'],
          billData['total_amount'],
        ]
      : <dynamic>[
          request['discounted_total'],
          request['request_eta_amount'],
          request['accepted_ride_fare'],
          billData['total_amount'],
        ];

  double? amount;
  double? zeroFallback;
  for (final candidate in candidates) {
    final parsed = double.tryParse(candidate?.toString().trim() ?? '');
    if (parsed != null && parsed > 0) {
      amount = parsed;
      break;
    }
    if (parsed == 0) zeroFallback = 0;
  }
  amount ??= zeroFallback;
  if (amount == null) return null;

  final rawCurrency = request['requested_currency_symbol'] ??
      billData['requested_currency_symbol'] ??
      userDetails['currency_symbol'] ??
      '';
  return _RideFareData(
    amount: amount.toStringAsFixed(2),
    currency: rawCurrency.toString().trim(),
  );
}

class _RideFareBadge extends StatelessWidget {
  const _RideFareBadge({
    required this.fare,
    required this.isRtl,
    this.expanded = false,
  });

  final _RideFareData fare;
  final bool isRtl;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final label = isRtl ? 'سعر الرحلة' : 'Trip fare';
    final amount = fare.currency.isEmpty
        ? fare.amount
        : isRtl
            ? '${fare.amount} ${fare.currency}'
            : '${fare.currency} ${fare.amount}';
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          expanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xffE8F2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.payments_outlined,
            size: 18,
            color: _searchBlue,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: _searchMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (expanded) const Spacer() else const SizedBox(width: 14),
        Text(
          amount,
          textDirection: ui.TextDirection.ltr,
          style: GoogleFonts.cairo(
            color: _searchNavy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FE),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffDCEAFF)),
      ),
      child: content,
    );
  }
}
