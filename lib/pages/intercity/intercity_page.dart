import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_car_form.dart';
import 'intercity_seats.dart';
import 'intercity_style.dart';

/// «سفر لمدينة ثانية»: a whole car at his price (drivers answer with price and time), or a seat in
/// a trip a chosen driver posted.
class IntercityPage extends StatefulWidget {
  const IntercityPage({super.key, required this.home, required this.pick, this.drop, this.routeId, this.seats = false});

  final IntercityHome home;
  final IcPlace pick;
  final IcPlace? drop;
  final int? routeId;
  final bool seats;

  static Future<void> open(BuildContext context, {required IntercityHome home, required IcPlace pick, IcPlace? drop, int? routeId, bool seats = false}) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => IntercityPage(home: home, pick: pick, drop: drop, routeId: routeId, seats: seats)));
  }

  @override
  State<IntercityPage> createState() => _IntercityPageState();
}

class _IntercityPageState extends State<IntercityPage> {
  late bool _seats = widget.seats;
  String? _done;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _done != null ? _doneView() : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: IcStyle.navy),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: IcStyle.navy, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.alt_route_rounded, color: IcStyle.gold, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('سفر لمدينة ثانية', style: IcStyle.t(20, w: FontWeight.w900)),
                  Text('من ${widget.home.from}', style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _tab('سيارة كاملة لك', !_seats, () => setState(() => _seats = false)),
                _tab('كرسي في رحلة${widget.home.shared.isEmpty ? '' : ' (${widget.home.shared.length})'}', _seats, () => setState(() => _seats = true)),
              ]),
            ),
            const SizedBox(height: 14),
            if (_seats)
              IntercitySeats(home: widget.home, pickAddress: widget.pick.address, onWholeCar: () => setState(() => _seats = false))
            else
              IntercityCarForm(
                home: widget.home,
                pick: widget.pick,
                drop: widget.drop,
                routeId: widget.routeId,
                onBooked: (m) => setState(() => _done = m),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _tab(String text, bool on, VoidCallback tap) => Expanded(
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? IcStyle.blue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Text(text, style: IcStyle.t(14, w: on ? FontWeight.w900 : FontWeight.w700, c: on ? Colors.white : IcStyle.muted)),
          ),
        ),
      );

  Widget _doneView() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: const Color(0xffDCFCE7), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.check_rounded, color: Color(0xff16803C), size: 40),
            ),
          ),
          const SizedBox(height: 14),
          Text('طلبك وصل 👍', textAlign: TextAlign.center, style: IcStyle.t(23, w: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(_done!, textAlign: TextAlign.center, style: IcStyle.t(15, w: FontWeight.w600, c: IcStyle.muted)),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(backgroundColor: IcStyle.blue, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('تمام', style: IcStyle.t(16, w: FontWeight.w900, c: Colors.white)),
          ),
        ]),
      );
}

/// The card in «خطط لرحلتك», only where the city has intercity routes.
class IntercityEntryCard extends StatelessWidget {
  const IntercityEntryCard({super.key, required this.home, required this.onOpen});

  final IntercityHome home;
  final void Function(int? routeId, bool seats) onOpen;

  @override
  Widget build(BuildContext context) {
    if (!home.enabled || home.routes.isEmpty) return const SizedBox.shrink();
    final shared = home.shared.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: IcStyle.navy,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: const ValueKey('intercity-entry'),
          onTap: () => onOpen(null, false),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: IcStyle.gold, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.alt_route_rounded, color: IcStyle.navy, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('سفر لمدينة ثانية', style: IcStyle.t(15, w: FontWeight.w900, c: Colors.white))),
                if (shared > 0)
                  InkWell(
                    onTap: () => onOpen(null, true),
                    child: Text(shared == 1 ? 'رحلة بالكراسي' : '$shared رحلات بالكراسي', style: IcStyle.t(12, w: FontWeight.w800, c: IcStyle.gold)),
                  ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final r in home.routes)
                  InkWell(
                    onTap: () => onOpen(r.id, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                      child: Text(r.to, style: IcStyle.t(13, w: FontWeight.w800, c: Colors.white)),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
