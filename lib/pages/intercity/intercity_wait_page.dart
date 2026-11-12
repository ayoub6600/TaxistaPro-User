import 'dart:async';

import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import '../../utils/scheduled_offers.dart';
import 'intercity_fare_page.dart' show IcFareBar, IcChoiceRow;
import 'intercity_style.dart';

/// د · العروض توصل: the drivers' offers arrive (price, rating, their time), he can raise his price,
/// pick one, or cancel (free, with a reason). Picking one books the ride.
class IntercityWaitPage extends StatefulWidget {
  const IntercityWaitPage({
    super.key,
    required this.rideId,
    required this.from,
    required this.to,
    required this.fare,
    required this.max,
    required this.step,
    required this.summary,
    required this.pickAddress,
    required this.dropAddress,
    this.note = '',
    this.load,
  });

  final String rideId;
  final String from;
  final String to;
  final num fare;
  final num max;
  final num step;
  final String summary;
  final String pickAddress;
  final String dropAddress;
  final String note;

  /// tests replace the network
  final Future<Map?> Function()? load;

  @override
  State<IntercityWaitPage> createState() => _IntercityWaitPageState();
}

class _IntercityWaitPageState extends State<IntercityWaitPage> {
  late num _sent = widget.fare;
  late num _fare = widget.fare;
  List<Map> _offers = const [];
  Timer? _poll;
  bool _busy = false;
  Map? _booked;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final ride = widget.load != null ? await widget.load!() : await IntercityApi.ride(widget.rideId);
    if (!mounted || ride == null) return;
    if (ride['is_cancelled'] == true || ride['is_cancelled'] == 1) {
      _poll?.cancel();
      Navigator.of(context).maybePop();
      return;
    }
    final raw = ride['scheduled_offers'];
    setState(() => _offers = raw is List ? [for (final o in raw) if (o is Map) o] : const []);
  }

  void _say(String m) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(m, textDirection: TextDirection.rtl)));

  Future<void> _raise() async {
    setState(() => _busy = true);
    final r = await IntercityApi.raise(widget.rideId, _fare);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _sent = _fare;
    });
    _say(r.message);
  }

  Future<void> _choose(Map o) async {
    final id = (o['offer_id'] as num?)?.toInt();
    if (id == null) return;
    setState(() => _busy = true);
    final r = await IntercityApi.acceptOffer(id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _poll?.cancel();
      setState(() => _booked = o);
    } else {
      _say(r.message);
      _refresh();
    }
  }

  Future<void> _cancel() async {
    const reasons = ['غيّرت رأيي', 'ما جاتنيش عروض', 'العروض غالية', 'نبي نغيّر الموعد أو الوجهة', 'لقيت وسيلة ثانية', 'سبب ثاني'];
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? pick;
        return StatefulBuilder(
          builder: (ctx, set) => Directionality(
            textDirection: TextDirection.rtl,
            child: IcSheet(children: [
              Text('ليش تبي تلغي؟', style: IcStyle.t(20, w: FontWeight.w900)),
              const SizedBox(height: 8),
              for (final r in reasons) ...[
                IcChoiceRow(text: r, selected: pick == r, onTap: () => set(() => pick = r)),
                const SizedBox(height: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xffFFF7E6), borderRadius: BorderRadius.circular(14)),
                child: Text('الإلغاء مجاني. لو تبي عروض أكثر، جرّب ترفع سعرك شوية.', style: IcStyle.t(13, c: const Color(0xff92400E))),
              ),
              const SizedBox(height: 10),
              IcButton(text: 'إلغاء الطلب', danger: true, onTap: pick == null ? null : () => Navigator.pop(ctx, pick)),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('رجوع، نستنى العروض', style: IcStyle.t(15, c: IcStyle.blue))),
            ]),
          ),
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    final r = await IntercityApi.cancel(widget.rideId, reason);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      _poll?.cancel();
      _say('تم إلغاء طلبك');
      Navigator.of(context).maybePop();
    } else {
      _say(r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booked != null) return _bookedView(_booked!);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: IcStyle.soft,
        body: SafeArea(
          child: Column(children: [
            const SizedBox(height: 8),
            Text('نجمعولك العروض', style: IcStyle.t(16, w: FontWeight.w900)),
            const SizedBox(height: 4),
            const SizedBox(height: 150, child: CustomPaint(painter: _WaitArt(), size: Size(double.infinity, 150))),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 20), children: [
                  Text('السائقين يردوا خلال دقائق · الطلب مفتوح حتى قبل الموعد بساعة',
                      textAlign: TextAlign.center, style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      IcFareBar(
                        compact: true,
                        value: _fare,
                        onPlus: _fare + widget.step <= widget.max ? () => setState(() => _fare += widget.step) : null,
                        onMinus: _fare - widget.step >= _sent ? () => setState(() => _fare -= widget.step) : null,
                      ),
                      const SizedBox(height: 6),
                      if (_fare > _sent)
                        IcButton(text: 'ارفع السعر إلى ${IcStyle.money(_fare)}', height: 44, busy: _busy, onTap: _raise)
                      else
                        Text('ارفع سعرك تجيك عروض أكثر', style: IcStyle.t(12, w: FontWeight.w700, c: const Color(0xff3B4E72))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(_offers.isEmpty ? 'نستنوا أول عرض…' : 'العروض (${_offers.length})', style: IcStyle.t(15, w: FontWeight.w900)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _offers.length; i++) _offer(_offers[i], i == 0),
                  const SizedBox(height: 8),
                  _summary(),
                  const SizedBox(height: 12),
                  IcButton(text: 'إلغاء الطلب', ghost: true, danger: true, height: 48, onTap: _busy ? null : _cancel),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _offer(Map o, bool first) {
    final name = '${o['driver_name'] ?? 'سائق'}';
    final time = (o['proposed_time'] ?? '').toString();
    final rating = o['driver_rating'];
    final done = o['driver_completed'];
    final car = [o['vehicle_make'], o['vehicle_model'], o['vehicle_color']].where((x) => x != null && '$x'.trim().isNotEmpty).join(' ');
    return Container(
      key: ValueKey('ic-offer-${o['offer_id']}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: first ? IcStyle.blue : IcStyle.line, width: first ? 2 : 1.5)),
      child: Row(children: [
        CircleAvatar(radius: 21, backgroundColor: const Color(0xffDCE8FB), child: Text(name.characters.first, style: IcStyle.t(17, w: FontWeight.w900, c: IcStyle.blue))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text([name, if (rating != null) '$rating', if (done != null) '$done رحلة'].join(' · '), style: IcStyle.t(14.5, w: FontWeight.w800)),
            Text(time.isNotEmpty ? 'يقترح ${IntercityApi.dayLabel(time)}' : (car.isEmpty ? 'في وقتك' : '$car · في وقتك'),
                style: IcStyle.t(12, w: time.isNotEmpty ? FontWeight.w800 : FontWeight.w600, c: time.isNotEmpty ? const Color(0xffB45309) : IcStyle.muted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('LYD ${moneyLabel(o['proposed_fare'])}', style: IcStyle.t(17, w: FontWeight.w900)),
          const SizedBox(height: 2),
          SizedBox(
            height: 30,
            child: FilledButton(
              onPressed: _busy ? null : () => _choose(o),
              style: FilledButton.styleFrom(backgroundColor: IcStyle.blue, padding: const EdgeInsets.symmetric(horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('اختار', style: IcStyle.t(13, w: FontWeight.w900, c: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _summary() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xffF7F9FC), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(widget.summary, style: IcStyle.t(14, w: FontWeight.w800))),
            _tag('سيارة كاملة', const Color(0xffEAF2FF), IcStyle.blue),
            const SizedBox(width: 4),
            _tag('نقدًا', const Color(0xffECFDF3), const Color(0xff16803C)),
          ]),
          const SizedBox(height: 4),
          Text('● ${widget.from} · ${widget.pickAddress}', maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(12.5, w: FontWeight.w600)),
          Text('● ${widget.dropAddress}', maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(12.5, w: FontWeight.w600)),
          if (widget.note.isNotEmpty) Text(widget.note, style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
        ]),
      );

  Widget _tag(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: IcStyle.t(11, w: FontWeight.w800, c: fg)),
      );

  Widget _bookedView(Map o) {
    final time = (o['proposed_time'] ?? '').toString();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 30, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(color: const Color(0xffDCFCE7), borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.check_rounded, color: Color(0xff16803C), size: 38),
                ),
              ),
              const SizedBox(height: 10),
              Text('سفرتك محجوزة', textAlign: TextAlign.center, style: IcStyle.t(23, w: FontWeight.w900)),
              Text('تلقاها في «الرحلات القادمة»', textAlign: TextAlign.center, style: IcStyle.t(14, w: FontWeight.w600, c: IcStyle.muted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('الموعد', style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
                      Text(time.isNotEmpty ? IntercityApi.dayLabel(time) : widget.summary.split(' · ').first, style: IcStyle.t(17, w: FontWeight.w900)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('نقدًا', style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
                    Text('LYD ${moneyLabel(o['proposed_fare'])}', style: IcStyle.t(17, w: FontWeight.w900)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              Text('${o['driver_name'] ?? 'السائق'} ${o['driver_rating'] != null ? '· ${o['driver_rating']}' : ''}', style: IcStyle.t(16, w: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('• الإلغاء مجاني\n• تذكير لك وللسائق قبل الموعد بساعتين\n• يوم السفر: رحلة عادية بالتتبع والمشاركة',
                  style: IcStyle.t(14, w: FontWeight.w600, c: IcStyle.muted).copyWith(height: 1.9)),
              const Spacer(),
              IcButton(text: 'تمام', onTap: () => Navigator.of(context).maybePop()),
            ]),
          ),
        ),
      ),
    );
  }
}

/// blue rings, a car and a clock: «waiting for offers», in the app's colours
class _WaitArt extends CustomPainter {
  const _WaitArt();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 70, Paint()..color = const Color(0xffDCE8FB));
    canvas.drawCircle(c, 49, Paint()..color = const Color(0xffBFD7FB));
    canvas.drawCircle(c, 30, Paint()..color = IcStyle.blue);
    final car = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(c + const Offset(-14, 6), c + const Offset(14, 6), car);
    canvas.drawPath(Path()..moveTo(c.dx - 11, c.dy + 1)..lineTo(c.dx - 8, c.dy - 7)..lineTo(c.dx + 8, c.dy - 7)..lineTo(c.dx + 11, c.dy + 1), car);
    canvas.drawCircle(c + const Offset(-7, 8), 2.6, Paint()..color = Colors.white);
    canvas.drawCircle(c + const Offset(7, 8), 2.6, Paint()..color = Colors.white);
    final clock = c + const Offset(84, -38);
    canvas.drawCircle(clock, 15, Paint()..color = IcStyle.gold);
    final hand = Paint()..color = IcStyle.navy..strokeWidth = 2.4..strokeCap = StrokeCap.round;
    canvas.drawLine(clock, clock + const Offset(0, -8), hand);
    canvas.drawLine(clock, clock + const Offset(5, 3), hand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
