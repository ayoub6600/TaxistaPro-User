import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/game_core.dart';
import '../core/paint_kit.dart';
import '../core/theme.dart';

/// «الإشارة» — tap the moment it turns green; never on yellow. Soft glow, no strobe.
class LightWorld extends GameWorld {
  LightWorld() : super(9);
  @override
  String get hint => 'اضغط أول ما تولّي خضرا · لا تضغطش على الصفرا';

  String state = 'red';
  double tm = 1, goT = 0;
  int lamp = 0, greens = 0, need = 5, faults = 0;
  final List<double> times = [];

  void _next() {
    state = 'red';
    tm = 1 + rng.nextDouble() * 1.8;
    lamp = 0;
  }

  @override
  void start() {
    greens = 0;
    faults = 0;
    times.clear();
    _next();
  }

  @override
  void down(Offset p) {
    final cx = vw / 2, cy = band + 100;
    if (state == 'green') {
      final rt = t - goT;
      times.add(rt);
      greens++;
      pop(cx, cy - 52, '${rt.toStringAsFixed(2)} ث', color: rt < .33 ? GamesTheme.gold : Colors.white, size: 16);
      fx.burst(cx + 46, cy, rt < .33 ? 28 : 14, GamesTheme.success, speed: 120, size: 9);
      buzz(rt < .33 ? 2 : 1);
      _check();
    } else if (state == 'yellow') {
      faults++;
      pop(cx, cy - 52, 'لا! هذي صفرا', color: GamesTheme.danger, size: 15);
      buzz(2);
      _next();
    } else {
      faults++;
      pop(cx, cy - 52, 'استعجلت!', color: GamesTheme.danger, size: 15);
      buzz(2);
      _next();
    }
  }

  @override
  void auto(double dt) {
    if (state == 'green' && t - goT > .27) down(Offset.zero);
  }

  void _check() {
    if (greens >= need) {
      final avg = times.reduce((a, b) => a + b) / times.length;
      var st = avg < .36 ? 3 : (avg < .5 ? 2 : 1);
      if (faults > 2) st = min(st, 1);
      finish(st, 'عين الصقر!', 'متوسط ردّة فعلك ${avg.toStringAsFixed(2)} ث · أخطاء $faults',
          score: max(0, (1000 - avg * 1000).round()));
    } else {
      _next();
    }
  }

  @override
  void update(double dt) {
    tm -= dt;
    if (state == 'red' && tm <= 0) {
      if (level >= 2 && rng.nextDouble() < .28) {
        state = 'yellow';
        tm = 1.1;
        lamp = 1;
      } else {
        state = 'green';
        goT = t;
        tm = 1.6;
        lamp = 2;
      }
    } else if (state == 'yellow' && tm <= 0) {
      pop(vw / 2, band + 48, 'تمام، صبرت', color: const Color(0xFF9FD0FF), size: 13);
      _next();
    } else if (state == 'green' && tm <= 0) {
      times.add(1.6);
      greens++;
      pop(vw / 2, band + 48, 'تأخرت شوية', color: GamesTheme.muted, size: 13);
      _check();
    }
  }

  @override
  void draw(Canvas c) {
    Kit.nightSky(c, Rect.fromLTWH(-4, -4, vw + 8, vh + 8));
    for (var i = 0; i < 22; i++) {
      Kit.glow(c, Offset((i * 97) % vw, 30 + (i * 53) % max(60, vh - 50)), 8 + (i % 4) * 4,
          i % 3 == 0 ? GamesTheme.warmWindow : GamesTheme.coolWindow, .12);
    }
    const cols = [Color(0xFFFF4D6D), Color(0xFFF6D365), Color(0xFF2EE59D)];
    final hx = vw / 2, hy = band + 100;
    const lx = [-40.0, 0.0, 40.0];
    final lit = cols[lamp];
    Kit.glow(c, Offset(hx + lx[lamp], hy), 45, lit, .5);
    Kit.pool(c, Offset(hx + lx[lamp], hy + 74), 26, 70, lit, .25);
    c.drawRect(Rect.fromLTWH(hx - 3, hy + 26, 6, vh - hy), Paint()..color = const Color(0xFF0E1D40));
    final box = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hx, hy), width: 132, height: 52), const Radius.circular(16));
    c.drawRRect(box, Paint()..color = const Color(0xFF0B1838));
    c.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: .12));
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(hx + lx[i], hy), 16, Paint()..color = i == lamp ? cols[i] : Colors.white.withValues(alpha: .08));
    }
    // the taxi waiting at the line
    Kit.car(c, Offset(hx, hy + 70 > vh - 16 ? vh - 16 : hy + 70), -pi / 2, 26, skin);
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'أخطاء $faults', b: '$greens/$need', cText: 'خضرا');
}

