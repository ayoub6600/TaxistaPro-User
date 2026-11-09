import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the phone's share sheet. iOS needs to know where it comes from, or it refuses and nothing
/// happens on the screen. If it still fails the text is copied, so the button never does nothing.
/// @return true when the sheet opened; false when the text was copied instead
Future<bool> shareText(BuildContext context, String text) async {
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize && !box.size.isEmpty ? box.localToGlobal(Offset.zero) & box.size : const Rect.fromLTWH(1, 1, 200, 200);
  try {
    await Share.share(text, sharePositionOrigin: origin);
    return true;
  } catch (e) {
    debugPrint('share failed: $e');
    await Clipboard.setData(ClipboardData(text: text));
    return false;
  }
}
