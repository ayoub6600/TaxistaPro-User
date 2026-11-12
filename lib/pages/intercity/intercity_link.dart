import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../../functions/functions.dart' show bearerToken;
import '../../functions/intercity_api.dart';
import '../../functions/schedule_time.dart';
import 'intercity_again.dart';
import 'intercity_wait_page.dart';

/// Back to one travel request from anywhere: a push («ما جاتكش عروض», «الكابتن ما وصلش»,
/// «سفرتك بكرة») or its card in «الرحلات القادمة». Opens the same waiting page the rider saw
/// after booking: the offers, «زيد سعرك», the booked driver, cancel.
class IntercityLink {
  static const pushTypes = {'intercity_no_offers', 'intercity_reopened', 'intercity_eve', 'intercity_booking'};
  static String? _pending;
  static bool _rate = false;

  static bool handles(Map data) =>
      '${data['push_type'] ?? ''}' == 'intercity_rate' || (pushTypes.contains('${data['push_type'] ?? ''}') && '${data['request_id'] ?? ''}'.isNotEmpty);

  static void openPush(Map data) {
    if ('${data['push_type'] ?? ''}' == 'intercity_rate') {
      _rate = true; // «وصلت بالسلامة 🌟» → «كيف كانت السفرة؟»
    } else {
      _pending = '${data['request_id']}';
    }
    flush();
  }

  static void _retry() {
    IntercityApi.notifier.removeListener(_retry);
    flush();
  }

  /// once the home screen is up and the person is signed in
  static Future<void> flush() async {
    final nav = appNavigatorKey.currentState;
    if (_rate && nav != null && bearerToken.isEmpty == false) {
      final place = IntercityApi.lastPlace;
      if (place == null) {
        // opened from a cold start: wait for the home screen's first travel read
        IntercityApi.notifier.removeListener(_retry);
        IntercityApi.notifier.addListener(_retry);
      } else {
        _rate = false;
        final home = await IntercityApi.home(place.$1, place.$2);
        final ctx = appNavigatorKey.currentContext;
        if (home?.toRate != null && ctx != null && ctx.mounted) await IntercityRateSheet.maybeShow(ctx, home!.toRate);
      }
    }
    final id = _pending;
    if (id == null || nav == null || bearerToken.isEmpty) return;
    _pending = null;
    final ride = await IntercityApi.ride(id);
    if (ride == null || ride['is_cancelled'] == true || ride['is_cancelled'] == 1 || ride['is_completed'] == true || ride['is_completed'] == 1) return;
    nav.push(MaterialPageRoute(builder: (_) => pageFor(ride)));
  }

  /// a travel request as the server sends it (TripRequestTransformer) → its waiting page
  static IntercityWaitPage pageFor(Map ride) {
    final ic = ride['intercity'] is Map ? ride['intercity'] as Map : const {};
    num n(Object? v, num d) => v is num ? v : (num.tryParse('${v ?? ''}') ?? d);
    final fare = n(ride['rider_proposed_fare'], n(ride['offerred_ride_fare'], 0));
    final max = n(ic['max_offer'], fare * 1.5);
    final start = parseTripStart(ride);
    final passengers = n(ic['passengers'], 1).toInt();
    final when = start == null ? '' : IntercityApi.dayLabel(IntercityApi.wallClock(start));
    return IntercityWaitPage(
      rideId: '${ride['id']}',
      from: '${ic['from'] ?? ''}',
      to: '${ic['to'] ?? ''}',
      fare: fare,
      max: max,
      step: max - fare >= 100 ? 10 : 5,
      summary: [if (when.isNotEmpty) when, '$passengers ${passengers == 1 ? 'راكب' : 'ركاب'}'].join(' · '),
      pickAddress: '${ride['pick_address'] ?? ''}',
      dropAddress: '${ride['drop_address'] ?? ''}',
      note: '${ic['note'] ?? ''}',
      payOnline: ic['pay_online'] == true,
      payment: IntercityApi.last?.payment,
    );
  }

  static bool isIntercity(Map ride) => ride['intercity'] is Map || ride['is_out_station'] == 1 || ride['is_out_station'] == true;
}
