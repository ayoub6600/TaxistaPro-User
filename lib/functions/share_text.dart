import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the phone's share sheet. iOS needs to know where it comes from, or it refuses and nothing
/// happens on the screen. If it still fails the text is copied, so the button never does nothing.
/// @return true when the sheet opened; false when the text was copied instead
Future<bool> shareText(BuildContext context, String text) async {
  // the sheet's anchor must lie inside the screen: a widget scrolled partly off the top gives a
  // negative corner and iOS refused the sheet (owner 2026-11-23 «زر المشاركة ما هوش شغال»)
  final screen = Offset.zero & MediaQuery.sizeOf(context);
  final box = context.findRenderObject();
  final raw = box is RenderBox && box.hasSize && !box.size.isEmpty ? box.localToGlobal(Offset.zero) & box.size : null;
  final inside = raw?.intersect(screen);
  final origin = inside != null && inside.width > 1 && inside.height > 1 ? inside : Rect.fromCenter(center: screen.center, width: 2, height: 2);
  try {
    await Share.share(text, sharePositionOrigin: origin);
    return true;
  } catch (e) {
    debugPrint('share failed: $e');
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  }
}
