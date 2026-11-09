import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gift_box.dart';

/// The paper burst around the box. `t` runs 0 to 1 over the burst; nothing is drawn outside it.
class GiftBurst extends StatelessWidget {
  const GiftBurst({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(size: Size.zero, painter: _BurstPainter(t)));
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t);

  final double t;

  static const _colors = [giftSkyDeep, giftSky, Color(0xFF7DD3FC), Colors.white, Color(0xFFFBBF24), giftBlue];
  static const _count = 18;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final eased = Curves.easeOutCubic.transform(t);
    final fade = t < .7 ? 1.0 : (1 - t) / .3;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = giftSky.withValues(alpha: (1 - eased) * .9);
    canvas.drawCircle(Offset.zero, 20 + 90 * eased, ring);

    final piece = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = i / _count * 2 * math.pi - 1.2;
      final reach = 70 + (i * 37) % 75;
      final x = math.cos(angle) * reach * eased;
      final y = math.sin(angle) * reach * eased + 40 * t * t - 14 * eased;
      final side = 6.0 + (i * 5) % 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i * 77) * math.pi / 180 * t);
      piece.color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: side, height: side + (i % 3) * 3), const Radius.circular(2)),
        piece,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
