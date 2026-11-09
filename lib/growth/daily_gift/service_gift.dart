import 'package:flutter/material.dart';

import '../growth_api.dart';

/// What a gift would take off one service's fare, from the server's own rule.
class ServiceGiftQuote {
  const ServiceGiftQuote({required this.minor, required this.words});

  final int minor;
  final String words; // "5 دينار"

  double get amount => minor / 100;
}

/// Asks once per service and fare; the answer is kept a minute so scrolling costs nothing.
class ServiceGiftLookup extends StatefulWidget {
  const ServiceGiftLookup({
    super.key,
    required this.zoneTypeId,
    required this.fare,
    required this.bidding,
    required this.coupon,
    required this.later,
    required this.builder,
  });

  final String? zoneTypeId;
  final double fare;
  final bool bidding;
  final bool coupon;
  final bool later;
  final Widget Function(BuildContext, ServiceGiftQuote?) builder;

  @override
  State<ServiceGiftLookup> createState() => _ServiceGiftLookupState();
}

class _ServiceGiftLookupState extends State<ServiceGiftLookup> {
  static final Map<String, (ServiceGiftQuote?, DateTime)> _kept = {};
  static const _keep = Duration(minutes: 1);

  ServiceGiftQuote? _quote;
  String _key = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant ServiceGiftLookup old) {
    super.didUpdateWidget(old);
    _check();
  }

  Future<void> _check() async {
    final key = '${widget.zoneTypeId}|${widget.fare}|${widget.bidding}|${widget.coupon}|${widget.later}';
    if (key == _key) return;
    _key = key;
    if (widget.zoneTypeId == null || widget.fare <= 0 || widget.later) {
      if (mounted) setState(() => _quote = null);
      return;
    }
    final kept = _kept[key];
    if (kept != null && DateTime.now().difference(kept.$2) < _keep) {
      if (mounted) setState(() => _quote = kept.$1);
      return;
    }
    final d = await GrowthApi.preview(zoneTypeId: widget.zoneTypeId!, fare: widget.fare, pricingMode: widget.bidding ? 'bidding' : 'fixed', coupon: widget.coupon);
    if (d == null) return; // a gift is never in the way of a ride
    final minor = (d['gift_minor'] as num?)?.toInt() ?? 0;
    final quote = minor > 0 ? ServiceGiftQuote(minor: minor, words: d['gift_words']?.toString() ?? d['gift']?.toString() ?? '') : null;
    _kept[key] = (quote, DateTime.now());
    if (mounted && key == _key) setState(() => _quote = quote);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _quote);
}
