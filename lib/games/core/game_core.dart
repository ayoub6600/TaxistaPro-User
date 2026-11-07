import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'paint_kit.dart';
import 'theme.dart';

/// The result of one round. Stars only — never money.
class GameResult {
  const GameResult({required this.stars, required this.title, required this.line, required this.level, this.score = 0});
  final int stars;
  final String title;
  final String line;
  final int level;
  final int score;
}

/// One round of one game. It lives in the controller (outside the widget tree)
/// so the same round continues when the box is enlarged to full screen.
class GameSession {
  GameSession({
    required this.game,
    required this.level,
    required this.onFinish,
    this.reducedMotion = false,
    this.skin = GamesTheme.brand,
    this.silent = false,
  });

  final TaxistaGame game;
  final int level;
  final void Function(GameResult) onFinish;
  bool reducedMotion;
  final Color skin;

  /// Thumbnails and tests: no haptics.
  final bool silent;

  /// Paused by the host (approach alert, offers, background, box closed).
  final ValueNotifier<bool> paused = ValueNotifier<bool>(true);

  /// Waiting for the first tap («اضغط باش تبدا» / «اضغط باش تكمّل»).
  final ValueNotifier<bool> awaiting = ValueNotifier<bool>(true);
  String awaitingText = 'اضغط باش تبدا';

  /// The running world (created lazily by the game's widget, kept across rebuilds).
  Object? world;
  bool finished = false;

  void finish(GameResult r) {
    if (finished) return;
    finished = true;
    onFinish(r);
  }

  void haptic(int strength) {
    if (silent) return;
    try {
      (strength >= 2 ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick()).ignore();
    } catch (_) {}
  }
}

/// A game in the catalog.
abstract class TaxistaGame {
  const TaxistaGame();
  String get id;
  String get title;
  String get pitch;
  IconData get icon;

  /// Badge earned after 3 levels with stars.
  String get badge;
  Widget build(BuildContext context, GameSession session);
}

/// A game drawn by a [GameWorld] on one canvas with one ticker.
class WorldGame extends TaxistaGame {
  const WorldGame({
    required this.id,
    required this.title,
    required this.pitch,
    required this.icon,
    required this.badge,
    required this.create,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String pitch;
  @override
  final IconData icon;
  @override
  final String badge;
  final GameWorld Function() create;

  GameWorld worldFor(GameSession s) {
    final existing = s.world;
    if (existing is GameWorld) return existing;
    final w = create()..attach(s);
    s.world = w;
    return w;
  }

  @override
  Widget build(BuildContext context, GameSession session) =>
      WorldView(key: ObjectKey(session), session: session, game: this);
}

class Pop {
  Pop(this.x, this.y, this.text, this.color, this.size);
  double x, y, life = 1.15;
  final String text;
  final Color color;
  final double size;
}

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color) : max = life;
  double x, y, vx, vy, life;
  final double max, size;
  final Color color;
}

class Particles {
  final List<Particle> list = [];
  final Random _r = Random();
  bool reduced = false;

  void burst(double x, double y, int n, Color col, {double speed = 100, double size = 8, double life = .7}) {
    final count = reduced ? (n / 3).ceil() : n;
    for (var i = 0; i < count; i++) {
      final a = _r.nextDouble() * tau, s = speed * (.35 + _r.nextDouble() * .9);
      list.add(Particle(x, y, cos(a) * s, sin(a) * s, life * (.6 + _r.nextDouble() * .6),
          size * (.6 + _r.nextDouble() * .8), col));
    }
    if (list.length > 220) list.removeRange(0, list.length - 220);
  }

  void update(double dt) {
    final d = pow(.05, dt).toDouble();
    for (final p in list) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= d;
      p.vy *= d;
      p.life -= dt;
    }
    list.removeWhere((p) => p.life <= 0);
  }

  void paint(Canvas c) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final p in list) {
      final k = clampD(p.life / p.max, 0, 1);
      paint.color = p.color.withValues(alpha: k * .35);
      c.drawCircle(Offset(p.x, p.y), p.size * .9 * (.5 + .5 * k), paint);
      paint.color = p.color.withValues(alpha: k * .95);
      c.drawCircle(Offset(p.x, p.y), p.size * .32 * (.5 + .5 * k), paint);
    }
  }
}

/// Base class for every game world. Coordinates are "units": the shorter side of the
/// play area is always 200 units, so each game lays out the same in the small box,
/// portrait and landscape. Worlds that are wide by nature can ask to be turned
/// a quarter turn in portrait ([rotateInPortrait]).
abstract class GameWorld {
  GameWorld(this.seed);
  final int seed;

