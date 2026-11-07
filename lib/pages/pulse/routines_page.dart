import '../../widgets/v2_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/pulse_api.dart';
import 'pickup_change_panel.dart' show PickupPointPicker;

const _blue = Color(0xff0873FF);
const _ink = Color(0xff12121D);
const _muted = Color(0xff6B7280);

/// Saturday first, as people here count the week; values are ISO weekdays (1 = Monday).
const _weekDays = [(6, 'السبت'), (7, 'الأحد'), (1, 'الاثنين'), (2, 'الثلاثاء'), (3, 'الأربعاء'), (4, 'الخميس'), (5, 'الجمعة')];

/// «رحلاتي المعتادة»: the rider's own routine trips and the two consents behind them. A routine
/// found in his history is only a suggestion until he confirms it; a reminder never books a ride.
class PulseRoutinesPage extends StatefulWidget {
  const PulseRoutinesPage({super.key});

  @override
  State<PulseRoutinesPage> createState() => _PulseRoutinesPageState();
}

class _PulseRoutinesPageState extends State<PulseRoutinesPage> {
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _routines = [];
  bool _loading = true;
  String? _error;

  TextStyle _t(double size, {FontWeight w = FontWeight.w500, Color c = _ink}) => GoogleFonts.cairo(fontSize: size, fontWeight: w, color: c, height: 1.5);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await PulseApi.settings();
    final r = await PulseApi.routines();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = s.ok ? null : s.message;
      _settings = s.data;
      _routines = r.list;
    });
    PulsePresence.remindersOn = _settings['reminders'] == true;
  }

  void _say(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m, style: GoogleFonts.cairo())));

  Future<void> _set(Map<String, dynamic> body) async {
    final r = await PulseApi.saveSettings(body);
    if (!r.ok) _say(r.message);
    await _load();
    if (body['reminders'] == true) PulsePresence.report();
  }

  Future<void> _act(Map<String, dynamic> routine, String action, String done) async {
    final r = await PulseApi.routineAction((routine['id'] as num).toInt(), action);
    _say(r.ok ? done : r.message);
    await _load();
  }

  String _daysLabel(List days) {
    final set = days.map((e) => (e as num).toInt()).toSet();
    if (set.length == 7) return 'كل يوم';
    return _weekDays.where((d) => set.contains(d.$1)).map((d) => d.$2).join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final suggested = _routines.where((r) => r['status'] == 'suggested').toList();
    final mine = _routines.where((r) => r['status'] != 'suggested').toList();
    final explain = (_settings['explain'] as Map?) ?? const {};
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(title: Text('رحلاتي المعتادة', style: _t(18, w: FontWeight.w800)), backgroundColor: Colors.white, foregroundColor: _ink, elevation: 0.5),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _blue,
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('رحلة معتادة', style: _t(14, w: FontWeight.w700, c: Colors.white)),
        ),
        body: _loading
            ? const V2Skeleton()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
                  if (_error != null) Text(_error!, style: _t(13, c: const Color(0xffB91C1C))),
                  _card([
                    Text('الخصوصية والتذكيرات', style: _t(15, w: FontWeight.w800)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _settings['personalization'] == true,
                      onChanged: (v) => _set({'personalization': v}),
                      title: Text('اقترح عليّ رحلاتي المتكررة', style: _t(14, w: FontWeight.w700)),
                      subtitle: Text('${explain['personalization'] ?? ''}', style: _t(12, c: _muted)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _settings['reminders'] == true,
                      onChanged: (v) => _set({'reminders': v}),
                      title: Text('ذكّرني بموعد رحلاتي المعتادة', style: _t(14, w: FontWeight.w700)),
                      subtitle: Text('${explain['reminders'] ?? ''}', style: _t(12, c: _muted)),
                    ),
                    if (_settings['reminders'] == true) ...[
                      Row(children: [
                        Expanded(child: Text('ساعات الهدوء: ${_settings['quiet_start'] ?? '—'} إلى ${_settings['quiet_end'] ?? '—'}', style: _t(13))),
                        TextButton(onPressed: _quiet, child: Text('تغيير', style: _t(13, c: _blue))),
                      ]),
                      Row(children: [
                        Expanded(
                            child: Text(_settings['paused_until'] == null ? 'التذكيرات تعمل' : 'التذكيرات موقوفة مؤقتًا', style: _t(13))),
                        PopupMenuButton<int>(
                          onSelected: (h) => _set({'pause_hours': h}),
                          itemBuilder: (_) => [
                            for (final h in [(0, 'تشغيل الآن'), (2, 'إيقاف ساعتين'), (24, 'إيقاف يوم'), (168, 'إيقاف أسبوع')])
                              PopupMenuItem(value: h.$1, child: Text(h.$2, style: GoogleFonts.cairo())),
                          ],
                          child: Padding(padding: const EdgeInsets.all(8), child: Text('إيقاف مؤقت', style: _t(13, c: _blue))),
                        ),
                      ]),
                    ],
                  ]),
                  if (suggested.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('وجدناها في رحلاتك', style: _t(15, w: FontWeight.w800)),
                    Text('لا تعمل حتى تؤكدها بنفسك.', style: _t(12, c: _muted)),
                    for (final r in suggested)
                      _card([
                        Text('${r['local_time']} — ${_daysLabel(r['days'] as List)}', style: _t(14, w: FontWeight.w800)),
                        Text('إلى ${(r['drop'] as Map?)?['label'] ?? 'وجهتك المعتادة'} — ${r['evidence'] ?? ''} رحلات سابقة', style: _t(12.5, c: _muted)),
                        Row(children: [
                          FilledButton(style: FilledButton.styleFrom(backgroundColor: _blue), onPressed: () => _act(r, 'confirm', 'فُعّلت الرحلة المعتادة.'), child: Text('تفعيل', style: GoogleFonts.cairo())),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: () => _act(r, 'dismiss', 'لن نقترحها مرة أخرى.'), child: Text('ليست رحلة معتادة', style: GoogleFonts.cairo())),
                        ]),
                      ]),
                  ],
                  const SizedBox(height: 14),
                  Text('رحلاتي', style: _t(15, w: FontWeight.w800)),
                  if (mine.isEmpty) Text('أضف رحلة تتكرر (الدراسة، العمل…) ونذكّرك قبل موعدها حين تكون قريبًا من مكان الانطلاق.', style: _t(13, c: _muted)),
                  for (final r in mine)
                    _card([
                      Row(children: [
                        Expanded(child: Text('${r['label'] ?? 'رحلة معتادة'} — ${r['local_time']}', style: _t(14, w: FontWeight.w800))),
                        if (r['status'] == 'paused') Text('موقوفة', style: _t(12, c: const Color(0xffB45309))),
                      ]),
                      Text('${_daysLabel(r['days'] as List)} — التذكير قبل ${r['lead_minutes']} دقيقة', style: _t(12.5, c: _muted)),
                      Row(children: [
                        TextButton(onPressed: () => _edit(r), child: Text('تعديل', style: _t(13, c: _blue))),
                        TextButton(
                            onPressed: () => _act(r, r['status'] == 'paused' ? 'resume' : 'pause', r['status'] == 'paused' ? 'شُغّلت.' : 'أُوقفت.'),
                            child: Text(r['status'] == 'paused' ? 'تشغيل' : 'إيقاف', style: _t(13, c: _blue))),
                        const Spacer(),
                        IconButton(tooltip: 'حذف', onPressed: () => _act(r, 'delete', 'حُذفت.'), icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffB91C1C))),
                      ]),
                    ]),
                ]),
              ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Future<void> _quiet() async {
    final from = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 0), helpText: 'بداية الهدوء');
    if (from == null || !mounted) return;
    final to = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0), helpText: 'نهاية الهدوء');
    if (to == null) return;
    String f(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    await _set({'quiet_start': f(from), 'quiet_end': f(to)});
  }

  Future<void> _edit(Map<String, dynamic>? r) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _RoutineForm(routine: r)));
    if (saved == true) {
      _say('حُفظت الرحلة المعتادة.');
      await _load();
    }
  }
}

