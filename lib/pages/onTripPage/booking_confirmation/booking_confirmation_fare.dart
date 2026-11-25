part of '../booking_confirmation.dart';

class _RideFareData {
  const _RideFareData({required this.value, required this.currency});

  final double value;
  final String currency;

  /// «11», or «11.50» when not whole (no «.00»)
  String get amount => moneyAmount(value);
}

bool isLegacyBiddingSearchRequest(Map<dynamic, dynamic> request,
    Map<dynamic, dynamic> profile) {
  final isBid = request['is_bid_ride'] == 1 ||
      request['is_bid_ride']?.toString() == '1';
  if (!isBid) return false;
  // The taxi module dispatches rider proposals as regular requests. Older
  // pending taxi requests may still carry is_bid_ride, but have no bid-meta.
  if (profile['enable_modules_for_applications'] == 'taxi') return false;
  final proposal = double.tryParse(
      request['rider_proposed_fare']?.toString() ?? '') ?? 0;
  return proposal <= 0;
}

_RideFareData? _resolveRideFare(Map<dynamic, dynamic> request) {
  if (request.isEmpty) return null;

  final isBidRide =
      request['is_bid_ride'] == 1 || request['is_bid_ride']?.toString() == '1';
  final acceptedFare =
      double.tryParse(request['accepted_ride_fare']?.toString() ?? '');
  final hasAcceptedFare = acceptedFare != null && acceptedFare > 0;
  final bill = request['requestBill'];
  final billData = bill is Map && bill['data'] is Map
      ? Map<dynamic, dynamic>.from(bill['data'] as Map)
      : const <dynamic, dynamic>{};
  // A regular ride can become a negotiated ride after a driver sends a
  // counter offer. Once accepted, that fare is authoritative even though the
  // original `is_bid_ride` flag remains false.
  final candidates = hasAcceptedFare
      ? <dynamic>[
          // a gift came off the agreed fare: what the rider really pays
          if ((double.tryParse(request['platform_coupon_subsidy']?.toString() ?? '') ?? 0) > 0) request['passenger_payable'],
          request['accepted_ride_fare'],
          request['discounted_total'],
          request['request_eta_amount'],
          request['offerred_ride_fare'],
          billData['total_amount'],
        ]
      : isBidRide
          ? <dynamic>[
              request['accepted_ride_fare'],
              request['rider_proposed_fare'],
              request['offerred_ride_fare'],
              request['request_eta_amount'],
              billData['total_amount'],
            ]
          : <dynamic>[
              request['rider_proposed_fare'],
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
    value: amount,
    currency: rawCurrency.toString().trim(),
  );
}

String _resolvedRideFareText(Map<dynamic, dynamic> request) {
  final fare = _resolveRideFare(request);
  if (fare == null) return '';
  // owner 2026-11-25: «11 د.ل», never «LYD 11.00»
  return moneyText(fare.value, fare.currency, arabic: languageDirection == 'rtl');
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
    final amount = moneyText(fare.value, fare.currency, arabic: isRtl);
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
