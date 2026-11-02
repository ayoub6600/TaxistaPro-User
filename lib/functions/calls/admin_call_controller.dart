import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

import '../../pages/callPage/admin_call_page.dart';
import '../functions.dart' show languageDirection;
import 'admin_call_api.dart';

/// Where the app's screens live, so a call can open its screen from a notification or CallKit.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// A voice call, one at a time: with the driver of the current ride or with the administration
/// (Taxista Admin).
///
///  - Someone calls this rider: the phone rings with the system call screen (CallKit on iPhone,
///    even locked and with the app closed; a full-screen incoming call on Android). With the app
///    open, Taxista's own incoming screen shows as well. Answering opens the call screen.
///  - The rider calls the driver of the ride (trip screen, trip chat) or the administration (admin
///    chat) - the administration only when an admin switched "riders may call me" on.
///
/// Audio is WebRTC, peer to peer or through Taxista's TURN server. The server never hears it, and
/// a rider and a driver never see each other's phone number.
class AdminCallController extends ChangeNotifier {
  AdminCallController._();
  static final AdminCallController instance = AdminCallController._();

  String? callId;

  /// idle | incoming | starting | ringing | connecting | accepted | reconnecting | ended
  String status = 'idle';
  String statusLabel = '';
  String role = 'caller';
  DateTime? answeredAt;
  bool muted = false;
  bool speaker = false;

  /// The other side: name, role (label), type (admin | driver | rider), photo, car, plate.
  Map<String, dynamic> peer = const {'name': 'إدارة تاكسيستا', 'role': 'الدعم والتشغيل', 'type': 'admin'};

  /// Where "back to chat" goes: {type: admin} or {type: trip, request_id}.
  Map<String, dynamic>? chat;

  RTCPeerConnection? _pc;
  MediaStream? _local;
  Timer? _poll;
  Timer? _reconnect;
  bool _listening = false;

  bool get busy => status != 'idle' && status != 'ended';
  bool get live => status == 'accepted' || status == 'reconnecting' || status == 'connecting';
  String get peerName => (peer['name'] ?? 'إدارة تاكسيستا').toString();

  /// A call notification tapped before the rider's session was ready: answered by [init].
  static String? pendingAnswer;

  // ---------------------------------------------------------------- setup (once, at startup)

