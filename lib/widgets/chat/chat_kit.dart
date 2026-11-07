import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../styles/styles.dart';
import 'chat_photos.dart';

/// The look shared by the app's conversations (support, the driver of a trip): colours for both
/// themes, dates and times, bubbles with time and delivery ticks, the header and the composer.

class ChatPalette {
  final bool dark;
  final Color background, surface, theirs, theirsBorder, ink, sub, line, field;

  const ChatPalette._(this.dark, this.background, this.surface, this.theirs, this.theirsBorder, this.ink, this.sub,
      this.line, this.field);

  factory ChatPalette.current() => isDarkTheme == true
      ? const ChatPalette._(true, Color(0xFF0B1220), Color(0xFF131B2A), Color(0xFF1B2537), Color(0xFF263248),
          Color(0xFFE8EDF6), Color(0xFF97A3B8), Color(0xFF223047), Color(0xFF1B2537))
      : const ChatPalette._(false, Color(0xFFF2F5FA), Colors.white, Colors.white, Color(0xFFE2E8F0), Color(0xFF0F172A),
          Color(0xFF64748B), Color(0xFFE6EBF2), Color(0xFFF1F4F9));

  Color get mine => theme;
  static const online = Color(0xFF16A34A);

  TextStyle text(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color ?? ink, height: height);
}

enum ChatDelivery { sending, sent, read, failed }

class ChatTime {
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _daysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// The server's created_at (UTC) in the phone's time.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String clock(DateTime t, bool ar) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final half = t.hour < 12 ? (ar ? 'ص' : 'AM') : (ar ? 'م' : 'PM');
    return '$h:$m $half';
  }

  static String dayLabel(DateTime t, bool ar) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final days = today.difference(day).inDays;
    if (days == 0) return ar ? 'اليوم' : 'Today';
    if (days == 1) return ar ? 'أمس' : 'Yesterday';
    if (days > 1 && days < 7) return (ar ? _daysAr : _daysEn)[t.weekday - 1];
    final month = (ar ? _monthsAr : _monthsEn)[t.month - 1];
    return t.year == now.year ? '${t.day} $month' : '${t.day} $month ${t.year}';
  }
}

/// Right to left for Arabic text, left to right for Latin, from the first letter.
ui.TextDirection? chatTextDirection(String text) {
  for (final rune in text.runes) {
    if ((rune >= 0x0590 && rune <= 0x08FF) || (rune >= 0xFB1D && rune <= 0xFEFC)) return ui.TextDirection.rtl;
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A) || (rune >= 0xC0 && rune <= 0x24F)) {
      return ui.TextDirection.ltr;
    }
  }
  return null;
}

/// The top of a conversation: back, who it is with (a photo, or an icon on the brand gradient)
/// with a green dot and a status line, the call button (green when the other side can take a
/// call now) and an optional menu button.
class ChatHeader extends StatelessWidget {
  final ChatPalette palette;
  final String title, status, callLabel;
  final String? photo, moreLabel;
  final IconData icon;
  final bool online, calling;
  final VoidCallback onBack;
  final VoidCallback? onCall, onMore;

