import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_brand.dart';

/// A bank card drawn to ISO ID-1 proportions (85.60 x 53.98 mm). Shows only
/// what it is given: callers pass a masked number unless the customer is
/// typing it in themselves.
class CardVisual extends StatelessWidget {
  const CardVisual({
    super.key,
    required this.brand,
    required this.numberText,
    required this.holderText,
    required this.expiryText,
    this.title,
    this.highlight,
    this.dimmed = false,
    this.badge,
  });

  final CardBrand brand;

  /// Already grouped (and masked where needed).
  final String numberText;
  final String holderText;
  final String expiryText;

  /// Nickname / bank name in the top corner.
  final String? title;

  /// A field to emphasise (e.g. the one being scanned or edited).
  final CardVisualField? highlight;
  final bool dimmed;

  /// A small chip in the top corner ("افتراضية", "منتهية").
  final Widget? badge;

  static const double aspect = 85.60 / 53.98;

  /// Taxista blue: local cards are drawn in the app's own colour.
  static const Color taxistaBlue = Color(0xFF0873FF);

  static List<Color> gradientFor(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa:
        return const [Color(0xFF1A1F71), Color(0xFF2E3DA8), Color(0xFF0E1247)];
      case CardBrand.mastercard:
        return const [Color(0xFF1C1C1E), Color(0xFF3A3A3C), Color(0xFF111113)];
      case CardBrand.amex:
        return const [Color(0xFF0F6E8C), Color(0xFF2E9CC0), Color(0xFF0A4F66)];
      case CardBrand.meeza:
        return const [Color(0xFF0B5D4B), Color(0xFF16896D), Color(0xFF07402F)];
      case CardBrand.numo:
        return const [Color(0xFF0B2A5B), Color(0xFF1D4E9E), Color(0xFF071B3D)];
      case CardBrand.local:
        return const [taxistaBlue, Color(0xFF4C9BFF), Color(0xFF0450B8)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final u = w / 340; // design unit: the card was drawn 340 wide
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.55 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * u),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientFor(brand)),
              boxShadow: [BoxShadow(color: gradientFor(brand).first.withValues(alpha: 0.35), blurRadius: 18 * u, offset: Offset(0, 8 * u))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * u),
              child: Stack(children: [
                // Soft light arcs, like a printed card face.
                Positioned(right: -60 * u, top: -70 * u, child: _arc(200 * u, 0.10)),
                Positioned(left: -90 * u, bottom: -120 * u, child: _arc(260 * u, 0.07)),
                if (w < 160)
                  // Thumbnail: chip, last digits and the network mark only.
                  Padding(
                    padding: EdgeInsets.all(8 * w / 120),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _Chip(size: 18 * w / 120),
                        const Spacer(),
                        Row(children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(numberText, maxLines: 1, style: _mono(11 * w / 120)),
                            ),
                          ),
                          _BrandMark(brand: brand, height: 13 * w / 120),
                        ]),
                      ]),
                    ),
                  )
                else
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * u, 16 * u, 20 * u, 16 * u),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13 * u, FontWeight.w700, 0.9)),
                        ),
                        if (badge != null) badge!,
                      ]),
                      SizedBox(height: 14 * u),
                      Row(children: [
                        _Chip(size: 40 * u),
                        SizedBox(width: 10 * u),
                        Icon(Icons.contactless_rounded, color: Colors.white.withValues(alpha: 0.75), size: 24 * u),
                      ]),
                      const Spacer(),
                      _field(
                        CardVisualField.number,
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(numberText, maxLines: 1, style: _mono(22 * u)),
                        ),
                        u,
                      ),
                      SizedBox(height: 12 * u),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(
                          child: _field(
                            CardVisualField.holder,
                            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              Text('CARD HOLDER', style: _t(8 * u, FontWeight.w700, 0.6, spacing: 1.2)),
                              SizedBox(height: 2 * u),
                              Text(holderText.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13 * u, FontWeight.w700, 1, spacing: 0.8)),
                            ]),
                            u,
                          ),
                        ),
                        SizedBox(width: 12 * u),
                        _field(
                          CardVisualField.expiry,
                          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text('VALID THRU', style: _t(8 * u, FontWeight.w700, 0.6, spacing: 1.2)),
                            SizedBox(height: 2 * u),
                            Text(expiryText, style: _mono(13 * u)),
                          ]),
                          u,
                        ),
                        SizedBox(width: 12 * u),
                        _BrandMark(brand: brand, height: 26 * u),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _field(CardVisualField field, Widget child, double u) {
    final on = highlight == field;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 6 * u, vertical: 3 * u),
      decoration: BoxDecoration(
        color: on ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(8 * u),
        border: Border.all(color: on ? Colors.white.withValues(alpha: 0.7) : Colors.transparent, width: 1.2),
      ),
      child: child,
    );
  }

  static Widget _arc(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );

  static TextStyle _t(double size, FontWeight weight, double opacity, {double spacing = 0}) => TextStyle(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        color: Colors.white.withValues(alpha: opacity),
      );

  static TextStyle _mono(double size) => TextStyle(
        fontFamily: 'Courier',
        fontFamilyFallback: const ['Menlo', 'monospace'],
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.12,
        color: Colors.white,
        shadows: const [Shadow(color: Color(0x55000000), offset: Offset(0, 1), blurRadius: 2)],
      );
}

