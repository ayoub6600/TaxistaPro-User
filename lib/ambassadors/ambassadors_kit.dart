import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The look of the approved board «سفراء تاكسيستا» (BvtfNm8SRD45adt3KEywVB): Cairo, the blue
/// #0b5cff, white cards on #f3f6fb, and the dark gold page.
class AmbLook {
  static const blue = Color(0xFF0B5CFF);
  static const blueSoft = Color(0xFFDBE6FF);
  static const ground = Color(0xFFF3F6FB);
  static const ink = Color(0xFF0F172A);
  static const sub = Color(0xFF475569);
  static const mute = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const lineStrong = Color(0xFFCBD5E1);
  static const green = Color(0xFF16A34A);
  static const greenText = Color(0xFF15803D);
  static const red = Color(0xFFB91C1C);

  // the gold card on the main page
  static const cream = Color(0xFFFFF7E6);
  static const creamLine = Color(0xFFF5D38A);
  static const gold = Color(0xFFD69E2E);
  static const brown = Color(0xFF78350F);

  // the gold page
  static const night = Color(0xFF1A1408);
  static const nightCard = Color(0xFF241B0B);
  static const nightLine = Color(0xFF4B3A16);
  static const nightGold = Color(0xFF3A2A0B);
  static const goldLight = Color(0xFFFDE68A);
  static const sand = Color(0xFFE7DCC4);
  static const sandDim = Color(0xFFC9B98F);

  static TextStyle t(double size, {FontWeight w = FontWeight.w600, Color color = ink, double? h}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: w, color: color, height: h);

  static BoxDecoration card({double radius = 22}) =>
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius), border: Border.all(color: line));
}

/// A plain «يلا» line with an icon: the board's notes (amber), errors (red) and good news (green).
class AmbNote extends StatelessWidget {
  const AmbNote(this.text, {super.key, this.tone = AmbNoteTone.amber});

  final String text;
  final AmbNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (tone) {
      AmbNoteTone.amber => (AmbLook.cream, AmbLook.creamLine, AmbLook.brown, Icons.info_outline_rounded),
      AmbNoteTone.red => (const Color(0xFFFEF2F2), const Color(0xFFFECACA), AmbLook.red, Icons.error_outline_rounded),
      AmbNoteTone.green => (const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF065F46), Icons.check_circle_outline_rounded),
      AmbNoteTone.night => (AmbLook.nightCard, AmbLook.nightLine, AmbLook.sand, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 19, color: fg)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AmbLook.t(13, color: fg, h: 1.6))),
      ]),
    );
  }
}

enum AmbNoteTone { amber, red, green, night }

/// The crown of «السفير الذهبي» in its gold square.
class AmbCrown extends StatelessWidget {
  const AmbCrown({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AmbLook.gold, borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: size * .56),
      );
}

/// A sheet's frame: the handle, RTL, and room for the keyboard.
class AmbSheet extends StatelessWidget {
  const AmbSheet({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(bottom: inset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AmbLook.lineStrong, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              ...children,
            ]),
          ),
        ),
      ),
    );
  }
}

void ambSay(BuildContext context, String text) => ScaffoldMessenger.maybeOf(context)
  ?..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
    content: Text(text, textDirection: TextDirection.rtl, style: AmbLook.t(14, color: Colors.white)),
    behavior: SnackBarBehavior.floating,
  ));
