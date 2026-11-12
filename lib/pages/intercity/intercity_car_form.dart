import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_style.dart';

/// Where he leaves from and (optionally) the exact place in the other city.
class IcPlace {
  const IcPlace(this.lat, this.lng, this.address);
  final double lat;
  final double lng;
  final String address;
}

/// A whole car: city, time, riders, bag, his price (the admin's range), a note. Drivers answer
/// with their price and time; he picks one in «الرحلات القادمة».
class IntercityCarForm extends StatefulWidget {
  const IntercityCarForm({super.key, required this.home, required this.pick, this.drop, this.routeId, required this.onBooked, this.send});

  final IntercityHome home;
  final IcPlace pick;
  final IcPlace? drop;
  final int? routeId;
  final void Function(String message) onBooked;

  /// tests replace the network call
  final Future<IntercityResult> Function(Map<String, Object?> booking)? send;

  @override
  State<IntercityCarForm> createState() => _IntercityCarFormState();
}

class _IntercityCarFormState extends State<IntercityCarForm> {
  late IntercityRoute _route;
  IcPlace? _drop;
  Map? _quote;
  String _when = 'soon';
  DateTime? _custom;
  int _passengers = 1;
  bool _bag = false;
  late num _fare;
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final routes = widget.home.routes;
    _route = routes.firstWhere((r) => r.id == widget.routeId, orElse: () => routes.first);
    _drop = widget.drop;
    _fare = _route.suggested;
    if (_drop != null) _loadQuote();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  num get _min => (_quote?['min'] as num?) ?? _route.min;
  num get _max => (_quote?['max'] as num?) ?? _route.max;
  num get _suggested => (_quote?['suggested'] as num?) ?? _route.suggested;

  Future<void> _loadQuote() async {
    final d = _drop;
    if (d == null) return;
    final q = await IntercityApi.quote(widget.pick.lat, widget.pick.lng, d.lat, d.lng);
    if (!mounted || q == null) return;
    setState(() {
      _quote = q;
      _fare = (q['suggested'] as num?) ?? _fare;
    });
  }

  void _pickRoute(IntercityRoute r) => setState(() {
        _route = r;
        _drop = null;
        _quote = null;
        _fare = r.suggested;
      });

  DateTime get _start {
    final now = DateTime.now();
    if (_when == 'soon') return now.add(const Duration(minutes: 45));
    if (_when == 'morning') return DateTime(now.year, now.month, now.day + 1, 7);
    return _custom ?? now.add(const Duration(hours: 2));
  }

