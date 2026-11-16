import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supply_api.dart';

const _navy = Color(0xff0D1B3E);
const _muted = Color(0xff66748F);

/// What the server says about captains around the home map's pin (null = off or unknown).
final ValueNotifier<Map<String, dynamic>?> homeCaptainsInfo = ValueNotifier(null);

/// The real cars drawn near the pin right now (the map keeps it up to date).
final ValueNotifier<int> homeNearCars = ValueNotifier(-1);

/// How far each car is drawn from its real spot (0 while the city has the map off).
int get homeCarPrivacyMeters => (homeCaptainsInfo.value?['privacy_m'] as num?)?.toInt() ?? 0;

/// Most cars the map shows (null = no limit, the old behaviour).
int? get homeCarMaxIcons => (homeCaptainsInfo.value?['max_icons'] as num?)?.toInt();

/// Radius around the pin that counts as «near», in metres.
double get homeNearRadiusMeters => ((homeCaptainsInfo.value?['radius_km'] as num?)?.toDouble() ?? 5) * 1000;

/// Loads the city's numbers for the pin; asks again only when the pin moved more than a km.
class HomeCaptainsLoader {
  static double? _lat;
  static double? _lng;
  static DateTime _at = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> around(double lat, double lng, {Future<Map<String, dynamic>?> Function(double, double)? api}) async {
    final moved = _lat == null || _km(lat, lng, _lat!, _lng!) > 1;
    if (!moved && DateTime.now().difference(_at) < const Duration(minutes: 2)) return;
    _lat = lat;
    _lng = lng;
    _at = DateTime.now();
    final d = await (api ?? SupplyApi.mapAround)(lat, lng);
    if (d == null || d.containsKey('_error')) return;
    homeCaptainsInfo.value = d['enabled'] == true ? d : null;
  }

  static double _km(double a, double b, double c, double d) {
    final dLat = (a - c) * 111.0;
    final dLng = (b - d) * 111.0 * math.cos(a * math.pi / 180);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }
}

/// «12 كابتن متصل في مصراتة توا» on top of the map, or the city's total when nobody is online
/// near; nothing below the minimums the owner set, and nothing while the city has it off.
class HomeCaptainsChip extends StatelessWidget {
  const HomeCaptainsChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: homeCaptainsInfo,
      builder: (context, info, _) => ValueListenableBuilder<int>(
        valueListenable: homeNearCars,
        builder: (context, near, _) {
          if (info == null) return const SizedBox.shrink();
          final text = near > 0 ? info['online_text'] : (info['total_text'] ?? info['online_text']);
          if (text == null) return const SizedBox.shrink();
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [BoxShadow(color: Color(0x2215386B), blurRadius: 10, offset: Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (near > 0)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xff16A34A), shape: BoxShape.circle)),
                if (near > 0) const SizedBox(width: 6),
                Text(text.toString(), style: GoogleFonts.cairo(color: _navy, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// The honest line in the home sheet when no real car is near the pin.
class HomeNoCaptainsLine extends StatelessWidget {
  const HomeNoCaptainsLine({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: homeCaptainsInfo,
      builder: (context, info, _) => ValueListenableBuilder<int>(
        valueListenable: homeNearCars,
        builder: (context, near, _) {
          if (info == null || near != 0) return const SizedBox.shrink();
          final line = info['empty_line'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xffF3F6FB), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text((info['empty_title'] ?? 'ما فيش كابتن متصل قريب منك توا').toString(),
                  textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _navy, fontSize: 13.5, fontWeight: FontWeight.w800)),
              if (line != null)
                Text(line.toString(), textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        },
      ),
    );
  }
}

/// Keeps the home map honest and light: at most the city's number of cars (the nearest to the
/// pin), and tells the chip and the sheet how many real cars are near the pin right now.
class HomeMapCars {
  static void settle(List<dynamic> markers, dynamic center) {
    final info = homeCaptainsInfo.value;
    final lat = (center.latitude as num).toDouble();
    final lng = (center.longitude as num).toDouble();
    double dist(dynamic m) => HomeCaptainsLoader._km(lat, lng, (m.position.latitude as num).toDouble(), (m.position.longitude as num).toDouble()) * 1000;
    final cars = markers.where((m) => m.markerId.value.toString().startsWith('car#')).toList();
    final max = homeCarMaxIcons;
    if (info != null && max != null && cars.length > max) {
      cars.sort((a, b) => dist(a).compareTo(dist(b)));
      final drop = cars.sublist(max).toSet();
      markers.removeWhere(drop.contains);
    }
    final near = info == null ? -1 : markers.where((m) => m.markerId.value.toString().startsWith('car#') && dist(m) <= homeNearRadiusMeters).length;
    if (near != homeNearCars.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => homeNearCars.value = near);
    }
  }
}
