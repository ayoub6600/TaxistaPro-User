import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'card_vault.dart';
import 'moamalat_api.dart';
import 'secure_clipboard.dart';

/// Everything the Moamalat screens need from the host app, so the screens
/// themselves stay identical in the Rider and Driver apps.
class MoamalatEnv {
  MoamalatEnv({
    required this.api,
    required this.vault,
    required this.clipboard,
    required this.isRtl,
    this.onWalletChanged,
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

  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;

  String t(String ar, String en) => isRtl ? ar : en;

  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  TextStyle style({double size = 14, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color ?? text);
}

/// Arabic-Indic and Persian digits -> Latin, so an Arabic keyboard works.
String normalizeDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    out.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
  }
  return out.toString();
}
