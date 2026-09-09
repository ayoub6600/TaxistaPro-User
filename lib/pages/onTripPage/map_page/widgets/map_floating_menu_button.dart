import 'package:flutter/material.dart';

import '../../../../styles/styles.dart';

class MapFloatingMenuButton extends StatelessWidget {
  const MapFloatingMenuButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: page,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox.square(
          dimension: 54,
          child: Icon(Icons.menu_rounded, color: textColor, size: 28),
        ),
      ),
    );
  }
}
