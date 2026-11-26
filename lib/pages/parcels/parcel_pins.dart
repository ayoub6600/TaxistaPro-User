import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../intercity/intercity_style.dart';

/// The parcels map's pins (owner 2026-11-19: «الدبابيس اجعلها أفضل بشكل موضح أكثر»): a teardrop in the
/// place's colour with its icon, and a white label above it saying what the place is. The same painter
/// draws the Google marker bitmap and the OpenStreetMap widget, so both maps look alike.
class ParcelPin {
  static const pickColor = Color(0xff16A34A);
  /// blue, as the map picker draws where it goes (owner 2026-11-19: the drop pin is blue, not red)
  static const dropColor = Color(0xff0879FA);

  static const _pinW = 40.0, _pinH = 50.0, _gap = 5.0, _labelH = 30.0, _padX = 11.0, _dot = 8.0;

  static TextPainter _text(String label) => TextPainter(
        text: TextSpan(text: label, style: IcStyle.t(13, w: FontWeight.w800).copyWith(height: 1.2)),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 190);

  static Size measure(String label) {
    final w = _text(label).width + _padX * 2 + _dot + 6;
    return Size(w < _pinW ? _pinW : w, _labelH + _gap + _pinH);
  }

  static void paint(Canvas c, Size size, {required String label, required Color color, required IconData icon}) {
    final cx = size.width / 2;
    final shadow = Paint()
      ..color = const Color(0x33102A56)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // the label
    final tp = _text(label);
    final lw = tp.width + _padX * 2 + _dot + 6;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(cx - lw / 2, 1, lw, _labelH - 2), const Radius.circular(15));
    c.drawRRect(box.shift(const Offset(0, 1.5)), shadow);
    c.drawRRect(box, Paint()..color = Colors.white);
    c.drawRRect(box, Paint()
      ..color = color.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // the dot sits at the start of the line (right in Arabic)
    c.drawCircle(Offset(box.right - _padX - _dot / 2, _labelH / 2), _dot / 2, Paint()..color = color);
    tp.paint(c, Offset(box.right - _padX - _dot - 6 - tp.width, (_labelH - tp.height) / 2));

    // the teardrop
    const top = _labelH + _gap;
    const r = _pinW / 2 - 2;
    final head = Offset(cx, top + r + 1);
    final drop = Path()
      ..moveTo(cx, top + _pinH - 1)
      ..quadraticBezierTo(cx - r * .55, top + _pinH - r * .55, cx - r * .92, head.dy + r * .38)
      ..arcToPoint(Offset(cx + r * .92, head.dy + r * .38), radius: const Radius.circular(r), largeArc: true)
      ..quadraticBezierTo(cx + r * .55, top + _pinH - r * .55, cx, top + _pinH - 1)
      ..close();
    c.drawPath(drop.shift(const Offset(0, 2)), shadow);
    c.drawPath(drop, Paint()..color = color);
    c.drawPath(drop, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    c.drawCircle(head, r * .58, Paint()..color = Colors.white);
    final ip = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: r * .82, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    ip.paint(c, head - Offset(ip.width / 2, ip.height / 2));
  }

  /// the Google marker: anchored at the tip of the teardrop
  static Future<BitmapDescriptor> bitmap({required String label, required Color color, required IconData icon, required double dpr}) async {
    final size = measure(label);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    paint(c, size, label: label, color: color, icon: icon);
    final img = await rec.endRecording().toImage((size.width * dpr).ceil(), (size.height * dpr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }

  /// the parcel that moves along the road: 📦 on a white disc
  static Future<BitmapDescriptor> parcel(double dpr, {String mover = '📦'}) async {
    const s = 34.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    c.drawCircle(const Offset(s / 2, s / 2 + 1.5), s / 2 - 2, Paint()
      ..color = const Color(0x40102A56)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
    c.drawCircle(const Offset(s / 2, s / 2), s / 2 - 2, Paint()..color = Colors.white);
    final tp = TextPainter(text: TextSpan(text: mover, style: const TextStyle(fontSize: 18)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset((s - tp.width) / 2, (s - tp.height) / 2));
    final img = await rec.endRecording().toImage((s * dpr).ceil(), (s * dpr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: dpr);
  }
}

/// the same pin as a widget (the OpenStreetMap map)
class ParcelPinWidget extends StatelessWidget {
  const ParcelPinWidget({super.key, required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => CustomPaint(size: ParcelPin.measure(label), painter: _Painter(label, color, icon));
}

class _Painter extends CustomPainter {
  _Painter(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  @override
  void paint(Canvas canvas, Size size) => ParcelPin.paint(canvas, size, label: label, color: color, icon: icon);

  @override
  bool shouldRepaint(_Painter o) => o.label != label || o.color != color || o.icon != icon;
}
