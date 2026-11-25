import 'package:flutter/material.dart';
import '../../functions/tr.dart';

import '../../functions/intercity_api.dart';
import 'intercity_again.dart';
import 'intercity_fare_page.dart';
import 'intercity_seats.dart';
import 'intercity_style.dart';
import 'intercity_trip_map.dart';
import 'intercity_type_widgets.dart';

/// «سفر لمدينة ثانية»: كيف تحب تسافر؟ → (سيارة كاملة → الركاب والأجرة → العروض) أو (كرسي في رحلة).
class IntercityFlow {
  /// from the home «سفر» button
  static Future<void> start(BuildContext context, {required IntercityHome home, required IcPlace pick, IcPlace? drop, int? routeId}) {
    if (!home.enabled || home.routes.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('السفر مش متاح من مدينتك حاليًا.', 'Intercity travel is not available from your city yet.'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => IntercityTypePage(home: home, pick: pick, drop: drop, routeId: routeId)));
  }

  /// the rider typed a place in another city: «وجهتك في طرابلس، تحب تحجزها سفر؟»
  static Future<bool> ask(BuildContext context, {required IntercityHome home, required IcPlace pick, required IcPlace drop, int? routeId, num? from}) async {
    final route = home.routes.firstWhere((r) => r.id == routeId, orElse: () => home.routes.first);
    final yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: IcSheet(children: [
          Row(children: [
            const IcIconTile(icon: Icons.luggage_rounded, background: Color(0xffEAF2FF), color: IcStyle.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('وجهتك في ${route.to}', 'Your destination in ${route.to}'), style: IcStyle.t(21, w: FontWeight.w900)),
                Text(tr('تحب تحجزها سفر؟ تحط سعرك والسائقين يبعتولك عروض.', 'Book it as a trip? Set your price and drivers send you offers.'), style: IcStyle.t(13.5, w: FontWeight.w600, c: IcStyle.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text('${home.from} ← ${route.to}', style: IcStyle.t(14.5))),
              Text(tr('من LYD ${IcStyle.money(from ?? route.suggested)}', 'From LYD ${IcStyle.money(from ?? route.suggested)}'), style: IcStyle.t(14.5, w: FontWeight.w900, c: IcStyle.blue)),
            ]),
          ),
          const SizedBox(height: 12),
          IcButton(text: tr('سفر إلى ${route.to}', 'Trip to ${route.to}'), onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 8),
          IcButton(text: tr('غيّر الوجهة', 'Change the destination'), ghost: true, onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    );
    if (yes == true && context.mounted) {
      await start(context, home: home, pick: pick, drop: drop, routeId: route.id);
      return true;
    }
    return false;
  }
}

/// ب · كيف تحب تسافر؟ — the city (with the drive to it), then a whole car or a seat in a trip, each
/// with its price from. The map on top shows where he stands and the city he chose.
class IntercityTypePage extends StatefulWidget {
  const IntercityTypePage({super.key, required this.home, required this.pick, this.drop, this.routeId, this.map});

  final IntercityHome home;
  final IcPlace pick;
  final IcPlace? drop;
  final int? routeId;

  /// tests replace the real map
  final Widget Function(IcPlace pick, IntercityRoute route)? map;

  @override
  State<IntercityTypePage> createState() => _IntercityTypePageState();
}

class _IntercityTypePageState extends State<IntercityTypePage> {
  // the city he chose, else the one he travelled to last time, else the first
  late IntercityRoute _route = widget.home.routes
      .firstWhere((r) => r.id == (widget.routeId ?? widget.home.lastTrip?.routeId), orElse: () => widget.home.routes.first);
  bool _seats = false;

  @override
  void initState() {
    super.initState();
    // a seat he travelled in and has not rated: ask once, gently
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final sent = await IntercityRateSheet.maybeShow(context, widget.home.toRate);
      if (sent == true && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('شكرًا على تقييمك 🌟', 'Thanks for your rating 🌟'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      }
    });
  }

  void _next() {
    final nav = Navigator.of(context);
    if (_seats) {
      nav.push(MaterialPageRoute(builder: (_) => IntercitySeatsPage(home: widget.home, pickAddress: widget.pick.address, routeTo: _route.to)));
    } else {
      // a place chosen in another city keeps its exact point; a city picked from the chips goes to its centre
      final drop = widget.drop != null && _route.id == widget.routeId ? widget.drop : null;
      nav.push(MaterialPageRoute(builder: (_) => IntercityFarePage(home: widget.home, pick: widget.pick, drop: drop, route: _route)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.home, city = _route.to;
    final trips = home.shared.where((t) => t.to == city).toList();
    // «كرسي» with no trip to this city: say so in the card, and the button offers the whole car
    final noTrip = _seats && trips.isEmpty;
    // «من»: the cheapest seat a captain posted to this city, else the admin's seat price
    final seatFrom = trips.isEmpty ? _route.seatPrice : trips.map((t) => t.seatPrice).reduce((a, b) => a < b ? a : b);
    // «ذهاب ورجوع» only where the next page offers it
    final round = home.roundTripOn ? _route.roundTrip : null;
    final back = round == null ? null : round['suggested'];
    return IcTypeScaffold(
      title: '${home.from} ← $city',
      note: IcStyle.travelTime(_route.travelMinutes),
      map: widget.map?.call(widget.pick, _route) ??
          IcTripMap(pick: widget.pick, route: _route, topInset: MediaQuery.of(context).padding.top + IcTypeScaffold.barHeight, bottomInset: IcTypeScaffold.overlap),
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (noTrip)
          Text(tr('مستعجل؟ السيارة الكاملة تطلع توّا، والكباتن يبعثولك عروضهم', 'In a hurry? A whole car leaves now, and captains send you their offers'), textAlign: TextAlign.center, style: IcStyle.t(12, c: IcStyle.muted))
        else
          IcSteps(_seats
              ? [tr('تختار الرحلة', 'Pick a trip'), tr('تحجز كرسيك', 'Book your seat'), tr('الكابتن يكلمك قبل الموعد', 'The captain calls you before')]
              : [tr('تحدد سعرك', 'Set your price'), tr('الكباتن يبعثوا عروضهم', 'Captains send offers'), tr('تختار الكابتن', 'Pick your captain')]),
        const SizedBox(height: 11),
        DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x470873FF), blurRadius: 22, offset: Offset(0, 10))]),
          child: noTrip
              ? IcButton(text: tr('اطلب سيارة كاملة بدلها', 'Book a whole car instead'), onTap: () => setState(() => _seats = false))
              : IcButton(text: _seats ? tr('التالي: كرسي ${icToCity(city)}', 'Next: a seat to $city') : tr('التالي: سيارة كاملة ${icToCity(city)}', 'Next: whole car to $city'), onTap: _next),
        ),
      ]),
      children: [
        if (home.lastTrip != null) ...[
          IcAgainCard(home: home, last: home.lastTrip!, pick: widget.pick),
          const SizedBox(height: 14),
        ],
        Text(tr('وين مسافر؟', 'Where to?'), style: IcStyle.t(21, w: FontWeight.w900, h: 1.3)),
        const SizedBox(height: 11),
        _cities(),
        const SizedBox(height: 13),
        Text(tr('كيف تحب تسافر؟', 'How would you like to travel?'), style: IcStyle.t(17, w: FontWeight.w900, h: 1.3)),
        const SizedBox(height: 11),
        IcTravelOption(
          selected: !_seats,
          compact: noTrip,
          icon: Icons.directions_car_outlined,
          title: tr('سيارة كاملة', 'Whole car'),
          subtitle: tr('أنت ومن معاك بس، من الباب للباب', 'Just you and your company, door to door'),
          price: _route.suggested,
          tags: [
            tr('لين ${home.maxPassengers} ركاب', 'Up to ${home.maxPassengers} riders'),
            tr('تحدد سعرك', 'You set the price'),
            if (back is num) '${tr('ذهاب ورجوع', 'Round trip')} ${IcStyle.lyd(back)}',
          ],
          onTap: () => setState(() => _seats = false),
        ),
        const SizedBox(height: 11),
        IcTravelOption(
          selected: _seats,
          warm: true,
          icon: Icons.event_seat_outlined,
          title: tr('كرسي في رحلة', 'A seat on a trip'),
          subtitle: tr('تدفع كرسيك بس، مع ركاب آخرين', 'You pay only your seat, with other riders'),
          price: seatFrom,
          tags: [
            tr('أرخص', 'Cheaper'),
            tr('رحلات بمواعيد محددة', 'Trips at set times'),
            if (trips.isNotEmpty) tr('${trips.length} ${trips.length == 1 || trips.length > 10 ? 'رحلة متاحة' : 'رحلات متاحة'}', '${trips.length} ${trips.length == 1 ? 'trip available' : 'trips available'}'),
          ],
          onTap: () => setState(() => _seats = true),
          child: noTrip ? IcNoTripNotice(city: city) : null,
        ),
      ],
    );
  }

  /// the cities side by side, each as wide as the others; many of them scroll sideways
  Widget _cities() {
    final cards = [
      for (final r in widget.home.routes)
        IcDestCard(city: r.to, time: IcStyle.travelTime(r.travelMinutes, short: true), selected: r.id == _route.id, onTap: () => setState(() => _route = r)),
    ];
    if (cards.length > 4) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final (i, c) in cards.indexed) Padding(padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 8), child: SizedBox(width: 104, child: c)),
        ]),
      );
    }
    return Row(children: [
      for (final (i, c) in cards.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: c),
      ],
    ]);
  }
}
