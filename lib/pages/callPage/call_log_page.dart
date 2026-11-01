import 'package:flutter/material.dart';

import '../../functions/calls/admin_call_api.dart';
import '../../functions/calls/admin_call_controller.dart';
import '../../functions/functions.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../chatPage/chat_page.dart';

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

  List<Map<String, dynamic>> get _shown => _items.where((c) {
        if (_filter == 'missed') return c['missed'] == true;
        if (_filter == 'out') return c['outgoing'] == true;
        if (_filter == 'in') return c['outgoing'] != true && c['missed'] != true;
        return true;
      }).toList();

  String _ago(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'الآن';
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    return '${at.day}/${at.month} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _callBack(Map<String, dynamic> c) async {
    final cb = Map<String, dynamic>.from(c['callback'] ?? {});
    final problem = cb['to'] == 'admin'
        ? await AdminCallController.instance.callAdministration()
        : await AdminCallController.instance.callDriver(requestId: cb['request_id']?.toString());
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem), behavior: SnackBarBehavior.floating));
    }
  }

  void _chat(Map<String, dynamic> c) {
    if (c['peer_type'] == 'admin') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminChatPage()));
      return;
    }
    if (userRequestData.isNotEmpty && userRequestData['id']?.toString() == c['request_id']?.toString()) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محادثة الرحلة متاحة أثناء الرحلة فقط.'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1D4ED8);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل المكالمات', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                for (final f in const [['all', 'الكل'], ['missed', 'الفائتة'], ['in', 'الواردة'], ['out', 'الصادرة']])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(f[1]),
                      selected: _filter == f[0],
                      onSelected: (_) => setState(() => _filter = f[0]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null || _shown.isEmpty)
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(_error != null ? Icons.wifi_off : Icons.call_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error ?? (_filter == 'missed' ? 'لا مكالمات فائتة' : 'لا توجد مكالمات بعد'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    ])
                  : ListView.separated(
                      itemCount: _shown.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _shown[i];
                        final peer = Map<String, dynamic>.from(c['peer'] ?? {});
                        final missed = c['missed'] == true;
                        final out = c['outgoing'] == true;
                        final secs = int.tryParse('${c['duration_seconds'] ?? ''}');
                        final line = [
                          out ? 'صادرة' : 'واردة',
                          c['status_label'],
                          if (secs != null && secs > 0) '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                        ].join(' · ');
                        final photo = peer['photo']?.toString();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: blue.withValues(alpha: 0.12),
                            foregroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: Icon(c['peer_type'] == 'admin' ? Icons.support_agent : Icons.local_taxi, color: blue),
                          ),
                          title: Text(peer['name']?.toString() ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, color: missed ? const Color(0xFFB91C1C) : null)),
                          subtitle: Row(children: [
                            Icon(missed ? Icons.call_missed : (out ? Icons.call_made : Icons.call_received), size: 15,
                                color: missed ? const Color(0xFFB91C1C) : Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('$line · ${_ago(c['at']?.toString())}', maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ]),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(tooltip: 'معاودة الاتصال', icon: const Icon(Icons.call, color: blue), onPressed: () => _callBack(c)),
                            IconButton(tooltip: 'الدردشة', icon: const Icon(Icons.chat_bubble_outline, color: blue), onPressed: () => _chat(c)),
                          ]),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