/// «عبّي الخزان» — hold to fill, release inside the green band. Don't overflow.
class FuelWorld extends GameWorld {
  FuelWorld() : super(10);
  @override
  String get hint => 'خلّي صبعك يعبّي · فكّه وسط المنطقة الخضرا';

  double value = 0, rate = 0, z0 = .5, zw = .2, evalT = 0;
  bool hold = false;
  String state = 'idle';
  int fills = 0, pts = 0;
  final List<int> res = [];

  void _setup() {
    value = 0;
    rate = 0;
    zw = max(.07, .22 - level * .015);
    z0 = .35 + rng.nextDouble() * (.55 - zw);
    state = 'idle';
    evalT = 0;
  }

  @override
  void start() {
    fills = 0;
    pts = 0;
    res.clear();
    _setup();
  }

  @override
  void down(Offset p) {
    if (state == 'idle') {
      state = 'fill';
      hold = true;
    }
  }

  @override
  void up(Offset p) {
    if (state == 'fill' && hold) {
      hold = false;
      _judge();
    }
  }

  @override
  void auto(double dt) {
    if (state == 'idle') down(Offset.zero);
    if (state == 'fill' && value >= z0 + zw * .45) up(Offset.zero);
  }

  void _judge() {
    final center = z0 + zw / 2;
    int s;
    String msg;
    if (value > 1) {
      s = 0;
      msg = 'دفقت!';
    } else if (value >= z0 && value <= z0 + zw) {
      s = (value - center).abs() < zw * .18 ? 3 : 2;
      msg = s == 3 ? 'بالضبط!' : 'زين';
    } else {
      s = (value - center).abs() < zw ? 1 : 0;
      msg = value < z0 ? 'ناقص شوية' : 'زايد شوية';
    }
    res.add(s);
    pts += s;
    final g = _gauge();
    pop(g.$1.dx, g.$1.dy - g.$2 - 14, msg, color: s == 3 ? GamesTheme.gold : (s > 0 ? Colors.white : GamesTheme.danger), size: 15);
    fx.burst(g.$1.dx, g.$1.dy, s == 3 ? 28 : 12, s > 0 ? GamesTheme.success : GamesTheme.danger, speed: 100, size: 8);
    buzz(s >= 2 ? 2 : 1);
    state = 'done';
    fills++;
  }

  (Offset, double) _gauge() {
    final r = min(80.0, min(vw * .32, vh * .42));
    return (Offset(vw / 2, band + 100 + r * .45), r);
  }

  @override
  void update(double dt) {
    if (state == 'fill') {
      rate = min(1.2, rate + dt * (.5 + level * .05));
      final wobble = level >= 3 ? (1 + .35 * sin(t * 6)) : 1.0;
      value += rate * wobble * dt * .55;
      if (value > 1.02) {
        hold = false;
        _judge();
      }
      if (!reduced && rng.nextDouble() < .3) {
        final g = _gauge();
        fx.burst(g.$1.dx - g.$2 - 18, g.$1.dy - 10, 1, const Color(0xFF7FD3FF), speed: 30, size: 5, life: .5);
      }
    } else if (state == 'done') {
      evalT += dt;
      if (evalT > 1) {
        if (fills >= 5) {
          final st = pts >= 13 ? 3 : (pts >= 8 ? 2 : (pts >= 3 ? 1 : 0));
          finish(st, st > 0 ? 'يد ثابتة!' : 'عاودها', 'خمس تعبيات · نقاطك $pts من 15', score: pts);
        } else {
          _setup();
        }
      }
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.radial(Offset(vw / 2, vh * .6), max(vw, vh), const [Color(0xFF10285A), Color(0xFF040B1E)]));
    final g = _gauge();
    final o = g.$1, r = g.$2;
    final arc = Rect.fromCircle(center: o, radius: r);
    c.drawArc(arc, pi, pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .08));
    c.drawArc(arc, pi + pi * z0, pi * zw, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = GamesTheme.success.withValues(alpha: .85));
    final f = clampD(value, 0, 1.05);
    c.drawArc(arc, pi, pi * min(1, f), false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(o, const [GamesTheme.brand, GamesTheme.brandLight, Color(0xFF7FD3FF)], const [0, .5, 1], TileMode.clamp, pi, pi * 2));
    final na = pi + pi * min(1.0, f);
    final tip = o + Offset(cos(na), sin(na)) * (r - 6);
    Kit.glow(c, tip, 12, const Color(0xFF7FD3FF), .7);
    c.drawLine(o, tip, Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    c.drawCircle(o, 6, Paint()..color = Colors.white);
    // pump and nozzle
    final px = o.dx - r - 34;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 12, o.dy - 50, 24, 50), const Radius.circular(6)), Paint()..color = const Color(0xFF13234A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 8, o.dy - 44, 16, 10), const Radius.circular(3)), Paint()..color = GamesTheme.brand.withValues(alpha: .7));
    Kit.icon(c, 'car', Offset(o.dx + r + 34, o.dy - 14), 26, skin);
    Kit.text(c, '${(min(1.0, value) * 100).round()}%', o.translate(0, -r * .42), 16);
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'نقاط $pts', b: '${min(5, fills + (state == 'done' ? 0 : 1))}/5', cText: 'تعبية');
}

