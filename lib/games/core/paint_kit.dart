import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'theme.dart';

const double tau = pi * 2;

double clampD(double v, double a, double b) => v < a ? a : (v > b ? b : v);
double lerpD(double a, double b, double t) => a + (b - a) * t;
double smooth(double t) {
  final x = clampD(t, 0, 1);
  return (1 - cos(pi * x)) / 2;
}

/// Shared drawing helpers (all drawn in code, no image assets).
class Kit {
  Kit._();

  static void glow(Canvas c, Offset o, double r, Color col, [double a = 1]) {
    if (r <= 0.5 || a <= 0.01) return;
    final k = clampD(a, 0, 1);
    final p = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(o, r, [
        col.withValues(alpha: k),
        col.withValues(alpha: 0.42 * k),
        col.withValues(alpha: 0),
      ], const [0, 0.3, 1]);
    c.drawCircle(o, r, p);
  }

  /// Elliptical glow (light pools on wet asphalt).
  static void pool(Canvas c, Offset o, double rx, double ry, Color col, double a) {
    if (rx <= 0 || ry <= 0) return;
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(1, ry / rx);
    glow(c, Offset.zero, rx, col, a);
    c.restore();
  }

  /// Headlight cone starting at [o] pointing along [ang].
  static void beam(Canvas c, Offset o, double ang, double length, double spread, [double a = .38]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(ang);
    final p = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(Offset.zero, Offset(length, 0), [
        const Color(0xFFD2E6FF).withValues(alpha: a),
        const Color(0xFFD2E6FF).withValues(alpha: 0),
      ]);
    final path = Path()
      ..moveTo(0, -spread * .18)
      ..lineTo(length, -spread)
      ..lineTo(length, spread)
      ..lineTo(0, spread * .18)
      ..close();
    c.drawPath(path, p);
    c.restore();
  }

