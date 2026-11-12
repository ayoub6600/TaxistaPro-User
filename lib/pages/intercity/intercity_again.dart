import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_fare_page.dart';
import 'intercity_seats.dart';
import 'intercity_style.dart';

/// «نفس السفرة مرة ثانية»: his last travel from this city, on top of «كيف تحب تسافر؟».
/// One tap fills everything (where, riders, bag, round trip, price); only the time is left.
class IcAgainCard extends StatelessWidget {
  const IcAgainCard({super.key, required this.home, required this.last, required this.pick});

  final IntercityHome home;
  final IntercityLastTrip last;
  final IcPlace pick;

  IntercityRoute? get _route {
    for (final r in home.routes) {
      if (r.id == last.routeId) return r;
    }
    return null;
  }

  String get _details {
    if (last.isSeat) {
      final seats = last.seats == 1 ? 'كرسي' : (last.seats == 2 ? 'كرسيين' : '${last.seats} كراسي');
      return '$seats · LYD ${IcStyle.money(last.paid)}';
    }
    final riders = last.passengers == 1 ? 'راكب' : (last.passengers == 2 ? 'راكبين' : '${last.passengers} ركاب');
    return [riders, if (last.roundTrip) 'ذهاب ورجوع', 'LYD ${IcStyle.money(last.price)}'].join(' · ');
  }

  String get _seatsLine => last.openTrips == 0
      ? 'ما فيش رحلات بالكراسي الآن'
      : '${last.openTrips == 1 ? 'رحلة وحدة متاحة' : '${last.openTrips} رحلات متاحة'}${last.cheapestSeat != null ? ' · من LYD ${IcStyle.money(last.cheapestSeat!)}' : ''}';

  void _open(BuildContext context) {
    final route = _route;
    if (route == null) return;
    final nav = Navigator.of(context);
    if (last.isSeat) {
      nav.push(MaterialPageRoute(builder: (_) => IntercitySeatsPage(home: home, pickAddress: pick.address, routeTo: route.to)));
      return;
    }
    nav.push(MaterialPageRoute(builder: (_) => IntercityFarePage(home: home, pick: pick, route: route, drop: last.drop, again: last)));
  }

  @override
  Widget build(BuildContext context) {
    if (_route == null) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('ic-again'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffEAF2FF), Colors.white], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffC9DCFB), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IcIconTile(
            icon: last.isSeat ? Icons.event_seat_rounded : Icons.luggage_rounded,
            background: last.isSeat ? const Color(0xffFFF4D6) : IcStyle.blue,
            color: last.isSeat ? const Color(0xffB45309) : Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('سفرتك الأخيرة · ${last.dateLabel}', style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
              Text('${home.from} ${last.roundTrip ? '⇄' : '←'} ${last.to}', style: IcStyle.t(18, w: FontWeight.w900)),
              Text(_details, style: IcStyle.t(13.5, w: FontWeight.w800, c: IcStyle.blue)),
            ]),
          ),
        ]),
        if (!last.isSeat && last.priceChanged) ...[
          const SizedBox(height: 8),
          IcPriceChanged(was: last.paid, now: last.price),
        ],
        if (last.isSeat) ...[
          const SizedBox(height: 6),
          Text(_seatsLine, style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
        ],
        const SizedBox(height: 10),
        IcButton(text: last.isSeat ? 'شوف الكراسي إلى ${last.to}' : 'اطلبها مرة ثانية', onTap: () => _open(context)),
      ]),
    );
  }
}

/// «وصلت بالسلامة 🌟 · كيف كانت السفرة مع محمد؟» — a seat in a shared trip, once.
/// Returns true when he sent his stars.
class IntercityRateSheet extends StatefulWidget {
  const IntercityRateSheet({super.key, required this.toRate, this.send});

  final IntercityToRate toRate;

  /// tests replace the network call
  final Future<IntercityResult> Function(int stars, List<String> tags)? send;

  static final Set<int> _shown = {};

  /// at most once per booking while the app is open
  static Future<bool?> maybeShow(BuildContext context, IntercityToRate? r) async {
    if (r == null || r.bookingId == 0 || _shown.contains(r.bookingId)) return null;
    _shown.add(r.bookingId);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: IntercityRateSheet(toRate: r)),
    );
  }

  static const tags = {'on_time': 'في الموعد', 'clean': 'سيارة نظيفة', 'safe': 'سواقة آمنة', 'late': 'تأخر', 'many_stops': 'وقف كثير'};

  @override
  State<IntercityRateSheet> createState() => _IntercityRateSheetState();
}

class _IntercityRateSheetState extends State<IntercityRateSheet> {
  int _stars = 0;
  final Set<String> _tags = {};
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    if (_stars == 0) {
      setState(() => _error = 'اختار عدد النجوم.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null ? await widget.send!(_stars, _tags.toList()) : await IntercityApi.rateSeat(widget.toRate.bookingId, _stars, _tags.toList());
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.toRate;
    final seats = r.seats == 1 ? 'كرسي' : (r.seats == 2 ? 'كرسيين' : '${r.seats} كراسي');
    final initial = r.driver.isEmpty ? 'ك' : r.driver.characters.first;
    return IcSheet(children: [
      Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: Color(0xffE7F8EE), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Color(0xff16803C), size: 32),
        ),
      ),
      const SizedBox(height: 8),
      Text('وصلت بالسلامة 🌟', textAlign: TextAlign.center, style: IcStyle.t(21, w: FontWeight.w900)),
      Text('← ${r.to} · $seats · LYD ${IcStyle.money(r.price)}', textAlign: TextAlign.center, style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.muted)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(radius: 16, backgroundColor: const Color(0xffDCE8FB), child: Text(initial, style: IcStyle.t(14, w: FontWeight.w900, c: IcStyle.blue))),
        const SizedBox(width: 8),
        Text('كيف كانت السفرة مع ${r.driver}؟', style: IcStyle.t(15.5, w: FontWeight.w900)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            label: '$i نجوم',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => setState(() {
                _stars = i;
                _error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 42, color: i <= _stars ? const Color(0xffF5A400) : const Color(0xffC9D3E3)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
        for (final e in IntercityRateSheet.tags.entries)
          IcChip(
            text: e.value,
            selected: _tags.contains(e.key),
            onTap: () => setState(() => _tags.contains(e.key) ? _tags.remove(e.key) : _tags.add(e.key)),
          ),
      ]),
      const SizedBox(height: 12),
      if (_error != null) ...[
        Text(_error!, textAlign: TextAlign.center, style: IcStyle.t(13, c: const Color(0xffD92D20))),
        const SizedBox(height: 6),
      ],
      IcButton(text: 'أرسل التقييم', busy: _busy, onTap: _send),
      const SizedBox(height: 6),
      IcButton(text: 'بعدين', ghost: true, onTap: () => Navigator.of(context).pop(false)),
    ]);
  }
}