/// «الغمّاز» — tap on the beat of the blinker; the ring shrinks onto the arrow.
class BlinkerWorld extends GameWorld {
  BlinkerWorld() : super(11);
  @override
  String get hint => 'اضغط لما الدايرة تلمس السهم';

  double beat = .75, startAt = 1.2;
  int total = 16, perfect = 0, good = 0, miss = 0, streak = 0, bestStreak = 0;
  final Set<int> judged = {};

  double _time(int i) => startAt + i * beat;

  @override
  void start() {
    beat = 60 / (78 + min(level, 12) * 6);
    total = 14 + min(level, 6);
    judged.clear();
  }

  int get _nearest => ((t - startAt) / beat).round().clamp(0, total - 1);

  @override
  void down(Offset p) {
    final i = _nearest;
    if (judged.contains(i)) return;
    final d = (t - _time(i)).abs();
    final o = Offset(vw / 2, band + 100);
    if (d < .1) {
      perfect++;
      streak++;
      judged.add(i);
      fx.burst(o.dx, o.dy, 24, GamesTheme.gold, speed: 120, size: 9);
      pop(o.dx, o.dy - 50, 'ممتاز', color: GamesTheme.gold, size: 15);
      buzz(2);
    } else if (d < .2) {
      good++;
      streak++;
      judged.add(i);
      fx.burst(o.dx, o.dy, 12, const Color(0xFF5AAAFF), speed: 90, size: 7);
      pop(o.dx, o.dy - 50, 'زين', color: const Color(0xFF9FD0FF), size: 14);
      buzz();
    } else {
      streak = 0;
      pop(o.dx, o.dy - 50, 'بدري', color: GamesTheme.muted, size: 12);
    }
    bestStreak = max(bestStreak, streak);
  }

  @override
  void auto(double dt) {
    final i = _nearest;
    if (!judged.contains(i) && (t - _time(i)).abs() < .04) down(Offset.zero);
  }

