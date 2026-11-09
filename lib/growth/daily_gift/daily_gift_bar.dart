import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../growth_api.dart';
import 'daily_gift_model.dart';
import 'daily_gift_sheet.dart';
import 'gift_box.dart';
import 'gift_burst.dart';

/// True while the bar takes room on the home, so the location button can step up above it.
final ValueNotifier<bool> dailyGiftBarShown = ValueNotifier(false);

/// «هدية كل يوم» on the home: nothing when the campaign is off here. The first open of the day
/// shows the box alone, then a burst with a soft sound, then the line; later opens show the line.
class DailyGiftBar extends StatefulWidget {
  const DailyGiftBar({super.key, this.lat, this.lng, this.offerForTest, this.playIntro});

  final double? lat;
  final double? lng;
  final DailyGiftOffer? offerForTest;

  /// tests decide; in the app the first open of the day does
  final bool? playIntro;

  @override
  State<DailyGiftBar> createState() => _DailyGiftBarState();
}

class _DailyGiftBarState extends State<DailyGiftBar> with SingleTickerProviderStateMixin {
  static const _seenKey = 'daily_gift_intro_date';
  static const _refresh = Duration(minutes: 5);

  // the intro on one 3.4 second line: box alone, burst, then the line opens out of the box
  static const _intro = Duration(milliseconds: 3400);
  static const _burstAt = 2100 / 3400;
  static const _lineAt = 2200 / 3400;
  static const _textAt = 2700 / 3400;

  late final AnimationController _c = AnimationController(vsync: this, duration: _intro);
  DailyGiftOffer? _offer;
  int _seconds = 0;
  Timer? _tick;
  DateTime _lastLoad = DateTime.fromMillisecondsSinceEpoch(0);
  bool _intoIntro = false;
  bool _sounded = false;
  AudioPlayer? _player;

