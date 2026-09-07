import 'package:flutter/material.dart';

import '../../styles/styles.dart';

class Loading extends StatelessWidget {
  const Loading({super.key, this.color, this.message, this.submessage});

  final Color? color;
  final String? message;
  final String? submessage;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.sizeOf(context);
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
                    message ?? (rtl ? 'لحظات من فضلك…' : 'Just a moment…'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
