import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/game_core.dart';
import '../core/paint_kit.dart';
import '../core/theme.dart';

const _districts = ['الكورنيش', 'وسط البلاد', 'السوق القديم', 'الميناء', 'حي النخيل', 'الطريق الساحلي'];

class RoadKnot {
  RoadKnot(this.x, this.g, this.w);
  final double x, g, w; // g = 0..1 inside the road's vertical range
}

/// «ليل المدينة» — hold = the taxi turns up, release = it drifts down.
/// Pick up the blue beacon and drop at the ring before its timer; clean driving fills the combo.
class NightWorld extends GameWorld {
  NightWorld() : super(1);
  @override
  String get hint => 'خلّي صبعك = يطلع لفوق · فكّه = ينزل';

  final List<RoadKnot> k = [];
  double x = 0, y = 0, vy = 0, v = 0, timeLeft = 45, slow = 0, kcd = 0, clk = 0, dT = 0, dTm = 1;
  double bx = 0, by = 0, dx = 0, dy = 0;
  int delivered = 0, combo = 1, best = 1, kerbs = 0, score = 0, goal = 5;
  bool hold = false, carrying = false;
  final List<Offset> trail = [];
  ui.Picture? _far, _palms;
  List<List<double>> _stars = [];

  double get hz => vh * .25;
  double get gt => vh * .35;
  double get gb => vh - 4;
  double get carX => vw * .74;
  double get speedScale => clampD(vw / 360, .6, 1);

  double _gToY(double g, double w) => gt + w / 2 + 5 + g * max(1, (gb - gt) - w - 10);

  ({double y, double w}) road(double xw) {
    var lo = 0, hi = k.length - 1;
    while (hi - lo > 1) {
      final m = (lo + hi) >> 1;
      if (k[m].x <= xw) {
        lo = m;
      } else {
        hi = m;
      }
    }
    final a = k[lo], b = k[hi];
    final e = smooth((xw - a.x) / max(1, b.x - a.x));
    final w = lerpD(a.w, b.w, e);
    return (y: _gToY(lerpD(a.g, b.g, e), w), w: w);
  }

  void _gen(double upto) {
    while (k.last.x < upto) {
      final last = k.last;
      final w0 = max(32.0, 46 - level * 1.2);
      final range = max(30.0, (gb - gt) - w0 - 10);
      final slope = min(.42, .3 + .02 * level);
      double lim(double from, double dxx, double dyUnits) =>
          clampD(from + clampD(dyUnits, -dxx * slope, dxx * slope) / range, 0, 1);
      final ty = rng.nextDouble();
      if (ty < .2) {
        k.add(RoadKnot(last.x + 150 + rng.nextDouble() * 70, last.g, w0));
      } else if (ty < .68) {
        final d = 130 + rng.nextDouble() * 80;
        k.add(RoadKnot(last.x + d, lim(last.g, d, (rng.nextDouble() * 2 - 1) * d * slope * 1.2), w0));
      } else if (ty < .88) {
        final s = rng.nextBool() ? -1.0 : 1.0, d1 = 100 + rng.nextDouble() * 30;
        final k1 = RoadKnot(last.x + d1, lim(last.g, d1, s * d1 * slope), w0);
        k.add(k1);
        final d2 = 100 + rng.nextDouble() * 30;
        k.add(RoadKnot(k1.x + d2, lim(k1.g, d2, -s * d2 * slope), w0));
      } else {
        k.add(RoadKnot(last.x + 170, lim(last.g, 170, (rng.nextDouble() * 2 - 1) * 30), level >= 3 ? w0 * .78 : w0));
      }
    }
    while (k.length > 4 && k[1].x < x - 700) {
      k.removeAt(0);
    }
  }

  void _place(double ahead) {
    bx = x + ahead + rng.nextDouble() * 70;
    final r = road(bx);
    by = r.y + (rng.nextDouble() * 2 - 1) * r.w * .24;
  }

  void _buildSky() {
    _far = Kit.skyline(level * 31 + 7, 600, hz, const Color(0xFF10275A));
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = Random(level * 17);
    var px = 8.0;
    while (px < 600) {
      Kit.palmSide(c, px, 30, 14 + r.nextDouble() * 10, const Color(0xFF050D22));
      px += 34 + r.nextDouble() * 40;
    }
    _palms = rec.endRecording();
    _stars = List.generate(40, (_) => [r.nextDouble() * 900, r.nextDouble() * hz * .85, r.nextDouble() * 1.1 + .3, r.nextDouble() * 6]);
  }

  @override
  void start() {
    final w0 = max(32.0, 46 - level * 1.2);
    k
      ..clear()
      ..add(RoadKnot(-500, .5, w0))
      ..add(RoadKnot(140, .5, w0));
    x = 0;
    y = road(0).y;
    v = (118 + min(level, 12) * 9).toDouble();
    goal = min(10, 5 + (level - 1) ~/ 2);
    _gen(1500);
    _place(220);
    _buildSky();
    pop(vw * .5, gt + 14, _districts[(level - 1) % _districts.length], color: GamesTheme.ink, size: 13);
  }

  @override
  void onResize() {
    _buildSky();
    y = clampD(y, gt + 4, gb - 4);
  }

