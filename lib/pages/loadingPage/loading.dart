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
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: theme.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
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
