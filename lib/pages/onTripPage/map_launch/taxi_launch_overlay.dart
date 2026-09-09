import 'dart:async';

import 'package:flutter/material.dart';

class TaxiLaunchOverlay extends StatefulWidget {
  const TaxiLaunchOverlay({
    super.key,
    required this.mapReady,
    required this.onRevealStarted,
    required this.onFinished,
  });

  final bool mapReady;
  final VoidCallback onRevealStarted;
  final VoidCallback onFinished;

  @override
  State<TaxiLaunchOverlay> createState() => _TaxiLaunchOverlayState();
}

class _TaxiLaunchOverlayState extends State<TaxiLaunchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _minimumSplashTimer;
  Timer? _safetyTimer;
  bool _minimumSplashShown = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });

    _minimumSplashTimer = Timer(const Duration(milliseconds: 650), () {
      _minimumSplashShown = true;
      if (widget.mapReady) _revealMap();
    });
    _safetyTimer = Timer(const Duration(milliseconds: 2400), _revealMap);
  }

  @override
  void didUpdateWidget(covariant TaxiLaunchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.mapReady && widget.mapReady && _minimumSplashShown) {
      _revealMap();
    }
  }

  void _revealMap() {
    if (_finished || _controller.isAnimating || _controller.isCompleted) return;
    widget.onRevealStarted();
    _controller.forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _minimumSplashTimer?.cancel();
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final reveal = Curves.easeInOutCubic.transform(_controller.value);
          final logoFade = Curves.easeIn.transform(
            ((_controller.value - 0.05) / 0.62).clamp(0.0, 1.0),
          );

          return Opacity(
            opacity: 1 - reveal,
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: Opacity(
                  opacity: 1 - logoFade,
                  child: Transform.translate(
                    offset: Offset(0, -10 * logoFade),
                    child: Transform.scale(
                      scale: 1 - (logoFade * 0.035),
                      child: SizedBox(
                        width: screen.width * 0.6,
                        height: screen.height * 0.6,
                        child: Image.asset(
                          'assets/images/new_logo.jpeg',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
