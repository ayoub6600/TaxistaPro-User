import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/game_core.dart';
import '../core/paint_kit.dart';
import '../core/theme.dart';

class RidePlace {
  const RidePlace(this.k, this.name, this.color);
  final String k, name;
  final Color color;
}

const _places = [
  RidePlace('house', 'البيت', Color(0xFF3D9BFF)),
  RidePlace('mosque', 'الجامع', Color(0xFF2FC6A0)),
  RidePlace('hosp', 'المستشفى', Color(0xFFFF5A6E)),
  RidePlace('market', 'السوق', Color(0xFFF6D365)),
  RidePlace('school', 'المدرسة', Color(0xFFA78BFA)),
  RidePlace('sea', 'البحر', Color(0xFF7FD3FF)),
];

/// «الدوار» — the taxi circles the roundabout; one tap = take the NEXT exit. Bring the rider to the exit they want.
class RingWorld extends GameWorld {
  RingWorld() : super(5);
  @override
  String get hint => 'اضغط مرة · التاكسي ياخذ المخرج الجاي';
  static const rad = 56.0;

  final List<(double, RidePlace)> exits = [];
  double th = 0, om = 1.25, pr = 0, pat = 9, patM = 9;
  String state = 'circle';
  int commit = -1, exitIdx = 0, enterFrom = 0, served = 0, target = 6, mist = 0, streak = 0;
  RidePlace req = _places.first;
  ui.Picture? _bg;

  bool get wide => vw >= vh * 1.25;
  Offset get center => wide ? Offset(min(vw * .33, 150), vh / 2) : Offset(vw / 2, max(vh * .6, 150));
  Offset _pos(double a, double r) => center + Offset(cos(a) * r, sin(a) * r);

  @override
  void start() {
    final n = level <= 1 ? 4 : (level <= 3 ? 5 : 6);
    final base = rng.nextDouble() * tau;
    final pl = List.of(_places)..shuffle(rng);
    exits
      ..clear()
      ..addAll(List.generate(n, (i) => (base + i * tau / n + (rng.nextDouble() - .5) * .25, pl[i])));
    th = exits.first.$1 + .4;
    om = 1.25 + .07 * (level - 1);
    target = min(12, 5 + level);
    _newReq(null);
    _bg = null;
  }

  @override
  void onResize() => _bg = null;

  void _newReq(String? not) {
    RidePlace p;
    do {
      p = exits[rng.nextInt(exits.length)].$2;
    } while (exits.length > 1 && p.k == not);
    req = p;
    patM = pat = max(5, 9 - level * .45);
  }

  int _nextGate() {
    var best = 0;
    var bd = 99.0;
    for (var i = 0; i < exits.length; i++) {
      var d = ((th - exits[i].$1) % tau + tau) % tau;
      if (d < .02) d += tau;
      if (d < bd) {
        bd = d;
        best = i;
      }
    }
    return best;
  }

  @override
  void down(Offset p) {
    if (state != 'circle' || commit >= 0) return;
    commit = _nextGate();
    buzz();
  }

  @override
  void auto(double dt) {
    if (state == 'circle' && commit < 0 && exits[_nextGate()].$2.k == req.k) down(Offset.zero);
  }

