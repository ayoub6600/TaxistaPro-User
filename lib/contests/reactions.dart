import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'contests_kit.dart';

/// The six reactions of a long press on «أعجبني» (owner 2026-11-23 «زي الفيسبوك»).
class Reaction {
  const Reaction(this.kind, this.emoji, this.label, this.color);
  final String kind;
  final String emoji;
  final String label;
  final Color color;

  static const all = [
    Reaction('like', '👍', 'أعجبني', Color(0xFF0873FF)),
    Reaction('love', '❤️', 'أحببته', Color(0xFFF33E58)),
    Reaction('haha', '😂', 'هههه', Color(0xFFD69E2E)),
    Reaction('wow', '😮', 'واو', Color(0xFFD69E2E)),
    Reaction('sad', '😢', 'أحزنني', Color(0xFFD69E2E)),
    Reaction('angry', '😡', 'أغضبني', Color(0xFFE9710F)),
  ];

  static Reaction? of(Object? kind) {
    for (final r in all) {
      if (r.kind == kind) return r;
    }
    return null;
  }

  /// The server's counts, biggest first: [{kind, count}]
  static List<(Reaction, int)> counts(Object? list) => [
        for (final x in (list is List ? list : const []))
          if (x is Map && of(x['kind']) != null) (of(x['kind'])!, ((x['count'] ?? 0) as num).toInt()),
      ];

  /// The counts after this person's change, before the server answers.
  static List<Map<String, dynamic>> adjust(Object? list, String? before, String? after) {
    final m = <String, int>{for (final (r, n) in counts(list)) r.kind: n};
    if (before != null) m[before] = (m[before] ?? 1) - 1;
    if (after != null) m[after] = (m[after] ?? 0) + 1;
    final out = [for (final e in m.entries) if (e.value > 0) {'kind': e.key, 'count': e.value}];
    out.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return out;
  }
}

/// A tap is «أعجبني» (or takes the reaction back); a long press opens the bar of six. Slide the
/// finger across it and let go on one, or let go and tap one.
class ReactionTrigger extends StatefulWidget {
  const ReactionTrigger({super.key, required this.current, required this.onPick, required this.child, this.small = false});
  final String? current;
  /// null = take the reaction back
  final ValueChanged<String?> onPick;
  final Widget child;
  final bool small;
  @override
  State<ReactionTrigger> createState() => _ReactionTriggerState();
}

class _ReactionTriggerState extends State<ReactionTrigger> {
  OverlayEntry? _entry;
  final _hover = ValueNotifier<int?>(null);
  Rect _bar = Rect.zero;

  double get _cell => widget.small ? 42 : 48;

  void _open() {
    HapticFeedback.mediumImpact();
    final box = context.findRenderObject() as RenderBox;
    final at = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final width = _cell * Reaction.all.length + 12;
    final left = (at.dx + box.size.width / 2 - width / 2).clamp(8.0, screen.width - width - 8);
    var top = at.dy - _cell - 22;
    if (top < MediaQuery.paddingOf(context).top + 8) top = at.dy + box.size.height + 6;
    _bar = Rect.fromLTWH(left, top, width, _cell + 12);
    _entry = OverlayEntry(builder: (_) => _barView());
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    _hover.value = null;
  }

  int? _indexAt(Offset global) {
    if (!_bar.inflate(18).contains(global)) return null;
    final i = ((global.dx - _bar.left - 6) / _cell).floor();
    // the bar runs left to right like the emoji row, whatever the page direction
    return i >= 0 && i < Reaction.all.length ? i : null;
  }

  void _pick(String? kind) {
    _close();
    HapticFeedback.selectionClick();
    widget.onPick(kind);
  }

  @override
  void dispose() {
    _entry?.remove();
    _hover.dispose();
    super.dispose();
  }

  Widget _barView() {
    final p = ContestLook.p;
    return Stack(children: [
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _close)),
      Positioned.fromRect(
        rect: _bar,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: p.surface,
            elevation: 10,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(40),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ValueListenableBuilder<int?>(
                valueListenable: _hover,
                builder: (_, hover, __) => Row(children: [
                  for (final (i, r) in Reaction.all.indexed)
                    GestureDetector(
                      key: ValueKey('reaction-${r.kind}'),
                      onTap: () => _pick(r.kind),
                      child: Semantics(
                        button: true,
                        label: r.label,
                        child: SizedBox(
                          width: _cell,
                          height: _cell,
                          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                            AnimatedScale(
                              scale: hover == i ? 1.45 : 1,
                              duration: const Duration(milliseconds: 120),
                              child: AnimatedSlide(
                                offset: hover == i ? const Offset(0, -.25) : Offset.zero,
                                duration: const Duration(milliseconds: 120),
                                child: Text(r.emoji, style: TextStyle(fontSize: widget.small ? 26 : 30)),
                              ),
                            ),
                            if (hover == i)
                              Positioned(
                                top: -30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                                  child: Text(r.label, style: p.text(11, weight: FontWeight.w700, color: Colors.white)),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onPick(widget.current == null ? 'like' : null),
        onLongPressStart: (_) => _open(),
        onLongPressMoveUpdate: (d) => _hover.value = _indexAt(d.globalPosition),
        onLongPressEnd: (d) {
          final i = _indexAt(d.globalPosition);
          if (i != null && _hover.value == i) _pick(Reaction.all[i].kind);
          // otherwise the bar stays open for a tap
        },
        child: widget.child,
      );
}

/// The faces under a post or on a comment: the top three, then the count.
class ReactionFaces extends StatelessWidget {
  const ReactionFaces({super.key, required this.reactions, required this.total, this.size = 19});
  final Object? reactions;
  final int total;
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    var top = [for (final (r, _) in Reaction.counts(reactions).take(3)) r];
    if (top.isEmpty && total > 0) top = [Reaction.all.first];
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size + (top.length - 1) * (size * .68),
        height: size,
        child: Stack(children: [
          for (final (i, r) in top.indexed)
            PositionedDirectional(
              start: i * size * .68,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.surface, width: 1.5)),
                child: Text(r.emoji, style: TextStyle(fontSize: size * .66, height: 1.1)),
              ),
            ),
        ]),
      ),
    ]);
  }
}