  Size size = Size.zero;
  double u = 1;
  double vw = 200, vh = 200; // virtual units (after the optional quarter turn)
  bool rotated = false;
  int level = 1;
  late GameSession session;
  Random rng = Random(1);
  double t = 0;
  bool over = false;
  double shake = 0;
  bool started = false;
  final Particles fx = Particles();
  final List<Pop> pops = [];
  ui.Shader? _vignette;
  Size _vigSize = Size.zero;

  bool get rotateInPortrait => false;
  String get hint;
  bool get reduced => session.reducedMotion;
  Color get skin => session.skin;

  /// Vertical offset that centres a 200-unit tall scene.
  double get band => max(0, (vh - 200) / 2);

  void attach(GameSession s) {
    session = s;
    level = s.level;
    fx.reduced = s.reducedMotion;
  }

  void ensure(Size s) {
    if (s.width < 4 || s.height < 4) return;
    if (s != size) resize(s);
    if (!started) {
      started = true;
      rng = Random(level * 7919 + seed * 131 + 7);
      start();
    }
  }

  void resize(Size s) {
    size = s;
    u = min(s.width, s.height) / 200;
    if (u <= 0) u = 1;
    final sw = s.width / u, sh = s.height / u;
    rotated = rotateInPortrait && sh > sw * 1.15;
    vw = rotated ? sh : sw;
    vh = rotated ? sw : sh;
    _vignette = null;
    if (started) onResize();
  }

  void onResize() {}
  void start();
  void update(double dt);

  /// Draw the world in virtual units.
  void draw(Canvas c);

  /// Heads-up display in pixels (never rotated).
  void hud(Canvas c) {}

  void down(Offset p) {}
  void move(Offset p) {}
  void up(Offset p) {}

  /// Simple autoplay, used for card thumbnails and tests.
  void auto(double dt) {}

  Offset toVirtual(Offset px) {
    final x = px.dx / u, y = px.dy / u;
    if (!rotated) return Offset(x, y);
    return Offset(y, size.width / u - x);
  }

  Offset toScreen(double vx, double vy) {
    if (!rotated) return Offset(vx * u, vy * u);
    return Offset(size.width - vy * u, vx * u);
  }

  void step(double dt) {
    t += dt;
    if (!over) update(dt);
    fx.update(dt);
    for (final p in pops) {
      p.y -= 24 * dt;
      p.life -= dt;
    }
    pops.removeWhere((p) => p.life <= 0);
    if (shake > 0) shake = max(0, shake - dt);
  }

  void pop(double x, double y, String text, {Color color = Colors.white, double size = 14}) {
    pops.add(Pop(x, y, text, color, size));
    if (pops.length > 8) pops.removeAt(0);
  }

  void buzz([int k = 1]) => session.haptic(k);

  void finish(int stars, String title, String line, {int score = 0}) {
    if (over) return;
    over = true;
    session.finish(GameResult(stars: stars.clamp(0, 3), title: title, line: line, level: level, score: score));
  }

  void paintAll(Canvas c) {
    if (size.isEmpty || !started) return;
    c.save();
    c.clipRect(Offset.zero & size);
    c.save();
    if (shake > 0 && !reduced) {
      final r = Random();
      c.translate((r.nextDouble() - .5) * 3, (r.nextDouble() - .5) * 3);
    }
    c.scale(u);
    if (rotated) {
      c.translate(size.width / u, 0);
      c.rotate(pi / 2);
    }
    draw(c);
    fx.paint(c);
    c.restore();
    for (final p in pops) {
      final k = clampD(p.life / 1.15 * 2, 0, 1);
      final at = toScreen(p.x, p.y);
      Kit.text(c, p.text, at.translate(1, 1), max(12, p.size * min(1.2, u * 1.05)), color: Colors.black.withValues(alpha: .35 * k));
      Kit.text(c, p.text, at, max(12, p.size * min(1.2, u * 1.05)), color: p.color.withValues(alpha: k));
    }
    if (_vignette == null || _vigSize != size) {
      _vigSize = size;
      _vignette = ui.Gradient.radial(Offset(size.width / 2, size.height * .55), max(size.width, size.height) * .75,
          const [Color(0x00020610), Color(0x8C020610)], const [.45, 1]);
    }
    c.drawRect(Offset.zero & size, Paint()..shader = _vignette);
    hud(c);
    c.restore();
  }

