import 'package:flutter/material.dart';

import '../../growth/daily_gift/daily_gift_bar.dart';
import '../../growth/gift_widgets.dart';
import '../../styles/styles.dart';
import 'home_services_row.dart';

class HomeQuickDestination {
  const HomeQuickDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isConfigured = true,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isConfigured;
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.rtl,
    required this.onChooseDestination,
    required this.onRideWithoutDestination,
    required this.showRideWithoutDestination,
    required this.destinations,
    this.onRecurring,
    this.onTravel,
    this.onDelivery,
    this.onTow,
    this.onFreight,
    this.onSoon,
    this.giftLat,
    this.giftLng,
  });

  /// where the rider is: the city of «هدية كل يوم»
  final double? giftLat;
  final double? giftLng;

  /// «مشوار الدوام»: only for a rider who has a recurring ride
  final VoidCallback? onRecurring;

  /// «سفر»: only where the rider's city has intercity routes
  final VoidCallback? onTravel;

  /// «توصيل»: only where the rider's city has parcels open (else «قريبًا»)
  final VoidCallback? onDelivery;

  /// «ونش»: only where the rider's city has the tow open (else «قريبًا»)
  final VoidCallback? onTow;

  /// «الشحن»: only where the rider's city has a freight class open (else «قريبًا»)
  final VoidCallback? onFreight;

  /// a «قريبًا» service was tapped (الشحن، توصيل، ونش)
  final void Function(String service)? onSoon;

  final bool rtl;
  final VoidCallback onChooseDestination;
  final VoidCallback onRideWithoutDestination;
  final bool showRideWithoutDestination;
  final List<HomeQuickDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        compact ? 12 : 18,
        0,
        compact ? 12 : 18,
        compact ? 10 : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DailyGiftBar(lat: giftLat, lng: giftLng),
          // a Taxista gift with its countdown (nothing when the rider has none)
          const GiftBanner(),
          Row(
            children: [
              for (var index = 0; index < destinations.length; index++) ...[
                if (index > 0) SizedBox(width: compact ? 7 : 9),
                Expanded(child: _QuickDestinationCard(destinations[index])),
              ],
            ],
          ),
          SizedBox(height: compact ? 5 : 7),
          HomeServicesRow(rtl: rtl, services: _services()),
          SizedBox(height: compact ? 7 : 9),
          _DestinationSearch(
            title: rtl ? 'إلى أين؟' : 'Where to?',
            label:
                rtl ? 'ابحث عن مكان أو عنوان' : 'Search for a place or address',
            now: rtl ? 'الآن' : 'Now',
            onTap: onChooseDestination,
          ),
        ],
      ),
    );
  }
}

extension on HomeQuickActions {
  /// بدون وجهة · سفر · مشوار الدوام · الشحن · توصيل · ونش
  List<HomeService> _services() {
    void soon(String what) => onSoon?.call(what);
    return [
      if (showRideWithoutDestination)
        HomeService(
          label: rtl ? 'بدون وجهة' : 'No destination',
          icon: Icons.navigation_rounded,
          background: Colors.white,
          foreground: const Color(0xFF0873FF),
          iconBackground: const Color(0xFF0873FF),
          iconColor: Colors.white,
          onTap: onRideWithoutDestination,
        ),
      if (onTravel != null)
        HomeService(
          label: rtl ? 'سفر' : 'Travel',
          icon: Icons.luggage_rounded,
          background: const Color(0xFF102A56),
          foreground: Colors.white,
          iconBackground: const Color(0xFFFFD34E),
          iconColor: const Color(0xFF102A56),
          onTap: onTravel!,
        ),
      if (onRecurring != null)
        HomeService(
          label: rtl ? 'مشوار الدوام' : 'Commute',
          icon: Icons.repeat_rounded,
          background: const Color(0xFFEAF2FF),
          foreground: const Color(0xFF102A56),
          iconBackground: const Color(0xFF2381E9),
          iconColor: Colors.white,
          onTap: onRecurring!,
        ),
      HomeService(
        label: rtl ? 'الشحن' : 'Freight',
        icon: Icons.local_shipping_rounded,
        background: const Color(0xFFFFF1E6),
        foreground: const Color(0xFF9A3412),
        iconBackground: const Color(0xFFEA580C),
        iconColor: Colors.white,
        soon: onFreight == null,
        onTap: onFreight ?? () => soon(rtl ? 'الشحن' : 'Freight'),
      ),
      HomeService(
        label: rtl ? 'توصيل' : 'Delivery',
        icon: Icons.inventory_2_rounded,
        background: const Color(0xFFE7F8EF),
        foreground: const Color(0xFF166534),
        iconBackground: const Color(0xFF16A34A),
        iconColor: Colors.white,
        soon: onDelivery == null,
        onTap: onDelivery ?? () => soon(rtl ? 'التوصيل' : 'Delivery'),
      ),
      HomeService(
        label: rtl ? 'ونش' : 'Tow',
        icon: Icons.car_crash_rounded,
        background: const Color(0xFFFEF3C7),
        foreground: const Color(0xFF854D0E),
        iconBackground: const Color(0xFFCA8A04),
        iconColor: Colors.white,
        soon: onTow == null,
        onTap: onTow ?? () => soon(rtl ? 'الونش' : 'Tow'),
      ),
    ];
  }
}

class _DestinationSearch extends StatelessWidget {
  const _DestinationSearch({required this.title, required this.label, required this.now, required this.onTap});

  final String title;
  final String label;
  final String now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: isDarkTheme ? const Color(0xFF171B22) : Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 62,
            padding: const EdgeInsetsDirectional.fromSTEB(17, 6, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.withValues(alpha: .08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withValues(alpha: .55),
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // «الآن»: the ride leaves now; a later time is chosen on the next step
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: theme.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, size: 16, color: textColor.withValues(alpha: .7)),
                    const SizedBox(width: 5),
                    Text(now,
                        style: TextStyle(
                            color: textColor.withValues(alpha: .8), fontSize: 13, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.withValues(alpha: .24),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickDestinationCard extends StatelessWidget {
  const _QuickDestinationCard(this.destination);

  final HomeQuickDestination destination;

  @override
  Widget build(BuildContext context) => Material(
        color: isDarkTheme ? const Color(0xFF171B22) : Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: destination.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 76,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: destination.accent.withValues(alpha: .11),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SoftIcon(
                  icon: destination.icon,
                  color: destination.accent,
                  size: 26,
                ),
                const Spacer(),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        destination.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      destination.isConfigured
                          ? Icons.chevron_right_rounded
                          : Icons.add_rounded,
                      size: 17,
                      color: Colors.blueGrey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * .48),
      );
}
