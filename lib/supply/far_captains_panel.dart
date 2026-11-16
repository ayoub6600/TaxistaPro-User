import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supply_api.dart';

const _navy = Color(0xff0D1B3E);
const _blue = Color(0xff0A6CF1);
const _muted = Color(0xff66748F);
const _line = Color(0xffE3E8F1);

/// «فيه فلان بعيد عليك» (owner approved 2026-11-16): while the rider searches and no captain is
/// near, the server lists the nearest free captains farther out (first name, rating, car, km,
/// minutes). «ابعتله» sends the ride to that captain for a few seconds; «كمّل البحث» hides the card.
/// Nothing shows while the city has it off or a near captain already has the ride.
class FarCaptainsPanel extends StatefulWidget {
  const FarCaptainsPanel({super.key, required this.requestId, this.bottomInset = 0, this.loader, this.picker});

  final String requestId;
  final double bottomInset;

  /// tests replace the server
  final Future<Map<String, dynamic>?> Function(String id)? loader;
  final Future<Map<String, dynamic>?> Function(String id, int driverId)? picker;

  @override
  State<FarCaptainsPanel> createState() => _FarCaptainsPanelState();
}

class _FarCaptainsPanelState extends State<FarCaptainsPanel> {
  Map<String, dynamic>? _data;
  Timer? _poll;
  Timer? _tick;
  bool _hidden = false;
  bool _busy = false;
  String? _error;
  String? _waitingFor; // first name of the captain who has the ride now
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant FarCaptainsPanel old) {
    super.didUpdateWidget(old);
    if (old.requestId != widget.requestId) {
      _hidden = false;
      _waitingFor = null;
      _data = null;
      _load();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_hidden || _waitingFor != null) return;
    final d = await (widget.loader ?? SupplyApi.farCaptains)(widget.requestId);
    if (!mounted || d == null || d.containsKey('_error')) return;
    setState(() => _data = d);
  }

  Future<void> _pick(Map c) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await (widget.picker ?? SupplyApi.pick)(widget.requestId, (c['driver_id'] as num).toInt());
    if (!mounted) return;
    if (r == null || r.containsKey('_error')) {
      setState(() {
        _busy = false;
        _error = (r?['_error'] as String?)?.isNotEmpty == true ? r!['_error'] as String : 'ما قدرناش نبعتوله. جرّب مرة ثانية.';
      });
      _load();
      return;
    }
    setState(() {
      _busy = false;
      _waitingFor = (c['first_name'] ?? '').toString();
      _left = (r['seconds'] as num?)?.toInt() ?? (_data?['offer_seconds'] as num?)?.toInt() ?? 20;
    });
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_left <= 1) {
        t.cancel();
        setState(() => _waitingFor = null); // no answer: back to the list, the search goes on for everyone
        _load();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final captains = (d?['captains'] as List?)?.whereType<Map>().toList() ?? const [];
    if (_hidden || d == null || d['show'] != true || (captains.isEmpty && _waitingFor == null)) {
      return const SizedBox.shrink();
    }
    final total = (d['offer_seconds'] as num?)?.toInt() ?? 20;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + widget.bottomInset),
        child: Material(
          color: Colors.white,
          elevation: 12,
          shadowColor: const Color(0x3315386B),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: _waitingFor != null ? _waiting(total) : _list(d, captains),
          ),
        ),
      ),
    );
  }

  Widget _list(Map d, List<Map> captains) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text((d['title'] ?? 'ما فيش كابتن قريب منك توا').toString(),
          textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _navy, fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.4)),
      if (d['subtitle'] != null)
        Text(d['subtitle'].toString(), textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      for (final c in captains) _CaptainRow(captain: c, busy: _busy, onPick: () => _pick(c)),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: const Color(0xffB91C1C), fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      TextButton(
        onPressed: () => setState(() => _hidden = true),
        child: Text('كمّل البحث لكل الكباتن', style: GoogleFonts.cairo(color: _blue, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    ]);
  }

  Widget _waiting(int total) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('بعتنا الطلب لـ$_waitingFor', style: GoogleFonts.cairo(color: _navy, fontSize: 16.5, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      SizedBox(
        width: 66,
        height: 66,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: _left / total, strokeWidth: 6, color: _blue, backgroundColor: const Color(0xffE6ECF6)),
          Text('0:${_left.toString().padLeft(2, '0')}',
              textDirection: TextDirection.ltr, style: GoogleFonts.cairo(color: _navy, fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
      ),
      const SizedBox(height: 8),
      Text('لو ما ردش، نرجعوا ندوروا لك عادي على كل الكباتن.',
          textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _CaptainRow extends StatelessWidget {
  const _CaptainRow({required this.captain, required this.busy, required this.onPick});

  final Map captain;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final rating = captain['rating'];
    final photo = captain['photo']?.toString();
    final car = captain['car']?.toString();
    final picked = captain['picked'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: _line), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xffEEF4FF),
          backgroundImage: photo != null && photo.startsWith('http') ? NetworkImage(photo) : null,
          child: photo != null && photo.startsWith('http') ? null : const Icon(Icons.person_rounded, color: _blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${captain['first_name'] ?? 'كابتن'}${rating != null ? ' ⭐ $rating' : ''}',
                style: GoogleFonts.cairo(color: _navy, fontSize: 13.5, fontWeight: FontWeight.w800)),
            if (car != null && car.isNotEmpty)
              Text(car, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            Text('${captain['km']} كم · يوصلك في حوالي ${captain['minutes']} دقيقة',
                style: GoogleFonts.cairo(color: _navy, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: busy || picked ? null : onPick,
          style: FilledButton.styleFrom(
            backgroundColor: _blue,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 36),
          ),
          child: Text(picked ? 'انبعتله' : 'ابعتله', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ]),
    );
  }
}