  @override
  void update(double dt) {
    if (state == 'circle') {
      final before = th;
      th -= om * dt;
      pat -= dt;
      if (commit >= 0) {
        final d0 = ((before - exits[commit].$1) % tau + tau) % tau;
        if (d0 - om * dt <= 0 || d0 > tau - .05) {
          th = exits[commit].$1;
          exitIdx = commit;
          state = 'exit';
          pr = 0;
        }
      }
      if (pat <= 0 && state == 'circle') {
        mist++;
        streak = 0;
        pop(center.dx, center.dy - rad - 22, 'الراكب زعل ونزل', color: GamesTheme.danger, size: 13);
        buzz(2);
        _check();
        if (!over) _newReq(null);
      }
    } else if (state == 'exit') {
      pr += dt / .55;
      if (pr >= 1) {
        final e = exits[exitIdx];
        final p = _pos(e.$1, rad + 70);
        if (e.$2.k == req.k) {
          served++;
          streak++;
          om *= 1.05;
          fx.burst(p.dx, p.dy, 30, e.$2.color, speed: 140, size: 10, life: .8);
          pop(p.dx, p.dy - 16, streak > 2 ? 'تمام! ×$streak' : 'تمام!', color: e.$2.color, size: 15);
          buzz(2);
        } else {
          mist++;
          streak = 0;
          pop(p.dx, p.dy - 16, 'مش هذا المخرج!', color: GamesTheme.danger, size: 14);
          buzz(2);
        }
        _check();
        if (!over) {
          enterFrom = rng.nextInt(exits.length);
          state = 'enter';
          pr = 1;
          _newReq(exits[enterFrom].$2.k);
        }
        commit = -1;
      }
    } else if (state == 'enter') {
      pr -= dt / .45;
      if (pr <= 0) {
        th = exits[enterFrom].$1 - .02;
        state = 'circle';
      }
    }
  }

  void _check() {
    if (served >= target || mist >= 3) {
      final ratio = served / target;
      final st = mist == 0 && served >= target ? 3 : (ratio >= .7 ? 2 : (ratio >= .35 ? 1 : 0));
      finish(st, st > 0 ? 'وصّلت الركاب لمخارجهم!' : 'قريبة! عاودها', '$served من $target ركاب · غلطات $mist', score: served);
    }
  }