  Future<void> init() async {
    if (_listening) return;
    _listening = true;
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      switch (event) {
        case CallEventActionCallAccept(:final callKitParams):
          // CallKit also "accepts" the call this phone is already in (when it is marked connected)
          await answer(_idOf(callKitParams));
          break;
        case CallEventActionCallDecline(:final callKitParams):
          final id = _idOf(callKitParams);
          if (_isCurrent(callKitParams) && busy) {
            await (status == 'incoming' ? decline() : hangUp(fromSystem: true));
          } else {
            await AdminCallApi.decline(id);
          }
          break;
        case CallEventActionCallEnded(:final callKitParams):
          if (_isCurrent(callKitParams) && busy) await hangUp(fromSystem: true);
          break;
        case CallEventActionCallToggleMute(:final isMuted):
          setMuted(isMuted);
          break;
        case CallEventActionDidUpdateDevicePushTokenVoip():
          await _sendVoipToken();
          break;
        default:
          break;
      }
    });
    await _sendVoipToken();
    unawaited(_sendReady());
    // back from the settings (or anywhere): the server learns at once whether calls can ring locked
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(_sendReady()));
    if (Platform.isAndroid) unawaited(Future.delayed(const Duration(seconds: 4), checkLockScreenCalls));
    // a call answered from the lock screen before the app finished starting
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      for (final c in calls) {
        if (c.isAccepted) {
          pendingAnswer = _idOf(c);
          break;
        }
      }
    } catch (_) {}
    final pending = pendingAnswer;
    pendingAnswer = null;
    if (pending != null) await answer(pending);
  }

  /// The rider tapped the "someone is calling" notification.
  static Future<void> answerFromNotification(Map<String, dynamic> data) async {
    final id = _norm(data['call_id']);
    if (id.isEmpty) return;
    if (!instance._listening) {
      pendingAnswer = id;
      return;
    }
    await instance.answer(id);
  }

  /// The server's call id. CallKit hands UUIDs back in upper case; the server's are lower case.
  static String _idOf(CallKitParams p) => _norm(p.extra?['call_id'] ?? p.id);

  static String _norm(Object? id) => (id ?? '').toString().trim().toLowerCase();

  /// The id this app gives CallKit for a server call: the server id itself (the Driver app on the
  /// same phone uses a different one, see its callKitId).
  static String callKitId(String serverId) => _norm(serverId);

  /// A CallKit event about the call this controller holds. An event for a call the plugin no longer
  /// tracks carries only the CallKit id.
  bool _isCurrent(CallKitParams p) => isSameCall(p, callId);

  /// Whether CallKit's [p] is the server call [serverId]: by the server id it carries, or by this
  /// app's CallKit id for it (all an event about an untracked call has).
  static bool isSameCall(CallKitParams p, String? serverId) {
    if (serverId == null || serverId.isEmpty) return false;
    final server = _norm(p.extra?['call_id']);
    // without the server id it is this app's call only under this app's CallKit id (on a phone
    // with both apps, the other app's call has the same server id under another CallKit id)
    return server.isNotEmpty ? server == _norm(serverId) : _norm(p.id) == callKitId(serverId);
  }

  /// The CallKit ids of every call but [serverId]'s: left behind by a ring the caller cancelled or a
  /// call the system kept, they make CallKit refuse or end a new one (one call at a time).
  static List<String> staleCallKitIds(List<CallKitParams> active, String serverId) =>
      [for (final c in active) if (!isSameCall(c, serverId) && _norm(c.id).isNotEmpty) _norm(c.id)];

  Future<void> _sendVoipToken() async {
    if (!Platform.isIOS) return;
    // the PushKit token: lets the server ring this iPhone through CallKit even when locked
    try {
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (token != null && token.isNotEmpty) await AdminCallApi.voipToken(token);
    } catch (_) {}
  }

  /// This version can take calls: the server rings it (older versions are never rung).
  Future<void> _sendReady() async {
    try {
      final info = await PackageInfo.fromPlatform();
      await AdminCallApi.ready(Platform.isIOS ? 'ios' : 'android', '${info.version}+${info.buildNumber}', fullScreen: await _fullScreenAllowed());
    } catch (_) {}
  }

  AppLifecycleListener? _lifecycle;
  static bool _askedLockScreen = false;

  /// Android 14+: may a call show over the lock screen (null elsewhere, where it always may).
  static Future<bool?> _fullScreenAllowed() async {
    if (!Platform.isAndroid) return null;
    try {
      return await FlutterCallkitIncoming.canUseFullScreenIntent();
    } catch (_) {
      return null;
    }
  }

  /// Without "full-screen notifications" a call reaches a locked Android phone as a plain
  /// notification. Ask once per start, straight to the right setting; some makers (Xiaomi, Oppo,
  /// Vivo, Tecno...) also need "show on lock screen" in the app's own settings.
  Future<void> checkLockScreenCalls() async {
    if (!Platform.isAndroid || _askedLockScreen) return;
    final allowed = await _fullScreenAllowed();
    final context = appNavigatorKey.currentContext;
    if (allowed != false || context == null || !context.mounted) return;
    _askedLockScreen = true;
    String maker = '';
    try {
      maker = (await DeviceInfoPlugin().androidInfo).manufacturer.toLowerCase();
    } catch (_) {}
    final strict = RegExp('xiaomi|redmi|poco|oppo|realme|vivo|huawei|honor|tecno|infinix|itel|oneplus').hasMatch(maker);
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => LockScreenCallsSheet(strict: strict),
    );
    if (choice == 'allow') {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } else if (choice == 'settings') {
      await perm.openAppSettings();
    }
  }

  static String roleLabel(String? type) =>
      {'admin': 'إدارة تاكسيستا', 'driver': 'سائق', 'rider': 'راكب'}[type] ?? '';

  // ---------------------------------------------------------------- incoming (push)

  /// A push said someone is calling: ring with the system call screen; with the app open, show
  /// Taxista's incoming screen too. Repeated deliveries of the same call id change nothing.
  static Future<void> incomingPush(Map<String, dynamic> data, {bool appOpen = false}) async {
    final id = _norm(data['call_id']);
    if (id.isEmpty || instance.callId == id) return;
    // the system screen rings (and works locked); the iOS Simulator ends CallKit calls by itself
    // after a moment, so there the app's own screen rings alone
    if (!(appOpen && await _onSimulator())) {
      await showIncoming(data);
    } else {
      unawaited(AdminCallApi.alerted(data)); // the app's own screen rings
    }
    if (appOpen && !instance.busy) instance._incomingInApp(id, data);
  }

  void _incomingInApp(String id, Map<String, dynamic> data) {
    callId = id;
    role = 'callee';
    final type = (data['caller_role'] ?? 'admin').toString();
    peer = {
      'name': (data['caller_name'] ?? 'إدارة تاكسيستا').toString(),
      'type': type,
      'role': roleLabel(type),
      'photo': (data['caller_photo'] ?? '').toString().isEmpty ? null : data['caller_photo'].toString(),
    };
    chat = type == 'driver' ? {'type': 'trip', 'request_id': data['request_id']} : {'type': 'admin'};
    _set('incoming', 'مكالمة واردة');
    _openScreen();
    _pollState(const Duration(seconds: 2)); // the caller may hang up before an answer
  }

  /// Ring with the system call screen (works from the background isolate too).
  static Future<void> showIncoming(Map<String, dynamic> data) async {
    final id = _norm(data['call_id']);
    if (id.isEmpty || instance.callId == id) return;
    final until = int.tryParse((data['ring_until'] ?? '').toString());
    final ms = until != null ? (until * 1000 - DateTime.now().millisecondsSinceEpoch).clamp(5000, 45000) : 45000;
    final type = (data['caller_role'] ?? 'admin').toString();
    final name = (data['caller_name'] ?? 'إدارة تاكسيستا').toString();
    await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
      id: callKitId(id),
      nameCaller: name,
      appName: 'Taxista',
      handle: type == 'driver' ? 'سائق · تاكسيستا' : 'إدارة تاكسيستا',
      avatar: (data['caller_photo'] ?? '').toString().isEmpty ? null : data['caller_photo'].toString(),
      type: 0,
      duration: ms.toInt(),
      missedCallNotification: NotificationParams(
          showNotification: true, isShowCallback: false, subtitle: type == 'driver' ? 'مكالمة فائتة من السائق' : 'مكالمة فائتة من الإدارة'),
      extra: <String, dynamic>{'call_id': id},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0d1a3d',
        actionColor: '#22c55e',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'مكالمات تاكسيستا',
        missedCallNotificationChannelName: 'مكالمات فائتة',
        isShowFullLockedScreen: true,
        textAccept: 'رد',
        textDecline: 'رفض',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    ));
    // shown: now the caller may see "ringing" (awaited, so a background isolate stays alive for it)
    await AdminCallApi.alerted(data);
  }

  /// The call stopped ringing on the server (the caller hung up, someone else answered...).
  static Future<void> dismissIncoming(String id) async {
    id = _norm(id);
    if (instance.callId == id && instance.busy) {
      await instance._finish(instance.status == 'incoming' ? 'مكالمة فائتة' : 'انتهت المكالمة');
      return;
    }
    try {
      await FlutterCallkitIncoming.endCall(callKitId(id));
    } catch (_) {}
  }

  // ---------------------------------------------------------------- calling out

  /// The administration (admins who accept rider calls). null = ringing, else why not.
  Future<String?> callAdministration() async {
    if (busy) return 'لديك مكالمة جارية بالفعل.';
    final available = await AdminCallApi.availability();
    if (!available.ok) return available.message;
    if (available.data['can_call_admin'] != true) {
      return (available.data['message'] ?? 'لا يوجد مسؤول متاح لاستقبال المكالمات الآن. استخدم المحادثة.').toString();
    }
    return _call('admin', null);
  }

  /// The driver of the current ride (no phone numbers either way).
  Future<String?> callDriver({String? requestId}) async {
    if (busy) return 'لديك مكالمة جارية بالفعل.';
    return _call('driver', requestId);
  }

  Future<String?> _call(String to, String? requestId) async {
    peer = to == 'admin' ? const {'name': 'إدارة تاكسيستا', 'role': 'الدعم والتشغيل', 'type': 'admin'} : const {'name': 'السائق', 'role': 'سائق', 'type': 'driver'};
    final started = await AdminCallApi.start(to: to, requestId: requestId);
    if (!started.ok) return started.message;
    callId = _norm(started.data['id']);
    role = 'caller';
    _apply(started.data);
    _set('starting', 'جارٍ تجهيز الميكروفون…');
    _openScreen();
    try {
      if (!await _micAllowed()) throw Exception('NotAllowed');
      await _ensureSystemCall(callId!);
      final pc = await _media(started.ice);
      final offer = await pc.createOffer({'offerToReceiveAudio': true});
      await pc.setLocalDescription(offer);
      await _gathered(pc);
      final desc = await pc.getLocalDescription();
      final sent = await AdminCallApi.offer(callId!, desc!.sdp!);
      if (!sent.ok) throw Exception(sent.message);
      // "ringing" only once the other side confirmed it shows the call
      _set('ringing', sent.data['alerted'] == true ? 'يرن…' : 'جارٍ الاتصال…');
      _pollState(const Duration(seconds: 1));
    } catch (e) {
      await _fail(e);
    }
    return null;
  }

  // ---------------------------------------------------------------- answering

  Future<void> answer(String id) async {
    id = _norm(id);
    if (id.isEmpty || (callId == id && busy && status != 'incoming')) return;
    callId = id;
    role = 'callee';
    _set('connecting', 'جارٍ الرد…');
    _openScreen();
    try {
      if (!await _micAllowed()) throw Exception('NotAllowed');
      final state = await AdminCallApi.state(id, ice: true);
      if (state.ok) _apply(state.data);
      if (!state.ok || state.data['status'] != 'ringing' || state.data['remote_sdp'] == null) {
        await _finish(state.ok ? (state.data['status_label'] ?? 'انتهت المكالمة').toString() : state.message);
        return;
      }
      await _ensureSystemCall(id);
      if (Platform.isAndroid) {
        // answered on Taxista's screen: the system's ringing notification stops (without "ending" the call)
        try {
          await FlutterCallkitIncoming.hideCallkitIncoming(CallKitParams(id: callKitId(id)));
        } catch (_) {}
      }
      final pc = await _media(state.ice);
      await pc.setRemoteDescription(RTCSessionDescription(state.data['remote_sdp'], 'offer'));
      final ans = await pc.createAnswer({'offerToReceiveAudio': true});
      await pc.setLocalDescription(ans);
      await _gathered(pc);
      final desc = await pc.getLocalDescription();
      final sent = await AdminCallApi.answer(id, desc!.sdp!);
      if (!sent.ok) throw Exception(sent.message);
      answeredAt = DateTime.now();
      _set('accepted', 'متصل');
      _pollState(const Duration(seconds: 2));
    } catch (e) {
      await _fail(e);
    }
  }

  /// "رفض" on Taxista's incoming screen.
  Future<void> decline() async {
    final id = callId;
    if (id == null) return;
    await AdminCallApi.decline(id);
    await _finish('رفضت المكالمة');
  }

  // ---------------------------------------------------------------- during the call

  void setMuted(bool value) {
    muted = value;
    _local?.getAudioTracks().forEach((t) => t.enabled = !muted);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speaker = !speaker;
    try {
      await Helper.setSpeakerphoneOn(speaker);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> hangUp({bool fromSystem = false}) async {
    final id = callId;
    if (id != null) await AdminCallApi.end(id);
    await _finish('انتهت المكالمة', endSystemCall: !fromSystem);
  }

  // ---------------------------------------------------------------- internals

  /// The server's view of the call: who the other side is, where "back to chat" goes.
  void _apply(Map<String, dynamic> data) {
    if (data['peer'] is Map) peer = Map<String, dynamic>.from(data['peer']);
    if (data['chat'] is Map) chat = Map<String, dynamic>.from(data['chat']);
  }

  /// Every call is known to the system (CallKit on iPhone): it is what switches the iPhone's audio
  /// on for WebRTC, and gives the green bar, Bluetooth and the lock-screen controls. A call that is
  /// ringing on the system screen is answered there; one started here, or answered from a tapped
  /// notification, is reported now.
  Future<void> _ensureSystemCall(String id) async {
    // the iOS Simulator cannot give CallKit an audio session and drops such calls at once; there
    // WebRTC manages the audio itself (see AppDelegate)
    if (!Platform.isIOS) return;
    try {
      _physical ??= (await DeviceInfoPlugin().iosInfo).isPhysicalDevice;
      if (_physical == false) return;
      final calls = await FlutterCallkitIncoming.activeCalls();
      for (final stale in staleCallKitIds(calls, id)) {
        try {
          await FlutterCallkitIncoming.endCall(stale);
        } catch (_) {}
      }
      final known = calls.where((c) => isSameCall(c, id)).toList();
      if (known.isNotEmpty) {
        // ringing on the system screen but answered on Taxista's: answer it in CallKit too (this
        // plugin call is CallKit's "answer" - right for a ringing incoming call, never for our own)
        if (!known.first.isAccepted && role == 'callee') await FlutterCallkitIncoming.setCallConnected(callKitId(id));
        return;
      }
      await FlutterCallkitIncoming.startCall(CallKitParams(
        id: callKitId(id),
        nameCaller: peerName,
        handle: (peer['type'] ?? 'admin') == 'driver' ? 'سائق · تاكسيستا' : 'إدارة تاكسيستا',
        type: 0,
        extra: <String, dynamic>{'call_id': id},
        ios: const IOSParams(handleType: 'generic', supportsVideo: false, audioSessionMode: 'voiceChat', audioSessionActive: true),
      ));
    } catch (_) {}
  }

  static bool? _physical;

  static const _audio = MethodChannel('taxista/call_audio');

  /// On a device WebRTC's audio waits for CallKit's audio session; if CallKit never handed one over
  /// (its call was refused or ended by the system) the call would be connected but silent.
  Future<void> _ensureAudio() async {
    if (!Platform.isIOS) return;
    try {
      await _audio.invokeMethod('ensure');
    } catch (_) {}
  }

  static Future<bool> _onSimulator() async {
    if (!Platform.isIOS) return false;
    _physical ??= (await DeviceInfoPlugin().iosInfo).isPhysicalDevice;
    return _physical == false;
  }

  Future<bool> _micAllowed() async {
    final status = await perm.Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  Future<RTCPeerConnection> _media(List<Map<String, dynamic>> ice) async {
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': {'echoCancellation': true, 'noiseSuppression': true, 'autoGainControl': true},
      'video': false,
    });
    final pc = _pc = await createPeerConnection({'iceServers': ice, 'sdpSemantics': 'unified-plan', 'iceCandidatePoolSize': 2});
    for (final t in _local!.getTracks()) {
      await pc.addTrack(t, _local!);
    }
    pc.onConnectionState = (RTCPeerConnectionState s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _reconnect?.cancel();
        answeredAt ??= DateTime.now();
        _set('accepted', 'متصل');
        unawaited(_ensureAudio());
      } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected && status == 'accepted') {
        // the network dropped: WebRTC usually finds its way back by itself within seconds
        _set('reconnecting', 'إعادة الاتصال…');
        _reconnect?.cancel();
        _reconnect = Timer(const Duration(seconds: 20), () {
          if (status == 'reconnecting') hangUp();
        });
      } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        hangUp();
      }
    };
    try {
      await Helper.setSpeakerphoneOn(speaker);
    } catch (_) {}
    return pc;
  }

  /// Every ICE candidate inside the description (no trickle): wait for gathering, at most 4 s.
  Future<void> _gathered(RTCPeerConnection pc) async {
    final done = Completer<void>();
    if (pc.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) return;
    pc.onIceGatheringState = (s) {
      if (s == RTCIceGatheringState.RTCIceGatheringStateComplete && !done.isCompleted) done.complete();
    };
    await done.future.timeout(const Duration(seconds: 4), onTimeout: () {});
  }

  void _pollState(Duration every) {
    _poll?.cancel();
    _poll = Timer(every, () async {
      final id = callId;
      if (id == null || !busy) return;
      final r = await AdminCallApi.state(id);
      if (!r.ok) {
        _pollState(const Duration(seconds: 3));
        return;
      }
      if (id != callId) return;
      _apply(r.data);
      final s = (r.data['status'] ?? '').toString();
      if (s == 'accepted' && role == 'caller' && _pc != null && r.data['remote_sdp'] != null) {
        final current = await _pc!.getRemoteDescription();
        if (current == null) {
          await _pc!.setRemoteDescription(RTCSessionDescription(r.data['remote_sdp'], 'answer'));
          _set('connecting', 'جارٍ الاتصال…');
        }
      }
      if (s != 'ringing' && s != 'accepted') {
        await _finish((r.data['status_label'] ?? 'انتهت المكالمة').toString());
        return;
      }
      if (s == 'ringing' && role == 'caller') statusLabel = (r.data['status_label'] ?? statusLabel).toString();
      notifyListeners();
      _pollState(Duration(seconds: s == 'accepted' ? 2 : 1));
    });
  }

  Future<void> _fail(Object e) async {
    debugPrint('call failed: $e');
    final text = e.toString().contains('Permission') || e.toString().contains('NotAllowed')
        ? 'اسمح للتطبيق باستخدام الميكروفون من إعدادات الهاتف'
        : e.toString().replaceFirst('Exception: ', '');
    final id = callId;
    if (id != null) await AdminCallApi.end(id);
    await _finish(text.isEmpty ? 'تعذّر الاتصال' : text);
  }

  Future<void> _finish(String label, {bool endSystemCall = true}) async {
    _poll?.cancel();
    _reconnect?.cancel();
    try {
      _local?.getTracks().forEach((t) => t.stop());
      await _local?.dispose();
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    _local = null;
    if (endSystemCall && callId != null) {
      try {
        await FlutterCallkitIncoming.endCall(callKitId(callId!));
      } catch (_) {}
    }
    _set('ended', label);
    // a moment to read how it ended (and to go back to the chat), then the screen closes
    Future.delayed(const Duration(seconds: 4), () {
      if (status == 'ended') _reset();
    });
  }

  void _reset() {
    _poll?.cancel();
    callId = null;
    status = 'idle';
    statusLabel = '';
    answeredAt = null;
    muted = false;
    speaker = false;
    notifyListeners();
  }

  void _set(String s, String label) {
    status = s;
    statusLabel = label;
    notifyListeners();
  }

  void _openScreen() {
    final nav = appNavigatorKey.currentState;
    if (nav == null || AdminCallPage.isOpen) return;
    nav.push(MaterialPageRoute(builder: (_) => const AdminCallPage(), fullscreenDialog: true));
  }

  /// Back to the call screen from anywhere (the "ongoing call" bar).
  void openScreen() => _openScreen();
}