  @override
  void down(Offset p) => hold = true;
  @override
  void up(Offset p) => hold = false;

  @override
  void auto(double dt) {
    final tx = carrying ? dx : bx, ty = carrying ? dy : by;
    final r = road(x + 30), lim = r.w / 2 - 9;
    var target = r.y;
    if (tx > x && tx - x < 110) target = clampD(ty, r.y - lim, r.y + lim);
    hold = target < y + vy * .16;
  }

  @override
  void update(double dt) {
    _gen(x + vw + 700);
    final sp = v * speedScale * (slow > 0 ? .62 : 1);
    v += dt * 1.3;
    x += sp * dt;
    slow -= dt;
    kcd -= dt;
    vy += ((hold ? -.8 * sp : .68 * sp) - vy) * min(1, dt * 6);
    y = clampD(y + vy * dt, gt + 4, gb - 4);
    final r = road(x), half = r.w / 2 - 5.5, d = y - r.y;
    if (d.abs() > half) {
      y = r.y + d.sign * half;
      vy *= -.2;
      if (kcd <= 0) {
        kerbs++;
        combo = 1;
        clk = 0;
        timeLeft = max(0, timeLeft - 1);
        slow = .6;
        kcd = .6;
        fx.burst(carX, y + d.sign * 5, 14, const Color(0xFFC8E1FF), speed: 90, size: 7, life: .5);
        pop(carX, y - 18, 'لمست الرصيف · −1 ث', color: const Color(0xFFFFB3C0), size: 12);
        buzz(2);
      }
    } else if (kcd <= 0) {
      clk += dt;
      if (clk >= 2.4) {
        clk = 0;
        if (combo < 5) {
          combo++;
          best = max(best, combo);
          pop(carX, y - 20, 'سلسلة ×$combo', color: const Color(0xFF9FD0FF));
          buzz();
          if (combo == 5) shake = .3;
        }
      }
    }
    trail.insert(0, Offset(x, y));
    if (trail.length > (reduced ? 12 : 30)) trail.removeLast();
    if (!carrying) {
      if ((bx - x).abs() < 9 && (by - y).abs() < 13) {
        carrying = true;
        dx = x + 340 + rng.nextDouble() * 170;
        final rr = road(dx);
        dy = rr.y + (rng.nextDouble() * 2 - 1) * rr.w * .22;
        dTm = dT = max(6, 9.6 - level * .3);
        fx.burst(carX, by, 22, const Color(0xFF5AAAFF), speed: 120, size: 9);
        pop(carX, by - 20, 'ركب معاك راكب!');
        buzz();
      } else if (x > bx + 14) {
        _place(120);
      }
    } else {
      dT -= dt;
      if ((dx - x).abs() < 10 && (dy - y).abs() < 15) {
        delivered++;
        final pts = 100 * combo;
        score += pts;
        timeLeft += 1;
        carrying = false;
        fx.burst(carX, dy, 34, GamesTheme.gold, speed: 150, size: 10, life: .9);
        fx.burst(carX, dy, 18, const Color(0xFFEBF4FF), speed: 110, size: 7, life: .6);
        pop(carX, dy - 22, '+$pts  وصّلته!', color: GamesTheme.gold, size: 15);
        buzz(2);
        _place(200);
      } else if (x > dx + 14) {
        dx = x + 170 + rng.nextDouble() * 60;
        final rr = road(dx);
        dy = rr.y + (rng.nextDouble() * 2 - 1) * rr.w * .22;
      }
      if (dT <= 0) {
        carrying = false;
        pop(carX, y - 20, 'الراكب ما استناش', color: GamesTheme.muted, size: 12);
        _place(160);
      }
    }
    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      var st = (delivered >= goal ? 1 : 0) + (best >= 4 ? 1 : 0) + (kerbs <= 3 ? 1 : 0);
      if (delivered == 0) st = 0;
      finish(st, st > 0 ? 'وصّلت الركاب!' : 'قريبة! عاودها',
          'وصّلت $delivered (المطلوب $goal) · أحسن سلسلة ×$best', score: score);
    }
  }

  @override
  void draw(Canvas c) {
    final cx = carX;
    Kit.nightSky(c, Rect.fromLTWH(-4, -4, vw + 8, hz + 4));
    final star = Paint()..color = GamesTheme.ink;
    for (final s in _stars) {
      final sx = ((s[0] - x * .02) % 900 + 900) % 900 * vw / 900;
      star.color = GamesTheme.ink.withValues(alpha: .35 + .35 * sin(t * 1.5 + s[3]));
      c.drawRect(Rect.fromLTWH(sx, s[1], s[2], s[2]), star);
    }
    final mx = vw * .16;
    Kit.glow(c, Offset(mx, hz * .32), 23, const Color(0xFFAACDFF), .55);
    c.drawCircle(Offset(mx, hz * .32), 6.5, Paint()..color = const Color(0xFFEAF2FF));
    c.drawCircle(Offset(mx + 2.6, hz * .32 - 1.4), 5.6, Paint()..color = const Color(0xFF0D2452));
    void tile(ui.Picture? p, double f, double y0) {
      if (p == null) return;
      const tw = 600.0;
      final o = ((x * f) % tw + tw) % tw;
      for (var px = o - tw; px < vw; px += tw) {
        c.save();
        c.translate(px, y0);
        c.drawPicture(p);
        c.restore();
      }
    }

    tile(_far, .08, 0);
    c.drawRect(
        Rect.fromLTWH(-4, hz, vw + 8, gt - hz),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, hz), Offset(0, gt), const [Color(0xFF0B2150), Color(0xFF071637)]));
    final sea = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 9; i++) {
      sea.color = const Color(0xFFAACDFF).withValues(alpha: .18 + .14 * sin(t * 2 + i));
      c.drawRect(Rect.fromLTWH(mx - 6 + sin(t * 1.7 + i) * 3, hz + 2 + i * 2, 12 - i * .6, .7), sea);
    }
    for (var i = 0; i < 16; i++) {
      final sx = ((i * 67 - x * .08) % vw + vw) % vw;
      sea.color = (i % 3 == 0 ? GamesTheme.coolWindow : GamesTheme.warmWindow).withValues(alpha: .16 + .12 * sin(t * 2.4 + i));
      c.drawRect(Rect.fromLTWH(sx, hz + 3 + (i % 4) * 3, 4, .7), sea);
    }
    tile(_palms, .5, gt - 30);
    c.drawRect(
        Rect.fromLTWH(-4, gt, vw + 8, vh - gt + 4),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, gt), Offset(0, vh), const [Color(0xFF0A1838), Color(0xFF040B1E)]));
    // road
    final top = Path(), bot = Path(), mid = Path(), body = Path();
    final pts = <Offset>[], pbs = <Offset>[];
    for (var sx = -10.0; sx <= vw + 10; sx += 5) {
      final r = road(x + (cx - sx));
      pts.add(Offset(sx, r.y - r.w / 2));
      pbs.add(Offset(sx, r.y + r.w / 2));
      if (sx == -10) {
        top.moveTo(sx, r.y - r.w / 2);
        bot.moveTo(sx, r.y + r.w / 2);
        mid.moveTo(sx, r.y);
      } else {
        top.lineTo(sx, r.y - r.w / 2);
        bot.lineTo(sx, r.y + r.w / 2);
        mid.lineTo(sx, r.y);
      }
    }
    body.addPolygon([...pts, ...pbs.reversed], true);
    c.drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, gt), Offset(0, vh), const [Color(0xFF15254A), Color(0xFF0E1A36)]));
    final kerbBlue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = GamesTheme.brand;
    c.drawPath(top, kerbBlue);
    c.drawPath(bot, kerbBlue);
    _dashed(c, pts, 5, 5, x, const Color(0xFFE6EEFF), 2.6);
    _dashed(c, pbs, 5, 5, x, const Color(0xFFE6EEFF), 2.6);
    final midPts = <Offset>[for (var i = 0; i < pts.length; i++) Offset(pts[i].dx, (pts[i].dy + pbs[i].dy) / 2)];
    _dashed(c, midPts, 9, 11, x, Colors.white.withValues(alpha: .28), 1.2);
    // street lights + reflections
    final k0 = ((x - (vw - cx) - 80) / 110).floor(), k1 = ((x + cx + 80) / 110).ceil();
    for (var kk = k0; kk <= k1; kk++) {
      final lx = kk * 110.0, side = kk.isOdd ? 1.0 : -1.0, r = road(lx);
      final ly = r.y + side * (r.w / 2 + 6), sx = cx - (lx - x);
      Kit.glow(c, Offset(sx, ly), 12, const Color(0xFFBEDCFF), .6);
      Kit.pool(c, Offset(sx, r.y + side * r.w * .16), 23, 10, const Color(0xFF96C3FF), .22);
      c.drawCircle(Offset(sx, ly), 1.5, Paint()..color = GamesTheme.ink);
    }
    // beacons
    final pulse = sin(t * 5);
    if (!carrying) {
      final sx = cx - (bx - x), yy = by + sin(t * 4) * 1.2;
      Kit.glow(c, Offset(sx, yy), 20 + pulse * 2, const Color(0xFF3C96FF), .75);
      c.drawOval(
          Rect.fromCenter(center: Offset(sx, by + 3), width: 18 + pulse * 4, height: 6.4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xCC78B9FF));
      Kit.pin(c, Offset(sx, yy), 10, GamesTheme.brand);
      if (sx < 6) _edge(c, by, const Color(0xFF5AAAFF));
    } else {
      final sx = cx - (dx - x), fr = clampD(dT / dTm, 0, 1), warn = dT < 3;
      Kit.glow(c, Offset(sx, dy), 24, warn ? GamesTheme.danger : const Color(0xFFEBF4FF), .55);
      c.drawCircle(
          Offset(sx, dy),
          14,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xE6EBF4FF));
      c.drawArc(
          Rect.fromCircle(center: Offset(sx, dy), radius: 17.5),
          -pi / 2,
          tau * fr,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = warn ? GamesTheme.danger : const Color(0xFF7FC0FF));
      Kit.icon(c, 'star', Offset(sx, dy), 10, GamesTheme.gold);
      if (sx < 6) _edge(c, dy, warn ? GamesTheme.danger : const Color(0xFFEBF4FF));
    }
    // trail, beam, car
    final sp = v * speedScale * (slow > 0 ? .62 : 1);
    final ang = atan2(vy, -sp); // travel direction on screen (leftwards)
    final tp = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < trail.length - 1; i++) {
      final p = trail[i], q = trail[i + 1], kk = 1 - i / trail.length;
      tp
        ..color = const Color(0xFF3C96FF).withValues(alpha: kk * .5)
        ..strokeWidth = kk * 6;
      c.drawLine(Offset(cx - (p.dx - x) + 9, p.dy), Offset(cx - (q.dx - x) + 9, q.dy), tp);
    }
    Kit.beam(c, Offset(cx + 9 * cos(ang), y + 9 * sin(ang)), ang, 62, 17);
    Kit.glow(c, Offset(cx, y), 17, GamesTheme.brand, .35);
    Kit.car(c, Offset(cx, y), ang, 22, skin);
  }

  void _dashed(Canvas c, List<Offset> pts, double on, double off, double phase, Color col, double w) {
    final p = Paint()
      ..color = col
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt;
    final period = on + off;
    for (var i = 0; i < pts.length - 1; i++) {
      // the world x at this screen point: dashes are anchored to the road, so they move
      final wx = x + (carX - pts[i].dx);
      if ((wx % period + period) % period < on) c.drawLine(pts[i], pts[i + 1], p);
    }
  }

  void _edge(Canvas c, double yy, Color col) {
    Kit.glow(c, Offset(6, yy), 10, col, .8);
    c.drawPath(
        Path()
          ..moveTo(3, yy)
          ..lineTo(9, yy - 4)
          ..lineTo(9, yy + 4)
          ..close(),
        Paint()..color = Colors.white);
  }

  @override
  void hud(Canvas c) {
    hudPill(c,
        a: '${timeLeft.ceil()} ث',
        aColor: timeLeft < 8 ? GamesTheme.danger : Colors.white,
        b: '$score',
        cText: '×$combo');
    if (carrying) {
      final small = size.height < 150;
      final r = Rect.fromCenter(center: Offset(size.width / 2, small ? 40 : 46), width: 128, height: small ? 18 : 22);
      Kit.pill(c, r);
      Kit.text(c, 'معاك راكب · ${dT.ceil()} ث', r.center, small ? 10.5 : 11.5, color: dT < 3 ? GamesTheme.danger : GamesTheme.ink);
    }
  }
}

