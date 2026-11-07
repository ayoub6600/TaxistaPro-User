import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/game_core.dart';
import '../core/paint_kit.dart';
import '../core/theme.dart';

/// «نجوم الكورنيش» — tap the stars in order to draw the night constellation.
class StarsWorld extends GameWorld {
  StarsWorld() : super(13);
  @override
  String get hint => 'اضغط النجوم بالترتيب: 1 ثم 2 ثم 3…';

  final List<Offset> stars = [];
  int next = 0, mistakes = 0;
  double elapsed = 0;

  void _place() {
    stars.clear();
    final n = min(14, 6 + level);
    final top = 36.0, bottom = vh - 30;
    for (var tries = 0; stars.length < n && tries < 4000; tries++) {
      final p = Offset(18 + rng.nextDouble() * (vw - 36), top + rng.nextDouble() * max(20, bottom - top));
      if (stars.every((s) => (s - p).distance > 34)) stars.add(p);
    }
    while (stars.length < n) {
      stars.add(Offset(18 + rng.nextDouble() * (vw - 36), top + rng.nextDouble() * max(20, bottom - top)));
    }
    // order as a walk from the right edge to the nearest star each time: a clean constellation line
    final left = List.of(stars)..sort((a, b) => b.dx.compareTo(a.dx));
    final ordered = <Offset>[left.removeAt(0)];
    while (left.isNotEmpty) {
      left.sort((a, b) => (a - ordered.last).distance.compareTo((b - ordered.last).distance));
      ordered.add(left.removeAt(0));
    }
    stars
      ..clear()
      ..addAll(ordered);
  }

  @override
  void start() {
    next = 0;
    mistakes = 0;
    elapsed = 0;
    _place();
  }

  @override
  void onResize() {
    // keep the order and progress, spread the stars over the new area
    final old = List.of(stars);
    _place();
    if (old.length == stars.length) return;
  }

  @override
  void down(Offset p) {
    if (next >= stars.length) return;
    var hit = -1;
    for (var i = 0; i < stars.length; i++) {
      if ((stars[i] - p).distance < 22) hit = i;
    }
    if (hit == next) {
      fx.burst(stars[hit].dx, stars[hit].dy, 16, GamesTheme.gold, speed: 90, size: 7);
      next++;
      buzz();
      if (next == stars.length) {
        fx.burst(vw / 2, vh / 2, 40, const Color(0xFF7FD3FF), speed: 160, size: 9, life: 1);
        final n = stars.length;
        final st = elapsed < n * .9 && mistakes == 0 ? 3 : (elapsed < n * 1.5 ? 2 : 1);
        finish(st, 'صياد النجوم!', 'رسمت $n نجمة في ${elapsed.toStringAsFixed(1)} ث · غلطات $mistakes',
            score: max(0, (n * 100 - elapsed * 10).round()));
      }
    } else if (hit >= 0 && hit > next) {
      mistakes++;
      elapsed += 1;
      shake = .2;
      pop(stars[hit].dx, stars[hit].dy - 20, '−1 ث', color: GamesTheme.danger, size: 12);
      buzz(2);
    }
  }

  @override
  void auto(double dt) {
    if (next < stars.length && (t * 3).floor() > next) down(stars[next]);
  }

