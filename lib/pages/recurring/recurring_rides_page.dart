import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../functions/calls/admin_call_controller.dart' show appNavigatorKey;
import '../../functions/functions.dart';
import '../../functions/recurring_api.dart';
import '../../functions/recurring_push.dart';
import '../../functions/live_activity.dart';

const _blue = Color(0xff0873FF);
const _navy = Color(0xff0B2A5B);
const _ink = Color(0xff12121D);
const _muted = Color(0xff6B7280);
const _line = Color(0xffE6EAF2);
const _bg = Color(0xffF3F6FB);
const _okBg = Color(0xffE7F7EE);
const _ok = Color(0xff0F8A4B);

TextStyle _t(double size, {FontWeight w = FontWeight.w600, Color c = _ink, double h = 1.45}) =>
    GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: h);

const _months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

String _clock(String? hhmm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm ?? '');
  if (m == null) return hhmm ?? '';
  final h = int.parse(m.group(1)!);
  return '${(h % 12) == 0 ? 12 : h % 12}:${m.group(2)} ${h < 12 ? 'صباحًا' : (h < 15 ? 'ظهرًا' : 'مساءً')}';
}

String _place(Map? p, String fallback) {
  final a = (p?['address'] ?? '').toString();
  if (a.startsWith('المنزل') || a.startsWith('البيت')) return 'البيت';
  if (a.startsWith('العمل') || a.startsWith('الشغل')) return 'الشغل';
  return a.isEmpty ? fallback : a.split('—').first.trim();
}

/// «رحلاتي المتكررة»: his schedules; with one schedule it opens that schedule directly.
class RecurringRidesPage extends StatefulWidget {
  const RecurringRidesPage({super.key});

  @override
  State<RecurringRidesPage> createState() => _RecurringRidesPageState();
}

class _RecurringRidesPageState extends State<RecurringRidesPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await RecurringApi.list();
    if (!mounted) return;
    if (r.status == 200) RecurringApi.rides.value = r.list;
    setState(() {
      _loading = false;
      _error = r.status == 200 || r.status == 404 ? null : r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: RecurringApi.rides,
              builder: (context, rides, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const _Header(title: 'رحلاتي المتكررة', sub: 'مشاويرك اللي تتكرر كل أسبوع'),
                  const SizedBox(height: 14),
                  if (_loading && rides.isEmpty) ...[for (var i = 0; i < 2; i++) const _Skeleton(height: 120)],
                  if (_error != null) _Note(text: _error!, bad: true),
                  if (!_loading && rides.isEmpty && _error == null) const _Empty(),
                  for (var i = 0; i < rides.length; i++)
                    _Appear(
                      index: i,
                      child: _ScheduleCard(
                        ride: rides[i],
                        onOpen: () => Navigator.of(context).push(_route(RecurringRidePage(uuid: '${rides[i]['id']}', initial: rides[i]))).then((_) => _load()),
                      ),
                    ),
                  const _ReminderTryout(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

PageRoute<T> _route<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(position: Tween(begin: const Offset(-0.06, 0), end: Offset.zero).animate(c), child: child),
        );
      },
    );

/// One schedule, the way the design shows it: its name, days and time, and how tomorrow looks.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.ride, required this.onOpen});
  final Map<String, dynamic> ride;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final next = ride['next'] is Map ? Map<String, dynamic>.from(ride['next']) : null;
    final active = ride['status'] == 'active';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(colors: [_navy, Color(0xff1556B8)], begin: Alignment.topRight, end: Alignment.bottomLeft) : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: active ? null : Border.all(color: _line),
            boxShadow: [BoxShadow(color: _navy.withValues(alpha: active ? .22 : .05), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: .14) : const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(15)),
              child: Icon(Icons.repeat_rounded, color: active ? Colors.white : _blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${ride['label'] ?? ''}', style: _t(17, w: FontWeight.w800, c: active ? Colors.white : _ink)),
                Text('${ride['status_label'] ?? ''} · ${ride['pattern'] ?? ''}', style: _t(12.5, c: active ? Colors.white70 : _muted), maxLines: 2),
                if (next != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${next['day_word'] == 'بكرة' ? 'غدًا' : next['date']} ${_clock('${next['time']}')} · ${next['label']}',
                        style: _t(13, w: FontWeight.w700, c: active ? Colors.white : _blue)),
                  ),
              ]),
            ),
            Icon(Icons.chevron_left_rounded, color: active ? Colors.white : _muted),
          ]),
        ),
      ),
    );
  }
}

