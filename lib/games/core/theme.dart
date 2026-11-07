import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours and type for the waiting games. Taxista blue + navy night. Never orange.
class GamesTheme {
  GamesTheme._();

  /// Tests switch this off so no font is fetched over the network.
  static bool useGoogleFonts = true;

  static const brand = Color(0xFF0873FF);
  static const brandLight = Color(0xFF3D9BFF);
  static const brandSoft = Color(0xFFEAF4FF);
  static const navy = Color(0xFF102A56);
  static const navy2 = Color(0xFF1965BF);
  static const night = Color(0xFF071430);
  static const nightDeep = Color(0xFF040B1E);
  static const nightRoad = Color(0xFF13234A);
  static const gold = Color(0xFFF6D365);
  static const danger = Color(0xFFFF5A6E);
  static const success = Color(0xFF2EE59D);
  static const ink = Color(0xFFDCE8FF);
  static const muted = Color(0xFF9FB4D8);
  static const tail = Color(0xFFFF4D6D);
  static const warmWindow = Color(0xFFFFECAA);
  static const coolWindow = Color(0xFFA0CDFF);

  static TextStyle text(double size,
      {FontWeight weight = FontWeight.w800, Color color = Colors.white, double? height}) {
    final base = TextStyle(fontSize: size, fontWeight: weight, color: color, height: height);
    if (!useGoogleFonts) return base;
    try {
      return GoogleFonts.cairo(textStyle: base);
    } catch (_) {
      return base;
    }
  }
}

/// Car colours unlocked with stars only (no money, no ride counts).
class CarSkin {
  const CarSkin(this.id, this.name, this.color, this.needStars);
  final String id;
  final String name;
  final Color color;
  final int needStars;

  static const all = <CarSkin>[
    CarSkin('blue', 'أزرق تاكسيستا', GamesTheme.brand, 0),
    CarSkin('pearl', 'أبيض لؤلؤي', Color(0xFFEEF3FA), 8),
    CarSkin('navy', 'كحلي الليل', Color(0xFF1B3F7A), 18),
    CarSkin('silver', 'فضي', Color(0xFFA9B6C8), 30),
    CarSkin('sky', 'سماوي', Color(0xFF7FD3FF), 45),
  ];

  static CarSkin byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
