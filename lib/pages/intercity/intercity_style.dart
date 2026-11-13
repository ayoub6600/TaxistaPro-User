import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/tr.dart';

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
      b('+', onPlus, tr('زيادة', 'Increase')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (label != null) Text(label!, style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
          Text(value, style: IcStyle.t(big ? 26 : 16, w: FontWeight.w900, c: big ? IcStyle.blue : IcStyle.navy)),
        ]),
      ),
      b('−', onMinus, tr('نقص', 'Decrease')),
    ]);
  }
}

class IcChip extends StatelessWidget {
  const IcChip({super.key, required this.text, required this.selected, required this.onTap, this.fill = false});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  /// it fills its slot (riders 1·2·3·4): the label sits in the middle
  final bool fill;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: fill ? Alignment.center : null,
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

/// a bottom sheet in the booking look: white, round top, grab handle
class IcSheet extends StatelessWidget {
  const IcSheet({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        // a short phone (or a big font) scrolls the sheet instead of cutting it
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: IcStyle.line, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );
}

class IcIconTile extends StatelessWidget {
  const IcIconTile({super.key, required this.icon, required this.background, required this.color, this.size = 56});

  final IconData icon;
  final Color background;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * .32)),
        child: Icon(icon, color: color, size: size * .54),
      );
}

class IcButton extends StatelessWidget {
  const IcButton({super.key, required this.text, required this.onTap, this.ghost = false, this.danger = false, this.busy = false, this.height = 56});

  final String text;
  final VoidCallback? onTap;
  final bool ghost;
  final bool danger;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? const Color(0xffD92D20) : (ghost ? IcStyle.soft : IcStyle.blue);
    final fg = ghost ? (danger ? const Color(0xffD92D20) : IcStyle.navy) : Colors.white;
    return FilledButton(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: ghost && danger ? IcStyle.soft : bg,
        disabledBackgroundColor: bg.withValues(alpha: .45),
        minimumSize: Size.fromHeight(height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: busy
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
          : Text(text, style: IcStyle.t(height < 50 ? 15 : 17, w: FontWeight.w900, c: ghost && danger ? const Color(0xffD92D20) : fg)),
    );
  }
}

/// a big choice card: «سيارة كاملة» / «كرسي في رحلة»
class IcOption extends StatelessWidget {
  const IcOption({
    super.key,
    required this.selected,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xffF5F9FF) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? IcStyle.blue : IcStyle.line, width: selected ? 2 : 1.5),
            ),
            child: Row(children: [
              IcIconTile(icon: icon, background: iconBackground, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: IcStyle.t(17, w: FontWeight.w900)),
                  Text(subtitle, style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
                ]),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? IcStyle.blue : const Color(0xffD5DEEB), width: selected ? 7 : 2)),
              ),
            ]),
          ),
        ),
      );
}

/// a light drawing of the trip (from green to blue) above the sheet
class IcRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xffEDEAE3));
    final road = Path()
      ..moveTo(0, size.height * .62)
      ..cubicTo(size.width * .25, size.height * .5, size.width * .4, size.height * .75, size.width * .6, size.height * .6)
      ..cubicTo(size.width * .8, size.height * .45, size.width * .9, size.height * .4, size.width, size.height * .48);
    canvas.drawPath(road, Paint()..color = const Color(0xffD9C9A8)..style = PaintingStyle.stroke..strokeWidth = 9);
    final a = Offset(size.width * .18, size.height * .78), b = Offset(size.width * .84, size.height * .28);
    final trip = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(size.width * .4, size.height * .7, size.width * .6, size.height * .5, b.dx, b.dy);
    canvas.drawPath(trip, Paint()..color = IcStyle.blue..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    for (final (p, c) in [(a, const Color(0xff16A34A)), (b, IcStyle.blue)]) {
      canvas.drawCircle(p, 11, Paint()..color = Colors.white);
      canvas.drawCircle(p, 8, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// the page shape of the trip screens: the drawing on top, a white sheet with the content below
class IcScaffold extends StatelessWidget {
  const IcScaffold({super.key, required this.title, required this.children, this.mapHeight = 260, this.bottom});

  final String title;
  final List<Widget> children;
  final double mapHeight;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Directionality(
      textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
      child: Scaffold(
        backgroundColor: const Color(0xffEDEAE3),
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, height: mapHeight + 30, child: CustomPaint(painter: IcRoutePainter())),
          Positioned(
            top: top + 8,
            right: 14,
            left: 14,
            child: Row(children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  tooltip: tr('رجوع', 'Return'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: IcStyle.navy),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x1F102A56), blurRadius: 12)]),
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14, w: FontWeight.w800)),
                ),
              ),
            ]),
          ),
          Positioned.fill(
            top: mapHeight,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x1F102A56), blurRadius: 24)]),
              child: Column(children: [
                const SizedBox(height: 10),
                Container(width: 42, height: 5, decoration: BoxDecoration(color: IcStyle.line, borderRadius: BorderRadius.circular(3))),
                Expanded(
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), children: children),
                ),
                if (bottom != null)
                  SafeArea(top: false, minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: bottom!),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