/// One schedule: the route, the price, tomorrow's question and this week's days.
class RecurringRidePage extends StatefulWidget {
  const RecurringRidePage({super.key, required this.uuid, this.initial, this.focusOccurrence});
  final String uuid;
  final Map<String, dynamic>? initial;

  /// opened from the evening reminder: that day's answer card is shown first
  final int? focusOccurrence;

  @override
  State<RecurringRidePage> createState() => _RecurringRidePageState();
}

class _RecurringRidePageState extends State<RecurringRidePage> {
  Map<String, dynamic>? _r;
  String? _error;

  @override
  void initState() {
    super.initState();
    _r = widget.initial;
    _load();
    RecurringPush.lastAnswer.addListener(_load);
  }

  @override
  void dispose() {
    RecurringPush.lastAnswer.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final r = await RecurringApi.show(widget.uuid);
    if (!mounted) return;
    setState(() {
      if (r.ok) _r = r.data;
      _error = r.ok ? null : r.message;
    });
    unawaited(RecurringApi.refresh(force: true));
  }

  List<Map<String, dynamic>> get _week {
    final list = (_r?['days_list'] is List ? (_r!['days_list'] as List) : const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day);
    return list.where((d) {
      final at = DateTime.tryParse('${d['date']}');
      return at != null && !at.isBefore(from);
    }).take(7).toList();
  }