/// «اصطف» — one flick slides the taxi into the glowing bay. Perfect stop = 3 stars.
class ParkWorld extends GameWorld {
  ParkWorld() : super(2);
  @override
  bool get rotateInPortrait => true;
  @override
  String get hint => 'اسحب التاكسي لليسار وفكّه · قوة السحبة = المسافة';

  double carX = 0, v = 0, a = 220, gL = 0, gR = 0, evalT = 0;
  String state = 'aim';
  int tries = 0, pts = 0;
  final List<int> res = [];
  final List<double> skid = [];
  final List<(double, Color)> parked = [];
  bool wet = false;
  final List<(double, double)> _samples = [];
  double? _dragX0, _dragX;

  double get len => min(40, vw * .16);
  double get lane => band + 62;

  void _setup() {
    final slack = max(5.0, 30 - (level - 1) * 3.6);
    final startX = vw - 34;
    final avail = max(40.0, startX - len * 3);
    final dist = avail * .35 + rng.nextDouble() * avail * .5;
    final center = startX - dist;
    gR = center + (len + slack) / 2;
    gL = center - (len + slack) / 2;
    carX = startX;
    v = 0;
    state = 'aim';
    skid.clear();
    wet = level >= 3 && rng.nextDouble() < .45;
    a = wet ? 140 : 220;
    evalT = 0;
    const cols = [Color(0xFF3A4A66), Color(0xFF8C98AD), Color(0xFFC9D2E0), Color(0xFF1F3B66), Color(0xFF5E6B82)];
    parked
      ..clear()
      ..add((gL - len / 2 - 3, cols[rng.nextInt(cols.length)]))
      ..add((gL - len * 1.5 - 8, cols[rng.nextInt(cols.length)]));
  }

