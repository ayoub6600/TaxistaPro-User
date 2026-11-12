import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../../functions/functions.dart' show bearerToken;
import '../../functions/intercity_api.dart';
import '../../functions/schedule_time.dart';
import 'intercity_wait_page.dart';

/// Back to one travel request from anywhere: a push («ما جاتكش عروض», «الكابتن ما وصلش»,
/// «سفرتك بكرة») or its card in «الرحلات القادمة». Opens the same waiting page the rider saw
/// after booking: the offers, «زيد سعرك», the booked driver, cancel.
class IntercityLink {
  static const pushTypes = {'intercity_no_offers', 'intercity_reopened', 'intercity_eve', 'intercity_booking'};
  static String? _pending;

  static bool handles(Map data) => pushTypes.contains('${data['push_type'] ?? ''}') && '${data['request_id'] ?? ''}'.isNotEmpty;

  static void openPush(Map data) {
    _pending = '${data['request_id']}';
    flush();
  }

  /// once the home screen is up and the person is signed in
  static Future<void> flush() async {
    final id = _pending;
    final nav = appNavigatorKey.currentState;
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
    );
  }

  static bool isIntercity(Map ride) => ride['intercity'] is Map || ride['is_out_station'] == 1 || ride['is_out_station'] == true;
}
