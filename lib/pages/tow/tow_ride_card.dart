import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/tr.dart';

/// On the owner's ride screen: what was asked (flatbed or not, what happened, which car, where it
/// goes), what to do now, and — once the truck is there — how many of the four photos it took.
class TowRideCard extends StatelessWidget {
  const TowRideCard({super.key, required this.tow, required this.arrived, required this.started});

  final Map tow;
  final bool arrived;
  final bool started;

  static Widget? of(Map ride) {
    final t = ride['tow'];
    if (t is! Map) return null;
    return TowRideCard(tow: t, arrived: ride['is_driver_arrived'] == 1 || ride['is_driver_arrived'] == true, started: ride['is_trip_start'] == 1 || ride['is_trip_start'] == true);
  }

  TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = const Color(0xff102A56)}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    final photos = (tow['before_sides'] as List?)?.length ?? 0;
    final workshop = tow['workshop'] is Map ? '${(tow['workshop'] as Map)['name'] ?? ''}' : '';
    final emergency = '${tow['emergency_text'] ?? ''}';
    final now = started
        ? tr('السيارة مرفوعة وفي الطريق${workshop.isEmpty ? '' : ' لـ$workshop'}.', 'The car is lifted and on its way${workshop.isEmpty ? '' : ' to $workshop'}.')
        : arrived
            ? tr('الكابتن عند السيارة يصوّرها قبل الرفع ($photos من 4).', 'The captain is at the car, photographing it before lifting ($photos of 4).')
            : tr('خليك قريب من السيارة. الكابتن يصوّرها من 4 جهات قبل ما يرفعها.', 'Stay near the car. The captain photographs it from 4 sides before lifting it.');
    return Container(
      key: const ValueKey('tow-ride-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffFEF7E6), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffFDE3A7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('🛻', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(child: Text(tr('ساحبة · ${tow['kind_label'] ?? ''}', 'Tow truck${tow['needs_flatbed'] == true ? ' · Flatbed' : ''}'), style: _t(15, w: FontWeight.w900))),
        ]),
        Text([tow['condition_label'], tow['car_label'], if (workshop.isNotEmpty) '← $workshop'].whereType<Object>().join(' · '),
            style: _t(12.5, w: FontWeight.w600, c: const Color(0xff55678A))),
        const SizedBox(height: 6),
        Text(now, style: _t(13, w: FontWeight.w800, c: const Color(0xff9A6700))),
        if (emergency.isNotEmpty && !started) ...[
          const SizedBox(height: 6),
          Text('⚠️ $emergency', style: _t(12.5, w: FontWeight.w800, c: const Color(0xffB42318))),
        ],
      ]),
    );
  }
}