  @override
  void start() {
    tries = 0;
    pts = 0;
    res.clear();
    _setup();
  }

  @override
  void onResize() {
    if (state == 'aim') _setup();
  }

  @override
  void down(Offset p) {
    if (state != 'aim') return;
    _dragX0 = p.dx;
    _dragX = p.dx;
    _samples
      ..clear()
      ..add((p.dx, t));
  }

  @override
  void move(Offset p) {
    if (_dragX0 == null) return;
    _dragX = p.dx;
    _samples.add((p.dx, t));
    if (_samples.length > 8) _samples.removeAt(0);
  }

  @override
  void up(Offset p) {
    if (_dragX0 == null || state != 'aim') {
      _dragX0 = null;
      return;
    }
    // velocity over the last ~0.11 s, in units per second (leftward is positive)
    var i = 0;
    while (i < _samples.length - 1 && t - _samples[i].$2 > .11) {
      i++;
    }
    final dx = _samples.last.$1 - _samples[i].$1, dt = max(1 / 60, _samples.last.$2 - _samples[i].$2);
    final pull = (_dragX0! - (_dragX ?? _dragX0!));
    _dragX0 = null;
    var speed = -dx / dt;
    if (speed < 60 && pull > 8) speed = sqrt(2 * a * pull * 2.2); // slow drag: treat the pull length as strength
    if (speed < 60) {
      pop((gL + gR) / 2, lane - 26, 'اسحب لليسار أسرع', color: GamesTheme.muted, size: 12);
      return;
    }
    v = min(560, speed * .9);
    state = 'slide';
    buzz();
  }