  Map<String, dynamic>? get _question {
    final n = _r?['next'];
    if (n is! Map || _r?['status'] != 'active') return null;
    final next = Map<String, dynamic>.from(n);
    if (widget.focusOccurrence != null && next['id'] != widget.focusOccurrence) {
      final d = _week.where((x) => x['id'] == widget.focusOccurrence).toList();
      if (d.isNotEmpty) return {...d.first, 'answerable': true, 'day_word': ''};
    }
    return next['answerable'] == true ? next : null;
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Header(title: '${r?['label'] ?? 'رحلتي المتكررة'}', sub: r == null ? '' : '${r['status_label']} · ${r['pattern']}'),
                const SizedBox(height: 14),
                if (r == null && _error == null) const _Skeleton(height: 260),
                if (_error != null) _Note(text: _error!, bad: true),
                if (r != null) ...[
                  _Appear(index: 0, child: _RouteCard(r: r)),
                  if (_question != null) ...[
                    const SizedBox(height: 14),
                    _Appear(index: 1, child: TomorrowAnswerCard(ride: r, day: _question!, onAnswered: _load)),
                  ],
                  const SizedBox(height: 18),
                  Row(children: [
                    Text('هذا الأسبوع', style: _t(16, w: FontWeight.w800)),
                    const Spacer(),
                    Text('اضغط على أي يوم', style: _t(12.5, c: _muted)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
                    child: Column(children: [
                      for (var i = 0; i < _week.length; i++) _Appear(index: i + 2, child: _DayRow(day: _week[i], last: i == _week.length - 1, onTap: () => _openDay(_week[i]))),
                      if (_week.isEmpty) Padding(padding: const EdgeInsets.all(18), child: Text('ما فيش أيام هذا الأسبوع.', style: _t(13, c: _muted))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('لو ما رديتش على تذكير الليلة، المشوار ماشي في موعده عادي. التخطي قبل الموعد بأكثر من نص ساعة ما عليه أي رسوم.',
                      style: _t(12.5, c: _muted, w: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDay(Map<String, dynamic> d) {
    final r = _r;
    if (r == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 14),
            Text(_dayTitle(d), style: _t(19, w: FontWeight.w800)),
            Text('${d['label']}${d['answer_label'] != null ? ' · ${d['answer_label']}' : ''}', style: _t(13.5, c: _muted)),
            const SizedBox(height: 14),
            if (['scheduled', 'searching', 'reserved', 'driver_ready', 'skipped'].contains(d['state']))
              TomorrowAnswerCard(ride: r, day: {...d, 'answerable': true}, flat: true, onAnswered: () {
                Navigator.of(ctx).maybePop();
                _load();
              })
            else
              _Note(text: 'هذا اليوم ${d['label']}.'),
          ]),
        ),
      ),
    );
  }
}

String _dayTitle(Map d) {
  final at = DateTime.tryParse('${d['date']}');
  if (at == null) return '${d['date']}';
  return '${_days[at.weekday - 1]} ${at.day} ${_months[at.month - 1]} · ${_clock('${d['time']}')}';
}

/// «مشوار الغد»: ✅ تأكيد / ⏭ تخطي, the same two answers as on the notification (for a phone where
/// the buttons do not show, or when he opens the app). The result is the server's own words.
class TomorrowAnswerCard extends StatefulWidget {
  const TomorrowAnswerCard({super.key, required this.ride, required this.day, this.onAnswered, this.flat = false});
  final Map<String, dynamic> ride;
  final Map<String, dynamic> day;
  final VoidCallback? onAnswered;
  final bool flat;

  @override
  State<TomorrowAnswerCard> createState() => _TomorrowAnswerCardState();
}

class _TomorrowAnswerCardState extends State<TomorrowAnswerCard> {
  String? _busy;
  String? _result;
  bool _failed = false;

  Future<void> _answer(String what) async {
    if (_busy != null) return; // one tap at a time; the server also keeps one answer per day
    if (what == 'skip') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تخطي ${_dayTitle(widget.day)}؟', style: _t(17, w: FontWeight.w800)),
            content: Text('ما يجيك حد هذا اليوم${widget.day['state'] == 'reserved' || widget.day['state'] == 'driver_ready' ? '، والسائق اللي حجزه يتبلغ' : ''}. باقي الأيام كما هي، وما عليك أي رسوم.',
                style: _t(14, w: FontWeight.w500)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('لا', style: _t(14))),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: _ink), child: Text('نعم، تخطي', style: _t(14, c: Colors.white))),
            ],
          ),
        ),
      );
      if (sure != true) return;
    }
    setState(() => _busy = what);
    final r = await RecurringApi.answer('${widget.ride['id']}', '${widget.day['date']}', what);
    if (!mounted) return;
    setState(() {
      _busy = null;
      _failed = !r.ok;
      _result = r.message;
    });
    if (r.ok) {
      unawaited(LiveActivity.endDay('${widget.day['id'] ?? ''}')); // its card leaves the lock screen
      widget.onAnswered?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.day;
    final answered = d['answer'] == 'coming' ? '✅ أكدت هذا المشوار' : (d['state'] == 'skipped' ? '⏭ تخطيت هذا المشوار' : null);
    final title = d['day_word'] == 'بكرة' ? 'مشوار الغد · ${_clock('${d['time']}')}' : _dayTitle(d);
    final body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!widget.flat) ...[
        Row(children: [
          const Text('🚕', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: _t(16.5, w: FontWeight.w800, c: Colors.white))),
        ]),
        Text(answered ?? 'هل ما زلت تحتاجه؟ ${d['label'] != null ? '· ${d['label']}' : ''}', style: _t(13, c: Colors.white70)),
        const SizedBox(height: 12),
      ],
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(a), child: c)),
        child: _result != null
            ? Container(
                key: ValueKey(_result),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _failed ? const Color(0xffFDECEC) : _okBg, borderRadius: BorderRadius.circular(14)),
                child: Text(_result!, style: _t(13.5, c: _failed ? const Color(0xffB91C1C) : _ok, w: FontWeight.w700)),
              )
            : Row(key: const ValueKey('buttons'), children: [
                Expanded(child: _AnswerButton(label: d['answer'] == 'coming' ? 'مأكد' : 'تأكيد', icon: Icons.check_rounded, primary: true, busy: _busy == 'attend', onTap: () => _answer('attend'))),
                const SizedBox(width: 10),
                Expanded(child: _AnswerButton(label: d['state'] == 'skipped' ? 'متخطى' : 'تخطي', icon: Icons.skip_next_rounded, busy: _busy == 'skip', dark: !widget.flat, onTap: d['state'] == 'skipped' ? null : () => _answer('skip'))),
              ]),
      ),
      if (_failed && _result != null)
        TextButton(onPressed: () => setState(() => _result = null), child: Text('جرب مرة ثانية', style: _t(13, c: widget.flat ? _blue : Colors.white))),
    ]);
    if (widget.flat) return body;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_navy, Color(0xff1556B8)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _navy.withValues(alpha: .25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: body,
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.onTap, this.primary = false, this.busy = false, this.dark = false, this.icon});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? _blue : (dark ? Colors.white.withValues(alpha: .14) : const Color(0xffF1F4F9));
    final fg = primary || dark ? Colors.white : _ink;
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: onTap == null ? bg.withValues(alpha: .5) : bg, borderRadius: BorderRadius.circular(16)),
        child: busy
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 6)],
                Text(label, style: _t(15, w: FontWeight.w800, c: fg)),
              ]),
      ),
    );
  }
}

