import 'package:flutter/material.dart';

import '../styles/styles.dart';

/// Design v2: while a page loads, soft cards in the shape of what is coming (no spinning circle).
class V2Skeleton extends StatefulWidget {
  const V2Skeleton({super.key, this.count = 5, this.height = 84, this.padding = const EdgeInsets.all(16), this.leadingCircle = true});

  final int count;
  final double height;
  final EdgeInsets padding;
  final bool leadingCircle;

  @override
  State<V2Skeleton> createState() => _V2SkeletonState();
}

class _V2SkeletonState extends State<V2Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = textColor.withValues(alpha: .07);
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: still ? .8 : .55 + .45 * _c.value,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.count,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => Container(
            height: widget.height,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xff171B22) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withValues(alpha: .06)),
            ),
            child: Row(children: [
              if (widget.leadingCircle) ...[
                Container(width: 44, height: 44, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FractionallySizedBox(
                    widthFactor: .62 - (i % 3) * .1,
                    child: Container(height: 12, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  ),
                  const SizedBox(height: 10),
                  FractionallySizedBox(
                    widthFactor: .9 - (i % 2) * .2,
                    child: Container(height: 10, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
