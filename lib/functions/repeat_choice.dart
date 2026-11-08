import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'calls/admin_call_controller.dart' show appNavigatorKey;
import 'recurring_api.dart';

/// «تكرر المشوار؟»: chosen on the scheduling sheet, sent right after the ride is booked, so the
/// ride he just scheduled becomes the first day of the pattern.
class RepeatChoice {
  /// null = once; workdays | daily | custom
  static String? preset;
  static Set<int> days = {};
  static DateTime? at;

  /// shown only when the server says this rider may repeat (the admin panel's setting)
  static final ValueNotifier<bool> available = ValueNotifier(false);

  static Future<void> refreshAvailability() async {
    final r = await RecurringApi.list();
    available.value = r.body['can_create'] == true;
  }

  static void clear() {
    preset = null;
    days = {};
    at = null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// [payload] is the booking body, [ride] the server's answer.
  static Future<void> commit(String payload, dynamic ride) async {
    final choice = preset;
    final when = at;
    if (choice == null || when == null || ride is! Map) return;
    clear();
    final p = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    final result = await RecurringApi.create({
      'pick': {'lat': p['pick_lat'], 'lng': p['pick_lng'], 'address': p['pick_address']},
      'drop': {'lat': p['drop_lat'], 'lng': p['drop_lng'], 'address': p['drop_address']},
      'pickup_time': '${_two(when.hour)}:${_two(when.minute)}',
      if (choice == 'custom') 'days': days.toList() else 'preset': choice,
      'starts_on': '${when.year}-${_two(when.month)}-${_two(when.day)}',
      'zone_type_id': p['vehicle_type'],
      'payment_opt': p['payment_opt'],
      'first_request_id': ride['id'],
    });
    final context = appNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(result.ok ? 'تم تكرار مشوارك. تقدر تديره من «رحلاتي المتكررة».' : '${result.body['message'] ?? 'رحلتك انحجزت، لكن التكرار ما تمش.'}'),
      ));
    }
    RecurringApi.refresh();
  }
}