  @override
  void update(double dt) => elapsed += dt;

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, vh), const [Color(0xFF030919), Color(0xFF0D2452)]));
    final r = Random(level * 3);
    for (var i = 0; i < 70; i++) {
      c.drawCircle(Offset(r.nextDouble() * vw, r.nextDouble() * vh), r.nextDouble() * .9 + .2,
          Paint()..color = GamesTheme.ink.withValues(alpha: .2 + .25 * sin(t * 1.3 + i)));
    }
    // sea and a far city line at the bottom
    c.drawRect(Rect.fromLTWH(-4, vh - 22, vw + 8, 26), Paint()..color = const Color(0xFF071637));
    for (var i = 0; i < 12; i++) {
      c.drawRect(Rect.fromLTWH((i * 61 + t * 6) % vw, vh - 16 + (i % 3) * 4, 6, .8),
          Paint()
            ..blendMode = BlendMode.plus
            ..color = GamesTheme.warmWindow.withValues(alpha: .25));
    }
    if (next > 1) {
      final path = Path()..moveTo(stars[0].dx, stars[0].dy);
      for (var i = 1; i < next; i++) {
        path.lineTo(stars[i].dx, stars[i].dy);
      }
      c.drawPath(
          path,
          Paint()
            ..blendMode = BlendMode.plus
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFF7FD3FF).withValues(alpha: .8));
    }
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final done = i < next, isNext = i == next;
      Kit.glow(c, s, done ? 16 : (isNext ? 18 + sin(t * 6) * 3 : 11), done ? GamesTheme.gold : const Color(0xFFBEDCFF), done ? .8 : .45);
      Kit.icon(c, 'star', s, done ? 12 : 10, done ? GamesTheme.gold : Colors.white);
      if (!done) Kit.text(c, '${i + 1}', s.translate(0, 14), 9, color: isNext ? Colors.white : GamesTheme.muted);
    }
  }

  @override
  void hud(Canvas c) => hudPill(c, a: '${elapsed.toStringAsFixed(1)} ث', b: '$next/${stars.length}', cText: 'نجوم');
}

/// «ذاكرة الركاب» — flip two windows, find the matching places.
class MemoryWorld extends GameWorld {
  MemoryWorld() : super(14);
  @override
  String get hint => 'اقلب مربعين ولقّى الزوج المتشابه';

  static const kinds = ['house', 'mosque', 'hosp', 'market', 'school', 'sea', 'palm', 'car'];
  static const kindCols = [Color(0xFF3D9BFF), Color(0xFF2FC6A0), Color(0xFFFF5A6E), Color(0xFFF6D365), Color(0xFFA78BFA), Color(0xFF7FD3FF), Color(0xFF2FC6A0), Color(0xFFEEF3FA)];
  final List<int> cards = [];
  final List<double> flip = []; // 0 hidden .. 1 shown
  final Set<int> matched = {}, open = {};
  int moves = 0, cols = 4, rows = 2;
  double resolveT = 0;
  double cw = 40, chh = 40, ox = 0, oy = 0;

  int get pairs => level <= 1 ? 4 : (level <= 2 ? 5 : 6);

  void _layout() {
    final n = cards.length;
    var best = 0.0;
    for (var c0 = 2; c0 <= n; c0++) {
      final r0 = (n / c0).ceil();
      final s = min((vw - 20) / c0, (vh - 44) / r0);
      if (s > best) {
        best = s;
        cols = c0;
        rows = r0;
      }
    }
    cw = min(best - 8, 74);
    chh = cw * 1.12 > (vh - 44) / rows - 8 ? (vh - 44) / rows - 8 : cw * 1.12;
    ox = (vw - cols * (cw + 8) + 8) / 2;
    oy = 34 + ((vh - 34) - rows * (chh + 8) + 8) / 2;
  }

  Rect _rect(int i) => Rect.fromLTWH(ox + (i % cols) * (cw + 8), oy + (i ~/ cols) * (chh + 8), cw, chh);

  @override
  void start() {
    cards
      ..clear()
      ..addAll([for (var i = 0; i < pairs; i++) ...[i, i]])
      ..shuffle(rng);
    flip
      ..clear()
      ..addAll(List.filled(cards.length, 0));
    matched.clear();
    open.clear();
    moves = 0;
    _layout();
  }

  @override
  void onResize() => _layout();

  @override
  void down(Offset p) {
    if (open.length >= 2) return;
    for (var i = 0; i < cards.length; i++) {
      if (_rect(i).inflate(3).contains(p) && !matched.contains(i) && !open.contains(i)) {
        open.add(i);
        buzz();
        if (open.length == 2) {
          moves++;
          resolveT = .65;
        }
        return;
      }
    }
  }

  @override
  void auto(double dt) {
    if (open.length >= 2) return;
    // a perfect memory: find a pair among already seen cards, else open the next unseen
    for (var i = 0; i < cards.length; i++) {
      if (!matched.contains(i) && !open.contains(i)) {
        if (open.isEmpty || cards[open.first] == cards[i]) {
          down(_rect(i).center);
          return;
        }
      }
    }
  }

