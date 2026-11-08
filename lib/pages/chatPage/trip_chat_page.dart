import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../functions/calls/admin_call_api.dart';
import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../../functions/trip_chat_api.dart';
import '../../styles/styles.dart';
import '../../widgets/chat/chat_kit.dart';
import '../../widgets/chat/chat_actions.dart';
import '../../widgets/chat/chat_reactions.dart';
import '../../widgets/chat/chat_photos.dart';
import '../../widgets/voice/voice_bubble.dart';
import '../../widgets/voice/voice_send.dart';

/// The chat with the driver of one ride from the trip history or the call log: the same
/// conversation as during the ride, voice messages, and a free call while the server allows it
/// (up to 24 hours after the ride). New messages are fetched every few seconds while open.
class TripChatPage extends StatefulWidget {
  final String requestId;
  final String driverName;
  final String? driverPhoto;

  /// Under the name: the car and its plate, or the trip number.
  final String? details;

  const TripChatPage({super.key, required this.requestId, required this.driverName, this.driverPhoto, this.details});

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _Outgoing {
  final String text;
  final Map? reply;
  final DateTime at = DateTime.now();
  bool failed = false;

  _Outgoing(this.text, [this.reply]);
}

class _TripChatPageState extends State<TripChatPage> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<_Outgoing> _outgoing = [];

  /// chat 2.0: the line being answered ({id, name, text})
  Map? _replying;
  String? _flashId;