  @override
  void draw(Canvas c) {
    final o = center;
    _bg ??= Kit.cityBlocks(level * 91 + 1, vw, vh, keepClear: Rect.fromCircle(center: o, radius: rad + 30));
    c.drawPicture(_bg!);
    final road = Paint()
      ..color = const Color(0xFF14254A)
      ..strokeWidth = 24;
    final lane = Paint()
      ..color = Colors.white.withValues(alpha: .2)
      ..strokeWidth = 1.2;
    for (final e in exits) {
      final a = _pos(e.$1, rad), b = _pos(e.$1, rad + 400);
      c.drawLine(a, b, road);
      for (var d = 6.0; d < 400; d += 13) {
        c.drawLine(_pos(e.$1, rad + d), _pos(e.$1, rad + d + 6), lane);
      }
    }
    c.drawCircle(
        o,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..color = const Color(0xFF14254A));
    c.drawCircle(
        o,
        rad - 13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = GamesTheme.brand);
    c.drawCircle(
        o,
        rad - 14,
        Paint()
          ..shader = ui.Gradient.radial(o, rad - 14, const [Color(0xFF13423F), Color(0xFF0B2A30)]));
    Kit.palmTop(c, o.translate(-14, -8), 14);
    Kit.palmTop(c, o.translate(15, 9), 12, const Color(0xFF22624F));
    Kit.palmTop(c, o.translate(8, -16), 10);
    Kit.glow(c, o, 20 + sin(t * 3) * 2, const Color(0xFF5AC8FF), .35);
    final ng = state == 'circle' ? (commit >= 0 ? commit : _nextGate()) : -1;
    for (var i = 0; i < exits.length; i++) {
      final e = exits[i], s = _pos(e.$1, rad + 36);
      if (i == ng) Kit.glow(c, _pos(e.$1, rad + 14), 20, const Color(0xFFEBF4FF), commit >= 0 ? .7 : .35);
      if (e.$2.k == req.k) Kit.glow(c, s, 26 + sin(t * 6) * 3, e.$2.color, .55);
      c.drawCircle(s, 12, Paint()..color = const Color(0xD9061028));
      c.drawCircle(
          s,
          12,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = e.$2.color);
      Kit.icon(c, e.$2.k, s, 13, e.$2.color);
    }
    Offset p;
    double ang;
    if (state == 'circle') {
      p = _pos(th, rad);
      ang = th - pi / 2; // moving with decreasing angle
    } else {
      final e = exits[state == 'exit' ? exitIdx : enterFrom];
      p = _pos(e.$1, rad + smooth(pr) * 80);
      ang = state == 'exit' ? e.$1 : e.$1 + pi;
    }
    Kit.glow(c, p, 15, GamesTheme.brand, .4);
    if (commit >= 0 && (t * 6).floor().isEven) Kit.glow(c, p + Offset(cos(ang - pi / 2), sin(ang - pi / 2)) * 7, 6, Colors.white, .9);
    Kit.car(c, p, ang, 21, skin);
    // rider card
    final cw = wide ? min(150.0, vw * .36) : vw - 24, ch = wide ? min(vh - 46, 110.0) : 54.0;
    final cx0 = wide ? vw - cw - 10 : 12.0, cy0 = wide ? max(36.0, (vh - ch) / 2 + 12) : 34.0;
    final card = RRect.fromRectAndRadius(Rect.fromLTWH(cx0, cy0, cw, ch), const Radius.circular(16));
    c.drawRRect(card, Paint()..color = const Color(0xB8081430));
    c.drawRRect(
        card,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: .12));
    if (wide) {
      Kit.text(c, 'ودّيني لـ', Offset(cx0 + cw - 14, cy0 + 18), 11, color: GamesTheme.muted, align: TextAlign.right);
      Kit.icon(c, req.k, Offset(cx0 + 28, cy0 + ch * .52), min(24, ch * .3), req.color);
      Kit.text(c, req.name, Offset(cx0 + cw - 14, cy0 + ch * .52), min(16, ch * .15), align: TextAlign.right);
      Kit.text(c, '$served/$target', Offset(cx0 + 12, cy0 + 16), 11, color: GamesTheme.ink, align: TextAlign.left);
    } else {
      Kit.icon(c, req.k, Offset(cx0 + 26, cy0 + ch / 2), 22, req.color);
      Kit.text(c, 'ودّيني لـ ${req.name}', Offset(cx0 + cw - 14, cy0 + ch / 2 - 2), 14, align: TextAlign.right);
    }
    final bar = Rect.fromLTWH(cx0 + 10, cy0 + ch - 9, cw - 20, 4);
    c.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(2)), Paint()..color = Colors.white.withValues(alpha: .14));
    final f = clampD(pat / patM, 0, 1);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bar.right - bar.width * f, bar.top, bar.width * f, 4), const Radius.circular(2)),
        Paint()..color = pat < 2.5 ? GamesTheme.danger : GamesTheme.brandLight);
  }

  @override
  void hud(Canvas c) {
    if (wide) return;
    hudPill(c, a: 'غلطات $mist', b: '$served/$target', cText: 'ركاب');
  }
}

/// «طريق مختصر» — draw the taxi's route through the blocks with one finger; the shorter, the more stars.
class RouteWorld extends GameWorld {
  RouteWorld() : super(6);
  @override
  String get hint => 'اسحب من التاكسي للراكب بين العمارات';

  int cols = 8, rows = 4, startCell = 0, goalCell = 0, trips = 0, pts = 0, shortest = 1;
  double cell = 36, ox = 0, oy = 0, drive = 0;
  final Set<int> blocked = {};
  final List<int> path = [];
  bool drawing = false, driving = false;
  double waitNext = 0;

  void _layout() {
    cell = 36;
    cols = max(4, ((vw - 16) / cell).floor());
    rows = max(3, ((vh - 40) / cell).floor());
    ox = (vw - cols * cell) / 2;
    oy = 32 + (vh - 32 - rows * cell) / 2;
  }

