import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart' show IcPlace;
import '../../functions/parcel_saved.dart';
import '../../functions/tr.dart';
import '../intercity/intercity_style.dart';

/// Saved receivers above the receiver's fields: a tap fills the name and the number, a long press
/// removes him (owner 2026-11-19).
class ParcelReceiverChips extends StatelessWidget {
  const ParcelReceiverChips({super.key, required this.receivers, required this.onPick, required this.onRemove});

  final List<SavedReceiver> receivers;
  final ValueChanged<SavedReceiver> onPick;
  final ValueChanged<SavedReceiver> onRemove;

  @override
  Widget build(BuildContext context) {
    if (receivers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Strip(children: [
        for (final r in receivers)
          SavedChip(key: ValueKey('parcel-receiver-${r.phone}'), icon: '👤', text: r.name, onTap: () => onPick(r), onLongPress: () => onRemove(r)),
      ]),
    );
  }
}

/// Saved pickup places under «من وين ياخذها الكابتن»: البيت، المحل… one tap and the captain takes it from there.
class ParcelPlaceChips extends StatelessWidget {
  const ParcelPlaceChips({super.key, required this.places, required this.onPick, required this.onRemove, this.current});

  final List<SavedPickPlace> places;

  /// the pickup now: its chip is lit
  final IcPlace? current;
  final ValueChanged<SavedPickPlace> onPick;
  final ValueChanged<SavedPickPlace> onRemove;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _Strip(children: [
        for (final p in places)
          SavedChip(
              key: ValueKey('parcel-place-${p.label}'),
              icon: p.icon,
              text: p.label,
              selected: current != null && p.near(current!),
              onTap: () => onPick(p),
              onLongPress: () => onRemove(p)),
      ]),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => children[i],
        ),
      );
}

class SavedChip extends StatelessWidget {
  const SavedChip({super.key, required this.icon, required this.text, required this.onTap, this.onLongPress, this.selected = false});

  final bool selected;
  final String icon;
  final String text;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: text,
        hint: onLongPress == null ? null : tr('اضغط مطوّل للحذف', 'Long-press to remove'),
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: selected ? const Color(0xffEAF2FF) : IcStyle.soft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? IcStyle.blue : const Color(0xffD5E3F7), width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(13, w: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      );
}
