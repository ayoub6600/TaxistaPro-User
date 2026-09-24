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
    this.fairFare,
    this.chosenFare,
    this.minimumFare,
    this.maximumFare,
    this.onFareStep,
    this.isArabic = true,
  });

  final Map service;
  final bool selected;
  final String arrivalText;
  final String offerFareLabel;
  final double? fairFare;
  final double? chosenFare;
  final double? minimumFare;
  final double? maximumFare;
  final void Function(int direction)? onFareStep;
  final bool isArabic;

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
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [colors.surface, accent.withValues(alpha: 0.075)],
              )
            : null,
        color: selected ? null : colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.82)
              : colors.outlineVariant.withValues(alpha: 0.72),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.035),
            blurRadius: selected ? 20 : 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _VehicleImage(
            imageUrl: imageUrl,
            selected: selected,
            accent: accent,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        service['name']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ),
                    if (service['is_default'] == true) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.16),
                              colors.secondary.withValues(alpha: 0.16),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: accent, size: 11),
                            const SizedBox(width: 2),
                            Text(isArabic ? 'الأكثر طلبًا' : 'Most popular',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
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
              total: chosenFare != null
                  ? _formatFare(chosenFare!)
                  : service['total']?.toString() ?? '--',
              discountedTotal:
                  hasDiscount ? service['discounted_totel']?.toString() : null,
            ),
        ]),
        if (selected &&
            onFareStep != null &&
            fairFare != null &&
            chosenFare != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(isArabic ? 'السعر العادل' : 'Fair fare',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant)),
                    const SizedBox(height: 1),
                    Text(
                        '${_formatFare(fairFare!)} ${service['currency'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface)),
                  ])),
              _stepButton(Icons.remove_rounded,
                  chosenFare! > (minimumFare ?? 0) + 0.001, -1, accent, colors),
              Container(
                  width: 74,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(isArabic ? 'عرضك' : 'Your offer',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant)),
                    Text(_formatFare(chosenFare!),
                        style: TextStyle(
                            height: 1.12,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: accent)),
                  ])),
              _stepButton(
                  Icons.add_rounded,
                  maximumFare == null || chosenFare! < maximumFare! - 0.001,
                  1,
                  accent,
                  colors),
            ]),
          ),
        ],
      ]),
    );
  }

  String _formatFare(double fare) => fare == fare.roundToDouble()
      ? fare.toStringAsFixed(0)
      : fare.toStringAsFixed(2);

  Widget _stepButton(IconData icon, bool enabled, int direction, Color color,
          ColorScheme colors) =>
      Material(
        color: enabled
            ? color.withValues(alpha: 0.11)
            : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? () => onFareStep?.call(direction) : null,
          child: SizedBox.square(
            dimension: 36,
            child: Icon(icon,
                size: 19,
                color: enabled
                    ? color
                    : colors.onSurfaceVariant.withValues(alpha: 0.4)),
          ),
        ),
      );
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
