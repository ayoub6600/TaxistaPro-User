import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Android 15+ draws every app under the phone's own bottom buttons (back, home, recent apps).
/// On Android the whole app is lifted above them, and every page is told the screen ends there,
/// so pages that size themselves from the screen height (most older pages) fit too. iPhone is untouched.
class AndroidNavSafe extends StatelessWidget {
  const AndroidNavSafe({super.key, required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return child;
    final mq = MediaQuery.of(context);
    final bar = mq.viewPadding.bottom;
    if (bar <= 0) return child;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.only(bottom: bar),
        child: MediaQuery(
          data: mq.copyWith(
            size: Size(mq.size.width, mq.size.height - bar),
            padding: mq.padding.copyWith(bottom: 0),
            viewPadding: mq.viewPadding.copyWith(bottom: 0),
            // the keyboard is measured from the bottom of the glass; the app now starts above the buttons
            viewInsets: mq.viewInsets.copyWith(bottom: math.max(0, mq.viewInsets.bottom - bar)),
          ),
          child: child,
        ),
      ),
    );
  }
}
