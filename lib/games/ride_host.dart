import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../functions/functions.dart';
import '../functions/live_activity.dart';
import 'waiting_games.dart';

/// The bridge between the booking screens and the games: one status the games listen to (built from the
/// app's own ride data, never the other way round), one controller so a round survives the sheet swap
/// from searching to driver-on-the-way, and the config (admin settings; TestFlight builds see them all).
class RideGamesHost {
  RideGamesHost._();

  static final WaitingGamesController controller = WaitingGamesController();
  static VoidCallback? _backToTrip;
  static final ValueNotifier<RideGameStatus> status =
      ValueNotifier(RideGameStatus(phase: 'searching', onBackToTrip: () => _backToTrip?.call()));
  static DateTime? _fetchedAt;

  /// the box in the searching sheet is open (kept here: that sheet is rebuilt every second)
  static bool boxOpen = false;
  static String? _lastPhase;

  /// on each search (at most every 5 minutes): the admin's games from the server
  /// (request/waiting-games, for the pickup's market), else the copy in the user details.
  /// TestFlight builds always show the games (the admin's per-game switches still apply).
  static Future<void> configure({bool force = false}) async {
    if (!force && _fetchedAt != null && DateTime.now().difference(_fetchedAt!) < const Duration(minutes: 5)) return;
    _fetchedAt = DateTime.now();
    Map? server = userDetails['waiting_games'] is Map ? userDetails['waiting_games'] as Map : null;
    try {
      final lat = userRequestData['pick_lat'], lng = userRequestData['pick_lng'];
      final q = lat != null && lng != null ? '?lat=$lat&lng=$lng' : '';
      final r = await http.get(Uri.parse('${url}api/v1/request/waiting-games$q'), headers: {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body)['data'];
        if (d is Map) server = d;
      }
    } catch (_) {}
    final tryout = await LiveActivity.isTryoutBuild();
    WaitingGamesConfig.loadFrom(server, tryoutBuild: tryout);
    if (tryout) WaitingGamesConfig.enabled = true;
  }

  /// fetched at least once since the app started (a ride resumed after a restart fetches it too)
  static bool get configured => _fetchedAt != null;

  /// the admin's rules: «وقت البحث» and «والسائق جاي»
  static bool get enabledWhileSearching => enabled && WaitingGamesConfig.whileSearching;
  static bool get enabledWhileDriverComing => enabled && WaitingGamesConfig.whileDriverComing;

  static bool get enabled => WaitingGamesConfig.enabled && WaitingGamesConfig.visibleGames().isNotEmpty;

  /// from the ride data: searching → accepted (→ approaching when close) → arrived → on_trip
  static void sync(BuildContext context, {double? distanceKm, VoidCallback? onCall, VoidCallback? onChat, VoidCallback? onBackToTrip}) {
    _backToTrip = onBackToTrip ?? _backToTrip;
    final d = userRequestData;
    String phase;
    if (d.isEmpty || d['is_cancelled'] == 1) {
      phase = 'cancelled';
    } else if (d['is_trip_start'] == 1) {
      phase = 'on_trip';
    } else if (d['arrived_at'] != null) {
      phase = 'arrived';
    } else if (d['accepted_at'] != null) {
      phase = (distanceKm != null && distanceKm <= .5) ? 'approaching' : 'accepted';
    } else {
      phase = 'searching';
    }
    final driver = d['driverDetail'] is Map ? d['driverDetail']['data'] : null;
    bool real(dynamic v) => v != null && '$v'.trim().isNotEmpty && '$v' != 'null';
    final car = driver is Map ? [driver['car_make_name'], driver['car_model_name'], driver['car_color']].where(real).join(' · ') : null;
    final eta = distanceKm == null ? null : '${(distanceKm * 2).round().clamp(1, 99)} د';
    final next = RideGameStatus(
      phase: phase,
      driverName: driver is Map ? '${driver['name'] ?? ''}' : null,
      etaText: eta,
      carText: car,
      onCall: onCall,
      onChat: onChat,
      onBackToTrip: () => _backToTrip?.call(),
    );
    final prev = _lastPhase;
    _lastPhase = phase;
    final cur = status.value;
    if (cur.phase != next.phase || cur.driverName != next.driverName || cur.etaText != next.etaText || cur.carText != next.carText) {
      // after the frame: this runs from build()
      WidgetsBinding.instance.addPostFrameCallback((_) => status.value = next);
    }
    // the toasts only while a round is going (the trip screens say the rest themselves)
    if (controller.playing && prev != null && prev != phase && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (phase == 'accepted' && prev == 'searching') WaitingGameToasts.showDriverFound(context, next.driverName);
        if (phase == 'approaching') WaitingGameToasts.showApproaching(context, eta);
      });
    }
  }
}

/// «العب وأنت تستنى»: the pill that opens the game box
class PlayWhileWaitingButton extends StatelessWidget {
  const PlayWhileWaitingButton({super.key, required this.onTap, this.label = 'العب وأنت تستنى'});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xff102A56),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xff102A56), Color(0xff1965BF)]),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(99)),
                child: Text('${WaitingGamesConfig.visibleGames().length} لعبة',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
}