  Future<void> _chooseTime() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(Duration(days: widget.home.horizonDays)),
      initialDate: _custom ?? now.add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (time == null || !mounted) return;
    setState(() {
      _custom = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _when = 'custom';
    });
  }

  Future<void> _send() async {
    final zt = widget.home.zoneTypeId;
    if (zt == null || zt.isEmpty) {
      setState(() => _error = 'الخدمة مش جاهزة في مدينتك. جرّب بعد شوي.');
      return;
    }
    if (_start.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      setState(() => _error = 'اختار موعد بعد نص ساعة على الأقل.');
      return;
    }
    final drop = _drop ?? IcPlace(_route.lat, _route.lng, _route.to);
    final booking = <String, Object?>{
      'zone_type_id': zt, 'drop': drop, 'start': _start, 'fare': _fare, 'passengers': _passengers, 'big_bag': _bag, 'note': _note.text,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null
        ? await widget.send!(booking)
        : await IntercityApi.requestCar(
            zoneTypeId: zt,
            pickLat: widget.pick.lat,
            pickLng: widget.pick.lng,
            pickAddress: widget.pick.address,
            dropLat: drop.lat,
            dropLng: drop.lng,
            dropAddress: drop.address,
            start: _start,
            fare: _fare,
            passengers: _passengers,
            bigBag: _bag,
            note: _note.text,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      widget.onBooked('طلبك وصل لسائقين ${widget.home.from} اللي يقبلوا السفر. العروض توصلك بإشعار وتلقاها في «الرحلات القادمة».');
    } else {
      setState(() => _error = r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _max - _min >= 100 ? 10 : 5;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('إلى وين؟', style: IcStyle.t(13, c: IcStyle.muted)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final r in widget.home.routes) IcChip(text: r.to, selected: r.id == _route.id, onTap: () => _pickRoute(r)),
      ]),
      const SizedBox(height: 10),
      _box(Row(children: [
        const Icon(Icons.place_rounded, color: Color(0xff16A34A), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_drop?.address.isNotEmpty == true ? _drop!.address : '${_route.to} · وسط المدينة',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14.5)),
        ),
        if ((_quote?['extra_km'] as num? ?? 0) > 0)
          Text('+${IcStyle.money(_quote!['extra_km'] as num)} كم', style: IcStyle.t(12, c: const Color(0xffB45309))),
      ])),
      const SizedBox(height: 12),
      Text('الموعد', style: IcStyle.t(13, c: IcStyle.muted)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        IcChip(text: 'أقرب وقت', selected: _when == 'soon', onTap: () => setState(() => _when = 'soon')),
        IcChip(text: 'بكرة 7 الصبح', selected: _when == 'morning', onTap: () => setState(() => _when = 'morning')),
        IcChip(text: _when == 'custom' && _custom != null ? IntercityApi.dayLabel(IntercityApi.wallClock(_custom!)) : 'موعد ثاني', selected: _when == 'custom', onTap: _chooseTime),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _box(Row(children: [
            Expanded(child: Text('الركاب', style: IcStyle.t(14))),
            IcStepper(
              value: '$_passengers',
              onPlus: _passengers < widget.home.maxPassengers ? () => setState(() => _passengers++) : null,
              onMinus: _passengers > 1 ? () => setState(() => _passengers--) : null,
            ),
          ])),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => setState(() => _bag = !_bag),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: _bag ? IcStyle.chip : IcStyle.soft, borderRadius: BorderRadius.circular(16), border: Border.all(color: _bag ? IcStyle.blue : Colors.transparent, width: 1.5)),
            child: Row(children: [
              Icon(Icons.luggage_outlined, size: 18, color: _bag ? IcStyle.blue : IcStyle.navy),
              const SizedBox(width: 4),
              Text('شنطة كبيرة', style: IcStyle.t(13, w: FontWeight.w800, c: _bag ? IcStyle.blue : IcStyle.navy)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: IcStyle.blue, width: 2)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السعر المقترح', style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
              Text('LYD ${IcStyle.money(_suggested)}', style: IcStyle.t(16, w: FontWeight.w900)),
              Text('سيارة كاملة لك', style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
            ]),
          ),
          IcStepper(
            big: true,
            label: 'عرضك',
            value: IcStyle.money(_fare),
            onPlus: _fare + step <= _max ? () => setState(() => _fare += step) : null,
            onMinus: _fare - step >= _min ? () => setState(() => _fare -= step) : null,
          ),
        ]),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _note,
        maxLength: 200,
        style: IcStyle.t(13.5, w: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'ملاحظة للسائق (اختياري): مثلًا عندي كرسي أطفال',
          hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 6),
        Text(_error!, textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
      ],
      const SizedBox(height: 10),
      FilledButton(
        onPressed: _busy ? null : _send,
        style: FilledButton.styleFrom(backgroundColor: IcStyle.blue, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: _busy
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
            : Text('اطلب عروض السائقين · LYD ${IcStyle.money(_fare)}', style: IcStyle.t(17, w: FontWeight.w900, c: Colors.white)),
      ),
      const SizedBox(height: 4),
      Text('الإلغاء مجاني حتى تختار سائق', textAlign: TextAlign.center, style: IcStyle.t(11.5, w: FontWeight.w600, c: IcStyle.muted)),
    ]);
  }

  Widget _box(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}