  @override
  void update(double dt) {
    for (var i = 0; i < total; i++) {
      if (!judged.contains(i) && t > _time(i) + .2) {
        judged.add(i);
        miss++;
        streak = 0;
      }
    }
    if (t > _time(total - 1) + .5) {
      final acc = (perfect + good * .6) / total;
      final st = acc > .85 ? 3 : (acc > .6 ? 2 : (acc > .3 ? 1 : 0));
      finish(st, st > 0 ? 'على الإيقاع!' : 'عاودها', 'ممتاز $perfect · زين $good · فاتك $miss', score: perfect * 2 + good);
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.radial(Offset(vw / 2, band + 100), max(vw, vh) * .7, const [Color(0xFF0F2754), Color(0xFF040B1E)]));
    final o = Offset(vw / 2, band + 100);
    final i = ((t - startAt) / beat).floor();
    final left = (max(0, i) ~/ 4).isEven;
    final phase = ((t - startAt) / beat) - i;
    final onBeat = phase < .25 && t >= startAt;
    // dashboard arc
    c.drawArc(Rect.fromCircle(center: o.translate(0, 70), radius: 110), pi * 1.1, pi * .8, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: .1));
    final arrow = Path();
    final dir = left ? 1.0 : -1.0;
    arrow
      ..moveTo(o.dx - 22 * dir, o.dy)
      ..lineTo(o.dx + 4 * dir, o.dy - 20)
      ..lineTo(o.dx + 4 * dir, o.dy - 8)
      ..lineTo(o.dx + 24 * dir, o.dy - 8)
      ..lineTo(o.dx + 24 * dir, o.dy + 8)
      ..lineTo(o.dx + 4 * dir, o.dy + 8)
      ..lineTo(o.dx + 4 * dir, o.dy + 20)
      ..close();
    if (onBeat) Kit.glow(c, o, 50, const Color(0xFF7FD3FF), .55);
    c.drawPath(arrow, Paint()..color = onBeat ? const Color(0xFF7FD3FF) : const Color(0xFF1C3566));
    // approaching ring for the next beat
    final next = ((t - startAt) / beat).ceil();
    if (next < total && next >= 0) {
      final until = _time(next) - t;
      final rr = 30 + clampD(until / beat, 0, 1) * 60;
      c.drawCircle(o, rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: .25 + .6 * (1 - clampD(until / beat, 0, 1))));
    }
    c.drawCircle(o, 30, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = GamesTheme.brand);
    final prog = clampD((t - startAt) / (beat * total), 0, 1);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(vw * .2, band + 172, vw * .6, 5), const Radius.circular(3)), Paint()..color = Colors.white.withValues(alpha: .1));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(vw * .2, band + 172, vw * .6 * prog, 5), const Radius.circular(3)), Paint()..color = GamesTheme.brandLight);
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'فاتك $miss', b: '${perfect + good}', cText: 'سلسلة $streak');
}

/// «شنطة فوق شنطة» — a bag slides above the roof rack; tap to drop it. Overhang falls off.
class BagsWorld extends GameWorld {
  BagsWorld() : super(12);
  @override
  String get hint => 'اضغط باش تطيّح الشنطة فوق اللي تحتها';

  final List<(double, double)> stack = []; // left, width (in units)
  double mx = 0, mw = 60, dirX = 1, speed = 90, drop = -1, cam = 0, camT = 0;
  int placed = 0, perfect = 0, target = 9;
  final List<List<double>> chips = []; // falling trimmed pieces x, y, w, vy
  static const bagH = 16.0;
  static const bagCols = [Color(0xFF3D9BFF), Color(0xFFC9D2E0), Color(0xFF1F3B66), Color(0xFF7FD3FF), Color(0xFFA78BFA), Color(0xFF2FC6A0)];

  double get baseY => vh - 26 - min(60, vh * .08) + cam;
  double get roofY => baseY - carLen * .48;
  double get carLen => min(120, vw * .55);

  @override
  void start() {
    stack
      ..clear()
      ..add((vw / 2 - carLen * .25, carLen * .5));
    mw = carLen * .5;
    mx = 10;
    speed = 80 + min(level, 12) * 12;
    target = 8 + min(level, 6);
    placed = 0;
    perfect = 0;
    cam = 0;
    camT = 0;
  }

  @override
  void onResize() {
    // keep the stack centred on the new width
    if (stack.isEmpty) return;
    final shift = vw / 2 - (stack.first.$1 + stack.first.$2 / 2);
    for (var i = 0; i < stack.length; i++) {
      stack[i] = (stack[i].$1 + shift, stack[i].$2);
    }
  }

  double _yOf(int i) => roofY - i * bagH;

  @override
  void down(Offset p) {
    if (drop >= 0) return;
    drop = 0;
  }

  @override
  void auto(double dt) {
    final top = stack.last;
    if (drop < 0 && (mx - top.$1).abs() < 3) down(Offset.zero);
  }

