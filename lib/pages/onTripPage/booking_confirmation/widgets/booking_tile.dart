import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design v2: one booking choice as a tile: a small caption over the current value, with its icon
/// («الدفع / نقدًا», «الوقت / الآن», «كوبونات الخصم / أضف», «التفضيلات / أمتعة»).
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.icon, required this.caption, required this.value, required this.color});

  final IconData icon;
  final String caption;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .06),
          border: Border.all(color: color.withValues(alpha: .14)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(color: color.withValues(alpha: .75), fontSize: 11, fontWeight: FontWeight.w700, height: 1.2)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(color: color, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.25)),
            ]),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: color.withValues(alpha: .7), size: 18),
        ]),
      );
}
