import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/pulse_api.dart';

const _blue = Color(0xff0873FF);
const _ink = Color(0xff12121D);
const _muted = Color(0xff6B7280);

String _fareLine(Map<String, dynamic> d) {
  final delta = (d['fare_delta'] as num?)?.toDouble() ?? 0;
  if (d['fare_mode'] != 'fixed') return 'السعر المتفق عليه لا يتغير.';
  if (delta.abs() < 0.01) return 'الأجرة لا تتغير.';
  return 'الأجرة ${delta > 0 ? 'تزيد' : 'تقل'} ${delta.abs().toStringAsFixed(2)} وتصبح ${(d['fare_after'] as num?)?.toStringAsFixed(2)}.';
}

/// The rider's side of changing the pickup of an accepted ride, before the trip starts: propose
/// another point, or answer the driver's proposal. A higher fare is confirmed by the rider for that
/// exact amount; nothing changes until the other side accepts.
class PickupChangePanel extends StatefulWidget {
  const PickupChangePanel({super.key, required this.rideId, required this.pickup, this.onChanged});

  final String rideId;
  final LatLng? pickup;
  final VoidCallback? onChanged;

  @override
  State<PickupChangePanel> createState() => _PickupChangePanelState();
}

class _PickupChangePanelState extends State<PickupChangePanel> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PickupChangeState.reload(widget.rideId);
    PickupChangeState.current.addListener(_changed);
  }

  @override
  void dispose() {
    PickupChangeState.current.removeListener(_changed);
    _noteTimer?.cancel();
    super.dispose();
  }

  int? _told;

  void _changed() {
    final c = PickupChangeState.current.value;
    final id = (c?['id'] as num?)?.toInt();
    if (c != null && id != null && _told != id && (c['status'] == 'accepted' || c['status'] == 'rejected')) {
      // the answer to a proposal, once: both sides see the same outcome
      _told = id;
      if (c['status'] == 'accepted') {
        widget.onChanged?.call();
        _say('تم تغيير نقطة الالتقاط. اعتمدوا النقطة الجديدة على الخريطة.');
      } else if (c['mine'] == true) {
        _say('السائق لم يقبل التغيير؛ بقيت نقطة الالتقاط كما كانت.');
      }
    }
    if (mounted) setState(() {});
  }

  // the trip screens have no Scaffold of their own (a SnackBar would assert), so the panel says it itself
  String? _note;
  Timer? _noteTimer;

  void _say(String m) {
    if (!mounted) return;
    _noteTimer?.cancel();
    setState(() => _note = m);
    _noteTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _note = null);
    });
  }

  Future<bool> _confirm(String title, String body, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            content: Text(body, style: GoogleFonts.cairo(height: 1.6)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('تراجع', style: GoogleFonts.cairo())),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes, style: GoogleFonts.cairo())),
            ],
          ),
        ),
      ) ==
      true;

  Future<void> _after(PulseResult r, String ok) async {
    if (!mounted) return;
    setState(() => _busy = false);
    _say(r.ok ? ok : r.message);
    await PickupChangeState.reload(widget.rideId);
  }

  Future<void> _propose() async {
    final at = await Navigator.of(context).push<LatLng>(MaterialPageRoute(builder: (_) => PickupPointPicker(start: widget.pickup, rtl: true)));
    if (at == null || !mounted) return;
    setState(() => _busy = true);
    final q = await PulseApi.pickupQuote(widget.rideId, at.latitude, at.longitude);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!q.ok) {
      _say(q.message);
      return;
    }
    final d = q.data;
    final delta = (d['fare_delta'] as num?)?.toDouble() ?? 0;
    final go = await _confirm('نقطة التقاط جديدة', 'تبعد ${d['move_m']} م عن النقطة الحالية.\n${_fareLine(d)}\nلن يتغير شيء حتى يقبل السائق.',
        delta > 0.5 ? 'أوافق على ${delta.toStringAsFixed(2)} وأرسل' : 'أرسل');
    if (!go) return;
    setState(() => _busy = true);
    await _after(await PulseApi.pickupPropose(widget.rideId, at.latitude, at.longitude, acceptFareDelta: delta > 0.5 ? delta : null), 'أُرسل الاقتراح إلى السائق.');
  }

  Future<void> _accept(Map<String, dynamic> c) async {
    final delta = (c['fare_delta'] as num?)?.toDouble() ?? 0;
    if (delta > 0.5 && !await _confirm('الأجرة تزيد', '${_fareLine(c)}\nهل توافق؟', 'أوافق على ${delta.toStringAsFixed(2)}')) return;
    setState(() => _busy = true);
    await _after(await PulseApi.pickupRespond(widget.rideId, (c['id'] as num).toInt(), true, acceptFareDelta: delta > 0.5 ? delta : null), 'تم تغيير نقطة الالتقاط.');
  }

  @override
  Widget build(BuildContext context) {
    final c = PickupChangeState.current.value;
    final pending = c != null && c['status'] == 'pending';
    final mine = c != null && c['mine'] == true;
    final to = (c?['to'] is Map) ? Map<String, dynamic>.from(c!['to'] as Map) : const <String, dynamic>{};
    Widget body;
    if (pending && !mine) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('السائق يقترح نقطة التقاط أخرى', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: _ink)),
        Text('${to['address'] ?? 'على الخريطة'} — ${_fareLine(c)}', style: GoogleFonts.cairo(fontSize: 12.5, color: _muted)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          await _after(await PulseApi.pickupRespond(widget.rideId, (c['id'] as num).toInt(), false), 'بقيت نقطة الالتقاط كما هي.');
                        },
                  child: Text('رفض', style: GoogleFonts.cairo()))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _blue),
                  onPressed: _busy ? null : () => _accept(c),
                  child: Text('قبول', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)))),
        ]),
      ]);
    } else if (pending && mine) {
      body = Row(children: [
        Expanded(child: Text('بانتظار رد السائق على نقطة الالتقاط الجديدة…', style: GoogleFonts.cairo(fontSize: 13, color: _ink))),
        TextButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await _after(await PulseApi.pickupCancel(widget.rideId, (c['id'] as num).toInt()), 'أُلغي الاقتراح.');
                  },
            child: Text('إلغاء', style: GoogleFonts.cairo())),
      ]);
    } else {
      body = InkWell(
        onTap: _busy ? null : _propose,
        child: Row(children: [
          const Icon(Icons.edit_location_alt_rounded, color: _blue, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('تغيير نقطة الالتقاط', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: _blue))),
          if (_busy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            body,
            if (_note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_note!, style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xffB45309), fontWeight: FontWeight.w600)),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Move the map until the pin sits on the point.
class PickupPointPicker extends StatefulWidget {
  const PickupPointPicker({super.key, required this.start, required this.rtl, this.title});

  final LatLng? start;
  final bool rtl;
  final String? title;

  @override
  State<PickupPointPicker> createState() => _PickupPointPickerState();
}

class _PickupPointPickerState extends State<PickupPointPicker> {
  late LatLng _at = widget.start ?? const LatLng(32.3754, 15.0925);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title ?? 'اختر نقطة الالتقاط', style: GoogleFonts.cairo(fontWeight: FontWeight.w700))),
        body: Stack(alignment: Alignment.center, children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _at, zoom: 17),
            onCameraMove: (p) => _at = p.target,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            // keep the map's own buttons above the confirm button
            padding: EdgeInsets.only(bottom: 90 + MediaQuery.of(context).padding.bottom),
          ),
          const Padding(padding: EdgeInsets.only(bottom: 36), child: Icon(Icons.location_on_rounded, size: 44, color: Color(0xffDC2626))),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.pop(context, _at),
              child: Text('هنا', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Approved pickup points near where the rider is choosing his pickup (around an event). Tapping one
/// moves the map onto it; the rider may just as well keep any other safe place.
class PulsePickupPoints extends StatefulWidget {
  const PulsePickupPoints({super.key, required this.around, required this.onSelect});

  final LatLng Function() around;
  final void Function(LatLng point, String name) onSelect;

  @override
  State<PulsePickupPoints> createState() => _PulsePickupPointsState();
}

class _PulsePickupPointsState extends State<PulsePickupPoints> {
  List<Map<String, dynamic>> _points = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final at = widget.around();
    final r = await PulseApi.pickupPoints(at.latitude, at.longitude);
    if (mounted && r.ok) setState(() => _points = r.list);
  }

  @override
  Widget build(BuildContext context) {
    if (_points.isEmpty) return const SizedBox.shrink();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_points.first['event'] != null ? 'نقاط التقاط معتمدة قرب ${_points.first['event']}' : 'نقاط التقاط معتمدة قريبة',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: _ink)),
            Wrap(spacing: 6, children: [
              for (final p in _points)
                ActionChip(
                  avatar: const Icon(Icons.verified_rounded, size: 16, color: Color(0xff047857)),
                  label: Text('${p['name']} (${p['distance_m']} م)', style: GoogleFonts.cairo(fontSize: 12)),
                  onPressed: () => widget.onSelect(LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()), '${p['name']}'),
                ),
            ]),
            Text('اختيارها اختياري؛ يمكنك تحديد أي مكان آمن آخر.', style: GoogleFonts.cairo(fontSize: 11, color: _muted)),
          ]),
        ),
      ),
    );
  }
}
