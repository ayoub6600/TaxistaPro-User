import 'package:flutter/material.dart';

class BookingBackButton extends StatelessWidget {
  const BookingBackButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 46,
          child: Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF162033),
            size: 25,
          ),
        ),
      ),
    );
  }
}
