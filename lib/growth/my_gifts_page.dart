import 'dart:async';

import 'package:flutter/material.dart';

import '../community/community_kit.dart';
import '../widgets/chat/chat_kit.dart';
import 'growth_api.dart';

/// «هداياي»: the rider's promotional balance and every gift with its state and the time it really
/// has left. The countdown starts from the server's seconds_left (a wrong phone clock cannot keep an
/// ended gift alive) and is refreshed from the server when it reaches zero or the page is pulled.
class MyGiftsPage extends StatefulWidget {
  final String? highlightRef;

  const MyGiftsPage({super.key, this.highlightRef});

  @override
  State<MyGiftsPage> createState() => _MyGiftsPageState();
}

class _MyGiftsPageState extends State<MyGiftsPage> {
  Map<String, dynamic>? _data;
  bool _loaded = false;
  String? _linkError;
  DateTime _loadedAt = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final ended = _gifts.any((g) => (g['seconds_left'] ?? 0) > 0 && _left(g) == Duration.zero);
      setState(() {});
      if (ended) _load();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  List<Map> get _gifts => (_data?['gifts'] is List) ? [for (final g in _data!['gifts'] as List) if (g is Map) g] : const [];

  Future<void> _load() async {
    if (widget.highlightRef != null && _data == null) {
      // opening the link records that the rider saw it; it never pays anything
      final one = await GrowthApi.offer(widget.highlightRef!);
      if (one != null && one.containsKey('_error')) _linkError = one['_error']?.toString();
    }
    final d = await GrowthApi.gifts();
    if (!mounted) return;
    setState(() {
      _data = d ?? _data;
      _loaded = true;
      _loadedAt = DateTime.now();
    });
  }

  Duration _left(Map g) {
    final secs = ((g['seconds_left'] ?? 0) as num).toInt() - DateTime.now().difference(_loadedAt).inSeconds;
    return Duration(seconds: secs < 0 ? 0 : secs);
  }

  static String countdown(Duration d) => MyGiftsPageCountdown.text(d);

  @override
  Widget build(BuildContext context) {
    final p = CommunityLook.palette;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: communityAppBar(context, 'هداياي'),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _data == null
                    ? ListView(children: [
                        const SizedBox(height: 140),
                        Center(child: Text('تعذر التحميل. اسحب للأسفل لإعادة المحاولة.', style: p.text(14, color: p.sub))),
                      ])
                    : _page(p),
              ),
      ),
    );
  }

  Widget _page(ChatPalette p) {
    final gifts = _gifts;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_linkError != null && _linkError!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_linkError!, style: p.text(13, color: p.sub)),
        ),
      CommunityCard(
        background: CommunityLook.goldBackground(p),
        child: Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: CommunityLook.gold, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('رصيد الهدايا', style: p.text(12.5, color: p.sub)),
              Text('${_data!['balance'] ?? '0 د.ل'}', style: p.text(24, weight: FontWeight.w800)),
              Text('رصيد ترويجي غير قابل للسحب', style: p.text(11.5, color: p.sub)),
            ]),
          ),
        ]),
      ),
      if (gifts.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('ما عندكش هدايا حاليًا.', style: p.text(14, color: p.sub))),
        ),
      for (final g in gifts) _gift(p, g),
      if ((_data!['rules'] ?? '').toString().isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: Text(_data!['rules'].toString(), style: p.text(12.5, color: p.sub, height: 1.7)),
        ),
    ]);
  }

  Widget _gift(ChatPalette p, Map g) {
    final live = g['state'] == 'active' || g['state'] == 'partly_used';
    final left = _left(g);
    final highlighted = widget.highlightRef != null && g['ref'] == widget.highlightRef;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlighted ? CommunityLook.gold : p.line, width: highlighted ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${g['title'] ?? 'هدية'}', style: p.text(15, weight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: live ? CommunityLook.good.withValues(alpha: 0.12) : p.field,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('${g['state_label']}', style: p.text(12, weight: FontWeight.w700, color: live ? CommunityLook.good : p.sub)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('القيمة ${g['amount']} · المتبقي ${g['remaining']}${(g['held_minor'] ?? 0) > 0 ? ' · محجوز لرحلة جارية' : ''}',
            style: p.text(13.5)),
        if (live)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.timer_outlined, size: 16, color: left.inHours < 6 ? const Color(0xFFDC2626) : p.sub),
              const SizedBox(width: 4),
              Text(countdown(left), style: p.text(13, weight: FontWeight.w700, color: left.inHours < 6 ? const Color(0xFFDC2626) : p.ink)),
            ]),
          ),
        const SizedBox(height: 6),
        Text('${g['text'] ?? ''}', style: p.text(12.5, color: p.sub, height: 1.6)),
      ]),
    );
  }
}

/// The countdown wording, apart so it can be tested without a server.
class MyGiftsPageCountdown {
  static String text(Duration d) {
    if (d == Duration.zero) return 'انتهت';
    final days = d.inDays;
    final h = d.inHours % 24;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    // words for days (a clock after Arabic text flips in RTL); the clock kept left-to-right
    if (days > 0) return 'باقي ${days == 1 ? 'يوم' : days == 2 ? 'يومين' : '$days أيام'}${h > 0 ? ' و$h ساعة' : ''}';
    return 'باقي \u2066${two(h)}:${two(m)}:${two(s)}\u2069';
  }
}
