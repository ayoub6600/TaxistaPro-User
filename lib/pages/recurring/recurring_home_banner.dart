import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import 'recurring_rides_page.dart';

/// Home: «مشوار الغد» while tomorrow's day of a recurring ride still waits for his answer (the same
/// question as the evening notification, for a phone where its buttons did not show).
class RecurringTomorrowBanner extends StatelessWidget {
  const RecurringTomorrowBanner({super.key, required this.ride, required this.next});
  final Map<String, dynamic> ride;
  final Map<String, dynamic> next;

  @override
  Widget build(BuildContext context) {
    final answered = next['answer'] == 'coming';
    TextStyle t(double s, {FontWeight w = FontWeight.w700, Color c = Colors.white}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: 1.35);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, (1 - v) * -16), child: child)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => appNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => RecurringRidePage(uuid: '${ride['id']}', initial: ride, focusOccurrence: next['id'] as int?))),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xff0B2A5B), Color(0xff1556B8)], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xff0B2A5B).withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.repeat_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text('${ride['label']} · غدًا ${next['time']}', style: t(14.5, w: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(answered ? '✅ أكدت · ${next['label']}' : 'هل ما زلت تحتاجه؟ اضغط للتأكيد أو التخطي', style: t(12.5, w: FontWeight.w600, c: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.white),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