  static RRect _rr(double x, double y, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

  /// Top-down car. Facing +x when [ang] = 0.
  static void car(Canvas c, Offset o, double ang, double len, Color body) {
    final w = len * .54;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(ang);
    c.drawRRect(_rr(-len / 2 + len * .05, -w / 2 + w * .12, len, w, w * .4),
        Paint()..color = const Color(0x66000000));
    c.drawRRect(
        _rr(-len / 2, -w / 2, len, w, w * .4),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, -w / 2), Offset(0, w / 2), [
            Color.lerp(body, Colors.white, .32)!,
            body,
            Color.lerp(body, Colors.black, .3)!,
          ], const [0, .5, 1]));
    final glass = Paint()..color = const Color(0xEB0A1836);
    c.drawRRect(_rr(len * .1, -w * .36, len * .17, w * .72, len * .05), glass);
    c.drawRRect(_rr(-len * .38, -w * .32, len * .1, w * .64, len * .04), glass);
    c.drawRRect(_rr(-len * .26, -w * .38, len * .35, w * .76, len * .06),
        Paint()..color = Color.lerp(body, Colors.white, .14)!);
    c.drawRRect(_rr(-len * .14, -w * .15, len * .12, w * .3, len * .03),
        Paint()..color = Colors.white);
    final hl = Paint()..color = const Color(0xFFF4FAFF);
    c.drawRRect(_rr(len * .44, -w * .38, len * .05, w * .2, len * .02), hl);
    c.drawRRect(_rr(len * .44, w * .18, len * .05, w * .2, len * .02), hl);
    final tl = Paint()..color = GamesTheme.tail;
    c.drawRRect(_rr(-len * .5, -w * .38, len * .045, w * .18, len * .02), tl);
    c.drawRRect(_rr(-len * .5, w * .2, len * .045, w * .18, len * .02), tl);
    c.restore();
  }

  /// Side-view taxi (for stacking bags). [o] is the bottom-centre.
  static void carSide(Canvas c, Offset o, double len, Color body) {
    final h = len * .26;
    final body1 = Paint()
      ..shader = ui.Gradient.linear(Offset(0, o.dy - h), Offset(0, o.dy), [
        Color.lerp(body, Colors.white, .25)!,
        Color.lerp(body, Colors.black, .2)!,
      ]);
    c.drawRRect(_rr(o.dx - len / 2, o.dy - h - len * .06, len, h, h * .35), body1);
    final cab = Path()
      ..moveTo(o.dx - len * .3, o.dy - h - len * .05)
      ..lineTo(o.dx - len * .2, o.dy - h - len * .2)
      ..lineTo(o.dx + len * .22, o.dy - h - len * .2)
      ..lineTo(o.dx + len * .34, o.dy - h - len * .05)
      ..close();
    c.drawPath(cab, Paint()..color = Color.lerp(body, Colors.white, .1)!);
    final win = Paint()..color = const Color(0xEB0A1836);
    c.drawRRect(_rr(o.dx - len * .19, o.dy - h - len * .17, len * .17, len * .1, 2), win);
    c.drawRRect(_rr(o.dx + .01 * len, o.dy - h - len * .17, len * .19, len * .1, 2), win);
    final wheel = Paint()..color = const Color(0xFF0A1226);
    c.drawCircle(Offset(o.dx - len * .3, o.dy - len * .05), len * .085, wheel);
    c.drawCircle(Offset(o.dx + len * .3, o.dy - len * .05), len * .085, wheel);
    final hub = Paint()..color = const Color(0xFF8C98AD);
    c.drawCircle(Offset(o.dx - len * .3, o.dy - len * .05), len * .035, hub);
    c.drawCircle(Offset(o.dx + len * .3, o.dy - len * .05), len * .035, hub);
    // roof rack
    final rack = Paint()
      ..color = const Color(0xFF8C98AD)
      ..strokeWidth = max(1, len * .015);
    c.drawLine(Offset(o.dx - len * .22, o.dy - h - len * .22),
        Offset(o.dx + len * .24, o.dy - h - len * .22), rack);
  }

  static void palmTop(Canvas c, Offset o, double r, [Color col = const Color(0xFF1F5A4A)]) {
    c.save();
    c.translate(o.dx, o.dy);
    for (var i = 0; i < 7; i++) {
      c.rotate(tau / 7);
      c.drawOval(Rect.fromCenter(center: Offset(r * .5, 0), width: r * 1.1, height: r * .34),
          Paint()..color = i.isOdd ? col : Color.lerp(col, Colors.white, .12)!);
    }
    c.drawCircle(Offset.zero, r * .14, Paint()..color = const Color(0xFF3B2F22));
    c.restore();
  }

  static void palmSide(Canvas c, double x, double base, double h, Color col) {
    final stroke = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, h * .07);
    final trunk = Path()
      ..moveTo(x, base)
      ..quadraticBezierTo(x + h * .12, base - h * .5, x + h * .05, base - h);
    c.drawPath(trunk, stroke);
    final fill = Paint()..color = col;
    final tx = x + h * .05, ty = base - h;
    for (var i = 0; i < 6; i++) {
      final a = -pi * .95 + i * pi * .38;
      c.save();
      c.translate(tx + cos(a) * h * .22, ty + sin(a) * h * .12 + h * .04);
      c.rotate(a);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: h * .48, height: h * .1), fill);
      c.restore();
    }
  }

  /// Simple glyphs used by several games. Kinds: house, mosque, hosp, market, school, sea, palm, car, star, bag.
  static void icon(Canvas c, String k, Offset o, double s, Color col) {
    final p = Paint()..color = col;
    final st = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.save();
    c.translate(o.dx, o.dy);
    switch (k) {
      case 'house':
        c.drawPath(
            Path()
              ..moveTo(-s * .5, 0)
              ..lineTo(0, -s * .48)
              ..lineTo(s * .5, 0)
              ..lineTo(s * .36, 0)
              ..lineTo(s * .36, s * .42)
              ..lineTo(-s * .36, s * .42)
              ..lineTo(-s * .36, 0)
              ..close(),
            p);
      case 'mosque':
        c.drawArc(Rect.fromCircle(center: Offset(0, s * .05), radius: s * .32), pi, pi, true, p);
        c.drawRect(Rect.fromLTWH(-s * .36, s * .05, s * .72, s * .36), p);
        c.drawRect(Rect.fromLTWH(s * .4, -s * .42, s * .1, s * .84), p);
      case 'hosp':
        c.drawRect(Rect.fromLTWH(-s * .13, -s * .42, s * .26, s * .84), p);
        c.drawRect(Rect.fromLTWH(-s * .42, -s * .13, s * .84, s * .26), p);
      case 'market':
        c.drawRRect(_rr(-s * .38, -s * .1, s * .76, s * .52, s * .08), p);
        c.drawArc(Rect.fromCircle(center: Offset(0, -s * .1), radius: s * .2), pi, pi, false, st);
      case 'school':
        c.drawPath(
            Path()
              ..moveTo(0, -s * .3)
              ..lineTo(-s * .46, -s * .4)
              ..lineTo(-s * .46, s * .34)
              ..lineTo(0, s * .42)
              ..lineTo(s * .46, s * .34)
              ..lineTo(s * .46, -s * .4)
              ..close(),
            p);
      case 'sea':
        for (var i = 0; i < 3; i++) {
          final path = Path();
          for (var j = 0; j <= 8; j++) {
            final x = -s * .45 + j * s * .1125, y = -s * .25 + i * s * .25 + sin(j * 1.3) * s * .07;
            j == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          c.drawPath(path, st);
        }
      case 'palm':
        c.restore();
        palmTop(c, o, s * .55, col);
        return;
      case 'car':
        c.restore();
        car(c, o, 0, s * 1.1, col);
        return;
      case 'star':
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? s * .5 : s * .22, a = -pi / 2 + i * pi / 5;
          i == 0 ? path.moveTo(cos(a) * r, sin(a) * r) : path.lineTo(cos(a) * r, sin(a) * r);
        }
        c.drawPath(path..close(), p);
      case 'bag':
        c.drawRRect(_rr(-s * .42, -s * .22, s * .84, s * .6, s * .1), p);
        c.drawRRect(_rr(-s * .16, -s * .4, s * .32, s * .22, s * .06), st);
      default:
        c.drawCircle(Offset.zero, s * .4, p);
    }
    c.restore();
  }

  static void pin(Canvas c, Offset o, double s, Color col) {
    final path = Path()
      ..addArc(Rect.fromCircle(center: Offset(o.dx, o.dy - s * .9), radius: s * .55), pi * .8, pi * 1.4)
      ..lineTo(o.dx, o.dy)
      ..close();
    c.drawPath(path, Paint()..color = Colors.white);
    c.drawCircle(Offset(o.dx, o.dy - s * .92), s * .24, Paint()..color = col);
  }

  static void pill(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
    c.drawRRect(rr, Paint()..color = const Color(0x9E061028));
    c.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x1FFFFFFF));
  }

  static final Map<String, TextPainter> _tp = {};

  /// Canvas text (Arabic, RTL). [at] is the centre unless [align] says otherwise.
  static void text(Canvas c, String s, Offset at, double size,
      {Color color = Colors.white, FontWeight weight = FontWeight.w800, TextAlign align = TextAlign.center}) {
    final key = '$s|${size.toStringAsFixed(1)}|${color.toARGB32()}|${weight.value}';
    var tp = _tp[key];
    if (tp == null) {
      if (_tp.length > 160) _tp.clear();
      tp = TextPainter(
        text: TextSpan(text: s, style: GamesTheme.text(size, weight: weight, color: color, height: 1.1)),
        textDirection: TextDirection.rtl,
        textAlign: align,
        maxLines: 1,
      )..layout();
      _tp[key] = tp;
    }
    var dx = at.dx - tp.width / 2;
    if (align == TextAlign.left) dx = at.dx;
    if (align == TextAlign.right) dx = at.dx - tp.width;
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  /// Picture of a generic Libyan night skyline (domes, minarets, palms). [w] x [h] in units.
  static ui.Picture skyline(int seed, double w, double h, Color col, {double windows = .3}) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = Random(seed);
    final fill = Paint()..color = col;
    final warm = Paint()..color = GamesTheme.warmWindow.withValues(alpha: .75);
    final cool = Paint()..color = GamesTheme.coolWindow.withValues(alpha: .7);
    var x = 0.0;
    while (x < w) {
      final k = r.nextDouble(), bw = 9 + r.nextDouble() * 22;
      if (k < .55) {
        final bh = 6 + r.nextDouble() * (h * .55);
        c.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), fill);
        _win(c, r, x, h - bh, bw, bh, windows, warm, cool);
      } else if (k < .72) {
        final bh = 6 + r.nextDouble() * (h * .25);
        c.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), fill);
        c.drawArc(Rect.fromCircle(center: Offset(x + bw / 2, h - bh), radius: bw * .36), pi, pi, true, fill);
        _win(c, r, x, h - bh, bw, bh, windows, warm, cool);
      } else if (k < .82) {
        final mh = h * .55 + r.nextDouble() * h * .3, cx = x + bw / 2;
        c.drawRect(Rect.fromLTWH(cx - 1.4, h - mh, 2.8, mh), fill);
        c.drawRect(Rect.fromLTWH(cx - 2.4, h - mh * .74, 4.8, 1.4), fill);
        c.drawPath(
            Path()
              ..moveTo(cx - 1.4, h - mh)
              ..lineTo(cx, h - mh - 4)
              ..lineTo(cx + 1.4, h - mh)
              ..close(),
            fill);
        c.drawRect(Rect.fromLTWH(cx - .5, h - mh * .86, 1, 1), cool);
      } else {
        palmSide(c, x + bw / 2, h, 8 + r.nextDouble() * 8, col);
      }
      x += bw + r.nextDouble() * 5;
    }
    return rec.endRecording();
  }

  static void _win(Canvas c, Random r, double x0, double y0, double w, double h, double dens, Paint warm, Paint cool) {
    for (var yy = y0 + 2; yy < y0 + h - 1.5; yy += 3.2) {
      for (var xx = x0 + 1.6; xx < x0 + w - 1.5; xx += 3) {
        if (r.nextDouble() < dens) c.drawRect(Rect.fromLTWH(xx, yy, 1.2, 1.3), r.nextDouble() < .6 ? warm : cool);
      }
    }
  }

  /// Night ground with city blocks seen from above (for top-down games). Returns a picture of w x h units.
  static ui.Picture cityBlocks(int seed, double w, double h, {Rect? keepClear}) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = Random(seed);
    c.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = ui.Gradient.radial(Offset(w * .4, h * .5), max(w, h) * .8,
              const [Color(0xFF10285A), Color(0xFF050D22)]));
    final b1 = Paint()..color = const Color(0xFF0C1D42);
    final b2 = Paint()..color = const Color(0xFF0A1938);
    final warm = Paint()..color = GamesTheme.warmWindow.withValues(alpha: .6);
    final cool = Paint()..color = GamesTheme.coolWindow.withValues(alpha: .55);
    final n = (w * h / 900).round().clamp(20, 160);
    for (var i = 0; i < n; i++) {
      final bx = r.nextDouble() * w, by = r.nextDouble() * h, bw = 14 + r.nextDouble() * 30, bh = 10 + r.nextDouble() * 24;
      final rect = Rect.fromLTWH(bx, by, bw, bh);
      if (keepClear != null && keepClear.overlaps(rect)) continue;
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), r.nextBool() ? b1 : b2);
      for (var k = 0; k < 6; k++) {
        if (r.nextDouble() < .5) {
          c.drawRect(Rect.fromLTWH(bx + 2 + r.nextDouble() * (bw - 4), by + 2 + r.nextDouble() * (bh - 4), 1.4, 1.4),
              r.nextDouble() < .6 ? warm : cool);
        }
      }
    }
    return rec.endRecording();
  }

  static void nightSky(Canvas c, Rect r) {
    c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter,
              const [Color(0xFF061230), Color(0xFF030918)]));
  }
}
