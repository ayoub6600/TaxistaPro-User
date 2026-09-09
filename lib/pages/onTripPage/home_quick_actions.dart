import 'package:flutter/material.dart';

import '../../styles/styles.dart';

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
  });

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
          Row(
            children: [
              for (var index = 0; index < destinations.length; index++) ...[
                if (index > 0) SizedBox(width: compact ? 7 : 9),
                Expanded(child: _QuickDestinationCard(destinations[index])),
              ],
            ],
          ),
          if (showRideWithoutDestination) ...[
            SizedBox(height: compact ? 7 : 9),
            _RideWithoutDestinationAction(
              label: rtl ? 'رحلة بدون وجهة' : 'Ride without destination',
              onTap: onRideWithoutDestination,
            ),
          ],
          SizedBox(height: compact ? 7 : 9),
          _DestinationSearch(
            label:
                rtl ? 'ابحث عن مكان أو عنوان' : 'Search for a place or address',
            onTap: onChooseDestination,
          ),
        ],
      ),
    );
  }
}

class _DestinationSearch extends StatelessWidget {
  const _DestinationSearch({required this.label, required this.onTap});

  final String label;
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
            height: 58,
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
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor.withValues(alpha: .64),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            height: 94,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
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
                  size: 32,
                ),
                const Spacer(),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
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

class _RideWithoutDestinationAction extends StatelessWidget {
  const _RideWithoutDestinationAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: isDarkTheme ? const Color(0xFF171B22) : Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.withValues(alpha: .14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: theme.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.route_rounded, color: theme, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.withValues(alpha: .72),
                  size: 15,
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