/// Android 14+: one friendly ask to let Taxista calls ring like ordinary calls, over the lock
/// screen ("full-screen notifications"); on makers that hide calls more, the app settings too.
class LockScreenCallsSheet extends StatelessWidget {
  final bool strict;

  const LockScreenCallsSheet({super.key, this.strict = false});

  static bool get _ar => languageDirection != 'ltr';
  static String _t(String ar, String en) => _ar ? ar : en;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    const ink = Color(0xff12121D);
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: green.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.ring_volume_rounded, color: green, size: 32),
                ),
              ),
              const SizedBox(height: 14),
              Text(_t('لا تفوّت أي مكالمة', "Don't miss a call"),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 8),
              Text(
                  _t('اسمح لمكالمات تاكسيستا أن ترنّ على شاشة القفل مثل المكالمات العادية.',
                      'Let Taxista calls ring on the lock screen like ordinary calls.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, height: 1.5, color: ink.withValues(alpha: 0.7))),
              if (strict) ...[
                const SizedBox(height: 10),
                Text(
                    _t('على هاتفك فعّل أيضًا «العرض على شاشة القفل» من إعدادات التطبيق.',
                        'On your phone, also turn on "Show on lock screen" in the app settings.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.45, color: ink.withValues(alpha: 0.55))),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const ValueKey('lock-calls-allow'),
                  style: FilledButton.styleFrom(backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pop(context, 'allow'),
                  child: Text(_t('السماح', 'Allow'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              if (strict) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.pop(context, 'settings'),
                  child: Text(_t('إعدادات التطبيق', 'App settings')),
                ),
              ],
              const SizedBox(height: 2),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t('لاحقًا', 'Later'), style: TextStyle(fontSize: 12.5, color: ink.withValues(alpha: 0.45))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