  @override
  void auto(double dt) {
    if (state == 'aim') {
      v = sqrt(2 * a * (carX - (gL + gR) / 2)) * (1 + (rng.nextDouble() - .5) * .03);
      state = 'slide';
    }
  }

  void _try(String kind) {
    const map = {
      'perfect': (3, 'ممتاز! ركنة نظيفة', GamesTheme.gold),
      'good': (2, 'زينة!', Color(0xFF9FD0FF)),
      'ok': (1, 'داخل الموقف', GamesTheme.ink),
      'out': (0, 'برا الموقف', GamesTheme.muted),
      'bump': (0, 'دقّيتها!', GamesTheme.danger),
    };
    final m = map[kind]!;
    res.add(m.$1);
    pts += m.$1;
    pop((gL + gR) / 2, lane - 28, m.$2, color: m.$3, size: 15);
    if (kind == 'perfect') {
      fx.burst((gL + gR) / 2, lane, 36, GamesTheme.gold, speed: 130, size: 10, life: .9);
      buzz(2);
    } else if (m.$1 > 0) {
      fx.burst((gL + gR) / 2, lane, 18, const Color(0xFF5AAAFF), speed: 100, size: 8);
      buzz();
    } else {
      buzz(2);
    }
    state = 'done';
    evalT = 0;
    tries++;
  }

  @override
  void update(double dt) {
    if (state == 'slide') {
      final nv = max(0.0, v - a * dt);
      carX -= (v + nv) / 2 * dt;
      v = nv;
      if (v > 40) skid.add(carX + len * .32);
      if (skid.length > 60) skid.removeAt(0);
      if (carX - len / 2 < gL) {
        carX = gL + len / 2;
        fx.burst(gL, lane, 16, GamesTheme.danger, speed: 90, size: 7, life: .5);
        shake = .2;
        v = 0;
        _try('bump');
        return;
      }
      if (v <= 0) {
        final slackHalf = ((gR - gL) - len) / 2, err = (carX - (gL + gR) / 2).abs();
        if (carX - len / 2 >= gL && carX + len / 2 <= gR) {
          _try(err <= max(1.4, slackHalf * .22) ? 'perfect' : (err <= slackHalf * .6 ? 'good' : 'ok'));
        } else {
          _try('out');
        }
      }
    } else if (state == 'done') {
      evalT += dt;
      if (evalT > 1.1) {
        if (tries >= 3) {
          final st = pts >= 8 ? 3 : (pts >= 5 ? 2 : (pts >= 2 ? 1 : 0));
          finish(st, st > 0 ? 'ركنت التاكسي!' : 'عاودها، تقدر', 'ثلاث ركنات · نقاطك $pts من 9', score: pts);
        } else {
          _setup();
        }
      }
    }
  }