  /// Standard top HUD pill: [a] on the visual left, [b] centre, [cText] right.
  void hudPill(Canvas c, {String? a, String? b, String? cText, Color bColor = GamesTheme.gold, Color aColor = Colors.white}) {
    final small = size.height < 150 || size.width < 300;
    final h = small ? 22.0 : 26.0, fs = small ? 11.0 : 12.5;
    final w = min(250.0, max(120.0, size.width - 156));
    final r = Rect.fromLTWH((size.width - w) / 2, 7, w, h);
    Kit.pill(c, r);
    if (a != null) Kit.text(c, a, Offset(r.left + 30, r.center.dy), fs, color: aColor);
    if (b != null) Kit.text(c, b, r.center, fs + 1, color: bColor);
    if (cText != null) Kit.text(c, cText, Offset(r.right - 32, r.center.dy), fs - .5, color: GamesTheme.ink);
  }
}

class _Frame extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Hosts a [GameWorld]: one ticker (only while playing), a repaint-only painter
/// (no widget rebuild per frame), pointer input, and a repaint boundary.
class WorldView extends StatefulWidget {
  const WorldView({super.key, required this.session, required this.game});
  final GameSession session;
  final WorldGame game;

  @override
  State<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends State<WorldView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _Frame _frame = _Frame();
  Duration _last = Duration.zero;
  double _afterOver = 0;

  GameWorld get world => widget.game.worldFor(widget.session);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.session.paused.addListener(_sync);
    widget.session.awaiting.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(covariant WorldView old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.paused.removeListener(_sync);
      old.session.awaiting.removeListener(_sync);
      widget.session.paused.addListener(_sync);
      widget.session.awaiting.addListener(_sync);
      _afterOver = 0;
      _sync();
    }
  }

  void _sync() {
    final s = widget.session;
    final run = !s.paused.value && !s.awaiting.value && _afterOver < 1.3;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      world.up(Offset.zero);
    }
    _frame.ping();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : clampD((elapsed - _last).inMicroseconds / 1e6, 0, 1 / 30);
    _last = elapsed;
    final w = world;
    if (w.started) w.step(dt);
    if (w.over) {
      _afterOver += dt;
      if (_afterOver >= 1.3) _ticker.stop();
    }
    _frame.ping();
  }

  bool get _input => !widget.session.paused.value && !widget.session.awaiting.value && !world.over;

  @override
  void dispose() {
    widget.session.paused.removeListener(_sync);
    widget.session.awaiting.removeListener(_sync);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    widget.session.reducedMotion = reduce;
    world.fx.reduced = reduce;
    return RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          if (_input) world.down(world.toVirtual(e.localPosition));
        },
        onPointerMove: (e) {
          if (_input) world.move(world.toVirtual(e.localPosition));
        },
        onPointerUp: (e) {
          if (_input) world.up(world.toVirtual(e.localPosition));
        },
        onPointerCancel: (e) => world.up(Offset.zero),
        child: SizedBox.expand(child: CustomPaint(painter: _WorldPainter(world, _frame))),
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  _WorldPainter(this.world, Listenable repaint) : super(repaint: repaint);
  final GameWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    world.ensure(size);
    world.paintAll(canvas);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) => old.world != world;
}

/// A static, pre-played frame of a game for cards (no ticker).
class GameThumb extends StatelessWidget {
  const GameThumb({super.key, required this.game, this.skin = GamesTheme.brand});
  final TaxistaGame game;
  final Color skin;

  @override
  Widget build(BuildContext context) {
    final g = game;
    if (g is! WorldGame) {
      // a game from the server: its icon on a lit night card (the page itself loads only when played)
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -.2), radius: .9, colors: [Color(0xff1E4FA3), GamesTheme.night]),
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Icon(g.icon, color: Colors.white, size: 34),
          ),
        ),
      );
    }
    return RepaintBoundary(child: SizedBox.expand(child: CustomPaint(painter: _ThumbPainter(g, skin))));
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.game, this.skin);
  final WorldGame game;
  final Color skin;
  static final Map<String, GameWorld> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    final key = '${game.id}|${size.width.round()}x${size.height.round()}|${skin.toARGB32()}';
    var w = _cache[key];
    if (w == null) {
      if (_cache.length > 40) _cache.clear();
      final s = GameSession(game: game, level: 2, onFinish: (_) {}, reducedMotion: true, skin: skin, silent: true);
      w = game.worldFor(s);
      w.ensure(size);
      for (var i = 0; i < 150 && !w.over; i++) {
        w.auto(1 / 60);
        w.step(1 / 60);
      }
      w.pops.clear();
      _cache[key] = w;
    }
    w.ensure(size);
    w.paintAll(canvas);
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter old) => old.game != game || old.skin != skin;
}
