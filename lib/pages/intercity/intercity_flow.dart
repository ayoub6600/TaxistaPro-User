import 'package:flutter/material.dart';

import '../../functions/intercity_api.dart';
import 'intercity_again.dart';
import 'intercity_fare_page.dart';
import 'intercity_seats.dart';
import 'intercity_style.dart';

/// «سفر لمدينة ثانية»: كيف تحب تسافر؟ → (سيارة كاملة → الركاب والأجرة → العروض) أو (كرسي في رحلة).
class IntercityFlow {
  /// from the home «سفر» button
  static Future<void> start(BuildContext context, {required IntercityHome home, required IcPlace pick, IcPlace? drop, int? routeId}) {
    if (!home.enabled || home.routes.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('السفر مش متاح من مدينتك حاليًا.', textDirection: TextDirection.rtl)));
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
        textDirection: TextDirection.rtl,
        child: IcSheet(children: [
          Row(children: [
            const IcIconTile(icon: Icons.luggage_rounded, background: Color(0xffEAF2FF), color: IcStyle.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('وجهتك في ${route.to}', style: IcStyle.t(21, w: FontWeight.w900)),
                Text('تحب تحجزها سفر؟ تحط سعرك والسائقين يبعتولك عروض.', style: IcStyle.t(13.5, w: FontWeight.w600, c: IcStyle.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text('${home.from} ← ${route.to}', style: IcStyle.t(14.5))),
              Text('من LYD ${IcStyle.money(from ?? route.suggested)}', style: IcStyle.t(14.5, w: FontWeight.w900, c: IcStyle.blue)),
            ]),
          ),
          const SizedBox(height: 12),
          IcButton(text: 'سفر إلى ${route.to}', onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 8),
          IcButton(text: 'غيّر الوجهة', ghost: true, onTap: () => Navigator.pop(ctx, false)),
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

/// ب · كيف تحب تسافر؟ — the city, then a whole car or a seat in a trip
class IntercityTypePage extends StatefulWidget {
  const IntercityTypePage({super.key, required this.home, required this.pick, this.drop, this.routeId});

  final IntercityHome home;
  final IcPlace pick;
  final IcPlace? drop;
  final int? routeId;

  @override
  State<IntercityTypePage> createState() => _IntercityTypePageState();
}

class _IntercityTypePageState extends State<IntercityTypePage> {
  // the city he chose, else the one he travelled to last time, else the first
  late IntercityRoute _route = widget.home.routes
      .firstWhere((r) => r.id == (widget.routeId ?? widget.home.lastTrip?.routeId), orElse: () => widget.home.routes.first);
  bool _seats = false;

  int get _sharedHere => widget.home.shared.where((t) => t.to == _route.to).length;

  @override
  void initState() {
    super.initState();
    // a seat he travelled in and has not rated: ask once, gently
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final sent = await IntercityRateSheet.maybeShow(context, widget.home.toRate);
      if (sent == true && mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('شكرًا على تقييمك 🌟', textDirection: TextDirection.rtl)));
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
    return IcScaffold(
      title: '${widget.home.from} ← ${_route.to}',
      mapHeight: 330,
      children: [
        if (widget.home.lastTrip != null) ...[
          IcAgainCard(home: widget.home, last: widget.home.lastTrip!, pick: widget.pick),
          const SizedBox(height: 14),
        ],
        Text('كيف تحب تسافر؟', style: IcStyle.t(22, w: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final r in widget.home.routes) IcChip(text: r.to, selected: r.id == _route.id, onTap: () => setState(() => _route = r)),
        ]),
        const SizedBox(height: 12),
        IcOption(
          selected: !_seats,
          icon: Icons.directions_car_filled_rounded,
          iconBackground: IcStyle.blue,
          iconColor: Colors.white,
          title: 'سيارة كاملة',
          subtitle: 'أنت ومن معاك بس · من LYD ${IcStyle.money(_route.suggested)}',
          onTap: () => setState(() => _seats = false),
        ),
        const SizedBox(height: 10),
        IcOption(
          selected: _seats,
          icon: Icons.event_seat_rounded,
          iconBackground: const Color(0xffFFF4D6),
          iconColor: const Color(0xffB45309),
          title: 'كرسي في رحلة',
          subtitle: _sharedHere == 0
              ? 'تدفع كرسيك بس${_route.seatPrice != null ? ' · من LYD ${IcStyle.money(_route.seatPrice!)}' : ''}'
              : 'تدفع كرسيك بس · $_sharedHere ${_sharedHere == 1 ? 'رحلة متاحة' : 'رحلات متاحة'}',
          onTap: () => setState(() => _seats = true),
        ),
        const SizedBox(height: 14),
        IcButton(text: 'التالي', onTap: _next),
      ],
    );
  }
}
