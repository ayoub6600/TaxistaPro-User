import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_api.dart';
import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../../functions/support_chat_link.dart';
import '../../styles/styles.dart';
import '../../widgets/chat/chat_kit.dart';
import '../../widgets/support_call_card.dart';
import '../../widgets/voice/voice_bubble.dart';
import '../../widgets/voice/voice_send.dart';

/// The conversation with Taxista support: messages, voice messages, call cards, and a voice
/// call to the administration from the header.
class AdminChatPage extends StatefulWidget {
  /// Opened from a notification: the message to bring into view (and briefly highlight).
  final int? focusMessageId;

  const AdminChatPage({super.key, this.focusMessageId});

  /// Whether the chat with the administration is on screen (a tapped notification reuses it).
  static bool get isOpen => adminChatPagesOpen > 0;

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

/// A text message on its way: shown at once, marked when it fails, never lost.
class _Outgoing {
  final String text;
  final DateTime at = DateTime.now();
  bool failed = false;

  _Outgoing(this.text);
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<_Outgoing> _outgoing = [];
  bool _loading = true;
  bool _loadFailed = false;

  /// Whether an administrator takes calls right now; null while checking.
  bool? _canCall;
  bool _calling = false;

  // the message a notification pointed at: scrolled into view once loaded, outlined for a moment
  final GlobalKey _focusKey = GlobalKey();
  int? _focusId;
  int? _highlightId;
  Timer? _highlightTimer;

  bool get _ar => languageDirection == 'rtl';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    adminChatPagesOpen++;
    _focusId = widget.focusMessageId;
    SupportChatLink.focus.addListener(_onFocusRequest);
    _load();
    _checkAvailability();
  }