  @override
  void update(double dt) {
    for (var i = 0; i < flip.length; i++) {
      final target = (matched.contains(i) || open.contains(i)) ? 1.0 : 0.0;
      flip[i] += (target - flip[i]) * min(1, dt * 12);
    }
    if (open.length == 2) {
      resolveT -= dt;
      if (resolveT <= 0) {
        final a = open.first, b = open.last;
        if (cards[a] == cards[b]) {
          matched.addAll(open);
          final r = _rect(a).center;
          fx.burst(r.dx, r.dy, 18, kindCols[cards[a]], speed: 100, size: 8);
          final r2 = _rect(b).center;
          fx.burst(r2.dx, r2.dy, 18, kindCols[cards[a]], speed: 100, size: 8);
          buzz(2);
          if (matched.length == cards.length) {
            final st = moves <= pairs + 2 ? 3 : (moves <= pairs * 2 ? 2 : 1);
            finish(st, 'ذاكرة حديد!', '$pairs أزواج في $moves محاولة', score: max(0, 100 - moves * 5));
          }
        }
        open.clear();
      }
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.radial(Offset(vw / 2, vh / 2), max(vw, vh) * .7, const [Color(0xFF10285A), Color(0xFF040B1E)]));
    for (var i = 0; i < cards.length; i++) {
      final r = _rect(i), f = flip[i];
      final sx = (f - .5).abs() * 2;
      final shown = f > .5;
      final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: r.width * max(.05, sx), height: r.height), const Radius.circular(10));
      if (shown) {
        c.drawRRect(rr, Paint()..color = matched.contains(i) ? const Color(0xFF16305F) : const Color(0xFF1B3B72));
        if (sx > .3) Kit.icon(c, kinds[cards[i]], r.center, min(r.width, r.height) * .48 * sx, kindCols[cards[i]]);
        if (matched.contains(i)) Kit.glow(c, r.center, r.width * .5, kindCols[cards[i]], .18);
      } else {
        c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [Color(0xFF1965BF), Color(0xFF102A56)]));
        if (sx > .3) {
          c.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: r.width * .5 * sx, height: r.height * .38), const Radius.circular(4)),
              Paint()..color = const Color(0x55A0CDFF));
        }
      }
    }
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'محاولات $moves', b: '${matched.length ~/ 2}/$pairs', cText: 'أزواج');
}

/// «فرز الركاب» — swipe each passenger to the taxi of their colour (or tap that side).
class SortWorld extends GameWorld {
  SortWorld() : super(15);
  @override
  String get hint => 'اسحب الراكب نحو التاكسي اللي بلونه';

  int colorNow = 0, done = 0, mistakes = 0, streak = 0, target = 16;
  double patience = 3, patM = 3, fly = 0;
  int flyTo = -1;
  bool swapped = false;
  Offset? _start;
  static const cols = [GamesTheme.brand, Color(0xFFEEF3FA)];

  bool get vertical => vh > vw * 1.15;

  Offset _taxi(int side) {
    final s = swapped ? 1 - side : side;
    return vertical ? Offset(vw / 2, s == 0 ? 52 : vh - 30) : Offset(s == 0 ? 36 : vw - 36, vh / 2 + 10);
  }

  Offset get mid => vertical ? Offset(vw / 2, vh / 2) : Offset(vw / 2, vh / 2 + 10);

  void _next() {
    colorNow = rng.nextInt(2);
    patM = patience = max(1.4, 3.2 - level * .15 - done * .04);
    fly = 0;
    flyTo = -1;
    if (level >= 3 && done > 0 && done % 6 == 0) {
      swapped = !swapped;
      pop(mid.dx, mid.dy - 40, 'انتبه! التاكسيات تبدّلت', color: const Color(0xFF9FD0FF), size: 13);
    }
  }

  @override
  void start() {
    done = 0;
    mistakes = 0;
    target = 14 + min(level, 8);
    _next();
  }