  int? _bfs(int from, int to) {
    final dist = <int, int>{from: 0};
    final q = Queue<int>()..add(from);
    while (q.isNotEmpty) {
      final c0 = q.removeFirst();
      if (c0 == to) return dist[c0];
      for (final n in _nbr(c0)) {
        if (!blocked.contains(n) && !dist.containsKey(n)) {
          dist[n] = dist[c0]! + 1;
          q.add(n);
        }
      }
    }
    return null;
  }

  Iterable<int> _nbr(int c0) sync* {
    final r = c0 ~/ cols, col = c0 % cols;
    if (r > 0) yield c0 - cols;
    if (r < rows - 1) yield c0 + cols;
    if (col > 0) yield c0 - 1;
    if (col < cols - 1) yield c0 + 1;
  }

  void _newTrip() {
    _layout();
    for (var attempt = 0; attempt < 60; attempt++) {
      blocked.clear();
      final dens = min(.36, .22 + level * .015);
      for (var i = 0; i < cols * rows; i++) {
        if (rng.nextDouble() < dens) blocked.add(i);
      }
      startCell = rng.nextInt(rows) * cols + cols - 1;
      goalCell = rng.nextInt(rows) * cols;
      blocked
        ..remove(startCell)
        ..remove(goalCell);
      final d = _bfs(startCell, goalCell);
      if (d != null && d >= cols - 1) {
        shortest = d;
        break;
      }
    }
    path
      ..clear()
      ..add(startCell);
    driving = false;
    drive = 0;
    drawing = false;
  }

  @override
  void start() {
    trips = 0;
    pts = 0;
    _newTrip();
  }

  @override
  void onResize() {
    if (!driving) _newTrip();
  }

  int? _cellAt(Offset p) {
    final col = ((p.dx - ox) / cell).floor(), r = ((p.dy - oy) / cell).floor();
    if (col < 0 || col >= cols || r < 0 || r >= rows) return null;
    return r * cols + col;
  }

  Offset _cxy(int c0) => Offset(ox + (c0 % cols + .5) * cell, oy + (c0 ~/ cols + .5) * cell);

  void _visit(int? c0) {
    if (c0 == null || driving || blocked.contains(c0)) return;
    final last = path.last;
    if (c0 == last) return;
    if (path.length > 1 && c0 == path[path.length - 2]) {
      path.removeLast();
      return;
    }
    if (path.contains(c0)) {
      path.removeRange(path.indexOf(c0) + 1, path.length);
      return;
    }
    if (_nbr(last).contains(c0)) {
      path.add(c0);
      if (c0 == goalCell) {
        driving = true;
        drawing = false;
        buzz();
      }
    }
  }

  @override
  void down(Offset p) {
    drawing = true;
    _visit(_cellAt(p));
  }

  @override
  void move(Offset p) {
    if (drawing) _visit(_cellAt(p));
  }

  @override
  void up(Offset p) => drawing = false;

  @override
  void auto(double dt) {
    if (driving || path.last == goalCell) return;
    // greedy BFS step toward the goal
    final prev = <int, int>{};
    final q = Queue<int>()..add(path.last);
    final seen = {path.last};
    while (q.isNotEmpty) {
      final c0 = q.removeFirst();
      if (c0 == goalCell) break;
      for (final n in _nbr(c0)) {
        if (!blocked.contains(n) && seen.add(n) && !path.contains(n)) {
          prev[n] = c0;
          q.add(n);
        }
      }
    }
    var cur = goalCell;
    if (!prev.containsKey(cur)) return;
    while (prev[cur] != path.last) {
      cur = prev[cur]!;
    }
    _visit(cur);
  }