  @override
  void draw(Canvas c) {
    final W = vw, b = band;
    c.drawRect(Rect.fromLTWH(-4, -4, W + 8, vh + 8), Paint()..color = const Color(0xFF071430));
    c.drawRect(Rect.fromLTWH(-4, b, W + 8, 32), Paint()..color = const Color(0xFF0D1D40));
    for (var xx = 0.0; xx < W + 12; xx += 12) {
      c.drawRect(Rect.fromLTWH(xx, b + 32, 12, 3),
          Paint()..color = ((xx / 12).round().isOdd) ? const Color(0xFFE6EEFF) : GamesTheme.brand);
    }
    c.drawRect(
        Rect.fromLTWH(-4, b + 35, W + 8, 170),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, b + 35), Offset(0, b + 200),
              [wet ? const Color(0xFF16284F) : const Color(0xFF121F40), const Color(0xFF0B1630)]));
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .25)
      ..strokeWidth = 1.4;
    for (var xx = 0.0; xx < W; xx += 24) {
      c.drawLine(Offset(xx, b + 92), Offset(xx + 12, b + 92), dash);
      c.drawLine(Offset(xx, b + 150), Offset(xx + 12, b + 150), dash);
    }
    for (var xx = 40.0; xx < W; xx += 120) {
      Kit.glow(c, Offset(xx, b + 18), 13, const Color(0xFFBEDCFF), .6);
      Kit.pool(c, Offset(xx, b + 58), 36, 14, const Color(0xFF96C3FF), wet ? .32 : .18);
    }
    for (var xx = 90.0; xx < W; xx += 120) {
      Kit.palmTop(c, Offset(xx, b + 16), 13);
    }
    // passing traffic (ambient)
    for (var i = 0; i < 3; i++) {
      final sp = [70.0, 95.0, 55.0][i], ln = b + [121.0, 176.0, 121.0][i];
      final ox = (t * sp + i * 260) % (W + 160) - 80;
      Kit.beam(c, Offset(ox + 18, ln), 0, 60, 14, .22);
      Kit.car(c, Offset(ox, ln), 0, 36, const [Color(0xFF5E6B82), Color(0xFFC9D2E0), Color(0xFF2B5C8A)][i]);
    }
    // bay
    final pulse = .5 + .5 * sin(t * 4);
    final bay = RRect.fromRectAndRadius(Rect.fromLTRB(gL, lane - 15, gR, lane + 15), const Radius.circular(4));
    c.drawRRect(bay, Paint()..color = GamesTheme.brand.withValues(alpha: .12 + .08 * pulse));
    c.drawRRect(
        bay,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = GamesTheme.brandLight);
    Kit.pool(c, Offset((gL + gR) / 2, lane), 40, 15, const Color(0xFF3C96FF), .35 + .2 * pulse);
    if (state == 'aim') Kit.text(c, 'هنا', Offset((gL + gR) / 2, lane - 21), 9, color: GamesTheme.ink);
    if (wet) Kit.text(c, 'طريق مبلول، التاكسي يزلق أكثر', Offset(8, b + 106), 8, color: const Color(0xFF9FD0FF), align: TextAlign.left);
    for (final p in parked) {
      Kit.car(c, Offset(p.$1, lane), pi, len, p.$2);
    }
    final sk = Paint()
      ..color = Colors.black.withValues(alpha: .3)
      ..strokeWidth = 1.3;
    for (var i = 1; i < skid.length; i++) {
      c.drawLine(Offset(skid[i - 1], lane - 6), Offset(skid[i], lane - 6), sk);
      c.drawLine(Offset(skid[i - 1], lane + 6), Offset(skid[i], lane + 6), sk);
    }
    if (_dragX0 != null && state == 'aim') {
      final d = clampD(_dragX0! - (_dragX ?? _dragX0!), 0, 160);
      for (var i = 0; i < 6; i++) {
        final ax = carX - len / 2 - 8 - i * (d / 6);
        c.drawPath(
            Path()
              ..moveTo(ax, lane - 4)
              ..lineTo(ax - 6, lane)
              ..lineTo(ax, lane + 4)
              ..close(),
            Paint()
              ..blendMode = BlendMode.plus
              ..color = const Color(0xFF5AAAFF).withValues(alpha: .5 - i * .07));
      }
    }
    Kit.beam(c, Offset(carX - len / 2, lane), pi, 60, 18);
    if (state == 'slide' && v < 120) Kit.glow(c, Offset(carX + len / 2, lane), 11, GamesTheme.tail, .5);
    Kit.car(c, Offset(carX, lane), pi, len, skin);
  }

  @override
  void hud(Canvas c) {
    hudPill(c, a: 'نقاط $pts', b: '${tries + (state == 'done' ? 0 : 1)}/3', cText: 'ركنة');
  }
}

/// «حارة وحارة» — tap above or below the taxi to change lanes; collect passengers, dodge cones.
class LaneWorld extends GameWorld {
  LaneWorld() : super(3);
  @override
  bool get rotateInPortrait => true;
  @override
  String get hint => 'اضغط فوق التاكسي أو تحته باش تبدّل الحارة';

  int laneIdx = 1, got = 0, hits = 0, combo = 1, goal = 8;
  double carY = 0, dist = 0, v = 150, timeLeft = 40, slow = 0, spawn = 0;
  final List<(double, int, bool)> items = []; // world x, lane, isCone
  final Set<int> _taken = {};

  double laneY(int i) => band + 60 + i * 40;
  double get carX => vw * .78;

  @override
  void start() {
    laneIdx = 1;
    carY = laneY(1);
    v = 140 + min(level, 12) * 10;
    goal = 14 + level * 2;
    items.clear();
    dist = 0;
    spawn = 0;
  }

  @override
  void onResize() => carY = laneY(laneIdx);

  @override
  void down(Offset p) {
    if (p.dy < carY - 4 && laneIdx > 0) {
      laneIdx--;
    } else if (p.dy > carY + 4 && laneIdx < 2) {
      laneIdx++;
    }
    buzz();
  }

  @override
  void auto(double dt) {
    for (final it in items) {
      final ahead = it.$1 - dist;
      if (ahead > 0 && ahead < 70) {
        if (it.$3 && it.$2 == laneIdx) laneIdx = laneIdx == 0 ? 1 : laneIdx - 1;
        if (!it.$3 && it.$2 != laneIdx && ahead < 50) laneIdx = it.$2;
        break;
      }
    }
  }