  void _send(int side) {
    if (flyTo >= 0) return;
    flyTo = side;
    final ok = side == colorNow;
    final p = _taxi(side);
    if (ok) {
      done++;
      streak++;
      fx.burst(p.dx, p.dy, 16, cols[colorNow], speed: 100, size: 8);
      if (streak % 5 == 0) pop(p.dx, p.dy - 22, 'سلسلة $streak!', color: GamesTheme.gold);
      buzz();
    } else {
      mistakes++;
      streak = 0;
      shake = .2;
      pop(p.dx, p.dy - 22, 'مش هذا!', color: GamesTheme.danger);
      buzz(2);
    }
  }

  int _sideFor(Offset p) {
    final a = _taxi(0), b = _taxi(1);
    return (p - a).distance < (p - b).distance ? 0 : 1;
  }

  @override
  void down(Offset p) => _start = p;

  @override
  void up(Offset p) {
    final s = _start;
    _start = null;
    if (s == null) return;
    final d = p - s;
    if (d.distance > 14) {
      _send(_sideFor(mid + d * 4));
    } else {
      _send(_sideFor(p));
    }
  }

  @override
  void auto(double dt) {
    if (flyTo < 0 && patience < patM - .3) _send(colorNow);
  }

  @override
  void update(double dt) {
    if (flyTo >= 0) {
      fly += dt / .3;
      if (fly >= 1) {
        if (done >= target || mistakes >= 3) {
          final st = mistakes == 0 && done >= target ? 3 : (done >= target ? 2 : (done >= target ~/ 2 ? 1 : 0));
          finish(st, st > 0 ? 'منظّم المحطة!' : 'عاودها', 'فرزت $done · غلطات $mistakes', score: done);
        } else {
          _next();
        }
      }
      return;
    }
    patience -= dt;
    if (patience <= 0) {
      mistakes++;
      streak = 0;
      pop(mid.dx, mid.dy - 30, 'تأخرت', color: GamesTheme.danger);
      if (mistakes >= 3) {
        finish(done >= target ~/ 2 ? 1 : 0, 'عاودها', 'فرزت $done · غلطات $mistakes', score: done);
      } else {
        _next();
      }
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.radial(mid, max(vw, vh) * .7, const [Color(0xFF10285A), Color(0xFF040B1E)]));
    // platform
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: mid, width: 70, height: 70), const Radius.circular(20)),
        Paint()..color = const Color(0xFF13234A));
    for (var s = 0; s < 2; s++) {
      final p = _taxi(s), col = cols[swapped ? 1 - s : s];
      Kit.glow(c, p, 30, col, .35);
      Kit.car(c, p, vertical ? (s == 0 ? -pi / 2 : pi / 2) : (s == 0 ? pi : 0), 40, col);
    }
    final shape = colorNow;
    Offset at = mid;
    if (flyTo >= 0) at = Offset.lerp(mid, _taxi(flyTo), smooth(fly))!;
    final col = cols[colorNow];
    Kit.glow(c, at, 26, col, .55);
    if (shape == 0) {
      c.drawCircle(at, 15, Paint()..color = col);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 28, height: 28), const Radius.circular(6)), Paint()..color = col);
    }
    Kit.icon(c, 'house', at, 12, shape == 0 ? Colors.white : GamesTheme.navy);
    if (flyTo < 0) {
      final f = clampD(patience / patM, 0, 1);
      c.drawArc(Rect.fromCircle(center: mid, radius: 30), -pi / 2, tau * f, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = f < .35 ? GamesTheme.danger : GamesTheme.brandLight);
    }
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'غلطات $mistakes', b: '$done/$target', cText: 'سلسلة $streak');
}

/// «غسيل وتلميع» — scrub the dirt off the taxi with your finger before time runs out.
class WashWorld extends GameWorld {
  WashWorld() : super(16);
  @override
  String get hint => 'امسح بصبعك على التاكسي لين يلمع';

  final List<List<double>> dirt = []; // local x, local y, radius, amount 0..1
  double timeLeft = 18, timeMax = 18, shine = 0;
  Offset? last;

  bool get vertical => vh > vw * 1.1;
  double get carLen => vertical ? min(vh * .62, vw * 1.3) : min(vw * .6, vh * 1.2);
  Offset get carC => Offset(vw / 2, vh / 2 + 8);

  Offset _toLocal(Offset p) {
    final d = p - carC;
    return vertical ? Offset(-d.dy, d.dx) : d;
  }

