import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/controller.dart';
import '../core/game_core.dart';
import '../core/theme.dart';

/// The play area shared by the small box and the full screen: the game picker,
/// the running game, and the overlays (start, result, driver approaching).
class GameStage extends StatelessWidget {
  const GameStage({
    super.key,
    required this.controller,
    required this.onBackToTrip,
    this.status,
    this.compact = false,
  });

  final WaitingGamesController controller;
  final ValueListenable<RideGameStatus>? status;
  final VoidCallback onBackToTrip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.progress, if (status != null) status!]),
      builder: (context, _) {
        final s = controller.session;
        final st = status?.value;
        final approaching = st?.phase == 'approaching' && !controller.approachDismissed;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ColoredBox(
            color: GamesTheme.night,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (s == null)
                  GamePicker(controller: controller, compact: compact)
                else ...[
                  Positioned.fill(child: s.game.build(context, s)),
                  if (controller.result == null && !approaching)
                    ValueListenableBuilder<bool>(
                      valueListenable: s.awaiting,
                      builder: (context, waiting, _) => waiting
                          ? _StartOverlay(text: s.awaitingText, hint: _hintOf(s), onTap: controller.tapToStart)
                          : const SizedBox.shrink(),
                    ),
                  if (controller.result != null)
                    _ResultOverlay(
                      result: controller.result!,
                      earned: controller.earned,
                      onNext: controller.playAgain,
                      onList: controller.toPicker,
                    ),
                ],
                if (approaching && s != null)
                  _ApproachOverlay(
                    etaText: st?.etaText,
                    driverName: st?.driverName,
                    onBack: onBackToTrip,
                    onStay: () {
                      controller.approachDismissed = true;
                      controller.pause();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _hintOf(GameSession s) {
    final w = s.world;
    if (w is GameWorld) return w.hint;
    return s.game.pitch;
  }
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({required this.text, required this.hint, required this.onTap});
  final String text, hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$text. $hint',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: const Color(0x73030919),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: GamesTheme.brand.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(text, style: GamesTheme.text(16)),
                    const SizedBox(height: 2),
                    Text(hint, style: GamesTheme.text(11.5, weight: FontWeight.w600, color: const Color(0xD9FFFFFF))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.stars, this.size = 30});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < stars;
        return Padding(
          padding: EdgeInsets.only(bottom: i == 1 ? size * .2 : 0),
          child: Icon(Icons.star_rounded, size: i == 1 ? size * 1.25 : size, color: on ? GamesTheme.gold : const Color(0x33FFFFFF)),
        );
      }),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.result, required this.earned, required this.onNext, required this.onList});
  final GameResult result;
  final List<String> earned;
  final VoidCallback onNext, onList;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xC2050E24),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              StarsRow(stars: result.stars),
              const SizedBox(width: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(result.title, style: GamesTheme.text(17)),
                  Text(result.line, style: GamesTheme.text(12, weight: FontWeight.w600, color: const Color(0xD9FFFFFF))),
                  for (final e in earned.take(2))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0x29F6D365), borderRadius: BorderRadius.circular(99)),
                      child: Text(e, style: GamesTheme.text(11, color: GamesTheme.gold)),
                    ),
                ]),
              ),
              const SizedBox(width: 14),
              Column(mainAxisSize: MainAxisSize.min, children: [
                _Btn(text: result.stars > 0 ? 'المستوى التالي' : 'عاود', primary: true, onTap: onNext),
                const SizedBox(height: 6),
                _Btn(text: 'الألعاب', onTap: onList),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ApproachOverlay extends StatelessWidget {
  const _ApproachOverlay({required this.onBack, required this.onStay, this.etaText, this.driverName});
  final VoidCallback onBack, onStay;
  final String? etaText, driverName;

  @override
  Widget build(BuildContext context) {
    final who = driverName == null ? 'السائق' : driverName!;
    return Semantics(
      liveRegion: true,
      label: 'السائق قرّب يوصل',
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xF5102A56), Color(0xF51965BF)]),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: Color(0x29FFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('السائق قرّب يوصل!', style: GamesTheme.text(17)),
                    Text(
                        '$who ${etaText == null ? 'قريب منك' : 'خلال $etaText'}. جهّز روحك. وقّفنا اللعبة وتقدّمك محفوظ.',
                        style: GamesTheme.text(12, weight: FontWeight.w600, color: const Color(0xE6FFFFFF))),
                  ]),
                ),
                const SizedBox(width: 12),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _Btn(text: 'رجوع للرحلة', primary: true, onTap: onBack),
                  const SizedBox(height: 6),
                  _Btn(text: 'كمّل دقيقة', onTap: onStay),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.text, required this.onTap, this.primary = false});
  final String text;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? Colors.white : const Color(0x24FFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 118, minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(text, style: GamesTheme.text(13.5, color: primary ? GamesTheme.brand : Colors.white)),
        ),
      ),
    );
  }
}

