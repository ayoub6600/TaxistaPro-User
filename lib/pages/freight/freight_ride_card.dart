import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// On the ride the passenger follows: what is being moved, the vehicle, workers, the floors at each
/// end, the photos he sent, and what happens now.
class FreightRideCard extends StatelessWidget {
  const FreightRideCard({super.key, required this.freight, required this.arrived, required this.started});

  final Map freight;
  final bool arrived;
  final bool started;

  static Widget? of(Map ride) {
    final f = ride['freight'];
    if (f is! Map) return null;
    return FreightRideCard(
        freight: f, arrived: ride['is_driver_arrived'] == 1 || ride['is_driver_arrived'] == true, started: ride['is_trip_start'] == 1 || ride['is_trip_start'] == true);
  }

  static const icons = {'pickup': '🛻', 'van': '🚐', 'truck': '🚚'};

  TextStyle _t(double s, {FontWeight w = FontWeight.w700, Color c = const Color(0xff102A56)}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    final f = freight;
    final workers = (f['workers'] as num?)?.toInt() ?? 0;
    final free = (f['free_loading_minutes'] as num?)?.toInt() ?? 20;
    final photos = [for (final p in (f['photos'] as List? ?? const [])) '$p'];
    final items = '${f['items'] ?? ''}';
    final now = started
        ? 'الحمولة في الطريق.'
        : arrived
            ? 'صاحب السيارة وصل. أول $free دقيقة تحميل مجانية.'
            : 'صاحب السيارة جاي. جهّز الحمولة قرب الباب لو تقدر.';
    return Container(
      key: const ValueKey('freight-ride-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffF5F9FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffD6E4FA))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(icons['${f['class']}'] ?? '🚚', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(child: Text('شحن · ${f['category_label'] ?? ''} · ${f['class_label'] ?? ''}', style: _t(15, w: FontWeight.w900))),
        ]),
        if (items.isNotEmpty) Text('«$items»', style: _t(12.5, w: FontWeight.w700, c: const Color(0xff55678A))),
        Text(
            [
              workers == 0 ? 'بدون عمال' : (workers == 1 ? 'عامل واحد' : '$workers عمال'),
              'التحميل: ${f['pick_floor_label'] ?? 'أرضي'}',
              'التنزيل: ${f['drop_floor_label'] ?? 'أرضي'}',
            ].join(' · '),
            style: _t(12.5, w: FontWeight.w600, c: const Color(0xff55678A))),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final p in photos)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(p, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xffE6EDF8))),
                  ),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 6),
        Text(now, style: _t(13, w: FontWeight.w800, c: const Color(0xff2381E9))),
      ]),
    );
  }
}
