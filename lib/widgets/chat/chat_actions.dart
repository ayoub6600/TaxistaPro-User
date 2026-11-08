import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_reactions.dart';

/// Chat 2.0 (WhatsApp-like) pieces shared by the chat with Taxista and the ride's chat:
/// the long-press menu (six emojis on top, «رد», «نسخ»), swipe-to-reply, the quoted line inside a
/// bubble, the reply bar above the composer and the reaction pill on the bubble's own corner.
class ChatMenuChoice {
  const ChatMenuChoice._(this.kind, [this.emoji]);
  final String kind; // react | reply | copy
  final String? emoji; // '' = remove my reaction

  static const reply = ChatMenuChoice._('reply');
  static const copy = ChatMenuChoice._('copy');
  factory ChatMenuChoice.react(String emoji) => ChatMenuChoice._('react', emoji);
}

class ChatMessageMenu {
  /// the sheet for one message; null when dismissed
  static Future<ChatMenuChoice?> show(
    BuildContext context, {
    required String preview,
    String? currentEmoji,
    bool canReact = true,
    bool canCopy = true,
    required bool rtl,
  }) {
    HapticFeedback.mediumImpact();
    String t(String ar, String en) => rtl ? ar : en;
    return showModalBottomSheet<ChatMenuChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = dark ? const Color(0xFF151E2E) : Colors.white;
        final soft = dark ? const Color(0xFF1E293B) : const Color(0xFFF2F5FA);
        final ink = dark ? Colors.white : const Color(0xFF0F172A);
        final sub = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        Widget action(IconData icon, String label, ChatMenuChoice choice) => Material(
              color: soft,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(ctx, choice),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(children: [
                    Icon(icon, size: 22, color: ink),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                  ]),
                ),
              ),
            );
        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(24)),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (canReact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(99)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      for (final e in ChatReactions.allowed)
                        _Emoji(
                          emoji: e,
                          selected: e == currentEmoji,
                          onTap: () => Navigator.pop(ctx, ChatMenuChoice.react(e == currentEmoji ? '' : e)),
                        ),
                    ]),
                  ),
                if (preview.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                    child: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: sub, height: 1.4)),
                  ),
                const SizedBox(height: 4),
                action(Icons.reply_rounded, t('رد', 'Reply'), ChatMenuChoice.reply),
                if (canCopy) ...[
                  const SizedBox(height: 6),
                  action(Icons.copy_rounded, t('نسخ النص', 'Copy text'), ChatMenuChoice.copy),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji({required this.emoji, required this.selected, required this.onTap});
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? const Color(0xFFD6E2FF) : Colors.transparent),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      );
}

/// drag a message sideways (either way) to answer it, like WhatsApp
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply, this.enabled = true});
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double _dx = 0;
  bool _armed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dx = (_dx + d.delta.dx).clamp(-80.0, 80.0);
          final armed = _dx.abs() > 56;
          if (armed && !_armed) HapticFeedback.selectionClick();
          _armed = armed;
        });
      },
      onHorizontalDragEnd: (_) {
        if (_armed) widget.onReply();
        setState(() {
          _dx = 0;
          _armed = false;
        });
      },
      onHorizontalDragCancel: () => setState(() {
        _dx = 0;
        _armed = false;
      }),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        if (_dx.abs() > 8)
          Positioned(
            left: _dx > 0 ? 4 : null,
            right: _dx < 0 ? 4 : null,
            child: Opacity(
              opacity: (_dx.abs() / 56).clamp(0.0, 1.0),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: _armed ? const Color(0xFF1D4ED8) : const Color(0x22000000),
                child: Icon(Icons.reply_rounded, size: 18, color: _armed ? Colors.white : const Color(0xFF475569)),
              ),
            ),
          ),
        AnimatedContainer(
          duration: Duration(milliseconds: _dx == 0 ? 180 : 0),
          transform: Matrix4.translationValues(_dx, 0, 0),
          child: widget.child,
        ),
      ]),
    );
  }
}

/// the quoted line at the top of a bubble (tap = jump to it)
class ChatQuote extends StatelessWidget {
  const ChatQuote({super.key, required this.quote, required this.onMine, this.onTap});
  final Map quote;
  final bool onMine; // drawn inside one of my (blue) bubbles
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = onMine ? Colors.white : const Color(0xFF1D4ED8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsetsDirectional.fromSTEB(9, 6, 9, 6),
        decoration: BoxDecoration(
          color: onMine ? Colors.white.withValues(alpha: .18) : const Color(0xFF1D4ED8).withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
          border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('${quote['name'] ?? ''}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 1),
          Text('${quote['text'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.35, color: onMine ? Colors.white.withValues(alpha: .9) : const Color(0xFF475569))),
        ]),
      ),
    );
  }
}

/// «رد على …» above the composer
class ChatReplyBar extends StatelessWidget {
  const ChatReplyBar({super.key, required this.name, required this.text, required this.onClose, required this.rtl});
  final String name, text;
  final VoidCallback onClose;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E293B) : const Color(0xFFEDF2FF),
        borderRadius: BorderRadius.circular(12),
        border: const BorderDirectional(start: BorderSide(color: Color(0xFF1D4ED8), width: 3)),
      ),
      child: Row(children: [
        const Icon(Icons.reply_rounded, size: 20, color: Color(0xFF1D4ED8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text((rtl ? 'رد على ' : 'Reply to ') + name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
            Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : const Color(0xFF475569))),
          ]),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20), tooltip: rtl ? 'إلغاء الرد' : 'Cancel reply'),
      ]),
    );
  }
}

/// the reactions as one small pill hanging on the bubble's own bottom corner
class ChatReactionPill extends StatelessWidget {
  const ChatReactionPill({super.key, required this.reactions, this.onTap});
  final List<Map> reactions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final emojis = <String>[];
    for (final r in reactions) {
      final e = '${r['emoji']}';
      if (!emojis.contains(e)) emojis.add(e);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFE3E9F2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .10), blurRadius: 6, offset: const Offset(0, 1))],
        ),
        child: Text(emojis.join('') + (reactions.length > 1 ? ' ${reactions.length}' : ''), style: const TextStyle(fontSize: 14, height: 1.2)),
      ),
    );
  }
}

/// a short line for the reply bar / menu: the text, or «📷 صورة» / «🎤 رسالة صوتية»
String chatSnippet(Map m, {required bool rtl, String? text}) {
  final t = (text ?? '${m['message'] ?? ''}').trim();
  if (t.isNotEmpty) return t.length > 90 ? '${t.substring(0, 90)}…' : t;
  if ('${m['message_type'] ?? ''}' == 'voice' || m['audio_url'] != null) return rtl ? '🎤 رسالة صوتية' : '🎤 Voice message';
  return rtl ? '📷 صورة' : '📷 Photo';
}
