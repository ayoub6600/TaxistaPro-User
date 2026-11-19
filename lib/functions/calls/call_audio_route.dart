import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// One place the call's sound can go: the earpiece, the speaker, the car, AirPods…
class CallRoute {
  const CallRoute(this.id, this.name, this.kind, this.selected);

  final String id;
  final String name;

  /// receiver | speaker | car | bluetooth | headset
  final String kind;
  final bool selected;

  bool get external => kind == 'car' || kind == 'bluetooth' || kind == 'headset';
}

/// Where the call's sound goes (owner 2026-11-19: «مكبر الصوت» and the car's Bluetooth). On iPhone
/// the native channel lists what iOS offers right now and picks one without touching the call's
/// audio setup (WebRTC's own speaker switch re-set it and lost the car); Android asks WebRTC.
class CallAudioRoute {
  static const _ch = MethodChannel('taxista/call_audio');

  static Future<List<CallRoute>> routes() async {
    try {
      if (Platform.isIOS) {
        final list = await _ch.invokeListMethod<Map>('routes') ?? const [];
        return [for (final r in list) CallRoute('${r['id']}', '${r['name']}', '${r['kind']}', r['selected'] == true)];
      }
      final outs = await Helper.audiooutputs;
      return [
        for (final d in outs)
          CallRoute(d.deviceId, _androidName(d.label, d.deviceId), _androidKind(d.deviceId, d.label), false),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> select(CallRoute r) async {
    try {
      if (Platform.isIOS) {
        await _ch.invokeMethod('select', {'id': r.id});
      } else if (r.kind == 'speaker') {
        await Helper.setSpeakerphoneOn(true);
      } else {
        await Helper.setSpeakerphoneOn(false);
        await Helper.selectAudioOutput(r.id);
      }
    } catch (_) {}
  }

  /// the plain speaker switch, for a phone with nothing else connected
  static Future<void> speaker(bool on) async {
    if (Platform.isIOS) {
      await select(CallRoute(on ? 'speaker' : 'receiver', '', on ? 'speaker' : 'receiver', false));
    } else {
      try {
        await Helper.setSpeakerphoneOn(on);
      } catch (_) {}
    }
  }

  static String _androidKind(String id, String label) {
    final s = '$id $label'.toLowerCase();
    if (s.contains('speaker')) return 'speaker';
    if (s.contains('bluetooth')) return 'bluetooth';
    if (s.contains('headset') || s.contains('wired')) return 'headset';
    return 'receiver';
  }

  static String _androidName(String label, String id) {
    switch (_androidKind(id, label)) {
      case 'speaker':
        return 'مكبر الصوت';
      case 'receiver':
        return 'سماعة التليفون';
      default:
        return label.isEmpty ? 'بلوتوث' : label;
    }
  }
}