  @override
  void dispose() {
    adminChatPagesOpen--;
    SupportChatLink.focus.removeListener(_onFocusRequest);
    _highlightTimer?.cancel();
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    adminChatList.clear();
    if (chatid != null && unSeenChatCount != '0') {
      adminmessageseen();
    }
    final result = await getadminCurrentMessages();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadFailed = result != 'success';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused());
  }

  Future<void> _checkAvailability() async {
    final result = await AdminCallApi.availability();
    if (mounted) setState(() => _canCall = result.ok && result.data['can_call_admin'] == true);
  }

  /// A notification tapped while this page is open: reload and show that message.
  Future<void> _onFocusRequest() async {
    final id = SupportChatLink.focus.value;
    if (id == null) return;
    _focusId = id;
    await getadminCurrentMessages();
    if (!mounted) return;
    valueNotifierChat.incrementNotifier();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused());
  }

  /// The message a notification pointed at: into view once, outlined for a moment.
  void _revealFocused() {
    final target = _focusKey.currentContext;
    if (_focusId == null || !mounted) return;
    if (target == null) {
      if (!_loading) _focusId = null; // not in the history (deleted, or another chat)
      return;
    }
    final id = _focusId;
    _focusId = null;
    Scrollable.ensureVisible(target, alignment: 0.4, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    setState(() => _highlightId = id);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _highlightId = null);
    });
  }

  void _toBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  // ------------------------------------------------------------------ sending

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
    final result = await sendadminMessage(text);
    if (!mounted) return;
    setState(() {
      if (result == 'success') {
        _outgoing.remove(item);
        // the server's copy carries no date yet: it was sent just now (the next refresh replaces it)
        if (adminChatList.isNotEmpty && adminChatList.last is Map) {
          final last = adminChatList.last as Map;
          last['created_at'] ??= DateTime.now().toUtc().toIso8601String();
          last['unseen_count'] ??= 0;
        }
      } else {
        item.failed = true;
      }
    });
  }

  Future<void> _sendVoice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await VoiceSend.recordAndSend(context, endpoint: 'send-voice-message',
        fields: {if (chatid != null) 'chat_id': chatid.toString()});
    if (sent == null) return;
    chatid = sent['chat_id'] ?? chatid;
    isnewchat = 0;
    await getadminCurrentMessages();
    if (mounted) setState(() {});
    _toBottom();
  }

  void _useTopic(String topic) {
    _input.text = '$topic: ';
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
    _inputFocus.requestFocus();
    setState(() {});
  }

  // ------------------------------------------------------------------ calling

  /// The call button: a voice call inside the app; when no administrator takes calls right
  /// now, the other ways to reach support.
  Future<void> _callAdministration() async {
    if (_calling) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _calling = true);
    final problem = await AdminCallController.instance.callAdministration();
    if (!mounted) return;
    setState(() => _calling = false);
    if (problem == null) return;
    unawaited(_checkAvailability());
    await _showCallAlternatives(problem);
  }

  /// [problem] null: only the other ways to reach support (the header's menu button).
  Future<void> _showCallAlternatives(String? problem) async {
    final numbers = <String>{
      for (final key in const ['contact_us_mobile1', 'contact_us_mobile2'])
        if ('${userDetails[key] ?? ''}'.trim().isNotEmpty) '${userDetails[key]}'.trim(),
    }.toList();
    final link = '${userDetails['contact_us_link'] ?? ''}'.trim();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CallAlternativesSheet(
        palette: ChatPalette.current(),
        ar: _ar,
        problem: problem,
        numbers: numbers,
        link: link.isEmpty ? null : link,
      ),
    );
    if (!mounted) return;
    if (choice == 'write') _inputFocus.requestFocus();
    if (choice == 'call') unawaited(_callAdministration());
  }

  // ------------------------------------------------------------------ layout

  @override
  Widget build(BuildContext context) {
    final p = ChatPalette.current();
    return Directionality(
      textDirection: _ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: PopScope(
        canPop: true,
        // ignore: deprecated_member_use
        onPopInvoked: (didPop) {
          unSeenChatCount = '0';
          if (chatid != null) {
            adminmessageseen();
          }
          valueNotifierChat.incrementNotifier();
        },
        child: Scaffold(
          backgroundColor: p.background,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              ChatHeader(
                palette: p,
                title: _t('دعم تاكسيستا', 'Taxista Support'),
                status: _canCall == null
                    ? _t('جارٍ التحقق…', 'Checking…')
                    : _canCall!
                        ? _t('متاحون للمكالمات الآن', 'Available for calls now')
                        : _t('نرد على رسائلك بأسرع وقت', 'We reply as soon as we can'),
                online: _canCall == true,
                calling: _calling,
                onBack: () => Navigator.of(context).maybePop(true),
                onCall: _callAdministration,
                callLabel: _t('اتصال مجاني عبر تطبيق تاكسيستا', 'Free call through the Taxista app'),
                onMore: () => _showCallAlternatives(null),
                moreLabel: _t('طرق تواصل أخرى', 'Other ways to contact us'),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: ValueListenableBuilder(
                    valueListenable: valueNotifierChat.value,
                    builder: (context, _, __) => _body(p),
                  ),
                ),
              ),
              ChatComposer(
                palette: p,
                controller: _input,
                focusNode: _inputFocus,
                hint: _t('اكتب رسالتك…', 'Write a message…'),
                sendLabel: _t('إرسال', 'Send'),
                voiceLabel: _t('تسجيل رسالة صوتية', 'Record a voice message'),
                onChanged: () => setState(() {}),
                onSend: () => _sendText(),
                onVoice: _sendVoice,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ChatPalette p) {
    final messages = adminChatList.whereType<Map>().toList();
    if (_loading && messages.isEmpty) {
      return Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.6, color: theme)));
    }
    if (_loadFailed && messages.isEmpty) {
      return ChatNotice(
        palette: p,
        icon: Icons.wifi_off_rounded,
        title: _t('تعذّر تحميل المحادثة', "Couldn't load the conversation"),
        body: _t('تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.', 'Check your connection and try again.'),
        action: _t('إعادة المحاولة', 'Try again'),
        onAction: _load,
      );
    }
    if (messages.isEmpty && _outgoing.isEmpty) {
      return _EmptyChat(palette: p, ar: _ar, onTopic: _useTopic);
    }

    final me = '${userDetails['id']}';
    final rows = <Widget>[];
    DateTime? previousDay;
    Map? previous;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final at = ChatTime.parse(m['created_at']);
      if (at != null && (previousDay == null || !ChatTime.sameDay(previousDay, at))) {
        rows.add(ChatDaySeparator(palette: p, label: ChatTime.dayLabel(at, _ar)));
        previousDay = at;
        previous = null;
      }
      final id = int.tryParse('${m['id'] ?? ''}');
      final focused = id != null && (id == _focusId || id == _highlightId);
      final callCard = SupportCallCard.fromMessage(m, highlighted: id != null && id == _highlightId, onCallBack: _callAdministration);
      if (callCard != null) {
        rows.add(Center(key: focused ? _focusKey : null, child: callCard));
        previous = null;
        continue;
      }
      final mine = '${m['from_id']}' == me;
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final groupedWithPrevious = previous != null && _sameRun(previous, m);
      final lastOfRun = next == null || !_sameRun(m, next) || SupportCallCard.fromMessage(next) != null ||
          (ChatTime.parse(next['created_at']) != null && at != null && !ChatTime.sameDay(at, ChatTime.parse(next['created_at'])!));
      rows.add(Padding(
        key: focused ? _focusKey : null,
        padding: EdgeInsets.only(top: groupedWithPrevious ? 2 : 10),
        child: ChatBubble(
          palette: p,
          mine: mine,
          tail: lastOfRun,
          highlighted: id != null && id == _highlightId,
          text: '${m['message'] ?? ''}',
          voice: VoiceBubble.fromMessage(m, mine: mine),
          time: at != null ? ChatTime.clock(at, _ar) : '${m['user_timezone'] ?? ''}',
          status: mine ? (m['unseen_count'].toString() == '1' ? ChatDelivery.read : ChatDelivery.sent) : null,
          copiedLabel: _t('تم نسخ الرسالة', 'Message copied'),
        ),
      ));
      previous = m;
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
      reverse: true, // anchored at the newest message, also while the keyboard opens
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  /// Consecutive messages from the same side within three minutes sit together.
  bool _sameRun(Map a, Map b) {
    if ('${a['from_id']}' != '${b['from_id']}') return false;
    final ta = ChatTime.parse(a['created_at']);
    final tb = ChatTime.parse(b['created_at']);
    if (ta == null || tb == null) return false;
    return tb.difference(ta).inMinutes.abs() < 3;
  }
}

