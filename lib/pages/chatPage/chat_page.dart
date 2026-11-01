import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/chat/chat_kit.dart';
import '../../widgets/voice/voice_bubble.dart';
import '../../widgets/voice/voice_send.dart';

/// The chat with the driver during the ride under way. Messages arrive through the ride's live
/// updates (valueNotifierBook); sending also nudges the driver's app through the ride node.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _Outgoing {
  final String text;
  final DateTime at = DateTime.now();
  bool failed = false;

  _Outgoing(this.text);
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<_Outgoing> _outgoing = [];
  bool _calling = false;

  bool get _ar => languageDirection == 'rtl';
  String _t(String ar, String en) => _ar ? ar : en;

  Map get _driver {
    final d = userRequestData['driverDetail'];
    return d is Map && d['data'] is Map ? d['data'] as Map : const {};
  }

  @override
  void initState() {
    super.initState();
    getCurrentMessages();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _sendText([_Outgoing? retry]) async {
    final text = retry?.text ?? _input.text.trim();
    if (text.isEmpty) return;
    final item = retry ?? _Outgoing(text);
    setState(() {
      item.failed = false;
      if (retry == null) {
        _outgoing.add(item);
        _input.clear();
      }
    });
    _toBottom();
    final result = await sendMessage(text);
    if (!mounted) return;
    setState(() {
      if (result == 'success') {
        _outgoing.remove(item);
      } else {
        item.failed = true;
      }
    });
  }

  Future<void> _sendVoice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await VoiceSend.recordAndSend(context, endpoint: 'send-voice', fields: {'request_id': userRequestData['id'].toString()});
    if (sent != null) await voiceMessageSent();
    _toBottom();
  }

  /// A voice call with the driver, inside the app (no phone numbers).
  Future<void> _callDriver() async {
    if (_calling) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _calling = true);
    final problem = await AdminCallController.instance.callDriver(requestId: userRequestData['id']?.toString());
    if (!mounted) return;
    setState(() => _calling = false);
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ChatPalette.current();
    final car = [
      [_driver['car_make_name'], _driver['car_model_name']].where((v) => v != null && '$v'.isNotEmpty).join(' '),
      _driver['car_number'],
    ].where((v) => v != null && '$v'.isNotEmpty).join(' · ');
    return Directionality(
      textDirection: _ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(children: [
          ChatHeader(
            palette: p,
            title: '${_driver['name'] ?? _t('السائق', 'Driver')}',
            status: car.isNotEmpty ? car : _t('سائق رحلتك', 'Your driver'),
            online: true,
            calling: _calling,
            photo: _driver['profile_picture']?.toString(),
            icon: Icons.local_taxi_rounded,
            onBack: () => Navigator.of(context).maybePop(),
            onCall: _callDriver,
            callLabel: _t('اتصال مجاني بالسائق عبر تاكسيستا', 'Free call to the driver through Taxista'),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, _, __) => _body(p),
              ),
            ),
          ),
          ChatComposer(
            palette: p,
            controller: _input,
            focusNode: _inputFocus,
            hint: _t('اكتب رسالة للسائق…', 'Write to the driver…'),
            sendLabel: _t('إرسال', 'Send'),
            voiceLabel: _t('تسجيل رسالة صوتية', 'Record a voice message'),
            onChanged: () => setState(() {}),
            onSend: () => _sendText(),
            onVoice: _sendVoice,
          ),
        ]),
      ),
    );
  }

  Widget _body(ChatPalette p) {
    final messages = chatList.whereType<Map>().toList();
    if (messages.isEmpty && _outgoing.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: theme.withValues(alpha: p.dark ? 0.2 : 0.09), shape: BoxShape.circle),
              child: Icon(Icons.chat_rounded, color: theme, size: 34),
            ),
            const SizedBox(height: 14),
            Text(_t('راسل سائقك', 'Message your driver'), textAlign: TextAlign.center, style: p.text(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_t('اكتب له مكانك بالضبط أو أي ملاحظة عن الرحلة، أو اتصل به مجانًا.', 'Tell the driver exactly where you are, or call for free.'),
                textAlign: TextAlign.center, style: p.text(14, color: p.sub, height: 1.6)),
          ]),
        ),
      );
    }
    bool sameRun(Map? a, Map? b) {
      if (a == null || b == null || '${a['from_type']}' != '${b['from_type']}') return false;
      final ta = ChatTime.parse(a['created_at']), tb = ChatTime.parse(b['created_at']);
      return ta != null && tb != null && ChatTime.sameDay(ta, tb) && tb.difference(ta).inMinutes.abs() < 3;
    }

    final rows = <Widget>[];
    DateTime? day;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final at = ChatTime.parse(m['created_at']);
      if (at != null && (day == null || !ChatTime.sameDay(day, at))) {
        rows.add(ChatDaySeparator(palette: p, label: ChatTime.dayLabel(at, _ar)));
        day = at;
      }
      final mine = '${m['from_type']}' == '1';
      rows.add(Padding(
        padding: EdgeInsets.only(top: sameRun(i > 0 ? messages[i - 1] : null, m) ? 2 : 10),
        child: ChatBubble(
          palette: p,
          mine: mine,
          tail: !sameRun(m, i + 1 < messages.length ? messages[i + 1] : null),
          text: '${m['message'] ?? ''}',
          voice: VoiceBubble.fromMessage(m, mine: mine),
          time: at != null ? ChatTime.clock(at, _ar) : '',
          status: mine ? ('${m['seen']}' == '1' ? ChatDelivery.read : ChatDelivery.sent) : null,
          copiedLabel: _t('تم نسخ الرسالة', 'Message copied'),
        ),
      ));
    }
    for (final o in _outgoing) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ChatBubble(
          palette: p,
          mine: true,
          tail: true,
          text: o.text,
          time: ChatTime.clock(o.at, _ar),
          status: o.failed ? ChatDelivery.failed : ChatDelivery.sending,
          failedLabel: _t('لم تُرسل · اضغط لإعادة المحاولة', 'Not sent · tap to retry'),
          onRetry: o.failed ? () => _sendText(o) : null,
          copiedLabel: _t('تم نسخ الرسالة', 'Message copied'),
        ),
      ));
    }
    return SingleChildScrollView(
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}