/// Horizontal carousel of game cards (inside the box / full screen).
class GamePicker extends StatelessWidget {
  const GamePicker({super.key, required this.controller, this.compact = false});
  final WaitingGamesController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final games = WaitingGamesConfig.visibleGames();
    return LayoutBuilder(builder: (context, box) {
      final showHeader = box.maxHeight >= 150;
      final cardW = (box.maxHeight * .9).clamp(104.0, 170.0);
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(.6, -1), radius: 1.4, colors: [Color(0xFF163A78), Color(0xFF0A1A3C), Color(0xFF061230)]),
        ),
        padding: EdgeInsets.only(top: showHeader ? 8 : 6, bottom: 8),
        child: Column(children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(56, 0, 56, 6),
              child: Row(children: [
                Text('اختار لعبة', style: GamesTheme.text(14)),
                const Spacer(),
                const Icon(Icons.star_rounded, color: GamesTheme.gold, size: 16),
                const SizedBox(width: 2),
                Text('${controller.progress.totalStars}', style: GamesTheme.text(12.5, color: GamesTheme.gold)),
              ]),
            ),
          Expanded(
            child: games.isEmpty
                ? Center(child: Text('الألعاب مطفية حاليًا', style: GamesTheme.text(13, color: GamesTheme.muted)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsetsDirectional.only(start: 12, end: showHeader ? 12 : 46),
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 9),
                    itemBuilder: (context, i) => GameCard(
                      game: games[i],
                      width: cardW,
                      stars: controller.progress.stats(games[i].id).starTotal,
                      isNew: WaitingGamesConfig.isNew(games[i].id),
                      isLast: controller.progress.lastPlayedId == games[i].id,
                      skin: controller.progress.skinColor,
                      onTap: () => controller.play(games[i]),
                    ),
                  ),
          ),
        ]),
      );
    });
  }
}

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.width,
    required this.stars,
    required this.onTap,
    this.isNew = false,
    this.isLast = false,
    this.skin = GamesTheme.brand,
  });

  final TaxistaGame game;
  final double width;
  final int stars;
  final bool isNew, isLast;
  final Color skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${game.title}. ${game.pitch}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                GameThumb(game: game, skin: skin),
                if (isNew || isLast)
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: _Tag(text: isNew ? 'جديد' : 'آخر لعبة', color: isNew ? GamesTheme.brand : const Color(0xD9FFFFFF), dark: !isNew),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 4, 9, 5),
              child: Row(children: [
                Icon(game.icon, size: 14, color: GamesTheme.brandLight),
                const SizedBox(width: 4),
                Expanded(child: Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GamesTheme.text(12.5))),
                if (stars > 0) Text('★ $stars', style: GamesTheme.text(11, color: GamesTheme.gold)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: GamesTheme.text(10, color: dark ? GamesTheme.navy : Colors.white)),
      );
}

/// Small round glass button used on top of the game area.
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 32});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: const Color(0x8C081430),
        shape: const CircleBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * .52, color: GamesTheme.ink)),
        ),
      ),
    );
  }
}
