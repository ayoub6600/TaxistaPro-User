import 'package:flutter/material.dart';

import '../../../../styles/styles.dart';

class MapFloatingMenuButton extends StatelessWidget {
  const MapFloatingMenuButton({super.key, required this.onTap, this.icon = Icons.menu_rounded, this.label, this.badge = 0});

  final VoidCallback onTap;
  final IconData icon;

  /// read by VoiceOver (the menu keeps its old unnamed behaviour)
  final String? label;

  /// a red count on the corner (0: none)
  final int badge;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: page,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox.square(
          dimension: 54,
          child: Icon(icon, color: textColor, size: 28, semanticLabel: label),
        ),
      ),
    );
    if (badge <= 0) return button;
    return Stack(clipBehavior: Clip.none, children: [
      button,
      PositionedDirectional(
        top: -4,
        end: -4,
        child: Container(
          constraints: const BoxConstraints(minWidth: 22),
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffE0243A),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(badge > 99 ? '99+' : '$badge',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1)),
        ),
      ),
    ]);
  }
}