  @override
  void update(double dt) {
    final sp = v * (slow > 0 ? .55 : 1);
    v += dt * 2;
    dist += sp * dt;
    slow -= dt;
    carY += (laneY(laneIdx) - carY) * min(1, dt * 12);
    spawn -= sp * dt;
    if (spawn <= 0) {
      spawn = 70 + rng.nextDouble() * 60 - min(level, 10) * 3;
      final cone = rng.nextDouble() < .38 + min(level, 10) * .02;
      items.add((dist + carX + 60, rng.nextInt(3), cone));
    }
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (_taken.contains(i)) continue;
      final ahead = it.$1 - dist;
      if (ahead.abs() < 12 && (laneY(it.$2) - carY).abs() < 14) {
        _taken.add(i);
        if (it.$3) {
          hits++;
          combo = 1;
          slow = .7;
          timeLeft = max(0, timeLeft - 2);
          fx.burst(carX, carY, 16, GamesTheme.danger, speed: 90, size: 7, life: .5);
          pop(carX, carY - 18, 'قمع! −2 ث', color: GamesTheme.danger, size: 12);
          shake = .2;
          buzz(2);
        } else {
          got++;
          if (got % 3 == 0 && combo < 5) combo++;
          fx.burst(carX, carY, 20, const Color(0xFF5AAAFF), speed: 110, size: 8);
          pop(carX, carY - 18, '+$combo راكب', color: const Color(0xFF9FD0FF));
          buzz();
        }
      }
    }
    // forget items far behind
    while (items.isNotEmpty && items.first.$1 - dist < -vw) {
      items.removeAt(0);
      final shifted = _taken.map((e) => e - 1).where((e) => e >= 0).toSet();
      _taken
        ..clear()
        ..addAll(shifted);
    }
    timeLeft -= dt;
    if (timeLeft <= 0) {
      final st = got >= goal + 8 ? 3 : (got >= goal ? 2 : (got >= goal ~/ 2 ? 1 : 0));
      finish(st, st > 0 ? 'سواقة نظيفة!' : 'عاودها', 'لقّطت $got راكب · لمست $hits قمع', score: got);
    }
  }

  @override
  void draw(Canvas c) {
    final b = band;
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8), Paint()..color = const Color(0xFF050D22));
    c.drawRect(
        Rect.fromLTWH(-4, b + 36, vw + 8, 128),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, b + 36), Offset(0, b + 164), const [Color(0xFF16284F), Color(0xFF0E1A36)]));
    final edge = Paint()
      ..color = GamesTheme.brand
      ..strokeWidth = 2.4;
    c.drawLine(Offset(-4, b + 36), Offset(vw + 4, b + 36), edge);
    c.drawLine(Offset(-4, b + 164), Offset(vw + 4, b + 164), edge);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..strokeWidth = 1.4;
    final off = dist % 24;
    for (var xx = -24.0 + off; xx < vw + 24; xx += 24) {
      c.drawLine(Offset(xx, b + 80), Offset(xx + 12, b + 80), dash);
      c.drawLine(Offset(xx, b + 120), Offset(xx + 12, b + 120), dash);
    }
    // roadside lights and blocks
    final lo = dist % 90;
    for (var xx = -90.0 + lo; xx < vw + 90; xx += 90) {
      Kit.glow(c, Offset(xx, b + 26), 12, const Color(0xFFBEDCFF), .55);
      Kit.glow(c, Offset(xx + 45, b + 174), 12, const Color(0xFFBEDCFF), .45);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(xx + 10, b + 4, 50, 16), const Radius.circular(3)),
          Paint()..color = const Color(0xFF0C1D42));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(xx + 30, b + 180, 44, 16), const Radius.circular(3)),
          Paint()..color = const Color(0xFF0C1D42));
    }
    for (var i = 0; i < items.length; i++) {
      if (_taken.contains(i)) continue;
      final it = items[i];
      final sx = carX - (it.$1 - dist), y = laneY(it.$2);
      if (sx < -20 || sx > vw + 20) continue;
      if (it.$3) {
        Kit.glow(c, Offset(sx, y), 14, GamesTheme.danger, .4 + .2 * sin(t * 8));
        c.drawPath(
            Path()
              ..moveTo(sx, y - 9)
              ..lineTo(sx + 7, y + 7)
              ..lineTo(sx - 7, y + 7)
              ..close(),
            Paint()..color = const Color(0xFFE0243A));
        c.drawRect(Rect.fromLTWH(sx - 4.5, y - 1, 9, 2.2), Paint()..color = Colors.white);
      } else {
        Kit.glow(c, Offset(sx, y), 18, const Color(0xFF3C96FF), .7);
        Kit.pin(c, Offset(sx, y + 6), 10, GamesTheme.brand);
      }
    }
    Kit.beam(c, Offset(carX - 11, carY), pi, 64, 18);
    Kit.car(c, Offset(carX, carY), pi + (laneY(laneIdx) - carY) * -.01, 24, skin);
  }

  @override
  void hud(Canvas c) => hudPill(c,
      a: '${timeLeft.ceil()} ث', aColor: timeLeft < 8 ? GamesTheme.danger : Colors.white, b: '$got', cText: '×$combo');
}

/// «المطبّ» — hold to brake before each speed bump, release to speed up. Fast but smooth.
class BumpWorld extends GameWorld {
  BumpWorld() : super(4);
  @override
  bool get rotateInPortrait => true;
  @override
  String get hint => 'خلّي صبعك = فرامل قبل المطب · فكّه = يسرع';

  double pos = 0, v = 0, vmax = 220, length = 1400, elapsed = 0, penalty = 0;
  bool brake = false;
  final List<double> bumps = [];
  final Set<int> crossed = {};
  int clean = 0, rough = 0;

  double get limit => vmax * .5;
  double get carX => vw * .75;
  double get roadY => band + 110;

