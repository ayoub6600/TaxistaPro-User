import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../lypay/lypay_api.dart';
import 'card_vault.dart';
import 'moamalat_api.dart';
import 'secure_clipboard.dart';
import 'smart_fill_controller.dart';

// Kept here too, where the payment screens have always found it.
export 'card_brand.dart' show normalizeDigits;

/// Everything the Moamalat screens need from the host app, so the screens
/// themselves stay identical in the Rider and Driver apps.
class MoamalatEnv {
  MoamalatEnv({
    required this.api,
    required this.vault,
    required this.clipboard,
    required this.isRtl,
    this.onWalletChanged,
    this.smartFill,
    this.lypay,
    this.accent = const Color(0xff1677FF),
    this.background = const Color(0xffF6F8FC),
    this.surface = Colors.white,
    this.text = const Color(0xff102A56),
    this.muted = const Color(0xff6B7A90),
    this.border = const Color(0xffE1E7F0),
  });

  final MoamalatApi api;
  final CardVault vault;
  final SecureClipboard clipboard;
  final bool isRtl;

  /// Called after a top-up is confirmed, so the wallet balance and history
  /// reload from the server.
  final VoidCallback? onWalletChanged;

  /// Smart Fill (card fill + terms in one tap) when this platform supports it; null keeps the classic helper.
  final SmartFillSupport? smartFill;

  /// «تحويل LYPay»: transfer from the customer's bank app, screenshot, the admin credits.
  final LypayApi? lypay;

  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;

  String t(String ar, String en) => isRtl ? ar : en;

  /// Text/icons drawn ON the accent colour (the Driver app's accent is black in
  /// its light look and white in its dark one).
  Color get onAccent => accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  TextStyle style({double size = 14, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color ?? text);
}