  @override
  void update(double dt) {
    final topY = _yOf(stack.length);
    if (drop < 0) {
      mx += dirX * speed * dt;
      if (mx < 4) {
        mx = 4;
        dirX = 1;
      }
      if (mx + mw > vw - 4) {
        mx = vw - 4 - mw;
        dirX = -1;
      }
    } else {
      drop += dt * 340;
      final hover = topY - 46;
      if (hover + drop >= topY) {
        final top = stack.last;
        final l = max(mx, top.$1), r = min(mx + mw, top.$1 + top.$2);
        drop = -1;
        if (r - l <= 2) {
          chips.add([mx, topY, mw, 0]);
          pop(vw / 2, topY - 20, 'طاحت!', color: GamesTheme.danger, size: 15);
          buzz(2);
          _end();
          return;
        }
        if ((mx - top.$1).abs() < 2.5) {
          perfect++;
          stack.add((top.$1, top.$2));
          fx.burst(top.$1 + top.$2 / 2, topY, 22, GamesTheme.gold, speed: 110, size: 8);
          pop(top.$1 + top.$2 / 2, topY - 22, 'ممتاز!', color: GamesTheme.gold);
          buzz(2);
        } else {
          if (mx < l) chips.add([mx, topY, l - mx, 0]);
          if (mx + mw > r) chips.add([r, topY, mx + mw - r, 0]);
          stack.add((l, r - l));
          buzz();
        }
        placed++;
        mw = stack.last.$2;
        mx = dirX > 0 ? 4 : vw - 4 - mw;
        speed *= 1.04;
        if (_yOf(stack.length) < vh * .38) camT += bagH;
        if (placed >= target) _end();
      }
    }
    cam += (camT - cam) * min(1, dt * 5);
    for (final ch in chips) {
      ch[3] += 600 * dt;
      ch[1] += ch[3] * dt;
    }
    chips.removeWhere((ch) => ch[1] > vh + 40);
  }

  void _end() {
    final st = placed >= target && perfect >= target ~/ 2 ? 3 : (placed >= target ? 2 : (placed >= target ~/ 2 ? 1 : 0));
    finish(st, st > 0 ? 'رصّة مرتّبة!' : 'طاحت، عاودها', 'رصّيت $placed من $target · ممتاز $perfect', score: placed * 10 + perfect * 5);
  }

  @override
  void draw(Canvas c) {
    Kit.nightSky(c, Rect.fromLTWH(-4, -4, vw + 8, vh + 8));
    for (var i = 0; i < 18; i++) {
      Kit.glow(c, Offset((i * 83) % vw, 20 + (i * 47) % max(40, vh - 60) + cam * .2), 6 + (i % 3) * 4, GamesTheme.coolWindow, .1);
    }
    c.drawRect(Rect.fromLTWH(-4, baseY, vw + 8, vh - baseY + 8), Paint()..color = const Color(0xFF0E1A36));
    c.drawLine(Offset(-4, baseY), Offset(vw + 4, baseY), Paint()
      ..color = GamesTheme.brand
      ..strokeWidth = 2);
    Kit.carSide(c, Offset(vw / 2, baseY), carLen, skin);
    final sway = reduced ? 0.0 : sin(t * 1.6) * min(4, stack.length * .35);
    for (var i = 1; i < stack.length; i++) {
      final s = stack[i];
      final dx = sway * (i / max(1, stack.length));
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(s.$1 + dx, _yOf(i), s.$2, bagH - 1.5), const Radius.circular(4));
      c.drawRRect(r, Paint()..color = bagCols[i % bagCols.length]);
      c.drawRect(Rect.fromLTWH(s.$1 + dx + s.$2 / 2 - 3, _yOf(i) + 1, 6, 2.5), Paint()..color = Colors.black.withValues(alpha: .25));
    }
    if (!over) {
      final y = drop < 0 ? _yOf(stack.length) - 46 : _yOf(stack.length) - 46 + drop;
      final col = bagCols[stack.length % bagCols.length];
      Kit.glow(c, Offset(mx + mw / 2, y + bagH / 2), mw * .6, col, .25);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx, y, mw, bagH - 1.5), const Radius.circular(4)), Paint()..color = col);
      if (drop < 0) {
        c.drawLine(Offset(mx + mw / 2, y + bagH), Offset(mx + mw / 2, _yOf(stack.length)), Paint()
          ..color = Colors.white.withValues(alpha: .22)
          ..strokeWidth = 1);
      }
    }
    for (final ch in chips) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ch[0], ch[1], ch[2], bagH - 1.5), const Radius.circular(3)),
          Paint()..color = const Color(0xFF8C98AD).withValues(alpha: .8));
    }
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'ممتاز $perfect', b: '$placed/$target', cText: 'شنطة');
}
