import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _ink = Color(0xff102A56);
const _muted = Color(0xff55678A);
const _blue = Color(0xff0873FF);

TextStyle _t(double size, {FontWeight w = FontWeight.w700, Color c = _ink}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

/// «مشوارك صار متكرر»: what was just set up, right after the ride is booked.
Future<void> showRecurringDoneSheet(BuildContext context, {required String days, required String time, required DateTime first}) {
  final today = DateTime.now();
  final isTomorrow = DateUtils.dateOnly(first).difference(DateUtils.dateOnly(today)).inDays == 1;
  final firstLine = '${isTomorrow ? 'غدًا' : '${first.day}/${first.month}'}، $time';
  Widget row(String a, String b) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: _t(14.5, c: _muted)), Text(b, style: _t(14.5))]);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.of(ctx).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: const Color(0xffE6F6EE), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.check_rounded, color: Color(0xff047857), size: 34),
            ),
          ),
          const SizedBox(height: 10),
          Text('مشوارك صار متكرر', textAlign: TextAlign.center, style: _t(21, w: FontWeight.w900)),
          Text('$days · $time', textAlign: TextAlign.center, style: _t(14.5, w: FontWeight.w600, c: _muted)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xffF3F7FE), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              row('أول رحلة', firstLine),
              const SizedBox(height: 8),
              row('التذكير', 'مساء اليوم السابق'),
              const SizedBox(height: 8),
              row('السائق', 'نبحث عن متاح كل يوم'),
            ]),
          ),
          const SizedBox(height: 12),
          Text('تقدر تتخطى أي يوم أو توقف التكرار من «رحلاتي المتكررة».', textAlign: TextAlign.center, style: _t(14, w: FontWeight.w600, c: _muted)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('تمام', style: _t(18, w: FontWeight.w900, c: Colors.white)),
          ),
        ]),
      ),
    ),
  );
}