  const ChatHeader({
    super.key,
    required this.palette,
    required this.title,
    required this.status,
    required this.online,
    required this.onBack,
    required this.callLabel,
    this.calling = false,
    this.onCall,
    this.onMore,
    this.moreLabel,
    this.photo,
    this.icon = Icons.support_agent_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Material(
      color: p.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        padding: EdgeInsets.fromLTRB(6, MediaQuery.of(context).padding.top + 6, 6, 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(Icons.arrow_back_rounded, color: p.ink),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [theme, Color.lerp(theme, const Color(0xFF17C3E8), 0.55)!],
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photo != null && photo!.isNotEmpty
                      ? Image.network(photo!,
                          fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, color: Colors.white, size: 26))
                      : Icon(icon, color: Colors.white, size: 26),
                ),
                PositionedDirectional(
                  end: -1,
                  bottom: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? ChatPalette.online : const Color(0xFF94A3B8),
                      border: Border.all(color: p.surface, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: p.text(17, weight: FontWeight.w700, height: 1.25)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(status,
                        key: ValueKey(status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: p.text(12.5, color: online ? ChatPalette.online : p.sub, height: 1.3)),
                  ),
                ],
              ),
            ),
            if (onCall != null)
              Padding(
                padding: EdgeInsetsDirectional.only(end: onMore == null ? 8 : 2),
                child: Tooltip(
                  message: callLabel,
                  child: Semantics(
                    button: true,
                    label: callLabel,
                    child: Material(
                      color: online ? ChatPalette.online : theme.withValues(alpha: p.dark ? 0.22 : 0.1),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: calling ? null : onCall,
                        child: SizedBox.square(
                          dimension: 46,
                          child: Center(
                            child: calling
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: online ? Colors.white : theme))
                                : Icon(Icons.call_rounded, size: 23, color: online ? Colors.white : theme),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                tooltip: moreLabel,
                icon: Icon(Icons.more_vert_rounded, color: p.sub),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatDaySeparator extends StatelessWidget {
  final ChatPalette palette;
  final String label;

  const ChatDaySeparator({super.key, required this.palette, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: palette.dark ? const Color(0xFF1B2537) : const Color(0xFFE4EAF2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: palette.text(11.5, weight: FontWeight.w600, color: palette.sub)),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatPalette palette;
  final bool mine, tail, highlighted;
  final String text, time, copiedLabel;
  final Widget? voice;

  /// photo links (message_type image): drawn above the caption ([text]); tap opens them full screen
  final List<String> photos;
  final ChatDelivery? status;
  final String? failedLabel;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.palette,
    required this.mine,
    required this.tail,
    required this.text,
    required this.time,
    required this.copiedLabel,
    this.highlighted = false,
    this.voice,
    this.photos = const [],
    this.status,
    this.failedLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final failed = status == ChatDelivery.failed;
    final fg = mine ? Colors.white : p.ink;
    final meta = mine ? Colors.white.withValues(alpha: 0.78) : p.sub;
    const round = Radius.circular(18);
    final corner = Radius.circular(tail ? 5 : 18);
    // the sender's side keeps the same place in both languages: own messages on the right
    final radius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomLeft: mine ? round : corner,
      bottomRight: mine ? corner : round,
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      padding: photos.isNotEmpty ? const EdgeInsets.fromLTRB(4, 4, 4, 6) : EdgeInsets.fromLTRB(12, voice != null ? 8 : 7, 12, 6),
      decoration: BoxDecoration(
        color: mine ? (failed ? p.mine.withValues(alpha: 0.55) : p.mine) : p.theirs,
        borderRadius: radius,
        border: highlighted
            ? Border.all(color: const Color(0xFFF59E0B), width: 2)
            : (mine ? null : Border.all(color: p.theirsBorder)),
        boxShadow: [
          if (!p.dark)
            BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photos.isNotEmpty) ...[
            ChatPhotoTiles(urls: photos, width: min(240, MediaQuery.of(context).size.width * 0.66)),
            if (text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: SelectableText(text, textDirection: chatTextDirection(text), style: p.text(15, color: fg, height: 1.45)),
                ),
              ),
          ] else
          voice ??
              Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: SelectableText(
                  text,
                  textDirection: chatTextDirection(text),
                  style: p.text(15, color: fg, height: 1.45),
                ),
              ),
          const SizedBox(height: 2),
          Padding(
            padding: photos.isNotEmpty ? const EdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, textDirection: ui.TextDirection.ltr, style: p.text(10.5, color: meta, height: 1.2)),
              if (status != null) ...[
                const SizedBox(width: 4),
                Icon(
                  switch (status!) {
                    ChatDelivery.sending => Icons.schedule_rounded,
                    ChatDelivery.sent => Icons.done_rounded,
                    ChatDelivery.read => Icons.done_all_rounded,
                    ChatDelivery.failed => Icons.error_outline_rounded,
                  },
                  size: 15,
                  color: switch (status!) {
                    ChatDelivery.read => const Color(0xFFBFE3FF),
                    ChatDelivery.failed => const Color(0xFFFFD4D4),
                    _ => meta,
                  },
                ),
              ],
            ],
          ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: onRetry,
            onLongPress: voice != null || photos.isNotEmpty || text.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: text));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(copiedLabel),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  },
            child: bubble,
          ),
        ),
        if (failed && failedLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  Text(failedLabel!, style: palette.text(12, weight: FontWeight.w600, color: const Color(0xFFDC2626))),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class ChatComposer extends StatelessWidget {
  final ChatPalette palette;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint, sendLabel, voiceLabel;
  final VoidCallback onChanged, onSend, onVoice;

  /// 📷 inside the field: camera or gallery (null = no photo button)
  final VoidCallback? onPhoto;

  const ChatComposer({
    super.key,
    required this.palette,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.sendLabel,
    required this.voiceLabel,
    required this.onChanged,
    required this.onSend,
    required this.onVoice,
    this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: p.field,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: p.line),
              ),
              alignment: Alignment.center,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textDirection: chatTextDirection(controller.text),
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                cursorColor: theme,
                style: p.text(15, height: 1.4),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: hint,
                  hintStyle: p.text(15, color: p.sub.withValues(alpha: 0.85), height: 1.4),
                ),
              )),
                if (onPhoto != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      onPressed: onPhoto,
                      tooltip: 'صورة',
                      icon: Icon(Icons.photo_camera_outlined, color: p.sub),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _RoundAction(
              key: ValueKey(hasText),
              icon: hasText ? Icons.send_rounded : Icons.mic_rounded,
              label: hasText ? sendLabel : voiceLabel,
              onTap: hasText ? onSend : onVoice,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundAction({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: theme,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 48, child: Icon(icon, color: Colors.white, size: 22)),
        ),
      ),
    );
  }
}

class ChatNotice extends StatelessWidget {
  final ChatPalette palette;
  final IconData icon;
  final String title, body, action;
  final VoidCallback onAction;

  const ChatNotice(
      {super.key,
      required this.palette,
      required this.icon,
      required this.title,
      required this.body,
      required this.action,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: p.sub),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: p.text(17, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: p.text(14, color: p.sub, height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(backgroundColor: theme, shape: const StadiumBorder()),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(action, style: p.text(14, weight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
