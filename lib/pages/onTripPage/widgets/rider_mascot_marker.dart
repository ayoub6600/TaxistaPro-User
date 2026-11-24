import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
                color: Colors.black.withValues(alpha: 0.15),
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

/// The mascot with [name] in its bubble, drawn once into a map marker: on the home map the pickup
/// is the phone's own place, so the mascot stands there and moves with the map instead of staying
/// in the middle of the screen. The feet are at the bottom centre: use the anchor (0.5, 1).
Future<BitmapDescriptor> riderMascotMarkerIcon(String name, double ratio) async {
  final data = await rootBundle.load(riderMascotAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: (riderMascotWidth * ratio).round());
  final mascot = (await codec.getNextFrame()).image;
  final text = TextPainter(
    text: TextSpan(text: name, style: TextStyle(color: Colors.white, fontSize: 11 * ratio, fontWeight: FontWeight.w700)),
    textDirection: TextDirection.rtl,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 140 * ratio);
  final padX = 10 * ratio, padY = 5 * ratio, tail = 5 * ratio, top = 2 * ratio, gap = 2 * ratio;
  final bubbleW = text.width + padX * 2, bubbleH = text.height + padY * 2;
  final width = max(bubbleW, mascot.width.toDouble()) + 6 * ratio;
  final height = top + bubbleH + tail + gap + mascot.height;
  final cx = width / 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(cx - bubbleW / 2, top, bubbleW, bubbleH), Radius.circular(12 * ratio));
  final shape = Path()
    ..addRRect(bubble)
    ..moveTo(cx - tail, top + bubbleH - 1)
    ..lineTo(cx + tail, top + bubbleH - 1)
    ..lineTo(cx, top + bubbleH + tail)
    ..close();
  canvas.drawShadow(shape, Colors.black, 2 * ratio, false);
  canvas.drawPath(shape, Paint()..color = theme);
  text.paint(canvas, Offset(cx - text.width / 2, top + padY));
  canvas.drawImage(mascot, Offset(cx - mascot.width / 2, top + bubbleH + tail + gap), Paint()..filterQuality = FilterQuality.medium);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.ceil(), height.ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  mascot.dispose();
  image.dispose();
  return BitmapDescriptor.bytes(png!.buffer.asUint8List(), imagePixelRatio: ratio);
}