  @override
  void update(double dt) {
    if (driving) {
      drive += dt * (5 + level * .3);
      if (drive >= path.length - 1) {
        driving = false;
        final extra = (path.length - 1) - shortest;
        final s = extra <= 0 ? 3 : (extra <= 2 ? 2 : 1);
        pts += s;
        trips++;
        final g = _cxy(goalCell);
        fx.burst(g.dx, g.dy, 28, s == 3 ? GamesTheme.gold : const Color(0xFF5AAAFF), speed: 120, size: 9);
        pop(g.dx, g.dy - 18, s == 3 ? 'أقصر طريق!' : (s == 2 ? 'زين!' : 'وصلت، بس لفّيت'), color: s == 3 ? GamesTheme.gold : Colors.white);
        buzz(2);
        waitNext = .9;
      }
    } else if (waitNext > 0) {
      waitNext -= dt;
      if (waitNext <= 0) {
        if (trips >= 3) {
          final st = pts >= 8 ? 3 : (pts >= 5 ? 2 : 1);
          finish(st, 'دليل المدينة!', 'ثلاث مشاوير · نقاطك $pts من 9', score: pts);
        } else {
          _newTrip();
        }
      }
    }
  }

  @override
  void draw(Canvas c) {
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8), Paint()..color = const Color(0xFF050D22));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ox - 4, oy - 4, cols * cell + 8, rows * cell + 8), const Radius.circular(12)),
        Paint()..color = const Color(0xFF13234A));
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;
    for (var i = 0; i <= cols; i++) {
      c.drawLine(Offset(ox + i * cell, oy), Offset(ox + i * cell, oy + rows * cell), grid);
    }
    for (var i = 0; i <= rows; i++) {
      c.drawLine(Offset(ox, oy + i * cell), Offset(ox + cols * cell, oy + i * cell), grid);
    }
    final r = Random(level * 13 + trips);
    for (final b in blocked) {
      final p = _cxy(b);
      final rect = Rect.fromCenter(center: p, width: cell - 6, height: cell - 6);
      if (r.nextDouble() < .2) {
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = const Color(0xFF0B2630));
        Kit.palmTop(c, p, cell * .3);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = const Color(0xFF0C1D42));
        for (var k = 0; k < 4; k++) {
          c.drawRect(Rect.fromLTWH(rect.left + 5 + k * (rect.width - 12) / 3, rect.top + 6 + (k.isOdd ? 8 : 0), 2, 2),
              Paint()..color = (k.isEven ? GamesTheme.warmWindow : GamesTheme.coolWindow).withValues(alpha: .7));
        }
      }
    }
    if (path.length > 1) {
      final pp = Path()..moveTo(_cxy(path.first).dx, _cxy(path.first).dy);
      for (final c0 in path.skip(1)) {
        final p = _cxy(c0);
        pp.lineTo(p.dx, p.dy);
      }
      c.drawPath(
          pp,
          Paint()
            ..blendMode = BlendMode.plus
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * .34
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = GamesTheme.brand.withValues(alpha: .85));
    }
    final g = _cxy(goalCell);
    Kit.glow(c, g, 22 + sin(t * 4) * 2, const Color(0xFF3C96FF), .7);
    Kit.pin(c, g.translate(0, 8), 11, GamesTheme.brand);
    Offset carP;
    double ang = pi;
    if (driving || (path.length > 1 && path.last == goalCell && drive > 0)) {
      final i = drive.floor().clamp(0, path.length - 2), f = drive - i;
      final a = _cxy(path[i]), b = _cxy(path[i + 1]);
      carP = Offset.lerp(a, b, f)!;
      ang = atan2(b.dy - a.dy, b.dx - a.dx);
    } else {
      carP = _cxy(path.first);
      if (path.length > 1) {
        final b = _cxy(path[1]);
        ang = atan2(b.dy - carP.dy, b.dx - carP.dx);
      }
    }
    Kit.glow(c, carP, 16, GamesTheme.brand, .4);
    Kit.car(c, carP, ang, cell * .62, skin);
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'نقاط $pts', b: '${min(3, trips + 1)}/3', cText: 'أقصر ${shortest + 1}');
}

