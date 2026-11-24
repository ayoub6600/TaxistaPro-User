import 'package:flutter/material.dart';

import '../../../functions/freight_api.dart';
import '../../../functions/parcel_api.dart';
import '../../../functions/tow_api.dart';

/// One service on the home sheet: a small circle with its name under it, and its own line under
/// «خدمات أخرى» when it has a real page to open.
class HomeService {
  const HomeService({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.soon = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// «قريبًا»: shown and tappable (it says so), no page yet in the rider's city
  final bool soon;
}

/// The home services, in the owner's order: بدون وجهة · سفر · نقل بضائع · طرود · ونش. A null
/// callback = closed in the rider's city right now: «سفر» is not shown there and the others say
/// «قريبًا» (as the home bar did before). «خدمات أخرى» never repeats them.
class HomeServices {
  HomeServices._();

  static const blue = Color(0xFF0873FF);
  static const teal = Color(0xFF0D9488);
  static const orange = Color(0xFFEA580C);
  static const green = Color(0xFF16A34A);
  static const gold = Color(0xFFCA8A04);
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF7C3AED);
  static const pink = Color(0xFFDB2777);
  static const sky = Color(0xFF0284C7);
  static const amber = Color(0xFFD97706);
  static const slate = Color(0xFF475569);

  /// the admin's own name for the service when he set one
  static String _adminName(Map? raw, bool rtl, String ar, String en) {
    final v = '${raw?[rtl ? 'home_name' : 'home_name_en'] ?? ''}'.trim();
    return v.isNotEmpty ? v : (rtl ? ar : en);
  }

  static List<HomeService> build({
    required bool rtl,
    required VoidCallback onRideWithoutDestination,
    required void Function(String service) onSoon,
    VoidCallback? onTravel,
    VoidCallback? onFreight,
    VoidCallback? onDelivery,
    VoidCallback? onTow,
    FreightHome? freight,
    ParcelHome? parcels,
    TowHome? tow,
  }) {
    final freightName = _adminName(freight?.raw, rtl, 'نقل بضائع', 'Moving');
    final parcelsName = _adminName(parcels?.raw, rtl, 'طرود', 'Parcels');
    final towName = _adminName(tow?.raw, rtl, 'ونش', 'Tow');
    return [
      HomeService(
        id: 'open_ride',
        label: rtl ? 'بدون وجهة' : 'No destination',
        icon: Icons.near_me_rounded,
        color: blue,
        onTap: onRideWithoutDestination,
      ),
      if (onTravel != null)
        HomeService(id: 'travel', label: rtl ? 'سفر' : 'Travel', icon: Icons.directions_car_rounded, color: teal, onTap: onTravel),
      HomeService(
        id: 'freight',
        label: freightName,
        icon: Icons.local_shipping_rounded,
        color: orange,
        soon: onFreight == null,
        onTap: onFreight ?? () => onSoon(freightName),
      ),
      HomeService(
        id: 'parcels',
        label: parcelsName,
        icon: Icons.inventory_2_rounded,
        color: green,
        soon: onDelivery == null,
        onTap: onDelivery ?? () => onSoon(parcelsName),
      ),
      HomeService(
        id: 'tow',
        label: towName,
        icon: Icons.car_crash_rounded,
        color: gold,
        soon: onTow == null,
        onTap: onTow ?? () => onSoon(towName),
      ),
    ];
  }
}