  @override
  void start() {
    vmax = 200 + min(level, 12) * 12;
    length = 1300 + min(level, 10) * 160.0;
    bumps.clear();
    var p = 260.0;
    while (p < length - 80) {
      bumps.add(p);
      p += 170 + rng.nextDouble() * 120 - min(level, 10) * 6;
    }
    pos = 0;
    v = vmax * .6;
  }

  @override
  void down(Offset p) => brake = true;
  @override
  void up(Offset p) => brake = false;

  @override
  void auto(double dt) {
    double? next;
    for (final b in bumps) {
      if (b > pos) {
        next = b;
        break;
      }
    }
    brake = next != null && next - pos < 90 && v > limit * .85;
  }

  @override
  void update(double dt) {
    elapsed += dt;
    v = brake ? max(30, v - 420 * dt) : min(vmax, v + 160 * dt);
    pos += v * dt;
    for (var i = 0; i < bumps.length; i++) {
      if (!crossed.contains(i) && pos >= bumps[i]) {
        crossed.add(i);
        if (v > limit) {
          rough++;
          penalty += 1.5;
          shake = .3;
          fx.burst(carX, roadY + 8, 18, const Color(0xFFC8E1FF), speed: 110, size: 7, life: .5);
          pop(carX, roadY - 24, 'هبطة! +1.5 ث', color: GamesTheme.danger, size: 13);
          buzz(2);
        } else {
          clean++;
          pop(carX, roadY - 24, 'رايق!', color: const Color(0xFF9FD0FF), size: 13);
          fx.burst(carX, roadY, 10, const Color(0xFF5AAAFF), speed: 70, size: 6);
          buzz();
        }
      }
    }
    if (pos >= length) {
      final total = elapsed + penalty, par = length / (vmax * .72);
      final st = rough == 0 && total < par * 1.1 ? 3 : (rough <= 1 && total < par * 1.35 ? 2 : 1);
      finish(st, 'وصلت بالسلامة!', 'الوقت ${total.toStringAsFixed(1)} ث · مطبات رايقة $clean من ${bumps.length}',
          score: max(0, (1000 - total * 20).round()));
    }
  }

  @override
  void draw(Canvas c) {
    final b = band;
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8), Paint()..color = const Color(0xFF050D22));
    c.drawRect(
        Rect.fromLTWH(-4, b + 70, vw + 8, 80),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, b + 70), Offset(0, b + 150), const [Color(0xFF16284F), Color(0xFF0E1A36)]));
    final edge = Paint()
      ..color = GamesTheme.brand
      ..strokeWidth = 2.4;
    c.drawLine(Offset(-4, b + 70), Offset(vw + 4, b + 70), edge);
    c.drawLine(Offset(-4, b + 150), Offset(vw + 4, b + 150), edge);
    final lo = pos % 100;
    for (var xx = -100.0 + lo; xx < vw + 100; xx += 100) {
      Kit.glow(c, Offset(xx, b + 58), 13, const Color(0xFFBEDCFF), .55);
      Kit.pool(c, Offset(xx, b + 84), 30, 10, const Color(0xFF96C3FF), .18);
      Kit.palmTop(c, Offset(xx + 50, b + 40), 12);
      Kit.palmTop(c, Offset(xx + 20, b + 172), 12);
    }
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..strokeWidth = 1.4;
    for (var xx = -24.0 + pos % 24; xx < vw + 24; xx += 24) {
      c.drawLine(Offset(xx, b + 110), Offset(xx + 12, b + 110), dash);
    }
    for (var i = 0; i < bumps.length; i++) {
      final sx = carX - (bumps[i] - pos);
      if (sx < -20 || sx > vw + 20) continue;
      for (var j = 0; j < 8; j++) {
        c.drawRect(Rect.fromLTWH(sx - 4, b + 71 + j * 10, 8, 10),
            Paint()..color = j.isEven ? const Color(0xFFE6EEFF) : GamesTheme.brand);
      }
      if (!crossed.contains(i)) Kit.glow(c, Offset(sx, b + 110), 22, const Color(0xFF5AAAFF), .25);
    }
    final finishX = carX - (length - pos);
    if (finishX > -10 && finishX < vw + 10) {
      for (var j = 0; j < 8; j++) {
        c.drawRect(Rect.fromLTWH(finishX - 3, b + 71 + j * 10, 6, 10), Paint()..color = j.isEven ? Colors.white : Colors.black);
      }
    }
    Kit.beam(c, Offset(carX - 12, roadY), pi, 70, 18);
    if (brake) Kit.glow(c, Offset(carX + 13, roadY), 12, GamesTheme.tail, .7);
    Kit.car(c, Offset(carX, roadY + (shake > 0 ? sin(t * 60) * 1.5 : 0)), pi, 26, skin);
  }

  @override
  void hud(Canvas c) {
    final fast = v > limit;
    hudPill(c,
        a: '${(elapsed + penalty).toStringAsFixed(0)} ث',
        b: '${(v / vmax * 80).round()} كم',
        bColor: fast ? GamesTheme.danger : GamesTheme.success,
        cText: '${(pos / length * 100).clamp(0, 100).round()}%');
  }
}
