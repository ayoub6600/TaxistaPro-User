import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../functions/functions.dart' show bearerToken;
import 'contests_api.dart';
import 'contests_kit.dart';

/// «مسابقات تاكسيستا»: every contest post for this person, newest first. Old contests stay with
/// their winners post above them, and keep their likes, comments and shares.
class ContestsFeedPage extends StatefulWidget {
  const ContestsFeedPage({super.key, this.openPostId});
  final int? openPostId;
  @override
  State<ContestsFeedPage> createState() => _ContestsFeedPageState();
}

class _ContestsFeedPageState extends State<ContestsFeedPage> {
  List<Map<String, dynamic>>? _posts;
  int? _next;
  bool _loadingMore = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.openPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(widget.openPostId!));
    }
  }

  Future<void> _load() async {
    final d = await ContestsApi.feed();
    if (!mounted) return;
    setState(() {
      _failed = d == null;
      if (d != null) {
        _posts = [for (final x in (d['posts'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
        _next = (d['next'] as num?)?.toInt();
      }
    });
    ContestsApi.refreshHome();
  }

  Future<void> _more() async {
    if (_next == null || _loadingMore) return;
    _loadingMore = true;
    final d = await ContestsApi.feed(before: _next);
    _loadingMore = false;
    if (!mounted || d == null) return;
    setState(() {
      _posts = [...?_posts, for (final x in (d['posts'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
      _next = (d['next'] as num?)?.toInt();
    });
  }

  Future<void> _open(int id, {bool compose = false}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContestPostPage(postId: id, composeNow: compose)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ContestLook.feed(p),
        appBar: _bar(context, 'مسابقات تاكسيستا'),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _posts == null
              ? ListView(children: [
                  SizedBox(height: 260, child: Center(child: _failed ? _empty('ما قدرناش نجيبوا المسابقات', 'تأكد من الإنترنت واسحب لتحت باش تحاول مرة ثانية.') : const CircularProgressIndicator())),
                ])
              : _posts!.isEmpty
                  ? ListView(children: [SizedBox(height: 320, child: Center(child: _empty('ما فيش مسابقات توا', 'أول ما تنزل مسابقة جديدة تلقاها هنا وفي الصفحة الرئيسية.')))])
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _more();
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _posts!.length,
                        itemBuilder: (_, i) {
                          final post = _posts![i];
                          final id = (post['id'] as num).toInt();
                          return ContestPostCard(
                            key: ValueKey('post-$id'),
                            post: post,
                            onOpen: () => _open(id),
                            onComment: () => _open(id, compose: post['can_predict'] == true),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _empty(String title, String sub) {
    final p = ContestLook.p;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: ContestLook.brand.withValues(alpha: .1), borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.emoji_events_outlined, size: 40, color: ContestLook.brand),
        ),
        const SizedBox(height: 14),
        Text(title, style: p.text(18, weight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(sub, style: p.text(14, color: p.sub, height: 1.7), textAlign: TextAlign.center),
      ]),
    );
  }
}

PreferredSizeWidget _bar(BuildContext context, String title) {
  final p = ContestLook.p;
  return AppBar(
    backgroundColor: p.surface,
    surfaceTintColor: p.surface,
    elevation: 0,
    centerTitle: false,
    leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: p.ink), onPressed: () => Navigator.of(context).maybePop()),
    title: Text(title, style: p.text(18, weight: FontWeight.w800)),
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: p.line)),
  );
}

/// One post with all its comments. The box at the bottom writes the prediction while the contest
/// is open and the person has none; otherwise a plain comment (also after the contest ends).
class ContestPostPage extends StatefulWidget {
  const ContestPostPage({super.key, required this.postId, this.composeNow = false});
  final int postId;
  final bool composeNow;
  @override
  State<ContestPostPage> createState() => _ContestPostPageState();
}

class _ContestPostPageState extends State<ContestPostPage> {
  Map<String, dynamic>? _post;
  String _pinned = '';
  List<Map<String, dynamic>> _comments = [];
  int? _next;
  String _side = 'all';
  String _sort = 'new';
  bool _gone = false;
  bool _sending = false;
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    final results = await Future.wait([ContestsApi.post(widget.postId), ContestsApi.comments(widget.postId, side: _side, sort: _sort)]);
    if (!mounted) return;
    final post = results[0], com = results[1];
    if (post == null) {
      setState(() => _gone = _post == null);
      return;
    }
    setState(() {
      _post = post;
      _pinned = '${com?['pinned'] ?? post['pinned'] ?? ''}';
      if (com != null) {
        _comments = [for (final x in (com['comments'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
        _next = (com['next'] as num?)?.toInt();
      }
    });
    if (first && widget.composeNow && post['can_predict'] == true) _compose();
    if (first && post['my_result']?['won'] == true && post['my_result']?['show_name'] == false) {
      // the winner hears it and chooses about the winners post, once per opening
      WidgetsBinding.instance.addPostFrameCallback((_) => _wonSheet());
    }
  }

  Future<void> _moreComments() async {
    if (_next == null) return;
    final d = await ContestsApi.comments(widget.postId, side: _side, sort: _sort, before: _sort == 'new' ? _next : null, offset: _sort == 'top' ? _next : null);
    if (!mounted || d == null) return;
    final ids = _comments.map((c) => c['id']).toSet();
    setState(() {
      _comments = [..._comments, for (final x in (d['comments'] as List? ?? const [])) if (!ids.contains((x as Map)['id'])) Map<String, dynamic>.from(x)];
      _next = (d['next'] as num?)?.toInt();
    });
  }

  void _say(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: ContestLook.p.text(14, color: Colors.white)), behavior: SnackBarBehavior.floating));

  Future<void> _sendPlain() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    final (data, error) = await ContestsApi.comment(widget.postId, body: t);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) return _say(error);
    _text.clear();
    FocusScope.of(context).unfocus();
    _applyComment(data!);
  }

  void _applyComment(Map<String, dynamic> data) {
    setState(() {
      if (data['post'] is Map) _post = Map<String, dynamic>.from(data['post']);
      if (data['comment'] is Map) _comments.insert(0, Map<String, dynamic>.from(data['comment']));
    });
  }

  Future<void> _compose() async {
    final post = _post;
    if (post == null) return;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PredictionSheet(post: post),
    );
    if (data != null && mounted) {
      HapticFeedback.mediumImpact();
      _applyComment(data);
      _say('توقّعك تسجّل ✓ نبعتولك إشعار بالنتيجة.');
    }
  }

  Future<void> _wonSheet() async {
    final r = Map<String, dynamic>.from(_post?['my_result'] ?? {});
    var show = r['show_name'] == true;
    final p = ContestLook.p;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).padding.bottom),
            decoration: BoxDecoration(color: p.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 14),
              const Text('🎉', style: TextStyle(fontSize: 46)),
              Text('مبروك! ربحت ${r['amount_lyd'] ?? ''} د.ل', style: p.text(19, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(r['credited'] == true ? 'الرصيد نزل في محفظتك.' : 'الرصيد ينزل في محفظتك قريب، بعد مراجعة الفائزين.', style: p.text(13.5, color: p.sub), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Material(
                color: p.field,
                borderRadius: BorderRadius.circular(14),
                child: SwitchListTile(
                  value: show,
                  activeThumbColor: const Color(0xFF14A47B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text('نسمح نذكروا اسمي (الاسم الأول وحرف من اللقب) في منشور الفائزين', style: p.text(13.5, weight: FontWeight.w700)),
                  onChanged: (v) async {
                    set(() => show = v);
                    await ContestsApi.consent(widget.postId, v);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ContestLook.brand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('تمام', style: p.text(15.5, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ),
        );
      }),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    final post = _post;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.surface,
        appBar: _bar(context, 'منشور تاكسيستا'),
        body: post == null
            ? Center(child: _gone ? Text('المنشور مش موجود', style: p.text(15, color: p.sub)) : const CircularProgressIndicator())
            : Column(children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: EdgeInsets.zero, children: [
                      if (post['my_result']?['won'] == true) _winBanner(post),
                      if (post['my_result'] != null && post['my_result']?['won'] == false)
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: ContestLook.brand.withValues(alpha: .08),
                          child: Text('المرة هذي ما طلعش اسمك في السحب. المسابقة الجاية قريب 💙', style: p.text(13.5)),
                        ),
                      ContestPostCard(post: post, full: true, onOpen: () {}, onComment: post['can_predict'] == true ? _compose : null, onChanged: (x) => setState(() => _post = x)),
                      _filters(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                        child: Column(children: [
                          if (_pinned.isNotEmpty) ContestCommentTile(comment: const {}, postId: widget.postId, pinnedText: _pinned),
                          for (final c in _comments) ContestCommentTile(key: ValueKey('c-${c['id']}'), comment: c, postId: widget.postId),
                          if (_comments.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text('ما فيش تعليقات بعد. كن الأول!', style: p.text(14, color: p.sub))),
                          if (_next != null) TextButton(onPressed: _moreComments, child: Text('عرض توقعات أكثر', style: p.text(13.5, weight: FontWeight.w800, color: p.sub))),
                        ]),
                      ),
                    ]),
                  ),
                ),
                _composer(post),
              ]),
      ),
    );
  }

  Widget _winBanner(Map<String, dynamic> post) {
    final r = post['my_result'] as Map;
    return InkWell(
      onTap: _wonSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: ContestLook.gold)),
        child: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مبروك! ربحت ${r['amount_lyd'] ?? ''} د.ل', style: ContestLook.p.text(16, weight: FontWeight.w800, color: const Color(0xFF4A3000))),
              Text(r['credited'] == true ? 'الرصيد نزل في محفظتك' : 'الرصيد ينزل بعد مراجعة الفائزين', style: ContestLook.p.text(12.5, color: const Color(0xFF4A3000))),
            ]),
          ),
          const Icon(Icons.chevron_left_rounded, color: Color(0xFF4A3000)),
        ]),
      ),
    );
  }

  Widget _filters() {
    final p = ContestLook.p;
    Widget chip(String v, String label) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: ChoiceChip(
            label: Text(label, style: p.text(12.5, weight: FontWeight.w800, color: _side == v ? ContestLook.brand : p.sub)),
            selected: _side == v,
            showCheckmark: false,
            selectedColor: ContestLook.brand.withValues(alpha: .12),
            backgroundColor: p.field,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            onSelected: (_) {
              setState(() => _side = v);
              _load();
            },
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
      child: Row(children: [
        chip('all', 'الكل'),
        chip('riders', 'الزبائن'),
        chip('drivers', 'الكباتن'),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() => _sort = _sort == 'new' ? 'top' : 'new');
            _load();
          },
          child: Text(_sort == 'new' ? 'الأحدث ▾' : 'الأكثر إعجاباً ▾', style: p.text(12.5, weight: FontWeight.w800, color: p.sub)),
        ),
      ]),
    );
  }

  Widget _composer(Map<String, dynamic> post) {
    final p = ContestLook.p;
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget wrap(Widget child) => Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
          decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.line))),
          child: child,
        );
    if (post['can_predict'] == true) {
      return wrap(Row(children: [
        Expanded(
          child: InkWell(
            onTap: _compose,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(22)),
              child: Text('اكتب توقّعك…', style: p.text(14.5, color: p.sub, weight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _sendButton(_compose),
      ]));
    }
    if (post['can_comment'] != true) {
      return wrap(Row(children: [
        Icon(Icons.lock_rounded, size: 18, color: p.sub),
        const SizedBox(width: 6),
        Text('وصلت للحد المسموح من التعليقات', style: p.text(13.5, color: p.sub, weight: FontWeight.w700)),
      ]));
    }
    return wrap(Row(children: [
      if (post['my_entry'] != null && post['contest']?['status'] == 'open') ...[
        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF14A47B)),
        const SizedBox(width: 6),
      ],
      Expanded(
        child: TextField(
          controller: _text,
          maxLength: 200,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendPlain(),
          style: p.text(14.5),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: 'اكتب تعليق…',
            hintStyle: p.text(14.5, color: p.sub),
            filled: true,
            fillColor: p.field,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _sending ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2.4))) : _sendButton(_sendPlain),
    ]));
  }

  Widget _sendButton(VoidCallback onTap) => Material(
        color: ContestLook.brand,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(width: 42, height: 42, child: Icon(Icons.send_rounded, color: Colors.white, size: 19)),
        ),
      );
}