enum CardVisualField { number, holder, expiry }

class _Chip extends StatelessWidget {
  const _Chip({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.16),
        gradient: const LinearGradient(colors: [Color(0xFFF7E08B), Color(0xFFD4AF37), Color(0xFFF2D675)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: CustomPaint(painter: _ChipLines()),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x66704A00)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), p);
    canvas.drawLine(Offset(size.width * 0.67, 0), Offset(size.width * 0.67, size.height), p);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.3, height: size.height * 0.4), const Radius.circular(3)), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The network mark, drawn (no logo files): VISA wordmark, Mastercard circles, Numo, Meeza.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.brand, required this.height});
  final CardBrand brand;
  final double height;

  @override
  Widget build(BuildContext context) {
    switch (brand) {
      case CardBrand.mastercard:
        final d = height;
        return SizedBox(
          width: d * 1.6,
          height: d,
          child: Stack(children: [
            Positioned(left: 0, child: _dot(d, const Color(0xFFEB001B))),
            Positioned(right: 0, child: _dot(d, const Color(0xFFF79E1B).withValues(alpha: 0.92))),
          ]),
        );
      case CardBrand.visa:
        return Text('VISA', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: height * 0.9, color: Colors.white, letterSpacing: 1));
      case CardBrand.amex:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: height * 0.25, vertical: height * 0.08),
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.4), borderRadius: BorderRadius.circular(4)),
          child: Text('AMEX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: height * 0.5, color: Colors.white)),
        );
      case CardBrand.meeza:
        return Text('meeza', style: TextStyle(fontWeight: FontWeight.w900, fontSize: height * 0.68, color: Colors.white, letterSpacing: 0.5));
      case CardBrand.numo:
        return Text('NUMO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: height * 0.6, color: Colors.white, letterSpacing: 1.5));
      case CardBrand.local:
        return Icon(Icons.account_balance_rounded, color: Colors.white.withValues(alpha: 0.85), size: height);
    }
  }

  Widget _dot(double d, Color c) => Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

/// `4111 11•• •••• 1111`: enough for the customer to recognise their card on
/// the scanner screen, never the whole number.
String maskForPreview(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final grouped = groupCardNumber(d);
  if (d.length < 10) return grouped;
  final keepStart = math.min(6, d.length - 4);
  final out = StringBuffer();
  var i = 0;
  for (final ch in grouped.split('')) {
    if (ch == ' ') {
      out.write(' ');
      continue;
    }
    out.write(i < keepStart || i >= d.length - 4 ? ch : '•');
    i++;
  }
  return out.toString();
}
