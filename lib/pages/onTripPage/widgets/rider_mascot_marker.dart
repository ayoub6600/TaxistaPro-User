import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../styles/styles.dart';

/// The rider/pickup pin's mascot: one small local PNG, reused as-is for
/// every status - the picking/confirmed text lives in [RiderMascotBubble]
/// instead of being baked into the image, so the same asset works for any
/// future bubble copy without ever needing a new image. Shared by every
/// screen that shows a fixed-center pickup pin (the pickup-location picker
/// and the home map's own drag-to-set-pickup pin).
const String riderMascotAsset = 'assets/images/rider_mascot.png';
const double riderMascotWidth = 68;
const double riderMascotHeight = 69;

/// Rough height of the bubble + the gap above the mascot, used only to keep
/// the mascot's feet anchored at the exact map-center point the old pin's
/// tip used to point at - the same manual-offset technique these screens
/// already used for their plain pin images.
const double riderMascotBubbleAllowance = 34;

/// The small speech bubble shown above the mascot. Pure text/shape, no
/// image baking, so it can show any string - the picking-location status,
/// the rider's name once confirmed, or any future pickup status - while
/// [riderMascotAsset] itself never changes.
class RiderMascotBubble extends StatelessWidget {
  const RiderMascotBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(width: 8, height: 8, color: theme),
          ),
        ),
      ],
    );
  }
}