/// The prediction: the score (match), an option (choice) or a number, with optional words. Sent as
/// the person's comment; final once sent.
class PredictionSheet extends StatefulWidget {
  const PredictionSheet({super.key, required this.post});
  final Map<String, dynamic> post;
  @override
  State<PredictionSheet> createState() => _PredictionSheetState();
}

class _PredictionSheetState extends State<PredictionSheet> {
  int _home = 0, _away = 0;
  String? _option;
  final _number = TextEditingController();
  final _words = TextEditingController();
  bool _sending = false;
  String? _error;

  Map<String, dynamic> get c => Map<String, dynamic>.from(widget.post['contest'] ?? {});

  @override
  void dispose() {
    _number.dispose();
    _words.dispose();
    super.dispose();
  }

  bool get _ready => switch ('${c['kind']}') { 'match' => true, 'number' => _number.text.trim().isNotEmpty, _ => _option != null };

  Future<void> _send() async {
    if (!_ready || _sending) return;
    final answer = switch ('${c['kind']}') {
      'match' => {'home': _home, 'away': _away},
      'number' => {'number': int.tryParse(_number.text.trim()) ?? -1},
      _ => {'option': _option},
    };
    setState(() {
      _sending = true;
      _error = null;
    });
    final (data, error) = await ContestsApi.comment((widget.post['id'] as num).toInt(), body: _words.text, answer: answer);
    if (!mounted) return;
    if (data != null) return Navigator.of(context).pop(data);
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ContestLook.p;
    final kind = '${c['kind']}';
    final teams = c['teams'] is Map ? Map<String, dynamic>.from(c['teams']) : <String, dynamic>{};
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: p.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 12),
              Text('توقّعك', style: p.text(19, weight: FontWeight.w800)),
              Text('${c['question'] ?? ''}', style: p.text(13.5, color: p.sub)),
              const SizedBox(height: 12),
              if (kind == 'match')
                Row(children: [
                  Expanded(child: _team(teams['home'], teams['away'])),
                  _stepper(_home, (v) => setState(() => _home = v)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(':', style: p.text(28, weight: FontWeight.w800))),
                  _stepper(_away, (v) => setState(() => _away = v)),
                  Expanded(child: _team(teams['away'], teams['home'])),
                ])
              else if (kind == 'number')
                TextField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: p.text(26, weight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: 'اكتب رقمك',
                    hintStyle: p.text(18, color: p.sub),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ContestLook.brand, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ContestLook.brand, width: 2)),
                  ),
                )
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final o in (c['options'] as List? ?? const []))
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 32 - 8) / 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: _option == '${o['key']}' ? ContestLook.brand.withValues(alpha: .1) : null,
                          side: BorderSide(color: _option == '${o['key']}' ? ContestLook.brand : p.line, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => setState(() => _option = '${o['key']}'),
                        child: Text('${o['label']}', style: p.text(14.5, weight: FontWeight.w800, color: _option == '${o['key']}' ? ContestLook.brand : p.ink)),
                      ),
                    ),
                ]),
              const SizedBox(height: 12),
              TextField(
                controller: _words,
                maxLength: 200,
                maxLines: 2,
                style: p.text(14),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'اكتب تعليق مع توقّعك (اختياري)',
                  hintStyle: p.text(14, color: p.sub),
                  filled: true,
                  fillColor: p.field,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFB7791F).withValues(alpha: p.dark ? .18 : .1), borderRadius: BorderRadius.circular(13)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFB7791F)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'توقّع واحد لكل حساب. بعد النشر ما تقدرش تبدّله ولا تمسحه.${c['hide_answers'] == true ? ' إجابتك تبان لك أنت بس لين تقفل المسابقة.' : ''}',
                      style: p.text(12.5, color: const Color(0xFF8A5A0F), height: 1.6),
                    ),
                  ),
                ]),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: p.text(13, color: const Color(0xFFE0243A), weight: FontWeight.w700))),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ContestLook.brand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _ready && !_sending ? _send : null,
                  child: _sending
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                      : Text('انشر توقّعي', style: p.text(16, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static String _initial(String name) {
    var t = name.trim().replaceFirst(RegExp(r'^ال'), '');
    if (RegExp(r'^[اأإآ]').hasMatch(t) && t.length > 1) t = t.substring(1);
    return t.isEmpty ? '' : t.characters.first;
  }

  /// The team's letter; when both teams start alike («الأهلي طرابلس» × «الأهلي بنغازي») the last word's.
  static String teamLetter(String name, String other) {
    final a = _initial(name);
    if (a.isNotEmpty && a == _initial(other)) {
      final words = name.trim().split(RegExp(r'\s+'));
      if (words.length > 1) return _initial(words.last);
    }
    return a;
  }

  Widget _team(dynamic t, dynamic o) {
    final p = ContestLook.p;
    final m = t is Map ? t : const {};
    final name = '${m['name'] ?? ''}';
    final letter = teamLetter(name, '${(o is Map ? o['name'] : null) ?? ''}');
    Color color;
    try {
      color = Color(int.parse('FF${'${m['color'] ?? '#0873FF'}'.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      color = ContestLook.brand;
    }
    return Column(children: [
      CircleAvatar(radius: 26, backgroundColor: color, child: Text(letter.isEmpty ? '؟' : letter, style: p.text(19, weight: FontWeight.w900, color: Colors.white))),
      const SizedBox(height: 4),
      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(12.5, weight: FontWeight.w800)),
    ]);
  }

  Widget _stepper(int v, ValueChanged<int> set) {
    final p = ContestLook.p;
    Widget b(String t, VoidCallback? on) => SizedBox(
          width: 42,
          height: 34,
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: p.field, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
            onPressed: on,
            child: Text(t, style: p.text(20, weight: FontWeight.w800, color: ContestLook.brand)),
          ),
        );
    return Column(children: [
      b('+', v < 20 ? () => set(v + 1) : null),
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('$v', style: p.text(36, weight: FontWeight.w800, height: 1))),
      b('−', v > 0 ? () => set(v - 1) : null),
    ]);
  }
}

