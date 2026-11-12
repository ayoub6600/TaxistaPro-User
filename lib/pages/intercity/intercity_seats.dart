import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_style.dart';

/// و · كرسي في رحلة: trips chosen drivers posted, by city; pick seats on the seat strip and book (cash).
class IntercitySeatsPage extends StatefulWidget {
  const IntercitySeatsPage({super.key, required this.home, required this.pickAddress, this.routeTo, this.book});

  final IntercityHome home;
  final String pickAddress;
  final String? routeTo;

  /// tests replace the network call
  final Future<IntercityResult> Function(int tripId, int seats)? book;

  @override
  State<IntercitySeatsPage> createState() => _IntercitySeatsPageState();
}

class _IntercitySeatsPageState extends State<IntercitySeatsPage> {
  late String? _city = widget.routeTo;
  int? _open;
  int _seats = 1;
  int? _busy;
  final Set<int> _booked = {};

  List<SharedTrip> get _trips => widget.home.shared.where((t) => _city == null || t.to == _city).toList();

  Future<void> _book(SharedTrip t) async {
    setState(() => _busy = t.id);
    final r = widget.book != null ? await widget.book!(t.id, _seats) : await IntercityApi.bookSeats(t.id, _seats, pickAddress: widget.pickAddress);
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (r.ok) _booked.add(t.id);
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(r.message, textDirection: TextDirection.rtl)));
  }

  @override
  Widget build(BuildContext context) {
    final trips = _trips;
    final open = trips.any((t) => t.id == _open) ? _open : (trips.isEmpty ? null : trips.first.id);
    return IcScaffold(
      title: 'كرسي في رحلة',
      mapHeight: 170,
      children: [
        Text('كرسي في رحلة', style: IcStyle.t(21, w: FontWeight.w900)),
        Text('سائقين مختارين من تاكسيستا · تدفع كرسيك نقدًا', style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          IcChip(text: 'الكل', selected: _city == null, onTap: () => setState(() => _city = null)),
          for (final r in widget.home.routes) IcChip(text: r.to, selected: _city == r.to, onTap: () => setState(() => _city = r.to)),
        ]),
        const SizedBox(height: 12),
        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(18)),
            child: Text('ما فيش رحلات بالكراسي الآن${_city == null ? '' : ' إلى $_city'}.', textAlign: TextAlign.center, style: IcStyle.t(14.5)),
          ),
        for (final t in trips) t.id == open ? _openCard(t) : _closedCard(t),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ما لقيتش وقت يناسبك؟', style: IcStyle.t(14, w: FontWeight.w800)),
              Text('اطلب سيارة كاملة بسعرك ←', style: IcStyle.t(12.5, w: FontWeight.w800, c: IcStyle.blue)),
            ]),
          ),
        ),
      ],
    );
  }

  String _who(SharedTrip t) {
    final d = t.driver;
    return [
      if ('${d['name'] ?? ''}'.isNotEmpty) d['name'],
      if ((d['rating'] as num? ?? 0) > 0) '${d['rating']}',
      if ('${d['car'] ?? ''}'.trim().isNotEmpty) d['car'],
    ].join(' · ');
  }

  Widget _closedCard(SharedTrip t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: ValueKey('trip-${t.id}'),
          onTap: () => setState(() {
            _open = t.id;
            _seats = 1;
          }),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: IcStyle.line, width: 1.5)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('← ${t.to} · ${IntercityApi.dayLabel(t.departAt)}', style: IcStyle.t(15.5, w: FontWeight.w800)),
                  Text('${_who(t)} · باقي ${t.seatsLeft}', style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
                ]),
              ),
              Text('LYD ${IcStyle.money(t.seatPrice)}', style: IcStyle.t(17, w: FontWeight.w900)),
            ]),
          ),
        ),
      );

  Widget _openCard(SharedTrip t) {
    final taken = t.seatsTotal - t.seatsLeft;
    final done = _booked.contains(t.id);
    return Container(
      key: ValueKey('trip-${t.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: IcStyle.blue, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('← ${t.to} · ${IntercityApi.dayLabel(t.departAt)}', style: IcStyle.t(16, w: FontWeight.w900)),
              Text([if (t.meetingPoint.isNotEmpty) 'من ${t.meetingPoint}', _who(t)].join(' · '), style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('LYD ${IcStyle.money(t.seatPrice)}', style: IcStyle.t(19, w: FontWeight.w900)),
            Text('للكرسي', style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
          ]),
        ]),
        const SizedBox(height: 8),
        Semantics(
          label: '$taken محجوز و${t.seatsLeft} فاضي',
          child: Row(children: [
            for (var i = 0; i < t.seatsTotal; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: i < taken ? const Color(0xffCBD5E1) : (i < taken + _seats ? IcStyle.blue : Colors.transparent),
                    borderRadius: BorderRadius.circular(9),
                    border: i >= taken + _seats ? Border.all(color: IcStyle.blue, width: 2) : null,
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        if (done)
          Text('محجوز ✅ السائق يكلمك قبل الموعد.', style: IcStyle.t(14, c: const Color(0xff16803C)))
        else
          Row(children: [
            IcStepper(
              value: '$_seats',
              onPlus: _seats < t.seatsLeft ? () => setState(() => _seats++) : null,
              onMinus: _seats > 1 ? () => setState(() => _seats--) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IcButton(text: 'احجز · LYD ${IcStyle.money(t.seatPrice * _seats)}', height: 44, busy: _busy == t.id, onTap: () => _book(t)),
            ),
          ]),
      ]),
    );
  }
}