  @override
  void start() {
    dirt.clear();
    final n = 14 + min(level, 10) * 2;
    final l = carLen, w = l * .54;
    for (var i = 0; i < n; i++) {
      dirt.add([(rng.nextDouble() - .5) * l * .9, (rng.nextDouble() - .5) * w * .85, 8 + rng.nextDouble() * 10, 1]);
    }
    timeMax = timeLeft = max(10, 20 - level * .6);
  }

  void _scrub(Offset p) {
    final lp = _toLocal(p);
    final dist = last == null ? 4.0 : (p - last!).distance;
    last = p;
    for (final d in dirt) {
      if (d[3] <= 0) continue;
      if ((Offset(d[0], d[1]) - lp).distance < d[2] + 10) {
        d[3] = max(0, d[3] - dist / 60);
        if (d[3] == 0) {
          fx.burst(p.dx, p.dy, 6, const Color(0xFFBEDCFF), speed: 60, size: 6, life: .6);
          buzz();
        }
      }
    }
    if (!reduced && rng.nextDouble() < .5) fx.burst(p.dx, p.dy, 1, const Color(0xFFEAF4FF), speed: 25, size: 7, life: .8);
  }

  @override
  void down(Offset p) {
    last = null;
    _scrub(p);
  }

  @override
  void move(Offset p) => _scrub(p);
  @override
  void up(Offset p) => last = null;

  @override
  void auto(double dt) {
    for (final d in dirt) {
      if (d[3] > 0) {
        final lp = Offset(d[0], d[1]);
        final sp = vertical ? Offset(lp.dy, -lp.dx) + carC : lp + carC;
        move(sp + Offset(sin(t * 30) * 6, 0));
        return;
      }
    }
  }

  double get clean => dirt.isEmpty ? 1 : 1 - dirt.fold(0.0, (a, d) => a + d[3]) / dirt.length;

  @override
  void update(double dt) {
    timeLeft -= dt;
    if (clean >= .999) {
      shine += dt;
      if (shine > .1 && shine - dt <= .1) fx.burst(carC.dx, carC.dy, 40, const Color(0xFF7FD3FF), speed: 170, size: 9, life: 1);
      if (shine > .6) {
        final st = timeLeft > timeMax * .45 ? 3 : (timeLeft > timeMax * .2 ? 2 : 1);
        finish(st, 'يلمع يلمع!', 'نظّفته وباقي ${timeLeft.ceil()} ث', score: (timeLeft * 10).round());
      }
    } else if (timeLeft <= 0) {
      final pc = clean;
      final st = pc > .9 ? 2 : (pc > .6 ? 1 : 0);
      finish(st, st > 0 ? 'قريب يلمع' : 'عاودها', 'نظّفت ${(pc * 100).round()}%', score: (pc * 100).round());
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8),
        Paint()..shader = ui.Gradient.radial(carC, max(vw, vh) * .7, const [Color(0xFF123068), Color(0xFF040B1E)]));
    for (var i = 0; i < 9; i++) {
      Kit.glow(c, Offset(vw * (i + .5) / 9, 16), 10, const Color(0xFFBEDCFF), .25);
    }
    final ang = vertical ? -pi / 2 : 0.0;
    Kit.car(c, carC, ang, carLen, skin);
    c.save();
    c.translate(carC.dx, carC.dy);
    c.rotate(ang);
    for (final d in dirt) {
      if (d[3] <= 0) continue;
      c.drawCircle(Offset(d[0], d[1]), d[2], Paint()..color = const Color(0xFF6B5A44).withValues(alpha: .75 * d[3]));
      c.drawCircle(Offset(d[0] + d[2] * .3, d[1] - d[2] * .2), d[2] * .45, Paint()..color = const Color(0xFF85704F).withValues(alpha: .6 * d[3]));
    }
    c.restore();
    if (shine > 0) Kit.glow(c, carC, carLen * .6, const Color(0xFFBEDCFF), .35 * (1 - clampD(shine, 0, 1)));
  }

  @override
  void hud(Canvas c) => hudPill(c,
      a: '${timeLeft.ceil()} ث', aColor: timeLeft < 5 ? GamesTheme.danger : Colors.white, b: '${(clean * 100).round()}%', cText: 'نظافة');
}