/// The route as the design draws it: the road (from the server) or a straight dashed line, both ends.
class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.r});
  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final price = r['price'] is Map ? Map<String, dynamic>.from(r['price']) : null;
    final from = _place(r['pick'] as Map?, 'الانطلاق');
    final to = _place(r['drop'] as Map?, 'الوجهة');
    final pays = num.tryParse('${price?['rider_pays'] ?? ''}');
    final official = num.tryParse('${price?['official'] ?? ''}');
    final discount = num.tryParse('${price?['discount'] ?? 0}') ?? 0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _navy.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(children: [
        SizedBox(height: 170, width: double.infinity, child: _RouteSketch(r: r)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$from ← $to', style: _t(17, w: FontWeight.w800)),
                Text('${r['pickup_time']} · ${r['payment']} · أي سائق متاح', style: _t(13, c: _muted)),
              ]),
            ),
            if (pays != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(pays.toStringAsFixed(2), style: _t(18, w: FontWeight.w800)),
                if (discount > 0 && official != null)
                  Text.rich(TextSpan(children: [
                    TextSpan(text: official.toStringAsFixed(2), style: _t(12, c: _muted).copyWith(decoration: TextDecoration.lineThrough)),
                    TextSpan(text: ' خصم تاكسيستا', style: _t(12, c: _muted)),
                  ]))
                else
                  Text('د.ل لكل مشوار', style: _t(12, c: _muted)),
              ]),
          ]),
        ),
      ]),
    );
  }
}

class _RouteSketch extends StatefulWidget {
  const _RouteSketch({required this.r});
  final Map<String, dynamic> r;

  @override
  State<_RouteSketch> createState() => _RouteSketchState();
}

