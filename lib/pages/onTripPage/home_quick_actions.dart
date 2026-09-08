import 'package:flutter/material.dart';

import '../../styles/styles.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.rtl,
    required this.onChooseDestination,
    required this.onRideWithoutDestination,
    required this.showRideWithoutDestination,
  });

  final bool rtl;
  final VoidCallback onChooseDestination;
  final VoidCallback onRideWithoutDestination;
  final bool showRideWithoutDestination;

  String _copy(String ar, String en) => rtl ? ar : en;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _copy('إلى أين نوصّلك؟', 'Where are you going?'),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _copy('اختر وجهتك وسنعرض لك أقرب سيارة.',
                  'Choose a destination and we will find a nearby ride.'),
              style: TextStyle(color: Colors.blueGrey.shade600, height: 1.35),
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: onChooseDestination,
                borderRadius: BorderRadius.circular(17),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.search_rounded, color: theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _copy('ابحث عن مكان أو عنوان',
                            'Search for a place or address'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 17, color: Colors.blueGrey.shade400),
                  ]),
                ),
              ),
            ),
            if (showRideWithoutDestination) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRideWithoutDestination,
                icon: const Icon(Icons.route_rounded, size: 20),
                label:
                    Text(_copy('رحلة بدون وجهة', 'Ride without destination')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: theme.withValues(alpha: .22)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ],
        ),
      );
}
