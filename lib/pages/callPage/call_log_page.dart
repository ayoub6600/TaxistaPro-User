import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_api.dart';
import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/chat/chat_kit.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../chatPage/chat_page.dart';
import '../chatPage/trip_chat_page.dart';

/// Recent calls - with drivers and with the administration: incoming, outgoing, missed - with
/// calling back and the chat. Only the call's details are kept, never its sound.
class CallLogPage extends StatefulWidget {
  const CallLogPage({super.key});

  @override
  State<CallLogPage> createState() => _CallLogPageState();
}

class _CallLogPageState extends State<CallLogPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  String? _calling;

  bool get _ar => languageDirection == 'rtl';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminCallApi.log();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.ok ? null : r.message;
      if (r.ok) _items = r.list;
    });
  }

  bool _matches(Map<String, dynamic> c, String filter) {
    if (filter == 'missed') return c['missed'] == true;
    if (filter == 'out') return c['outgoing'] == true;
    if (filter == 'in') return c['outgoing'] != true && c['missed'] != true;
    return true;
  }

  Future<void> _callBack(Map<String, dynamic> c) async {
    final cb = Map<String, dynamic>.from(c['callback'] ?? {});
    setState(() => _calling = '${c['id']}');
    final problem = cb['to'] == 'admin'
        ? await AdminCallController.instance.callAdministration()
        : await AdminCallController.instance.callDriver(requestId: (cb['request_id'] ?? c['request_id'])?.toString());
    if (!mounted) return;
    setState(() => _calling = null);
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(problem),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: _t('مراسلة', 'Write'), onPressed: () => _chat(c)),
      ));
    }
  }

  void _chat(Map<String, dynamic> c) {
    if (c['peer_type'] == 'admin') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminChatPage()));
      return;
    }
    final requestId = (c['request_id'] ?? (c['callback'] is Map ? c['callback']['request_id'] : null))?.toString();
    if (userRequestData.isNotEmpty && userRequestData['id']?.toString() == requestId) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
      return;
    }
    if (requestId == null || requestId.isEmpty) return;
    final peer = Map<String, dynamic>.from(c['peer'] ?? {});
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TripChatPage(
        requestId: requestId,
        driverName: peer['name']?.toString() ?? _t('السائق', 'Driver'),
        driverPhoto: peer['photo']?.toString(),
        details: peer['car']?.toString(),
      ),
    ));
  }

  String _duration(int secs) => '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = ChatPalette.current();
    final shown = _items.where((c) => _matches(c, _filter)).toList();
    final missedCount = _items.where((c) => c['missed'] == true).length;
    return Directionality(
      textDirection: _ar ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: p.background,
        body: Column(children: [
          Container(
            decoration: BoxDecoration(color: p.surface, border: Border(bottom: BorderSide(color: p.line))),
            padding: EdgeInsets.fromLTRB(6, MediaQuery.of(context).padding.top + 6, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: Icon(Icons.arrow_back_rounded, color: p.ink),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t('سجل المكالمات', 'Calls'), style: p.text(19, weight: FontWeight.w700, height: 1.25)),
                    Text(_t('مكالمات مجانية عبر تطبيق تاكسيستا', 'Free calls through the Taxista app'),
                        style: p.text(12.5, color: p.sub, height: 1.3)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Row(children: [
                  for (final f in [
                    ['all', _t('الكل', 'All')],
                    ['missed', _t('الفائتة', 'Missed')],
                    ['in', _t('الواردة', 'Incoming')],
                    ['out', _t('الصادرة', 'Outgoing')],
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _FilterPill(
                        palette: p,
                        label: f[1],
                        selected: _filter == f[0],
                        badge: f[0] == 'missed' && missedCount > 0 ? '$missedCount' : null,
                        onTap: () => setState(() => _filter = f[0]),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              color: theme,
              onRefresh: _load,
              child: _loading
                  ? ListView(children: [
                      const SizedBox(height: 160),
                      Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.6, color: theme))),
                    ])
                  : (_error != null || shown.isEmpty)
                      ? ListView(children: [
                          const SizedBox(height: 110),
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(color: theme.withValues(alpha: p.dark ? 0.2 : 0.09), shape: BoxShape.circle),
                              child: Icon(_error != null ? Icons.wifi_off_rounded : Icons.call_rounded, color: theme, size: 36),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error ??
                                (_filter == 'missed'
                                    ? _t('لا توجد مكالمات فائتة', 'No missed calls')
                                    : _t('لا توجد مكالمات بعد', 'No calls yet')),
                            textAlign: TextAlign.center,
                            style: p.text(17, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _t('مكالماتك مع السائقين ومع دعم تاكسيستا تظهر هنا، ويمكنك معاودة الاتصال أو المراسلة منها.',
                                  'Calls with drivers and Taxista support appear here; call back or write from here.'),
                              textAlign: TextAlign.center,
                              style: p.text(13.5, color: p.sub, height: 1.6),
                            ),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                          children: _rows(p, shown),
                        ),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _rows(ChatPalette p, List<Map<String, dynamic>> shown) {
    final rows = <Widget>[];
    DateTime? day;
    for (final c in shown) {
      final at = ChatTime.parse(c['at']);
      if (at != null && (day == null || !ChatTime.sameDay(day, at))) {
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(ChatTime.dayLabel(at, _ar), style: p.text(13, weight: FontWeight.w700, color: p.sub)),
        ));
        day = at;
      }
      rows.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: _callRow(p, c, at)));
    }
    return rows;
  }

  Widget _callRow(ChatPalette p, Map<String, dynamic> c, DateTime? at) {
    const red = Color(0xFFDC2626);
    const green = Color(0xFF16A34A);
    final peer = Map<String, dynamic>.from(c['peer'] ?? {});
    final missed = c['missed'] == true;
    final out = c['outgoing'] == true;
    final admin = c['peer_type'] == 'admin';
    final secs = int.tryParse('${c['duration_seconds'] ?? ''}');
    final photo = peer['photo']?.toString();
    final direction = missed ? _t('فائتة', 'Missed') : (out ? _t('صادرة', 'Outgoing') : _t('واردة', 'Incoming'));
    final line = [
      direction,
      if (!missed && c['status_label'] != null && '${c['status_label']}'.isNotEmpty) '${c['status_label']}',
      if (secs != null && secs > 0) _duration(secs),
    ].join(' · ');
    final badgeColor = missed ? red : (out ? green : theme);

    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _chat(c),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.line)),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 46,
                height: 46,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.withValues(alpha: p.dark ? 0.22 : 0.1)),
                child: photo != null && photo.isNotEmpty && !admin
                    ? Image.network(photo,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.local_taxi_rounded, color: theme))
                    : Icon(admin ? Icons.support_agent_rounded : Icons.local_taxi_rounded, color: theme),
              ),
              PositionedDirectional(
                end: -3,
                bottom: -3,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle, border: Border.all(color: p.surface, width: 2)),
                  child: Icon(missed ? Icons.call_missed_rounded : (out ? Icons.call_made_rounded : Icons.call_received_rounded),
                      size: 11, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(peer['name']?.toString() ?? (admin ? _t('دعم تاكسيستا', 'Taxista Support') : '—'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p.text(15, weight: FontWeight.w700, color: missed ? red : p.ink, height: 1.3)),
                const SizedBox(height: 2),
                Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: p.text(12.5, color: missed ? red : p.sub, height: 1.3)),
              ]),
            ),
            if (at != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
                child: Text(ChatTime.clock(at, _ar), textDirection: ui.TextDirection.ltr, style: p.text(11.5, color: p.sub)),
              ),
            _RoundIcon(
              icon: Icons.call_rounded,
              color: green,
              tooltip: _t('معاودة الاتصال المجاني', 'Call back for free'),
              busy: _calling == '${c['id']}',
              onTap: () => _callBack(c),
            ),
            const SizedBox(width: 6),
            _RoundIcon(
              icon: Icons.chat_bubble_rounded,
              color: theme,
              tooltip: _t('المحادثة', 'Chat'),
              onTap: () => _chat(c),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final ChatPalette palette;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.palette, required this.label, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Material(
      color: selected ? theme : p.field,
      shape: StadiumBorder(side: BorderSide(color: selected ? theme : p.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: p.text(13.5, weight: FontWeight.w700, color: selected ? Colors.white : p.ink)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                child: Text(badge!,
                    style: p.text(11, weight: FontWeight.w800, color: selected ? const Color(0xFFDC2626) : Colors.white)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool busy;

  const _RoundIcon({required this.icon, required this.color, required this.tooltip, required this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Center(
              child: busy
                  ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(icon, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