class _RouteSketchState extends State<_RouteSketch> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final pts = <Offset>[];
    final path = r['route'] is Map ? (r['route']['path']) : null;
    if (path is List && path.length > 1) {
      for (final p in path) {
        if (p is List && p.length >= 2) pts.add(Offset((p[1] as num).toDouble(), (p[0] as num).toDouble()));
      }
    } else if (r['pick'] is Map && r['drop'] is Map) {
      pts.add(Offset((r['pick']['lng'] as num).toDouble(), (r['pick']['lat'] as num).toDouble()));
      pts.add(Offset((r['drop']['lng'] as num).toDouble(), (r['drop']['lat'] as num).toDouble()));
    }
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _draw,
      builder: (_, __) => CustomPaint(painter: _RoutePainter(pts, reduce ? 1 : Curves.easeInOutCubic.transform(_draw.value), straight: path is! List || path.length < 2)),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.pts, this.t, {required this.straight});
  final List<Offset> pts;
  final double t;
  final bool straight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xffEEF2F8));
    final grid = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    for (double x = -size.height; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * .55, size.height), grid);
    }
    for (double y = 18; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), grid);
    }
    if (pts.length < 2) return;
    var minX = pts.map((p) => p.dx).reduce(math.min), maxX = pts.map((p) => p.dx).reduce(math.max);
    var minY = pts.map((p) => p.dy).reduce(math.min), maxY = pts.map((p) => p.dy).reduce(math.max);
    final w = math.max(maxX - minX, 1e-4), h = math.max(maxY - minY, 1e-4);
    final scale = math.min((size.width - 60) / w, (size.height - 50) / h);
    final ox = (size.width - w * scale) / 2, oy = (size.height - h * scale) / 2;
    // east is right on a map; the route keeps the real shape
    Offset at(Offset p) => Offset(ox + (p.dx - minX) * scale, oy + (maxY - p.dy) * scale);
    final route = Path()..moveTo(at(pts.first).dx, at(pts.first).dy);
    for (final p in pts.skip(1)) {
      route.lineTo(at(p).dx, at(p).dy);
    }
    final metric = route.computeMetrics().toList();
    final shown = Path();
    for (final m in metric) {
      shown.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    canvas.drawPath(shown, Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(shown, Paint()
      ..color = _blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    void pin(Offset c, Color color) {
      canvas.drawCircle(c, 11, Paint()..color = Colors.white);
      canvas.drawCircle(c, 7, Paint()..color = color);
    }

    pin(at(pts.first), _ok);
    if (t > .98) pin(at(pts.last), _blue);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.t != t || old.pts != pts;
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.last, required this.onTap});
  final Map<String, dynamic> day;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse('${day['date']}');
    final state = '${day['state']}';
    final (IconData icon, Color fg, Color bg) = switch (state) {
      'reserved' || 'driver_ready' || 'driver_on_way' || 'trip_started' => (Icons.person_outline_rounded, _blue, const Color(0xffEAF2FF)),
      'skipped' || 'cancelled' => (Icons.skip_next_rounded, _muted, const Color(0xffF1F4F9)),
      'completed' => (Icons.check_rounded, _ok, _okBg),
      'no_driver' || 'failed' => (Icons.error_outline_rounded, const Color(0xffB91C1C), const Color(0xffFDECEC)),
      _ => (Icons.schedule_rounded, _blue, const Color(0xffEAF2FF)),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: _line))),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: const Color(0xffEDF2FA), borderRadius: BorderRadius.circular(14)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${at?.day ?? ''}', style: _t(16, w: FontWeight.w800, c: _navy, h: 1.1)),
              Text(at == null ? '' : _months[at.month - 1].substring(0, 3), style: _t(10.5, c: _muted, h: 1.1)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_dayTitle(day), style: _t(14.5, w: FontWeight.w800)),
              Text(day['answer_label'] != null ? '${day['label']} · ${day['answer'] == 'coming' ? 'أكدت' : 'تخطيت'}' : '${day['label']}', style: _t(12.5, c: _muted)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 4),
              Text(state == 'scheduled' ? 'مجدول' : '${day['label']}', style: _t(12, w: FontWeight.w800, c: fg)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.sub});
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Pressable(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _navy.withValues(alpha: .06), blurRadius: 12)]),
          child: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _t(22, w: FontWeight.w800, h: 1.25)),
          if (sub.isNotEmpty) Text(sub, style: _t(13, c: _muted)),
        ]),
      ),
    ]);
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.bad = false});
  final String text;
  final bool bad;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bad ? const Color(0xffFDECEC) : const Color(0xffF1F4F9), borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: _t(13.5, c: bad ? const Color(0xffB91C1C) : _ink, w: FontWeight.w600)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
        child: Column(children: [
          const Icon(Icons.repeat_rounded, size: 40, color: _blue),
          const SizedBox(height: 8),
          Text('ما عندكش رحلات متكررة', style: _t(16, w: FontWeight.w800)),
          Text('مشوار تعمله كل يوم أو كل أسبوع؟ كلم دعم تاكسيستا ونجهزولك جدول، وكل يوم يجيك سائق متاح في موعدك.', textAlign: TextAlign.center, style: _t(13, c: _muted)),
        ]),
      );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.height});
  final double height;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: .45, end: 1.0).animate(_a),
        child: Container(margin: const EdgeInsets.only(bottom: 12), height: widget.height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22))),
      );
}

