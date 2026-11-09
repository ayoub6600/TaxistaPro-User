import 'package:flutter/material.dart';

const giftSky = Color(0xFF38BDF8);
const giftSkyDeep = Color(0xFF0EA5E9);
const giftInk = Color(0xFF0B3A5B);
const giftBlue = Color(0xFF0284C7);
const giftPale = Color(0xFFE4F5FF);

/// The sky-blue gift box, drawn so it stays sharp at any size and costs no image.
class GiftBox extends StatelessWidget {
  const GiftBox({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _GiftBoxPainter());
}

class _GiftBoxPainter extends CustomPainter {
  const _GiftBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);
    final fill = Paint()..isAntiAlias = true;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = giftSkyDeep;
    void loop(double side) {
      final p = Path()
        ..moveTo(24, 13)
        ..cubicTo(24 + side * 3, 6, 24 + side * 13, 4, 24 + side * 14.5, 9.5)
        ..cubicTo(24 + side * 15.7, 14, 24 + side * 7, 15, 24, 13);
      canvas.drawPath(p, fill..color = Colors.white);
      canvas.drawPath(p, line);
    }

    loop(-1);
    loop(1);
    canvas.drawRRect(RRect.fromLTRBR(9, 22, 39, 43, const Radius.circular(4)), fill..color = giftSky);
    canvas.drawRRect(RRect.fromLTRBR(6, 13, 42, 24, const Radius.circular(3.5)), fill..color = giftSkyDeep);
    canvas.drawRect(const Rect.fromLTRB(21, 13, 27, 43), fill..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