/// «لقّط الركاب» — drag the taxi left and right to catch falling passengers; avoid the cones.
class CatchWorld extends GameWorld {
  CatchWorld() : super(7);
  @override
  String get hint => 'حرّك صبعك يمين ويسار باش تلقّط الركاب';

  double carX = 100, targetX = 100, timeLeft = 40, spawn = 0;
  int got = 0, cones = 0, combo = 1, goal = 12;
  final List<List<double>> items = []; // x, y, kind(0 rider,1 cone,2 star), speed

  double get carY => vh - 24;

  @override
  void start() {
    carX = targetX = vw / 2;
    goal = 30 + level * 4;
    items.clear();
  }

  @override
  void down(Offset p) => targetX = p.dx;
  @override
  void move(Offset p) => targetX = p.dx;

  @override
  void auto(double dt) {
    List<double>? best;
    for (final it in items) {
      if (it[2] != 1 && it[1] < carY && (best == null || it[1] > best[1])) best = it;
    }
    if (best != null) targetX = best[0];
  }

  @override
  void update(double dt) {
    carX += (clampD(targetX, 16, vw - 16) - carX) * min(1, dt * 14);
    spawn -= dt;
    if (spawn <= 0) {
      spawn = max(.35, .9 - level * .04) * (.7 + rng.nextDouble() * .6);
      final r = rng.nextDouble();
      final kind = r < .22 + min(level, 10) * .02 ? 1.0 : (r > .95 ? 2.0 : 0.0);
      items.add([12 + rng.nextDouble() * (vw - 24), -10, kind, vh * (.45 + min(level, 10) * .035) * (.85 + rng.nextDouble() * .3)]);
    }
    for (final it in items) {
      it[1] += it[3] * dt;
    }
    for (final it in List.of(items)) {
      if ((it[1] - carY).abs() < 12 && (it[0] - carX).abs() < 18) {
        items.remove(it);
        if (it[2] == 1) {
          cones++;
          combo = 1;
          timeLeft = max(0, timeLeft - 3);
          shake = .2;
          fx.burst(it[0], it[1], 16, GamesTheme.danger, speed: 90, size: 7, life: .5);
          pop(it[0], it[1] - 16, 'قمع! −3 ث', color: GamesTheme.danger, size: 12);
          buzz(2);
        } else {
          final pts = it[2] == 2 ? 3 : 1;
          got += pts * combo;
          if (got % 5 == 0 && combo < 3) combo++;
          fx.burst(it[0], it[1], it[2] == 2 ? 30 : 16, it[2] == 2 ? GamesTheme.gold : const Color(0xFF5AAAFF), speed: 110, size: 8);
          pop(it[0], it[1] - 16, it[2] == 2 ? 'نجمة! +${pts * combo}' : '+$combo', color: it[2] == 2 ? GamesTheme.gold : Colors.white);
          buzz();
        }
      } else if (it[1] > vh + 12) {
        items.remove(it);
        if (it[2] == 0) combo = 1;
      }
    }
    timeLeft -= dt;
    if (timeLeft <= 0) {
      final st = got >= goal * 1.5 ? 3 : (got >= goal ? 2 : (got >= goal / 2 ? 1 : 0));
      finish(st, st > 0 ? 'ولا راكب طاح!' : 'عاودها', 'لقّطت $got · قموع $cones', score: got);
    }
  }

