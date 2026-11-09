import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'calls/admin_call_controller.dart' show appNavigatorKey;
import 'recurring_api.dart';
import '../pages/recurring/recurring_done_sheet.dart';

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

  static const week = [6, 0, 1, 2, 3, 4, 5]; // Saturday first; 0 = Sunday, as the server counts
  static const _workdays = {6, 0, 1, 2, 3, 4};
  static const _names = {6: 'السبت', 0: 'الأحد', 1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة'};

  static Set<int> get selected => switch (preset) {
        'workdays' => _workdays,
        'daily' => week.toSet(),
        'custom' => days,
        _ => const <int>{},
      };

  /// a tap on one day: from a preset it becomes his own list
  static void toggleDay(int day) {
    final next = {...selected};
    next.contains(day) ? next.remove(day) : next.add(day);
    days = next;
    preset = 'custom';
  }

  static bool get readyToSend => preset == null || selected.isNotEmpty;

  /// «كل يوم من السبت إلى الخميس»
  static String get daysLine {
    if (preset == 'daily') return 'كل يوم';
    if (preset == 'workdays') return 'كل يوم من السبت إلى الخميس';
    return 'كل ${week.where(days.contains).map((d) => _names[d]).join('، ')}';
  }

  static String clock(DateTime when) {
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    return '$h:${_two(when.minute)} ${when.hour < 12 ? 'ص' : 'م'}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// [payload] is the booking body, [ride] the server's answer.
  static Future<void> commit(String payload, dynamic ride) async {
    final choice = preset;
    final when = at;
    if (choice == null || when == null || ride is! Map) return;
    final line = daysLine;
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
      if (result.ok) {
        unawaited(showRecurringDoneSheet(context, days: line, time: clock(when), first: when));
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('${result.body['message'] ?? 'حُجز مشوارك، لكن ما قدرناش نكرره. جرب من «رحلاتي المتكررة».'}')));
      }
    }
    RecurringApi.refresh();
  }
}