  Future<void> _menu(Map m, bool mine, String text) async {
    if ('${m['id'] ?? ''}'.isEmpty) return;
    final rtl = languageDirection == 'rtl';
    final mineEmoji = ChatReactions.mine(m);
    final choice = await ChatMessageMenu.show(context, preview: chatSnippet(m, rtl: rtl, text: text), currentEmoji: mineEmoji, canCopy: text.trim().isNotEmpty, rtl: rtl);
    if (choice == null || !mounted) return;
    if (choice.kind == 'reply') return _startReply(m, mine, text);
    if (choice.kind == 'copy') {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rtl ? 'تم نسخ الرسالة' : 'Message copied'), behavior: SnackBarBehavior.floating));
      return;
    }
    final ok = await ChatReactions.sendTrip(m, (choice.emoji ?? '').isEmpty ? null : choice.emoji);
    if (!mounted) return;
    if (ok) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rtl ? 'ما قدرناش نحفظ التفاعل، جرّب مرة ثانية' : "Couldn't save the reaction")));
    }
  }

  void _startReply(Map m, bool mine, String text) {
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return;
    final rtl = languageDirection == 'rtl';
    setState(() => _replying = {'id': id, 'name': mine ? (rtl ? 'أنت' : 'You') : (rtl ? 'السائق' : 'Driver'), 'text': chatSnippet(m, rtl: rtl, text: text)});
    _inputFocus.requestFocus();
  }

  void _flash(dynamic id) {
    setState(() => _flashId = '${id ?? ''}');
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _flashId = null);
    });
  }
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _loadFailed = false;
  bool? _canCall;
  bool _calling = false;
  Timer? _poll;
  AppLifecycleListener? _life;

  bool get _ar => languageDirection == 'rtl';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
    _checkCall();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _load(quiet: true));
    _life = AppLifecycleListener(onResume: () => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _life?.dispose();
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    final list = await TripChatApi.history(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (list != null) _messages = list;
      _loadFailed = list == null && _messages.isEmpty;
    });
    if (list != null && list.any((m) => '${m['from_type']}' == '2' && '${m['seen']}' != '1')) {
      unawaited(TripChatApi.seen(widget.requestId));
    }
  }

  Future<void> _checkCall() async {
    final r = await AdminCallApi.availability(requestId: widget.requestId);
    if (mounted) setState(() => _canCall = r.ok && r.data['can_call_driver'] == true);
  }

  void _toBottom() {
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _sendText([_Outgoing? retry]) async {
    final text = retry?.text ?? _input.text.trim();
    if (text.isEmpty) return;
    final item = retry ?? _Outgoing(text, _replying);
    setState(() {
      item.failed = false;
      if (retry == null) {
        _outgoing.add(item);
        _input.clear();
        _replying = null;
      }
    });
    _toBottom();
    final list = await TripChatApi.send(widget.requestId, text, replyTo: item.reply == null ? null : '${item.reply!['id']}');
    if (!mounted) return;
    setState(() {
      if (list != null) {
        _outgoing.remove(item);
        _messages = list;
      } else {
        item.failed = true;
      }
    });
  }

  /// 📷: a photo to the driver of this ride
  Future<void> _sendPhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await ChatPhotos.pickAndSend(context, endpoint: 'send-image', fields: {'request_id': widget.requestId});
    if (sent == null) return;
    await _load(quiet: true);
    _toBottom();
  }

  Future<void> _sendVoice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await VoiceSend.recordAndSend(context, endpoint: 'send-voice', fields: {'request_id': widget.requestId});
    if (sent == null) return;
    await _load(quiet: true);
    _toBottom();
  }

  Future<void> _call() async {
    if (_calling) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_canCall == false) {
      _explain(_t('انتهت مدة الاتصال بهذا السائق', 'Calling this driver has ended'),
          _t('الاتصال المجاني بالسائق متاح أثناء الرحلة وحتى 24 ساعة بعد انتهائها. يمكنك مراسلته هنا وسيصله إشعار.',
              'The free call is available during the ride and up to 24 hours after it. You can still write here; the driver is notified.'));
      return;
    }
    setState(() => _calling = true);
    final problem = await AdminCallController.instance.callDriver(requestId: widget.requestId);
    if (!mounted) return;
    setState(() => _calling = false);
    if (problem != null) {
      unawaited(_checkCall());
      _explain(_t('تعذّر الاتصال بالسائق الآن', "Couldn't call the driver now"), problem);
    }
  }

  void _explain(String title, String body) {
    final p = ChatPalette.current();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Directionality(
        textDirection: _ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          decoration: BoxDecoration(color: p.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + MediaQuery.of(c).padding.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Color(0xFFFFF4E5), shape: BoxShape.circle),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: p.text(17, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: p.text(13, color: p.sub, height: 1.5)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(c);
                _inputFocus.requestFocus();
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.edit_rounded, size: 19),
              label: Text(_t('اكتب رسالة للسائق', 'Write to the driver'), style: p.text(15, weight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ChatPalette.current();
    return Directionality(
      textDirection: _ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(children: [
          ChatHeader(
            palette: p,
            title: widget.driverName,
            status: _canCall == true
                ? _t('يمكنك الاتصال به مجانًا الآن', 'You can call for free now')
                : (widget.details ?? _t('سائق رحلتك', 'Your driver')),
            online: _canCall == true,
            calling: _calling,
            photo: widget.driverPhoto,
            icon: Icons.local_taxi_rounded,
            onBack: () => Navigator.of(context).maybePop(),
            onCall: _call,
            callLabel: _t('اتصال مجاني بالسائق عبر تاكسيستا', 'Free call to the driver through Taxista'),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: _body(p),
            ),
          ),
          if (_replying != null)
            ChatReplyBar(
              name: '${_replying!['name']}',
              text: '${_replying!['text']}',
              rtl: languageDirection == 'rtl',
              onClose: () => setState(() => _replying = null),
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
            onPhoto: _sendPhoto,
          ),
        ]),
      ),
    );
  }

  Widget _body(ChatPalette p) {
    if (_loading && _messages.isEmpty) {
      return Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.6, color: theme)));
    }
    if (_loadFailed) {
      return ChatNotice(
        palette: p,
        icon: Icons.wifi_off_rounded,
        title: _t('تعذّر تحميل المحادثة', "Couldn't load the conversation"),
        body: _t('تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.', 'Check your connection and try again.'),
        action: _t('إعادة المحاولة', 'Try again'),
        onAction: _load,
      );
    }
    if (_messages.isEmpty && _outgoing.isEmpty) {
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
            Text(_t('لا توجد رسائل مع السائق بعد', 'No messages with the driver yet'),
                textAlign: TextAlign.center, style: p.text(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_t('اكتب له إذا نسيت شيئًا في السيارة أو لديك سؤال عن الرحلة.', 'Write if you left something in the car or have a question about the ride.'),
                textAlign: TextAlign.center, style: p.text(14, color: p.sub, height: 1.6)),
          ]),
        ),
      );
    }

    final rows = <Widget>[];
    DateTime? day;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final at = ChatTime.parse(m['created_at']);
      if (at != null && (day == null || !ChatTime.sameDay(day, at))) {
        rows.add(ChatDaySeparator(palette: p, label: ChatTime.dayLabel(at, _ar)));
        day = at;
      }
      final mine = '${m['from_type']}' == '1';
      final prev = i > 0 ? _messages[i - 1] : null;
      final next = i + 1 < _messages.length ? _messages[i + 1] : null;
      bool sameRun(Map<String, dynamic>? a, Map<String, dynamic>? b) {
        if (a == null || b == null || '${a['from_type']}' != '${b['from_type']}') return false;
        final ta = ChatTime.parse(a['created_at']), tb = ChatTime.parse(b['created_at']);
        return ta != null && tb != null && ChatTime.sameDay(ta, tb) && tb.difference(ta).inMinutes.abs() < 3;
      }

      final text = ChatPhotos.of(m).isNotEmpty ? ChatPhotos.caption(m) : '${m['message'] ?? ''}';
      final quote = m['reply_to'] is Map ? m['reply_to'] as Map : null;
      rows.add(Padding(
        padding: EdgeInsets.only(top: sameRun(prev, m) ? 2 : 10),
        child: ChatBubble(
          palette: p,
          mine: mine,
          tail: !sameRun(m, next),
          highlighted: _flashId != null && _flashId == '${m['id']}',
          replyTo: quote,
          reactions: ChatReactions.of(m),
          onMenu: '${m['id'] ?? ''}'.isEmpty ? null : () => _menu(m, mine, text),
          onSwipeReply: '${m['id'] ?? ''}'.isEmpty ? null : () => _startReply(m, mine, text),
          onQuoteTap: quote == null ? null : () => _flash(quote['id']),
          text: text,
          photos: ChatPhotos.of(m),
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
          replyTo: o.reply,
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