  @override
  void draw(Canvas c) {
    Kit.nightSky(c, Rect.fromLTWH(-4, -4, vw + 8, vh + 8));
    final r = Random(level);
    for (var i = 0; i < 30; i++) {
      final x = r.nextDouble() * vw, y = r.nextDouble() * vh * .8;
      Kit.glow(c, Offset(x, y), 4 + r.nextDouble() * 8, i.isEven ? GamesTheme.coolWindow : GamesTheme.warmWindow, .12 + .06 * sin(t * 2 + i));
    }
    c.drawRect(Rect.fromLTWH(-4, carY - 16, vw + 8, 40), Paint()..color = const Color(0xFF13234A));
    c.drawLine(Offset(-4, carY - 16), Offset(vw + 4, carY - 16), Paint()
      ..color = GamesTheme.brand
      ..strokeWidth = 2);
    for (final it in items) {
      final o = Offset(it[0], it[1]);
      if (it[2] == 1) {
        Kit.glow(c, o, 13, GamesTheme.danger, .45);
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - 9)
              ..lineTo(o.dx + 7, o.dy + 7)
              ..lineTo(o.dx - 7, o.dy + 7)
              ..close(),
            Paint()..color = const Color(0xFFE0243A));
      } else if (it[2] == 2) {
        Kit.glow(c, o, 18, GamesTheme.gold, .7);
        Kit.icon(c, 'star', o, 14, GamesTheme.gold);
      } else {
        Kit.glow(c, o, 16, const Color(0xFF3C96FF), .65);
        Kit.pin(c, o.translate(0, 7), 10, GamesTheme.brand);
      }
    }
    Kit.glow(c, Offset(carX, carY), 20, GamesTheme.brand, .4);
    Kit.car(c, Offset(carX, carY), -pi / 2, 30, skin);
  }

  @override
  void hud(Canvas c) => hudPill(c,
      a: '${timeLeft.ceil()} ث', aColor: timeLeft < 8 ? GamesTheme.danger : Colors.white, b: '$got', cText: '×$combo');
}

/// «عدّ السيارات» — watch the cars pass, then answer: how many of one colour?
class CountWorld extends GameWorld {
  CountWorld() : super(8);
  @override
  String get hint => 'ركّز في السيارات اللي تعدّي وجاوب';

  static const colors = [
    (GamesTheme.brand, 'زرقا'),
    (Color(0xFFEEF3FA), 'بيضا'),
    (Color(0xFF8C98AD), 'رمادية'),
    (Color(0xFF2FC6A0), 'خضرا'),
  ];

  final List<List<double>> cars = []; // startTime, lane, colourIndex, speed
  int q = 0, correct = 0, ask = 0, answer = 0;
  double phaseT = 0, showFor = 7;
  String state = 'watch';
  List<int> choices = [];
  int? picked;

  void _round() {
    cars.clear();
    final n = 7 + min(level, 8) + rng.nextInt(4);
    showFor = max(5.0, 8 - level * .25);
    for (var i = 0; i < n; i++) {
      cars.add([rng.nextDouble() * (showFor - 1.6), rng.nextInt(2).toDouble(), rng.nextInt(level >= 3 ? 4 : 3).toDouble(), 150 + rng.nextDouble() * 90 + level * 6]);
    }
    ask = cars[rng.nextInt(cars.length)][2].toInt();
    answer = cars.where((cc) => cc[2] == ask).length;
    final set = <int>{answer};
    while (set.length < 3) {
      set.add(max(0, answer + rng.nextInt(5) - 2));
    }
    choices = set.toList()..shuffle(rng);
    phaseT = 0;
    state = 'watch';
    picked = null;
  }

  @override
  void start() {
    q = 0;
    correct = 0;
    _round();
  }

  Rect _btn(int i) {
    final w = min(80.0, (vw - 60) / 3), h = 44.0;
    final total = w * 3 + 24;
    return Rect.fromLTWH((vw - total) / 2 + i * (w + 12), band + 118, w, h);
  }

  @override
  void down(Offset p) {
    if (state != 'ask') return;
    for (var i = 0; i < 3; i++) {
      if (_btn(i).inflate(6).contains(p)) {
        picked = choices[i];
        final ok = picked == answer;
        if (ok) correct++;
        final b = _btn(i).center;
        fx.burst(b.dx, b.dy, ok ? 26 : 12, ok ? GamesTheme.gold : GamesTheme.danger, speed: 110, size: 8);
        pop(b.dx, b.dy - 30, ok ? 'صح!' : 'الصح $answer', color: ok ? GamesTheme.gold : GamesTheme.danger, size: 15);
        buzz(ok ? 2 : 1);
        state = 'result';
        phaseT = 0;
      }
    }
  }

