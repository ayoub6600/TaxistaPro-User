import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/controller.dart';
import '../core/theme.dart';

/// Compact ride status shown above the enlarged game: status / driver / ETA / call / chat / back to trip.
class TripBar extends StatelessWidget {
  const TripBar({super.key, required this.status, required this.onBackToTrip, this.onCollapse});
  final ValueListenable<RideGameStatus> status;
  final VoidCallback onBackToTrip;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RideGameStatus>(
      valueListenable: status,
      builder: (context, s, _) {
        final near = s.phase == 'approaching';
        final searching = s.phase == 'searching';
        final title = searching
            ? 'نبحثو لك على سائق'
            : near
                ? 'السائق قرّب يوصل'
                : s.phase == 'arrived'
                    ? 'وصل السائق'
                    : (s.driverName ?? 'السائق في الطريق');
        final sub = searching
            ? 'أول ما سائق يقبل نعلموك'
            : [if (s.etaText != null) (near ? 'خلال ${s.etaText}' : 'يوصلك خلال ${s.etaText}'), if (s.carText != null) s.carText!].join(' · ');
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: near ? Border.all(color: GamesTheme.brand, width: 2.5) : null,
              boxShadow: const [BoxShadow(color: Color(0x33102A56), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: searching ? null : const LinearGradient(colors: [GamesTheme.navy, GamesTheme.navy2]),
                  color: searching ? GamesTheme.brandSoft : null,
                ),
                child: searching
                    ? const Icon(Icons.radar_rounded, color: GamesTheme.brand, size: 22)
                    : Text((s.driverName ?? 'س').characters.first, style: GamesTheme.text(15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GamesTheme.text(14, color: GamesTheme.navy)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GamesTheme.text(11.5, weight: FontWeight.w700, color: near ? GamesTheme.brand : const Color(0xFF7B8BA8))),
                ]),
              ),
              if (s.onCall != null) _Square(icon: Icons.call_rounded, label: 'اتصال بالسائق', onTap: s.onCall!),
              if (s.onChat != null) _Square(icon: Icons.chat_bubble_outline_rounded, label: 'رسالة للسائق', onTap: s.onChat!),
              const SizedBox(width: 4),
              Material(
                color: GamesTheme.brand,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onBackToTrip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(searching ? 'الطلب' : 'الرحلة', style: GamesTheme.text(12.5)),
                    ]),
                  ),
                ),
              ),
              if (onCollapse != null) ...[
                const SizedBox(width: 4),
                _Square(icon: Icons.close_fullscreen_rounded, label: 'صغّر اللعبة', onTap: onCollapse!),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Semantics(
          button: true,
          label: label,
          child: Material(
            color: GamesTheme.brandSoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 19, color: GamesTheme.brand)),
            ),
          ),
        ),
      );
}
