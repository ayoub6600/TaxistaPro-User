import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/ride_pricing_mode.dart';

class VehicleServiceCard extends StatelessWidget {
  const VehicleServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.arrivalText,
    required this.offerFareLabel,
  });

  final Map service;
  final bool selected;
  final String arrivalText;
  final String offerFareLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;
    final mode = RidePricingMode.fromService(service);
    final isDelivery = service['transport_type'] == 'delivery';
    final hasDiscount = service['has_discount'] == true;
    final imageUrl = service['icon']?.toString().trim() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.09) : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? accent : colors.outlineVariant,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.045),
            blurRadius: selected ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _VehicleImage(
            imageUrl: imageUrl,
            selected: selected,
            accent: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      isDelivery ? CupertinoIcons.bag : Icons.person_outline,
                      size: 15,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        (isDelivery ? service['size'] : service['capacity'])
                                ?.toString() ??
                            '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (arrivalText.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          arrivalText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (mode == RidePricingMode.riderOffer)
            _PricingBadge(label: offerFareLabel)
          else
            _Fare(
              currency: service['currency']?.toString() ?? '',
              total: service['total']?.toString() ?? '--',
              discountedTotal:
                  hasDiscount ? service['discounted_totel']?.toString() : null,
            ),
        ],
      ),
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({
    required this.imageUrl,
    required this.selected,
    required this.accent,
  });

  final String imageUrl;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.local_taxi_rounded, color: accent, size: 30);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 62,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surface
                : accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: imageUrl.isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 50,
                  height: 44,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 160),
                  placeholder: (_, __) => const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => fallback,
                ),
        ),
        if (selected)
          PositionedDirectional(
            end: -4,
            bottom: -4,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _Fare extends StatelessWidget {
  const _Fare({
    required this.currency,
    required this.total,
    this.discountedTotal,
  });

  final String currency;
  final String total;
  final String? discountedTotal;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (discountedTotal != null)
          Text(
            '$currency $total'.trim(),
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.55),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          '$currency ${discountedTotal ?? total}'.trim(),
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PricingBadge extends StatelessWidget {
  const _PricingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
