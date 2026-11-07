import 'package:flutter/material.dart';

import '../widgets/chat/chat_kit.dart';

/// The look of the community and rewards screens: the chat palette for surfaces and text (both
/// themes), plus the two colours that mean something here - the heart of "سواقيني" and gold.
class CommunityLook {
  static const heart = Color(0xFFE11D48);
  static const gold = Color(0xFFB7791F);
  static const goldSoft = Color(0xFFFFF4DB);
  static const goldSoftDark = Color(0xFF3A2E14);
  static const good = Color(0xFF15803D);

  static ChatPalette get palette => ChatPalette.current();

  static Color goldBackground(ChatPalette p) => p.dark ? goldSoftDark : goldSoft;
}

/// A round photo, or the first letter of the name when there is no photo.
class CommunityAvatar extends StatelessWidget {
  final String? photo;
  final String name;
  final double size;

  const CommunityAvatar({super.key, this.photo, required this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    final letter = name.trim().isEmpty ? '؟' : name.trim().characters.first;
    final fallback = Center(child: Text(letter, style: p.text(size * 0.4, weight: FontWeight.w700, color: p.mine)));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: p.mine.withValues(alpha: 0.12)),
      clipBehavior: Clip.antiAlias,
      child: (photo ?? '').startsWith('http')
          ? Image.network(photo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
          : fallback,
    );
  }
}

/// A selectable chip (badges, reasons).
class CommunityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;

  const CommunityChip({super.key, required this.label, this.selected = false, this.onTap, this.accent});

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    final color = accent ?? p.mine;
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : p.line, width: selected ? 1.4 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[Icon(Icons.check_rounded, size: 16, color: color), const SizedBox(width: 4)],
            Text(label, style: p.text(13, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : p.ink)),
          ]),
        ),
      ),
    );
  }
}

/// A card section with an optional title line.
class CommunityCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final Color? background;
  final EdgeInsets padding;

  const CommunityCard(
      {super.key, this.title, this.trailing, required this.child, this.background, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) ...[
          Row(children: [
            Expanded(child: Text(title!, style: p.text(15, weight: FontWeight.w700))),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 10),
        ],
        child,
      ]),
    );
  }
}

/// A gold coin mark.
class GoldCoin extends StatelessWidget {
  final double size;
  const GoldCoin({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFFF6D365), Color(0xFFD69E2E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Icon(Icons.star_rounded, size: size * 0.66, color: Colors.white),
      );
}

/// A plain app bar in the screens' palette.
PreferredSizeWidget communityAppBar(BuildContext context, String title, {List<Widget> actions = const [], String? subtitle}) {
  final p = CommunityLook.palette;
  return PreferredSize(
    preferredSize: Size.fromHeight(subtitle == null ? 64 : 82),
    child: SafeArea(
      bottom: false,
      child: Container(
        color: p.background,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: p.ink),
            style: IconButton.styleFrom(backgroundColor: p.ink.withValues(alpha: .05), fixedSize: const Size(44, 44)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: p.text(21, weight: FontWeight.w800)),
              if (subtitle != null) Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: p.text(12, color: p.sub)),
            ]),
          ),
          ...actions,
        ]),
      ),
    ),
  );
}
