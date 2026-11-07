import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/styles.dart';

/// How long a wait is normal before the rider is told the connection is the
/// reason - so a slow network is never mistaken for a broken app.
const slowConnectionAfter = Duration(seconds: 6);
const verySlowConnectionAfter = Duration(seconds: 18);

/// What the waiting card says about the connection after [waited].
({String title, String note})? connectionNotice(Duration waited, bool rtl) {
  if (waited >= verySlowConnectionAfter) {
    return rtl
        ? (title: 'الإنترنت ضعيف جدًا', note: 'تحقّق من الواي فاي أو بيانات الهاتف. سنكمل فور عودة الاتصال.')
        : (title: 'Very weak internet', note: 'Check your Wi-Fi or mobile data. We carry on as soon as it is back.');
  }
  if (waited >= slowConnectionAfter) {
    return rtl
        ? (title: 'الاتصال بطيء…', note: 'يبدو أن الإنترنت لديك ضعيف. أبقِ التطبيق مفتوحًا، ما زلنا نحاول.')
        : (title: 'Slow connection…', note: 'Your internet looks weak. Keep the app open, we are still trying.');
  }
  return null;
}

class Loading extends StatefulWidget {
  const Loading({super.key, this.color, this.message, this.submessage});

  final Color? color;
  final String? message;
  final String? submessage;

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  final Stopwatch _waited = Stopwatch()..start();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // re-checked every second only while the card is on screen
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final w = _waited.elapsed;
      if (w >= slowConnectionAfter && w < verySlowConnectionAfter + const Duration(seconds: 2)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Color? get color => widget.color;
  String? get message => widget.message;
  String? get submessage => widget.submessage;

  @override
  Widget build(BuildContext context) {
    // The overlay blocks taps from the first frame, but stays invisible for
    // the first ~180ms and then fades in: quick actions never flash a dialog.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: const Interval(0.53, 1, curve: Curves.easeOut),
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: _buildOverlay(context),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.sizeOf(context);
    final notice = connectionNotice(_waited.elapsed, rtl);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: ColoredBox(
        color: color ?? Colors.black.withValues(alpha: .34),
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: message ?? (rtl ? 'جارٍ التحميل' : 'Loading'),
            child: Container(
              width: 278,
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // design v2: the Taxista car driving along a short road (no spinning circle)
                  const TaxiRoadLoader(),
                  const SizedBox(height: 18),
                  Text(
                    message ?? notice?.title ?? (rtl ? 'لحظات من فضلك…' : 'Just a moment…'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (submessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      submessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.45,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                  if (notice != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 18, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            notice.note,
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.45, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// A small Taxista car going along a dashed road, looping; still when the phone asks for less motion.
class TaxiRoadLoader extends StatefulWidget {
  const TaxiRoadLoader({super.key, this.width = 150});
  final double width;

  @override
  State<TaxiRoadLoader> createState() => _TaxiRoadLoaderState();
}

class _TaxiRoadLoaderState extends State<TaxiRoadLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: widget.width,
      height: 46,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = still ? .5 : Curves.easeInOut.transform(_c.value);
          final x = (rtl ? 1 - t : t) * (widget.width - 40);
          return Stack(children: [
            // the road: dashes that slide under the car
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: CustomPaint(size: Size(widget.width, 4), painter: _RoadPainter(phase: still ? 0 : _c.value, rtl: rtl)),
            ),
            Positioned(
              left: x,
              bottom: 10,
              child: Transform.translate(
                offset: Offset(0, still ? 0 : -1.5 * (1 - (2 * _c.value - 1).abs())),
                child: Transform.flip(
                  flipX: rtl,
                  child: Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(color: theme.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.local_taxi_rounded, color: theme, size: 24),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.phase, required this.rtl});
  final double phase;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xffE3E8EF);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)), base);
    final dash = Paint()..color = const Color(0xff0873FF).withValues(alpha: .55);
    const w = 12.0, gap = 10.0;
    final shift = (rtl ? 1 : -1) * phase * (w + gap);
    for (double x = -w - gap + shift % (w + gap); x < size.width; x += w + gap) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, w, size.height), const Radius.circular(2)), dash);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.phase != phase;
}
