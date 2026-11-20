// ignore_for_file: experimental_member_use -- LiveKit 2.13.2 is pinned; its CallKit mode is the one we need

import 'dart:io';

import 'package:livekit_client/livekit_client.dart';

import 'admin_call_api.dart';

/// A call whose sound goes through Taxista's LiveKit server (owner 2026-11-19): better on weak
/// internet, and recorded for 15 days. The ring, the answer and the end stay on our server; this
/// only joins the call's room with the microphone. CallKit (iPhone) keeps owning the audio session,
/// so the car / AirPods / speaker routing stays as the call screen sets it.
class LiveKitCall {
  Room? _room;
  EventsListener<RoomEvent>? _events;
  bool recorded = false;
  String? notice;

  bool get joined => _room != null;

  Future<void> join(
    String callId, {
    required void Function() onRemote,
    required void Function() onReconnecting,
    required void Function() onReconnected,
    required void Function() onLost,
  }) async {
    final r = await AdminCallApi.livekit(callId);
    if (!r.ok) throw Exception(r.message);
    await AudioManager.instance.setAudioSessionManagementMode(
        Platform.isIOS ? AudioSessionManagementMode.externalCallSystem : AudioSessionManagementMode.automatic);
    await AudioManager.instance.setSpeakerOutputPreferred(false);
    final room = _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: false,
        dynacast: false,
        defaultAudioCaptureOptions: AudioCaptureOptions(echoCancellation: true, noiseSuppression: true, autoGainControl: true),
      ),
    );
    final events = _events = room.createListener();
    events
      ..on<TrackSubscribedEvent>((e) {
        if (e.track is RemoteAudioTrack) onRemote();
      })
      ..on<RoomReconnectingEvent>((_) => onReconnecting())
      ..on<RoomReconnectedEvent>((_) => onReconnected())
      ..on<RoomDisconnectedEvent>((_) => onLost());
    await room.connect('${r.data['url']}', '${r.data['token']}');
    await room.localParticipant?.setMicrophoneEnabled(true);
    recorded = r.data['recorded'] == true;
    notice = r.data['notice']?.toString();
    // the other side may already be in the room (the caller joins first)
    if (room.remoteParticipants.values.any((p) => p.audioTrackPublications.any((t) => t.subscribed))) onRemote();
  }

  Future<void> setMuted(bool muted) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!muted);
    } catch (_) {}
  }

  Future<void> leave() async {
    final room = _room;
    _room = null;
    try {
      await _events?.dispose();
      await room?.disconnect();
      await room?.dispose();
    } catch (_) {}
    _events = null;
    recorded = false;
    notice = null;
  }
}
