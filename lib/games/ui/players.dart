import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog.dart';
import '../core/config.dart';
import '../core/controller.dart';
import '../core/game_core.dart';
import '../core/progress.dart';
import '../core/theme.dart';
import 'stage.dart';
import 'trip_bar.dart';

/// The small game box inside the searching / ride sheet (≈ a quarter of the screen).
class WaitingGamesBox extends StatefulWidget {
  const WaitingGamesBox({
    super.key,
    required this.status,
    required this.height,
    required this.onClose,
    this.controller,
  });

  final ValueListenable<RideGameStatus> status;
  final double height;
  final VoidCallback onClose;

  /// Optional: pass one controller to keep the round when the host swaps sheets.
  final WaitingGamesController? controller;

  @override
  State<WaitingGamesBox> createState() => _WaitingGamesBoxState();
}

class _WaitingGamesBoxState extends State<WaitingGamesBox> with WidgetsBindingObserver {
  late WaitingGamesController _ctrl = widget.controller ?? WaitingGamesController();
  bool get _owns => widget.controller == null;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.status.addListener(_onStatus);
    if (!_ctrl.progress.loaded) _ctrl.progress.load();
  }

  @override
  void didUpdateWidget(covariant WaitingGamesBox old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      old.status.removeListener(_onStatus);
      widget.status.addListener(_onStatus);
    }
    if (old.controller != widget.controller && widget.controller != null) {
      if (old.controller == null) _ctrl.dispose();
      _ctrl = widget.controller!;
    }
  }

  void _onStatus() {
    final s = widget.status.value;
    if (s.mustClose) {
      _ctrl.pause();
      _ctrl.progress.save();
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onClose();
        });
      }
    } else if (s.phase == 'approaching' && !_ctrl.approachDismissed) {
      _ctrl.pause('السائق قرّب');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _ctrl.pause();
      _ctrl.progress.save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.status.removeListener(_onStatus);
    _ctrl.pause();
    _ctrl.progress.save();
    if (_owns) _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enlarge() async {
    _ctrl.pause();
    setState(() => _ctrl.fullScreenOpen = true);
    await WaitingGamesFullScreen.open(context, controller: _ctrl, status: widget.status);
    if (mounted) setState(() => _ctrl.fullScreenOpen = false);
  }

  void _backToTrip() {
    widget.status.value.onBackToTrip();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.height < 150;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              if (_ctrl.fullScreenOpen) {
                return ColoredBox(
                  color: GamesTheme.night,
                  child: Center(child: Text('اللعبة مكبّرة', style: GamesTheme.text(13, color: GamesTheme.muted))),
                );
              }
              return Stack(fit: StackFit.expand, children: [
                GameStage(controller: _ctrl, status: widget.status, compact: compact, onBackToTrip: _backToTrip),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: GlassButton(icon: Icons.close_rounded, label: 'سكّر الألعاب', onTap: widget.onClose),
                ),
                PositionedDirectional(
                  top: 6,
                  start: 6,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    GlassButton(icon: Icons.open_in_full_rounded, label: 'تكبير', onTap: _enlarge),
                    if (_ctrl.playing) ...[
                      const SizedBox(width: 5),
                      GlassButton(icon: Icons.grid_view_rounded, label: 'قائمة الألعاب', onTap: _ctrl.toPicker),
                    ],
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// Full-screen player with the trip bar on top. Portrait and landscape while open.
class WaitingGamesFullScreen extends StatefulWidget {
  const WaitingGamesFullScreen({super.key, required this.controller, this.status});
  final WaitingGamesController controller;
  final ValueListenable<RideGameStatus>? status;

  static Future<void> open(BuildContext context,
      {required WaitingGamesController controller, ValueListenable<RideGameStatus>? status}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => WaitingGamesFullScreen(controller: controller, status: status)),
    );
  }

  @override
  State<WaitingGamesFullScreen> createState() => _WaitingGamesFullScreenState();
}

class _WaitingGamesFullScreenState extends State<WaitingGamesFullScreen> with WidgetsBindingObserver {
  String? _lastPhase;
  String? _banner;
  Timer? _bannerTimer;
  bool _popped = false;

  WaitingGamesController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).ignore();
    _lastPhase = widget.status?.value.phase;
    widget.status?.addListener(_onStatus);
    if (!_ctrl.progress.loaded) _ctrl.progress.load();
  }

  void _onStatus() {
    final s = widget.status!.value;
    if (s.mustClose) {
      _ctrl.pause();
      _ctrl.progress.save();
      _close();
      return;
    }
    if (_lastPhase == 'searching' && s.phase == 'accepted') {
      _showBanner('🚕 لقينا لك سائق!${s.driverName == null ? '' : ' ${s.driverName} في الطريق'}');
    }
    if (s.phase == 'approaching' && _lastPhase != 'approaching' && !_ctrl.approachDismissed) {
      _ctrl.pause('السائق قرّب');
    }
    _lastPhase = s.phase;
  }

  void _showBanner(String text) {
    _bannerTimer?.cancel();
    setState(() => _banner = text);
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _close() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).maybePop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _ctrl.pause();
      _ctrl.progress.save();
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.status?.removeListener(_onStatus);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]).ignore();
    _ctrl.pause();
    _ctrl.progress.save();
    super.dispose();
  }

  void _backToTrip() {
    widget.status?.value.onBackToTrip();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _ctrl.pause();
      },
      child: Scaffold(
        backgroundColor: GamesTheme.nightDeep,
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(children: [
              if (status != null)
                TripBar(status: status, onBackToTrip: _backToTrip, onCollapse: _close)
              else
                _PlainBar(onClose: _close),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(fit: StackFit.expand, children: [
                      GameStage(controller: _ctrl, status: status, onBackToTrip: _backToTrip),
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) => _ctrl.playing
                              ? GlassButton(icon: Icons.grid_view_rounded, label: 'قائمة الألعاب', onTap: _ctrl.toPicker, size: 36)
                              : const SizedBox.shrink(),
                        ),
                      ),
                      if (_banner != null)
                        PositionedDirectional(
                          top: 10,
                          start: 54,
                          end: 54,
                          child: _Banner(text: _banner!),
                        ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlainBar extends StatelessWidget {
  const _PlainBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        child: Row(children: [
          Text('مركز الألعاب', style: GamesTheme.text(17)),
          const Spacer(),
          GlassButton(icon: Icons.close_rounded, label: 'سكّر', onTap: onClose, size: 36),
        ]),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: GamesTheme.navy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Text(text, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GamesTheme.text(14)),
        ),
      );
}

/// Toasts the host can show over the ride screen.
class WaitingGameToasts {
  WaitingGameToasts._();
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void showDriverFound(BuildContext context, String? name) => _show(context, '🚕', 'لقينا لك سائق!',
      name == null ? 'كمّل لعب، ننبّهوك قبل ما يوصل.' : '$name في الطريق إليك. كمّل لعب، ننبّهوك قبل ما يوصل.');

  static void showApproaching(BuildContext context, String? etaText) => _show(context, '📍', 'السائق قرّب يوصل!',
      etaText == null ? 'جهّز روحك واطلع لنقطة الركوب.' : 'خلال $etaText. جهّز روحك واطلع لنقطة الركوب.');

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static void _show(BuildContext context, String emoji, String title, String sub) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    hide();
    final entry = OverlayEntry(
      builder: (ctx) => PositionedDirectional(
        top: MediaQuery.paddingOf(ctx).top + 56,
        start: 12,
        end: 12,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: hide,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: GamesTheme.navy,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: GamesTheme.text(15)),
                      Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: GamesTheme.text(11.5, weight: FontWeight.w600, color: const Color(0xD9FFFFFF))),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 5), hide);
  }
}