/// Opens the contests from a push («النتيجة طلعت») or a share link (/c/<code>) once the home
/// screen is up and the person is signed in.
class ContestLink {
  static int? _pendingPost;
  static bool _pendingFeed = false;

  static bool handles(Map data) => data['push_type']?.toString() == 'contest_result';

  static void openPush(Map data) {
    _pendingPost = int.tryParse('${data['post_id'] ?? ''}');
    _pendingFeed = true;
    flush();
  }

  /// /c/<code> opened the app.
  static bool isLink(String? route) => RegExp(r'^/c/[A-Za-z0-9]{4,12}/?$').hasMatch(Uri.tryParse(route ?? '')?.path ?? route ?? '');

  static void openLink() {
    _pendingFeed = true;
    flush();
  }

  static void flush() {
    final nav = appNavigatorKey.currentState;
    if (!_pendingFeed || nav == null || bearerToken.isEmpty) return;
    _pendingFeed = false;
    final post = _pendingPost;
    _pendingPost = null;
    nav.push(MaterialPageRoute(builder: (_) => ContestsFeedPage(openPostId: post)));
  }
}


/// The home screen card, in the same place and look as the campaign cards: the post's picture,
/// what to do now (predict, see your prediction, see the result), and it opens «مسابقات تاكسيستا».
class ContestHomeCard extends StatelessWidget {
  const ContestHomeCard({super.key, required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final c = Map<String, dynamic>.from(post['contest'] ?? {});
    final counts = Map<String, dynamic>.from(post['counts'] ?? {});
    final n = ContestLook.count(((counts['comments'] ?? 0) as num).toInt());
    final status = '${c['status']}';
    final mine = post['my_entry'] != null;
    final won = post['my_result']?['won'] == true;
    final winnersPost = post['kind'] == 'winners';
    final teams = c['teams'] is Map ? c['teams'] as Map : null;
    final title = won
        ? 'مبروك! ربحت في مسابقة تاكسيستا'
        : (winnersPost || status == 'resolved' || status == 'paid')
            ? 'النتيجة طلعت! شوف الفائزين'
            : (teams != null ? 'توقّع: ${teams['home']?['name'] ?? ''} × ${teams['away']?['name'] ?? ''}' : '${c['question'] ?? 'مسابقات تاكسيستا'}');
    final sub = status == 'open' ? (mine ? 'توقّعك مسجّل ✓ · $n توقّع' : '$n توقّع · ${post['contest']?['prizes']?['riders']?['text'] ?? post['contest']?['prizes']?['drivers']?['text'] ?? 'مسابقة مجانية'}') : (status == 'closed' ? 'قفلت التوقعات · النتيجة قريب' : 'مسابقات تاكسيستا');
    final action = status == 'open' && !mine ? 'توقّع' : 'شوف';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContestsFeedPage(openPostId: status == 'open' && !mine ? (post['id'] as num).toInt() : null))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
            border: Border.all(color: won ? const Color(0xFFD69E2E) : const Color(0xffDCEBFF)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 42,
                height: 42,
                child: (post['image_url'] ?? '').toString().startsWith('http')
                    ? Image.network('${post['image_url']}', fit: BoxFit.cover, cacheWidth: 126, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1965BF)))
                    : const ColoredBox(color: Color(0xFF1965BF)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ContestLook.p.text(13, weight: FontWeight.w800, color: const Color(0xff10264A))),
                const SizedBox(height: 1),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ContestLook.p.text(11, color: const Color(0xff687994))),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(color: action == 'توقّع' ? ContestLook.brand : const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(99)),
              child: Text(action, style: ContestLook.p.text(12, weight: FontWeight.w800, color: action == 'توقّع' ? Colors.white : ContestLook.brand)),
            ),
          ]),
        ),
      ),
    );
  }
}