class _EmptyChat extends StatelessWidget {
  final ChatPalette palette;
  final bool ar;
  final ValueChanged<String> onTopic;

  const _EmptyChat({required this.palette, required this.ar, required this.onTopic});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final topics = ar
        ? const ['مشكلة في رحلة', 'المحفظة والرصيد', 'الدفع', 'حسابي', 'اقتراح أو ملاحظة']
        : const ['A problem with a trip', 'Wallet and balance', 'Payment', 'My account', 'A suggestion'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: theme.withValues(alpha: p.dark ? 0.2 : 0.09), shape: BoxShape.circle),
            child: Icon(Icons.forum_rounded, color: theme, size: 40),
          ),
          const SizedBox(height: 18),
          Text(ar ? 'كيف يمكننا مساعدتك؟' : 'How can we help?',
              textAlign: TextAlign.center, style: p.text(20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              ar
                  ? 'اكتب رسالتك أو سجّل رسالة صوتية، وسيرد عليك فريق تاكسيستا هنا في أقرب وقت.'
                  : 'Write or record a voice message and the Taxista team will reply here as soon as possible.',
              textAlign: TextAlign.center,
              style: p.text(14, color: p.sub, height: 1.6),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in topics)
                ActionChip(
                  label: Text(topic, style: p.text(13, weight: FontWeight.w600, color: p.dark ? p.ink : theme)),
                  onPressed: () => onTopic(topic),
                  backgroundColor: p.surface,
                  side: BorderSide(color: theme.withValues(alpha: 0.28)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reaching support another way. With [problem] (the in-app call could not start): why, then
/// "write instead" and "try the free call again"; the phone numbers and the website stay
/// behind one "other ways" button. Without [problem] (the header's menu): those other ways.
/// Pops 'write', 'call' or nothing.
class _CallAlternativesSheet extends StatefulWidget {
  final ChatPalette palette;
  final bool ar;
  final String? problem;
  final List<String> numbers;
  final String? link;

  const _CallAlternativesSheet({required this.palette, required this.ar, required this.problem, required this.numbers, this.link});

  @override
  State<_CallAlternativesSheet> createState() => _CallAlternativesSheetState();
}

class _CallAlternativesSheetState extends State<_CallAlternativesSheet> {
  late bool _others = widget.problem == null;

  String _t(String ar, String en) => widget.ar ? ar : en;

  Widget _option({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, bool ltr = false, Color? tint}) {
    final p = widget.palette;
    final color = tint ?? theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: p.dark ? 0.2 : 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, textDirection: ltr ? ui.TextDirection.ltr : null, style: p.text(15, weight: FontWeight.w700)),
                if (subtitle != null) Text(subtitle, style: p.text(12.5, color: p.sub)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: p.sub),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final problem = widget.problem;
    final hasOthers = widget.numbers.isNotEmpty || widget.link != null;
    return Directionality(
      textDirection: widget.ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(color: p.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + MediaQuery.of(context).padding.bottom),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 18),
              if (problem != null) ...[
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
                      Text(_t('المكالمة المجانية غير متاحة الآن', 'The free call is not available right now'),
                          style: p.text(17, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(problem, style: p.text(13, color: p.sub, height: 1.5)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, 'write'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  label: Text(_t('اكتب رسالة للدعم', 'Write to support'), style: p.text(15, weight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'call'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: ChatPalette.online.withValues(alpha: 0.5)),
                    foregroundColor: ChatPalette.online,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 19),
                  label: Text(_t('حاول الاتصال المجاني مرة أخرى', 'Try the free call again'),
                      style: p.text(14.5, weight: FontWeight.w700, color: ChatPalette.online)),
                ),
              ] else
                Text(_t('طرق تواصل أخرى', 'Other ways to contact us'), style: p.text(17, weight: FontWeight.w700)),
              if (problem != null && hasOthers) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => setState(() => _others = !_others),
                  icon: Icon(_others ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: p.sub),
                  label: Text(_t('طرق تواصل أخرى', 'Other ways to contact us'), style: p.text(14, weight: FontWeight.w600, color: p.sub)),
                ),
              ],
              if (_others) ...[
                const SizedBox(height: 4),
                if (problem == null)
                  _option(
                    icon: Icons.call_rounded,
                    tint: ChatPalette.online,
                    title: _t('اتصال مجاني عبر تاكسيستا', 'Free call through Taxista'),
                    subtitle: _t('مكالمة صوتية داخل التطبيق دون رصيد', 'A voice call inside the app, no airtime'),
                    onTap: () => Navigator.pop(context, 'call'),
                  ),
                for (final number in widget.numbers)
                  _option(
                    icon: Icons.phone_rounded,
                    title: number,
                    subtitle: _t('اتصال هاتفي عادي (بتكلفة الشبكة)', 'Regular phone call (network rates)'),
                    ltr: true,
                    onTap: () {
                      Navigator.pop(context);
                      makingPhoneCall(number);
                    },
                  ),
                if (widget.link != null)
                  _option(
                    icon: Icons.language_rounded,
                    title: _t('موقع تاكسيستا', 'Taxista website'),
                    subtitle: _t('معلومات التواصل والمساعدة', 'Contact details and help'),
                    onTap: () {
                      Navigator.pop(context);
                      openBrowser(widget.link);
                    },
                  ),
                if (!hasOthers && problem == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_t('لا توجد أرقام أخرى حاليًا.', 'No other numbers right now.'), style: p.text(13, color: p.sub)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