class _RoutineForm extends StatefulWidget {
  const _RoutineForm({this.routine});

  final Map<String, dynamic>? routine;

  @override
  State<_RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<_RoutineForm> {
  late final TextEditingController _label = TextEditingController(text: '${widget.routine?['label'] ?? ''}');
  late final Set<int> _days = ((widget.routine?['days'] as List?) ?? const [6, 7, 1, 2, 3]).map((e) => (e as num).toInt()).toSet();
  late TimeOfDay _time = _parse('${widget.routine?['local_time'] ?? '07:30'}');
  late int _lead = (widget.routine?['lead_minutes'] as num?)?.toInt() ?? 10;
  LatLng? _pick;
  LatLng? _drop;
  bool _busy = false;

  static TimeOfDay _parse(String v) {
    final p = v.split(':');
    return TimeOfDay(hour: int.tryParse(p[0]) ?? 7, minute: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.routine?['pickup'] as Map?;
    final d = widget.routine?['drop'] as Map?;
    if (p != null) _pick = LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
    if (d != null) _drop = LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
  }

  Future<void> _here() async {
    try {
      final p = await Geolocator.getCurrentPosition();
      setState(() => _pick = LatLng(p.latitude, p.longitude));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذّر تحديد موقعك؛ اختره على الخريطة.', style: GoogleFonts.cairo())));
    }
  }

  Future<void> _choose(bool pickup) async {
    final at = await Navigator.of(context).push<LatLng>(MaterialPageRoute(builder: (_) => PickupPointPicker(start: pickup ? _pick : (_drop ?? _pick), rtl: true, title: pickup ? 'مكان الانطلاق' : 'الوجهة')));
    if (at != null) setState(() => pickup ? _pick = at : _drop = at);
  }

  Future<void> _save() async {
    if (_pick == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدّد مكان الانطلاق.', style: GoogleFonts.cairo())));
      return;
    }
    setState(() => _busy = true);
    final body = {
      'label': _label.text.trim(),
      'days': _days.toList(),
      'local_time': '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      'lead_minutes': _lead,
      'pickup_lat': _pick!.latitude, 'pickup_lng': _pick!.longitude,
      if (_drop != null) 'drop_lat': _drop!.latitude,
      if (_drop != null) 'drop_lng': _drop!.longitude,
      if (widget.routine != null) 'version': widget.routine!['version'],
    };
    final r = await PulseApi.saveRoutine(body, id: (widget.routine?['id'] as num?)?.toInt());
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message, style: GoogleFonts.cairo())));
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle t(double s, {FontWeight w = FontWeight.w600, Color c = _ink}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.routine == null ? 'رحلة معتادة جديدة' : 'تعديل الرحلة المعتادة', style: t(17, w: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: _label, maxLength: 80, decoration: const InputDecoration(labelText: 'الاسم (اختياري): الجامعة، العمل…')),
          Text('الأيام', style: t(14)),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final d in _weekDays)
              FilterChip(
                label: Text(d.$2, style: GoogleFonts.cairo()),
                selected: _days.contains(d.$1),
                onSelected: (v) => setState(() => v ? _days.add(d.$1) : _days.remove(d.$1)),
              ),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('وقت الرحلة', style: t(14)),
            trailing: Text(_time.format(context), style: t(15, w: FontWeight.w800, c: _blue)),
            onTap: () async {
              final v = await showTimePicker(context: context, initialTime: _time);
              if (v != null) setState(() => _time = v);
            },
          ),
          Row(children: [
            Expanded(child: Text('ذكّرني قبلها بـ', style: t(14))),
            DropdownButton<int>(
              value: _lead,
              items: [for (final m in [5, 10, 15, 30, 60]) DropdownMenuItem(value: m, child: Text('$m دقيقة', style: GoogleFonts.cairo()))],
              onChanged: (v) => setState(() => _lead = v ?? 10),
            ),
          ]),
          const Divider(),
          Text('مكان الانطلاق', style: t(14)),
          Text(_pick == null ? 'لم يُحدد بعد' : 'محدد على الخريطة', style: t(12.5, c: _muted, w: FontWeight.w500)),
          Row(children: [
            TextButton.icon(onPressed: _here, icon: const Icon(Icons.my_location_rounded), label: Text('موقعي الحالي', style: GoogleFonts.cairo())),
            TextButton.icon(onPressed: () => _choose(true), icon: const Icon(Icons.map_rounded), label: Text('على الخريطة', style: GoogleFonts.cairo())),
          ]),
          Text('الوجهة (اختياري)', style: t(14)),
          Text(_drop == null ? 'بدون وجهة' : 'محددة على الخريطة', style: t(12.5, c: _muted, w: FontWeight.w500)),
          TextButton.icon(onPressed: () => _choose(false), icon: const Icon(Icons.flag_rounded), label: Text('اختر الوجهة', style: GoogleFonts.cairo())),
          const SizedBox(height: 8),
          Text('نذكّرك فقط إذا فتحت التطبيق مؤخرًا وأنت قريب من مكان الانطلاق، ولا نطلب رحلة دون تأكيدك.', style: t(12, c: _muted, w: FontWeight.w500)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(50)),
            onPressed: _busy || _days.isEmpty ? null : _save,
            child: Text('حفظ', style: t(16, w: FontWeight.w800, c: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
