import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Android 15+ draws every app under the phone's own bottom buttons (back, home, recent apps),
/// which covered our bottom buttons. On Android the whole app stays above them; iPhone is untouched.
class AndroidNavSafe extends StatelessWidget {
  const AndroidNavSafe({super.key, required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return child;
    return ColoredBox(color: color, child: SafeArea(top: false, left: false, right: false, child: child));
  }
}