/// Rows come in one after another (skipped when the phone asks for less motion).
class _Appear extends StatelessWidget {
  const _Appear({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + math.min(index, 8) * 55),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: c)),
      child: child,
    );
  }
}

/// sinks a little under the finger
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                widget.onTap!();
              },
        child: AnimatedScale(scale: _down ? .97 : 1, duration: const Duration(milliseconds: 110), child: widget.child),
      );
}

/// a notification was tapped (the question itself, not a button): open that schedule at that day
class RecurringLink {
  static Map<String, dynamic>? _pending;

  static void open(Map data) {
    _pending = Map<String, dynamic>.from(data);
    unawaited(_flush());
  }

  static void appReady() => unawaited(_flush());

  static Future<void> _flush() async {
    final data = _pending;
    final nav = appNavigatorKey.currentState;
    if (data == null || nav == null) return;
    if (bearerToken.isEmpty || userDetails.isEmpty) return; // signed out, or the session is still loading
    final uuid = '${data['recurring_id'] ?? ''}';
    if (uuid.isEmpty) return;
    _pending = null;
    nav.push(_route(RecurringRidePage(uuid: uuid, focusOccurrence: int.tryParse('${data['occurrence_id'] ?? ''}'))));
  }
}


/// TestFlight only (never in the App Store build): try the evening reminder's look on this iPhone -
/// the lock-screen card with both buttons, and the plain notification. Nothing reaches the server.
class _ReminderTryout extends StatefulWidget {
  const _ReminderTryout();

  @override
  State<_ReminderTryout> createState() => _ReminderTryoutState();
}

class _ReminderTryoutState extends State<_ReminderTryout> {
  Map<String, dynamic> _info = const {};
  String? _note;

  @override
  void initState() {
    super.initState();
    LiveActivity.info().then((i) {
      if (mounted) setState(() => _info = i);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_info['tryout'] != true) return const SizedBox.shrink();
    final card = _info['supported'] == true;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD6E4F7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('🧪 تجربة شكل تذكير «مشوارك غدًا»', style: _t(15, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('للتجربة في TestFlight فقط. ما يتسجل شي في حسابك، وما يوصل شي للسائقين.', style: _t(12.5, w: FontWeight.w500, c: Colors.black54)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: card
              ? () async {
                  final r = await LiveActivity.demoCard();
                  if (mounted) setState(() => _note = r == 'ok' ? 'البطاقة بدأت. اقفل الشاشة وشوفها على شاشة القفل، وجرب الزرين.' : r);
                }
              : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1466DB), minimumSize: const Size.fromHeight(44)),
          child: Text(card ? 'بطاقة شاشة القفل (الزرين ظاهرين)' : 'بطاقة شاشة القفل تحتاج iOS 17.2 أو أحدث', style: _t(14, c: Colors.white)),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: card
              ? () async {
                  final r = await LiveActivity.demoCardAlert();
                  if (mounted) {
                    setState(() => _note = r == 'ok'
                        ? 'افتح فيسبوك أو أي تطبيق ثاني توا. بعد 8 ثواني البطاقة تنفتح كبيرة فوقه لثواني، جرب الزرين وهي مفتوحة.'
                        : r);
                  }
                }
              : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B0B0F), minimumSize: const Size.fromHeight(44)),
          child: Text('وأنت في تطبيق ثاني (بعد 8 ثواني)', style: _t(14, c: Colors.white)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            await LiveActivity.demoNotification();
            if (mounted) setState(() => _note = 'الإشعار يوصل بعد 5 ثواني. اقفل الشاشة الآن، ثم اضغط عليه ضغطة مطوّلة باش تبان الأزرار.');
          },
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: Text('الإشعار العادي (بعد 5 ثواني)', style: _t(14)),
        ),
        if (_note != null) ...[const SizedBox(height: 10), Text(_note!, style: _t(13, w: FontWeight.w600, c: const Color(0xFF1466DB)))],
      ]),
    );
  }
}