  @override
  void initState() {
    super.initState();
    _c.addListener(_maybeSound);
    if (widget.offerForTest != null) {
      _show(widget.offerForTest!, widget.playIntro ?? false);
    } else {
      _load();
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void didUpdateWidget(covariant DailyGiftBar old) {
    super.didUpdateWidget(old);
    if (_offer == null && (old.lat != widget.lat || old.lng != widget.lng)) _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _c.dispose();
    _player?.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => dailyGiftBarShown.value = false);
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    if (_offer != null && _seconds > 0) setState(() => _seconds--);
    final over = _offer != null && _seconds <= 0;
    if (widget.offerForTest == null && (over || DateTime.now().difference(_lastLoad) > _refresh)) _load();
  }

  Future<void> _load() async {
    if (DateTime.now().difference(_lastLoad) < const Duration(seconds: 15)) return;
    _lastLoad = DateTime.now();
    final offer = DailyGiftOffer.fromJson(await GrowthApi.dailyGift(lat: widget.lat, lng: widget.lng));
    if (!mounted) return;
    if (offer == null) {
      setState(() => _offer = null);
      dailyGiftBarShown.value = false;
      return;
    }
    var intro = false;
    if (offer.isLive && _offer == null) {
      final prefs = await SharedPreferences.getInstance();
      intro = prefs.getString(_seenKey) != offer.date;
      if (intro) await prefs.setString(_seenKey, offer.date);
      if (!mounted) return;
    }
    _show(offer, intro);
  }

  void _show(DailyGiftOffer offer, bool intro) {
    setState(() {
      _offer = offer;
      _seconds = offer.secondsLeft;
      _intoIntro = intro || _intoIntro;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => dailyGiftBarShown.value = true);
    if (intro) {
      _c.forward(from: 0);
    } else if (!_c.isAnimating) {
      _c.value = 1;
    }
  }

  void _maybeSound() {
    if (_sounded || !_intoIntro || _c.value < _burstAt) return;
    _sounded = true;
    if (widget.offerForTest != null) return;
    unawaited(_playBurst());
  }

  /// A short sound once a day; the phone's silent switch wins and other audio keeps playing.
  Future<void> _playBurst() async {
    try {
      final player = _player = AudioPlayer();
      await player.setAudioContext(AudioContextConfig(respectSilence: true, focus: AudioContextConfigFocus.mixWithOthers).build());
      await player.setVolume(.8);
      await player.play(AssetSource('audio/gift_burst.mp3'));
    } catch (_) {
      // a gift is never in the way of anything, least of all because of a sound
    }
  }

  static double _phase(double v, double from, double to) => ((v - from) / (to - from)).clamp(0.0, 1.0);

  /// box size over the intro: pops in, shakes, swells, shrinks back
  static double _boxScale(double v) {
    if (v < .05) return .4 + 1.1 * (v / .05);
    if (v < _burstAt - .1) return 1.32;
    if (v < _burstAt) return 1.32 + .5 * _phase(v, _burstAt - .1, _burstAt);
    if (v < _burstAt + .1) return 1.8 - .9 * _phase(v, _burstAt, _burstAt + .1);
    return .9 + .1 * _phase(v, _burstAt + .1, _burstAt + .22);
  }

  static double _boxTurn(double v) {
    final shake = _phase(v, .2, _burstAt - .06);
    if (shake <= 0 || shake >= 1) return 0;
    return ((shake * 8).floor().isEven ? -1 : 1) * .2 * (1 - shake * .3);
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    if (offer == null) return const SizedBox.shrink();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: SizedBox(
          height: 46,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              final open = Curves.easeOutCubic.transform(_phase(v, _lineAt, _lineAt + .15));
              final text = _phase(v, _textAt, _textAt + .12);
              return LayoutBuilder(builder: (context, box) {
                return Stack(clipBehavior: Clip.none, children: [
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    width: 46 + (box.maxWidth - 46) * open,
                    child: Opacity(
                      opacity: _phase(v, _lineAt - .01, _lineAt),
                      child: _Line(offer: offer, clock: DailyGiftOffer.clock(_seconds), textOpacity: text, fullWidth: box.maxWidth, onTap: () => showDailyGiftSheet(context, offer)),
                    ),
                  ),
                  if (v > _burstAt && v < 1)
                    PositionedDirectional(start: 27, top: 9, child: GiftBurst(t: _phase(v, _burstAt, 1))),
                  PositionedDirectional(
                    start: 6,
                    top: -12,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: _boxTurn(v),
                        child: Transform.scale(scale: _boxScale(v), alignment: const Alignment(0, .6), child: const GiftBox()),
                      ),
                    ),
                  ),
                ]);
              });
            },
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.offer, required this.clock, required this.textOpacity, required this.onTap, required this.fullWidth});

  final DailyGiftOffer offer;
  final String clock;
  final double textOpacity;
  final VoidCallback onTap;

  /// the finished line's width: the text stays put while the line opens over it
  final double fullWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${offer.headline} ${offer.amount}، ${offer.timerLabel} $clock',
      child: Material(
        color: giftPale,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFBAE6FD))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: textOpacity,
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: 0,
              maxWidth: double.infinity,
              child: SizedBox(
                width: fullWidth,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 54, end: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: _headline())),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(offer.timerLabel, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF5B7A90), height: 1.15)),
                          Text(clock,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: giftBlue, height: 1.15, fontFeatures: [FontFeature.tabularFigures()])),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headline() {
    const base = TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: giftInk);
    if (offer.state == 'used' || offer.state == 'sold_out') return Text(offer.headline, style: base);
    return Text.rich(
      TextSpan(style: base, children: [
        TextSpan(text: '${offer.headline} '),
        TextSpan(text: offer.amount, style: const TextStyle(color: giftBlue, fontWeight: FontWeight.w900)),
        const TextSpan(text: ' · كل يوم'),
      ]),
    );
  }
}