/// «مركز الألعاب» — the whole catalog with stars, badges, colours, «جديد» and the last game played.
class GamesCenterPage extends StatefulWidget {
  const GamesCenterPage({super.key, this.status, this.controller});
  final ValueListenable<RideGameStatus>? status;
  final WaitingGamesController? controller;

  static Future<void> open(BuildContext context, {ValueListenable<RideGameStatus>? status, WaitingGamesController? controller}) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => GamesCenterPage(status: status, controller: controller)));

  @override
  State<GamesCenterPage> createState() => _GamesCenterPageState();
}

class _GamesCenterPageState extends State<GamesCenterPage> {
  late final WaitingGamesController _ctrl = widget.controller ?? WaitingGamesController();
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    if (!_ctrl.progress.loaded) _ctrl.progress.load();
    widget.status?.addListener(_onStatus);
  }

  void _onStatus() {
    if (widget.status!.value.mustClose && !_closed && mounted) {
      _closed = true;
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    widget.status?.removeListener(_onStatus);
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  Future<void> _play(TaxistaGame game) async {
    _ctrl.play(game);
    await WaitingGamesFullScreen.open(context, controller: _ctrl, status: widget.status);
  }

  @override
  Widget build(BuildContext context) {
    final games = WaitingGamesConfig.visibleGames();
    return Scaffold(
      backgroundColor: GamesTheme.nightDeep,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AnimatedBuilder(
            animation: _ctrl.progress,
            builder: (context, _) {
              final p = _ctrl.progress;
              return Column(children: [
                if (widget.status != null)
                  TripBar(
                    status: widget.status!,
                    onBackToTrip: () {
                      widget.status!.value.onBackToTrip();
                      Navigator.of(context).maybePop();
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 4),
                  child: Row(children: [
                    Expanded(child: Text('مركز الألعاب', maxLines: 1, overflow: TextOverflow.ellipsis, style: GamesTheme.text(20))),
                    const Icon(Icons.star_rounded, color: GamesTheme.gold, size: 20),
                    const SizedBox(width: 3),
                    Text('${p.totalStars}', style: GamesTheme.text(15, color: GamesTheme.gold)),
                    const SizedBox(width: 8),
                    GlassButton(icon: Icons.close_rounded, label: 'سكّر', onTap: () => Navigator.of(context).maybePop(), size: 36),
                  ]),
                ),
                Expanded(
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: _BadgesStrip(progress: p)),
                    SliverToBoxAdapter(child: _SkinsStrip(progress: p)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                      sliver: games.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Center(child: Text('الألعاب مطفية حاليًا', style: GamesTheme.text(14, color: GamesTheme.muted))),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 230,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: .8,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final g = games[i];
                                  final st = p.stats(g.id);
                                  return _CenterCard(
                                    game: g,
                                    stars: st.starTotal,
                                    level: st.level,
                                    isNew: WaitingGamesConfig.isNew(g.id),
                                    isLast: p.lastPlayedId == g.id,
                                    skin: p.skinColor,
                                    onTap: () => _play(g),
                                  );
                                },
                                childCount: games.length,
                              ),
                            ),
                    ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({
    required this.game,
    required this.stars,
    required this.level,
    required this.onTap,
    required this.skin,
    this.isNew = false,
    this.isLast = false,
  });
  final TaxistaGame game;
  final int stars, level;
  final bool isNew, isLast;
  final Color skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              GameThumb(game: game, skin: skin),
              if (isNew || isLast)
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(color: isNew ? GamesTheme.brand : const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(99)),
                    child: Text(isNew ? 'جديد' : 'آخر لعبة', style: GamesTheme.text(10.5, color: isNew ? Colors.white : GamesTheme.navy)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(game.icon, size: 15, color: GamesTheme.brandLight),
                const SizedBox(width: 4),
                Expanded(child: Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GamesTheme.text(14))),
              ]),
              Text(game.pitch,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: GamesTheme.text(11, weight: FontWeight.w600, color: GamesTheme.muted, height: 1.35)),
              const SizedBox(height: 3),
              Row(children: [
                Text('المستوى $level', style: GamesTheme.text(11, color: GamesTheme.ink)),
                const Spacer(),
                const Icon(Icons.star_rounded, size: 14, color: GamesTheme.gold),
                Text(' $stars', style: GamesTheme.text(11.5, color: GamesTheme.gold)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BadgesStrip extends StatelessWidget {
  const _BadgesStrip({required this.progress});
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final names = progress.badges.map((b) => GameProgress.badgeName(b, GameCatalog.all)).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        if (names.isEmpty)
          Text('العب واكسب أوسمة ونجوم، والنجوم تفتح ألوان جديدة للتاكسي.',
              style: GamesTheme.text(12, weight: FontWeight.w600, color: GamesTheme.muted)),
        for (final n in names)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0x29F6D365), borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.military_tech_rounded, size: 15, color: GamesTheme.gold),
              const SizedBox(width: 3),
              Text(n, style: GamesTheme.text(11.5, color: GamesTheme.gold)),
            ]),
          ),
      ]),
    );
  }
}

class _SkinsStrip extends StatelessWidget {
  const _SkinsStrip({required this.progress});
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(children: [
        Text('لون التاكسي', style: GamesTheme.text(12, color: GamesTheme.ink)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in CarSkin.all)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Semantics(
                    button: true,
                    label: progress.skinUnlocked(s) ? s.name : '${s.name}، يتفتح بـ ${s.needStars} نجمة',
                    child: GestureDetector(
                      onTap: () => progress.setSkin(s),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: progress.skinUnlocked(s) ? 1 : .3),
                          shape: BoxShape.circle,
                          border: Border.all(color: progress.skinId == s.id ? Colors.white : const Color(0x40FFFFFF), width: 2),
                        ),
                        child: progress.skinUnlocked(s) ? null : const Icon(Icons.lock_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
