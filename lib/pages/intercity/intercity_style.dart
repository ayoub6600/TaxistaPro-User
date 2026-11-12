import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The rider app's own colours for «سفر بين المدن» (same blue / navy as booking).
class IcStyle {
  static const navy = Color(0xff102A56);
  static const muted = Color(0xff55678A);
  static const blue = Color(0xff0873FF);
  static const soft = Color(0xffF3F7FE);
  static const line = Color(0xffE3E9F2);
  static const chip = Color(0xffDCE8FB);
  static const gold = Color(0xffFFD34E);

  static TextStyle t(double size, {FontWeight w = FontWeight.w700, Color c = navy}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.45);

  static String money(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// − value + in the booking sheet's look
class IcStepper extends StatelessWidget {
  const IcStepper({super.key, required this.value, required this.onMinus, required this.onPlus, this.big = false, this.label});

  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool big;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final size = big ? 42.0 : 32.0;
    Widget b(String s, VoidCallback? f, String semantic) => Semantics(
          button: true,
          label: semantic,
          child: InkWell(
            onTap: f,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: f == null ? IcStyle.soft : IcStyle.chip, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(s, style: IcStyle.t(big ? 22 : 18, w: FontWeight.w900, c: f == null ? IcStyle.muted : IcStyle.blue)),
            ),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      b('+', onPlus, 'زيادة'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (label != null) Text(label!, style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
          Text(value, style: IcStyle.t(big ? 26 : 16, w: FontWeight.w900, c: big ? IcStyle.blue : IcStyle.navy)),
        ]),
      ),
      b('−', onMinus, 'نقص'),
    ]);
  }
}

class IcChip extends StatelessWidget {
  const IcChip({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? IcStyle.blue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? IcStyle.blue : const Color(0xffD5E3F7), width: 1.5),
          ),
          child: Text(text, style: IcStyle.t(13.5, w: FontWeight.w800, c: selected ? Colors.white : IcStyle.navy)),
        ),
      );
}
