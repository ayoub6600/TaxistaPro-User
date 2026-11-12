import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_style.dart';

/// «كرسي في رحلة»: trips chosen drivers posted, seat by seat; he pays his seats only, cash.
class IntercitySeats extends StatefulWidget {
  const IntercitySeats({super.key, required this.home, required this.pickAddress, required this.onWholeCar, this.book});

  final IntercityHome home;
  final String pickAddress;
  final VoidCallback onWholeCar;

  /// tests replace the network call
  final Future<IntercityResult> Function(int tripId, int seats)? book;

  @override
  State<IntercitySeats> createState() => _IntercitySeatsState();
}

class _IntercitySeatsState extends State<IntercitySeats> {
  final Map<int, int> _seats = {};
  int? _busy;
  final Set<int> _booked = {};

  Future<void> _book(SharedTrip t) async {
    final n = _seats[t.id] ?? 1;
    setState(() => _busy = t.id);
    final r = widget.book != null ? await widget.book!(t.id, n) : await IntercityApi.bookSeats(t.id, n, pickAddress: widget.pickAddress);
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (r.ok) _booked.add(t.id);
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(r.message, textDirection: TextDirection.rtl)));
  }

  @override
  Widget build(BuildContext context) {
    final trips = widget.home.shared;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('سائقين مختارين من الإدارة مسافرين وعندهم كراسي فاضية. تدفع كرسيك بس، نقدًا للسائق.', style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
      const SizedBox(height: 10),
      if (trips.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(18)),
          child: Text('ما فيش رحلات بالكراسي الآن.', textAlign: TextAlign.center, style: IcStyle.t(14.5)),
        ),
      for (final t in trips) _card(t),
      const SizedBox(height: 10),
      InkWell(
        onTap: widget.onWholeCar,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: IcStyle.navy, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ما لقيتش وقت يناسبك؟', style: IcStyle.t(14, c: Colors.white)),
            Text('اطلب سيارة كاملة بسعرك، والسائقين يبعتولك عروضهم.', style: IcStyle.t(12.5, w: FontWeight.w600, c: const Color(0xffC9D6EE))),
          ]),
        ),
      ),
    ]);
  }

  Widget _card(SharedTrip t) {
    final n = _seats[t.id] ?? 1;
    final d = t.driver;
    final done = _booked.contains(t.id);
    return Container(
      key: ValueKey('shared-${t.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: IcStyle.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.home.from} ← ${t.to}', style: IcStyle.t(16.5, w: FontWeight.w900)),
              Text([IntercityApi.dayLabel(t.departAt), if (t.meetingPoint.isNotEmpty) 'من ${t.meetingPoint}'].join(' · '), style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('LYD ${IcStyle.money(t.seatPrice)}', style: IcStyle.t(19, w: FontWeight.w900)),
            Text('للكرسي', style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
          ]),
        ]),
        const SizedBox(height: 6),
        Text(
          [if ('${d['name'] ?? ''}'.isNotEmpty) d['name'], if ((d['rating'] as num? ?? 0) > 0) '★ ${d['rating']}', if (d['completed'] != null) '${d['completed']} رحلة', if ('${d['car'] ?? ''}'.trim().isNotEmpty) d['car']].join(' · '),
          style: IcStyle.t(13, w: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('باقي ${t.seatsLeft} من ${t.seatsTotal}', style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
        const SizedBox(height: 8),
        if (done)
          Text('محجوز ✅ السائق يتواصل معاك قبل الموعد.', style: IcStyle.t(14, c: const Color(0xff0F8A4B)))
        else
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(14)),
              child: IcStepper(
                value: '$n',
                onPlus: n < t.seatsLeft ? () => setState(() => _seats[t.id] = n + 1) : null,
                onMinus: n > 1 ? () => setState(() => _seats[t.id] = n - 1) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy == null ? () => _book(t) : null,
                style: FilledButton.styleFrom(backgroundColor: IcStyle.blue, minimumSize: const Size.fromHeight(46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _busy == t.id
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text('احجز · LYD ${IcStyle.money(t.seatPrice * n)}', style: IcStyle.t(15, w: FontWeight.w900, c: Colors.white)),
              ),
            ),
          ]),
      ]),
    );
  }
}
