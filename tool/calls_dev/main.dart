// Developer-only entry point (never part of the shipped app): the REAL call engine, call screen,
// call log and voice messages (recorder sheet, upload, player) against the local backend test
// rig, with a disposable test rider's token. No Firebase, no push: an incoming call is found by
// asking the rig.
//
//   flutter run -t tool/calls_dev/main.dart \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8137/ \
//     --dart-define=RIDER_TOKEN=<local rig token> \
//     --dart-define=AUTO_ANSWER=true
//
// Local rig only. Never a production URL or a real rider's token.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxista/functions/calls/admin_call_controller.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/callPage/admin_call_page.dart';
import 'package:taxista/pages/callPage/call_log_page.dart';
import 'package:taxista/widgets/voice/voice_bubble.dart';
import 'package:taxista/widgets/voice/voice_send.dart';

const String kToken = String.fromEnvironment('RIDER_TOKEN');
const bool kAutoAnswer = bool.fromEnvironment('AUTO_ANSWER');

void main() {
  bearerToken = [BearerClass(type: 'Bearer', token: kToken)];
  runApp(MaterialApp(
    navigatorKey: appNavigatorKey,
    debugShowCheckedModeBanner: false,
    builder: (context, child) => Stack(children: [child!, const Positioned(top: 0, left: 0, right: 0, child: OngoingCallBar())]),
    home: const _Dev(),
  ));
}

class _Dev extends StatefulWidget {
  const _Dev();
  @override
  State<_Dev> createState() => _DevState();
}

class _DevState extends State<_Dev> {
  final call = AdminCallController.instance;
  Timer? _ring;
  String _note = '';
  final Set<String> _seen = {};
  List _voice = [];

  @override
  void initState() {
    super.initState();
    call.init();
    call.addListener(_changed);
    _ring = Timer.periodic(const Duration(seconds: 1), (_) => _checkRinging());
    _loadVoice();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// The rig's stand-in for the "someone is calling" push (with the app open: Taxista's own incoming screen).
  Future<void> _checkRinging() async {
    if (call.busy) return;
    try {
      final r = await http.get(Uri.parse('${url}__dev/ringing?rider=1'));
      final id = (jsonDecode(r.body)['id'] ?? '').toString();
      if (id.isEmpty || _seen.contains(id)) return;
      _seen.add(id);
      if (kAutoAnswer) {
        await call.answer(id);
      } else {
        await AdminCallController.incomingPush({'call_id': id, 'caller_name': 'إدارة تاكسيستا', 'caller_role': 'admin'}, appOpen: true);
      }
    } catch (_) {}
  }

  Future<void> _loadVoice() async {
    try {
      final r = await http.get(Uri.parse('${url}api/v1/request/admin-chat-history'), headers: {'Authorization': 'Bearer $kToken', 'Accept': 'application/json'});
      final chats = (jsonDecode(r.body)['data']['chats'] as List).where((m) => m['message_type'] == 'voice').toList();
      if (mounted) setState(() => _voice = chats.reversed.take(3).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _ring?.cancel();
    call.removeListener(_changed);
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    final problem = await action();
    if (mounted) setState(() => _note = problem ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مكالمات ورسائل صوتية · بيئة محلية')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('الحالة: ${call.status} ${call.statusLabel}', key: const Key('status')),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('call-admin'),
            icon: const Icon(Icons.support_agent),
            label: const Text('اتصل بالإدارة'),
            onPressed: call.busy ? null : () => _run(call.callAdministration),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('call-driver'),
            icon: const Icon(Icons.local_taxi),
            label: const Text('اتصل بالسائق'),
            onPressed: call.busy ? null : () => _run(() => call.callDriver()),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('voice'),
            icon: const Icon(Icons.mic),
            label: const Text('رسالة صوتية للإدارة'),
            onPressed: () async {
              final sent = await VoiceSend.recordAndSend(context, endpoint: 'send-voice-message');
              setState(() => _note = sent == null ? 'لم تُرسل' : 'أُرسلت: ${sent['audio_duration_ms']} ms');
              await _loadVoice();
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('log'),
            icon: const Icon(Icons.history),
            label: const Text('سجل المكالمات'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallLogPage())),
          ),
          const SizedBox(height: 12),
          Text(_note),
          const SizedBox(height: 12),
          for (final m in _voice)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(18)),
                child: VoiceBubble.fromMessage(m, mine: true),
              ),
            ),
        ]),
      ),
    );
  }
}
