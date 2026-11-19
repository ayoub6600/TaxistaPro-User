import 'package:flutter/material.dart';

import '../../functions/calls/call_audio_route.dart';

/// «وين الصوت؟»: the earpiece, the speaker, the car, AirPods… as the phone offers them now
/// (owner 2026-11-19). With nothing connected the sound button just switches the speaker.
class CallSoundSheet {
  static IconData icon(String kind) => switch (kind) {
        'speaker' => Icons.volume_up_rounded,
        'car' => Icons.directions_car_rounded,
        'bluetooth' => Icons.bluetooth_audio_rounded,
        'headset' => Icons.headphones_rounded,
        _ => Icons.phone_in_talk_rounded,
      };

  /// the sound button: a sheet when there is more than earpiece and speaker, else a speaker toggle
  static Future<void> open(BuildContext context, {required Future<void> Function() toggleSpeaker, required Future<void> Function(CallRoute) choose}) async {
    final routes = await CallAudioRoute.routes();
    if (!routes.any((r) => r.external)) {
      await toggleSpeaker();
      return;
    }
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<CallRoute>(
      context: context,
      backgroundColor: const Color(0xFF0D1A3D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(alignment: AlignmentDirectional.centerStart, child: Text('وين الصوت؟', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
            ),
            for (final r in routes)
              ListTile(
                leading: Icon(icon(r.kind), color: r.selected ? const Color(0xFF60A5FA) : Colors.white70),
                title: Text(r.name, style: TextStyle(color: Colors.white, fontWeight: r.selected ? FontWeight.w800 : FontWeight.w600)),
                trailing: r.selected ? const Icon(Icons.check_rounded, color: Color(0xFF60A5FA)) : null,
                onTap: () => Navigator.of(ctx).pop(r),
              ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
    if (picked != null) await choose(picked);
  }
}
