import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/recurring_api.dart';

const _ink = Color(0xff17233A);
const _muted = Color(0xff6B7280);
const _blue = Color(0xff0873FF);
const _line = Color(0xffE3E8F0);
const _soft = Color(0xffEAF2FF);

TextStyle _t(double size, {FontWeight w = FontWeight.w700, Color c = _ink}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

void startRecurringBooking(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  RecurringApi.startNew.value++;
}

/// The page with nothing on it yet: what a repeat is, and the way to make one.
class RecurringStartCard extends StatelessWidget {
  const RecurringStartCard({super.key});

  Widget _step(int n, String text) => Row(children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _soft, shape: BoxShape.circle),
          child: Text('$n', style: _t(14, w: FontWeight.w900, c: _blue)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: _t(15))),
      ]);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _line)),
          child: Column(children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.repeat_rounded, size: 36, color: _blue),
            ),
            const SizedBox(height: 8),
            Text('مشوار تعمله كل يوم؟', style: _t(20, w: FontWeight.w900)),
            Text('حدد وجهتك وموعدك مرة واحدة، ونحجزه لك في الأيام اللي تختارها.', textAlign: TextAlign.center, style: _t(14.5, w: FontWeight.w600, c: _muted)),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)),
          child: Column(children: [
            _step(1, 'اختر من وين وإلى وين'),
            const SizedBox(height: 12),
            _step(2, 'حدد الموعد وفعّل «كرر هذا المشوار»'),
            const SizedBox(height: 12),
            _step(3, 'نذكرك قبلها، وتتخطى أي يوم تبيه'),
          ]),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => startRecurringBooking(context),
          style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
          child: Text('جدول مشواري', style: _t(18, w: FontWeight.w900, c: Colors.white)),
        ),
      ]);
}

class RecurringAddButton extends StatelessWidget {
  const RecurringAddButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: () => startRecurringBooking(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xff9DBDF0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text('+ أضف مشوارًا متكررًا', style: _t(16, w: FontWeight.w900, c: _blue)),
      );
}

/// Saturday to Friday, the days of this schedule filled.
class RecurringWeekRow extends StatelessWidget {
  const RecurringWeekRow({super.key, required this.days, required this.active});

  final List days;
  final bool active;

  static const _letters = {6: 'س', 0: 'ح', 1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج'};

  @override
  Widget build(BuildContext context) {
    final on = days.map((d) => int.tryParse('$d')).toSet();
    return Row(children: [
      for (final e in _letters.entries) ...[
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: on.contains(e.key) ? (active ? Colors.white : _blue) : (active ? Colors.white.withValues(alpha: .14) : const Color(0xffEEF1F6)),
            ),
            child: Text(e.value, style: _t(13.5, w: FontWeight.w900, c: on.contains(e.key) ? (active ? const Color(0xff102A56) : Colors.white) : (active ? Colors.white70 : _muted))),
          ),
        ),
        if (e.key != 5) const SizedBox(width: 5),
      ],
    ]);
  }
}