  @override
  void auto(double dt) {
    if (state == 'ask' && phaseT > .5) down(_btn(choices.indexOf(answer)).center);
  }

  @override
  void update(double dt) {
    phaseT += dt;
    if (state == 'watch' && phaseT >= showFor) {
      state = 'ask';
      phaseT = 0;
    } else if (state == 'result' && phaseT > 1.1) {
      q++;
      if (q >= 4) {
        final st = correct == 4 ? 3 : (correct >= 3 ? 2 : (correct >= 1 ? 1 : 0));
        finish(st, st > 0 ? 'عين ما تفوتها!' : 'عاودها', 'جاوبت صح $correct من 4', score: correct);
      } else {
        _round();
      }
    }
  }

  @override
  void draw(Canvas c) {
    final b = band;
    c.drawRect(Rect.fromLTWH(-4, -4, vw + 8, vh + 8), Paint()..color = const Color(0xFF050D22));
    c.drawRect(
        Rect.fromLTWH(-4, b + 58, vw + 8, 84),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, b + 58), Offset(0, b + 142), const [Color(0xFF16284F), Color(0xFF0E1A36)]));
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..strokeWidth = 1.4;
    for (var xx = 0.0; xx < vw; xx += 24) {
      c.drawLine(Offset(xx, b + 100), Offset(xx + 12, b + 100), dash);
    }
    for (var xx = 30.0; xx < vw; xx += 110) {
      Kit.glow(c, Offset(xx, b + 48), 12, const Color(0xFFBEDCFF), .5);
      Kit.palmTop(c, Offset(xx + 55, b + 156), 12);
    }
    if (state == 'watch') {
      for (final cc in cars) {
        final age = phaseT - cc[0];
        if (age < 0) continue;
        final lane = cc[1].toInt(), dir = lane == 0 ? -1.0 : 1.0;
        final x = lane == 0 ? vw + 20 - age * cc[3] : -20 + age * cc[3];
        if (x < -30 || x > vw + 30) continue;
        final y = b + (lane == 0 ? 80 : 120);
        Kit.beam(c, Offset(x + dir * 11, y), dir > 0 ? 0 : pi, 50, 14, .25);
        Kit.car(c, Offset(x, y), dir > 0 ? 0 : pi, 26, colors[cc[2].toInt()].$1);
      }
      final left = (showFor - phaseT).clamp(0, 99).ceil();
      Kit.text(c, 'عِدّ السيارات · $left', Offset(vw / 2, b + 24), 13, color: GamesTheme.ink);
    } else {
      final col = colors[ask];
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(vw / 2, b + 76), width: min(vw - 20, 260), height: 52), const Radius.circular(16)),
          Paint()..color = const Color(0xD9081430));
      Kit.car(c, Offset(vw / 2 + min(vw - 20, 260) / 2 - 30, b + 76), pi, 26, col.$1);
      Kit.text(c, 'كم سيارة ${col.$2} عدّت؟', Offset(vw / 2 - 12, b + 76), 15);
      for (var i = 0; i < 3; i++) {
        final r = _btn(i);
        final isPick = picked == choices[i];
        final ok = choices[i] == answer;
        c.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(14)),
            Paint()
              ..color = state == 'result'
                  ? (ok ? GamesTheme.brand : (isPick ? const Color(0xFF7A1F2E) : const Color(0xFF13234A)))
                  : GamesTheme.brand);
        Kit.text(c, '${choices[i]}', r.center, 18);
      }
    }
  }

  @override
  void hud(Canvas c) => hudPill(c, a: 'صح $correct', b: '${min(4, q + 1)}/4', cText: 'سؤال');
}
