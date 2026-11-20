import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../functions/errand_api.dart';
import '../../../functions/functions.dart' show walletBalance;
import '../../../functions/intercity_api.dart' show IcPlace, IntercityResult;
import '../../../functions/parcel_api.dart';
import '../../../functions/parcel_saved.dart';
import '../../../functions/tr.dart';
import '../../intercity/intercity_style.dart';
import '../../onTripPage/open_booked_ride.dart';
import '../../onTripPage/trip_place.dart' show TripCopy, TripPointRole;
import '../parcel_options.dart' show ParcelPay;
import '../parcel_places.dart';
import 'errand_confirm_sheet.dart';
import 'errand_draft.dart';
import 'errand_map.dart';
import 'errand_mode_switch.dart';
import 'errand_price.dart';
import 'errand_stop_card.dart';

/// «مشوار بوقفات» (owner approved the board 2026-11-20): the captain passes by up to max_stops
/// places, takes something at each (already paid, or he pays and photographs the receipt), and
/// brings it all to him. The page shows the stops numbered on the map, the price (road + stops),
/// the free wait at each stop, and asks nothing of the server before «أكّد الطلب».
class ErrandView extends StatefulWidget {
  const ErrandView({
    super.key,
    required this.home,
    required this.config,
    required this.pick,
    required this.draft,
    required this.onMode,
    this.pickIsHere = true,
    this.saved = const [],
    this.choosePlace,
    this.quote,
    this.send,
    this.map,
    this.balance,
  });

  final ParcelHome home;
  final ErrandConfig config;

  /// where he is (the parcels page's pick): «لوين يجيبهم» starts here
  final IcPlace pick;
  final bool pickIsHere;
  final ErrandDraft draft;
  final ValueChanged<bool> onMode;
  final List<SavedPickPlace> saved;

  /// tests replace the search (index null: «لوين يجيبهم»), the network, the map and the wallet
  final Future<IcPlace?> Function(int? index)? choosePlace;
  final Future<IntercityResult> Function(List<IcPlace> stops, IcPlace drop)? quote;
  final Future<IntercityResult> Function(List<ErrandStopData> stops, IcPlace drop)? send;
  final Widget Function(List<IcPlace> stops, IcPlace drop)? map;
  final num? Function()? balance;

  @override
  State<ErrandView> createState() => _ErrandViewState();
}

class _ErrandViewState extends State<ErrandView> {
  ErrandDraft get _d => widget.draft;
  IcPlace get _drop => _d.drop ?? widget.pick;
  Map? _q;
  bool _quoting = false;
  bool _busy = false;
  String? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    if (_d.places.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _quote());
  }

  num? get _price => _q?['price'] as num?;

  static TripCopy _words(int? n) => TripCopy(
        title: n == null ? tr('لوين يجيبهم؟ 🏠', 'Where to bring them? 🏠') : tr('وين الوقفة $n؟ 🛍️', 'Where is stop $n? 🛍️'),
        labels: [tr('مكانك الآن', 'Where you are'), n == null ? tr('لوين يجيبهم', 'Where to bring them') : tr('الوقفة $n', 'Stop $n')],
        asks: [tr('وين أنت؟', 'Where are you?'), n == null ? tr('لوين الكابتن يجيب الحاجات؟', 'Where should the captain bring them?') : tr('وين الكابتن يوقف؟', 'Where does the captain stop?')],
        confirm: tr('تمام، هذا المكان', 'Done, this place'),
        mapHints: [
          tr('حط الدبوس الأخضر وين أنت.', 'Put the green pin where you are.'),
          n == null
              ? tr('حط الدبوس الأزرق وين يجيبلك الحاجات: باب البيت أو المحل.', 'Put the blue pin where he brings them: the door of the house or shop.')
              : tr('حط الدبوس الأزرق على المحل أو المكان اللي ياخذ منه الكابتن.', 'Put the blue pin on the shop or place the captain takes it from.'),
        ],
        mapConfirm: [tr('أنا هنا', 'I am here'), n == null ? tr('يجيبهم هنا', 'Bring them here') : tr('الوقفة هنا', 'The stop is here')],
      );

  Future<IcPlace?> _choose(int? index) async {
    if (widget.choosePlace != null) return widget.choosePlace!(index);
    final current = index == null ? _drop : _d.stops[index].place;
    final r = await ParcelPlaces.choose(context,
        pick: widget.pick, drop: current, role: TripPointRole.destination, saved: widget.saved, words: _words(index == null ? null : index + 1));
    return r?.$2;
  }

  Future<void> _place(int? index) async {
    final p = await _choose(index);
    if (p == null || !mounted) return;
    setState(() => index == null ? _d.drop = p : _d.stops[index].place = p);
    _quote();
  }

  Future<void> _quote() async {
    final stops = _d.places;
    final gen = ++_gen;
    if (stops.isEmpty) {
      setState(() => _q = null);
      return;
    }
    setState(() {
      _quoting = true;
      _error = null;
    });
    final r = widget.quote != null ? await widget.quote!(stops, _drop) : await ErrandApi.quote(stops, _drop);
    if (!mounted || gen != _gen) return;
    setState(() {
      _quoting = false;
      _q = r.ok && r.data is Map && (r.data as Map)['price'] is num ? r.data as Map : null;
      if (_q == null) _error = r.message;
    });
  }

  void _add() {
    if (_d.stops.length >= widget.config.maxStops) return;
    setState(_d.add);
  }

  void _remove(int i) {
    setState(() => _d.remove(i));
    _quote();
  }

  void _move(int i, int by) {
    setState(() => _d.move(i, by));
    _quote();
  }

  num? get _balance => widget.balance != null ? widget.balance!() : (walletBalance.isEmpty ? null : num.tryParse('${walletBalance['wallet_balance']}'));

  String get _payLine {
    final cur = widget.config.currency;
    return switch (ParcelPay.senderWallet(price: _price, balance: _balance, offers: false)) {
      true => tr('من محفظتك (رصيدك $cur ${IcStyle.money(_balance!)})', 'From your wallet (balance $cur ${IcStyle.money(_balance!)})'),
      false => tr('كاش للكابتن', 'Cash to the captain'),
      null => tr('من محفظتك لو رصيدك يكفي، وإلا كاش للكابتن', 'From your wallet if it covers it, else cash to the captain'),
    };
  }

  String _placeName(IcPlace p) => p.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : p.address;

  ErrandSummary _summary() {
    final cur = widget.config.currency;
    return ErrandSummary(
      name: widget.config.name,
      stops: [
        for (final s in _d.stops)
          ErrandSummaryStop(
            place: _placeName(s.place!),
            item: s.item.text.trim(),
            contact: [s.contactName.text.trim(), s.contactPhone.text.trim()].where((e) => e.isNotEmpty).join(' · '),
            pays: s.pays == 'captain'
                ? tr('الكابتن يدفع عنك (لين ${IcStyle.money(widget.config.buyMax)} $cur) وتأكد المبلغ', 'The captain pays (up to ${IcStyle.money(widget.config.buyMax)} $cur), you confirm the amount')
                : tr('مدفوعة', 'Already paid'),
          ),
      ],
      to: widget.pickIsHere && _d.drop == null ? tr('مكانك الآن · ${_placeName(_drop)}', 'Where you are · ${_placeName(_drop)}') : _placeName(_drop),
      price: _price == null ? tr('يتحسب عند الطلب', 'Priced when you order') : '$cur ${IcStyle.money(_price!)}',
      pay: _payLine,
      wait: ErrandPrice.waitLine(widget.config),
    );
  }

  void _said(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text, textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr)));

  /// the only way it leaves the phone: the request button, then «أكّد الطلب» on the summary
  Future<void> _send() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final why = _quoting ? tr('استنى شوية، نحسبوا السعر.', 'One moment, pricing.') : _d.missing(buyAllowed: widget.config.buyAllowed);
    if (why != null) {
      setState(() => _error = why);
      return;
    }
    setState(() => _error = null);
    if (!await ErrandConfirmSheet.show(context, _summary()) || !mounted) return;
    final stops = [for (final s in _d.stops) s.toData()];
    setState(() => _busy = true);
    final r = widget.send != null ? await widget.send!(stops, _drop) : await ErrandApi.create(stops, _drop);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    _said(r.message);
    // the errand is a ride now: the same screen as any ride
    if (widget.send == null) {
      await openBookedRide(context);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config, cur = cfg.currency;
    final top = MediaQuery.of(context).padding.top;
    final full = _d.stops.length >= cfg.maxStops;
    return IcScaffold(
      title: tr('${cfg.name} · ${widget.home.city}', '${cfg.name} · ${widget.home.city}'),
      mapHeight: 290,
      map: Stack(children: [
        Positioned.fill(
          child: widget.map?.call(_d.places, _drop) ??
              ErrandMap(stops: [for (final p in _d.places) LatLng(p.lat, p.lng)], drop: LatLng(_drop.lat, _drop.lng), topInset: top, bottomInset: 30),
        ),
        PositionedDirectional(bottom: 44, end: 14, child: ErrandPrice.chip(quote: _q, quoting: _quoting, hasStops: _d.places.isNotEmpty, currency: cur)),
      ]),
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('errand-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        IcButton(
          key: const ValueKey('errand-request'),
          text: _price == null ? tr('اطلب المشوار', 'Request the errand') : tr('اطلب المشوار · $cur ${IcStyle.money(_price!)}', 'Request the errand · $cur ${IcStyle.money(_price!)}'),
          busy: _busy,
          onTap: _send,
        ),
      ]),
      children: [
        ErrandModeSwitch(errand: true, name: cfg.name, onChanged: widget.onMode),
        const SizedBox(height: 12),
        Text(tr('الكابتن يعدّي على الوقفات بالترتيب ويجيبلك كل شي', 'The captain passes by the stops in order and brings you everything'),
            style: IcStyle.t(14, w: FontWeight.w800, c: IcStyle.muted)),
        const SizedBox(height: 10),
        for (var i = 0; i < _d.stops.length; i++) ...[
          ErrandStopCard(
            key: ObjectKey(_d.stops[i]),
            stop: _d.stops[i],
            index: i,
            count: _d.stops.length,
            config: cfg,
            onPlace: () => _place(i),
            onPays: (v) => setState(() => _d.stops[i].pays = v),
            onMove: (by) => _move(i, by),
            onRemove: () => _remove(i),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          key: const ValueKey('errand-add'),
          onPressed: full ? null : _add,
          style: OutlinedButton.styleFrom(
            foregroundColor: IcStyle.blue,
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: full ? IcStyle.line : IcStyle.blue, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(full ? tr('وصلت لأقصى عدد (${cfg.maxStops} وقفات)', 'That is the most (${cfg.maxStops} stops)') : tr('زيد وقفة (لين ${cfg.maxStops})', 'Add a stop (up to ${cfg.maxStops})'),
              style: IcStyle.t(14, w: FontWeight.w900, c: full ? IcStyle.muted : IcStyle.blue)),
        ),
        const SizedBox(height: 12),
        _dropRow(),
        const SizedBox(height: 12),
        ErrandPrice(quote: _q, quoting: _quoting, config: cfg),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 20, color: IcStyle.navy),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('الدفع: $_payLine', 'Payment: $_payLine'), key: const ValueKey('errand-pay-line'), style: IcStyle.t(13, w: FontWeight.w700, c: IcStyle.navy))),
        ]),
        const SizedBox(height: 10),
        _rules(),
      ],
    );
  }

  Widget _dropRow() {
    final here = widget.pickIsHere && _d.drop == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('errand-drop'),
        onTap: () => _place(null),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line, width: 1.5)),
          child: Row(children: [
            const Icon(Icons.flag_rounded, color: Color(0xff16A34A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('لوين يجيبهم', 'Where to bring them'), style: IcStyle.t(12, w: FontWeight.w800, c: const Color(0xff16A34A))),
                Text(here ? tr('مكانك الآن · ${_placeName(_drop)}', 'Where you are · ${_placeName(_drop)}') : _placeName(_drop),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14.5, w: FontWeight.w800)),
              ]),
            ),
            const Icon(Icons.chevron_left_rounded, color: IcStyle.muted),
          ]),
        ),
      ),
    );
  }

  Widget _rules() => InkWell(
        onTap: () => setState(() => _d.rules = !_d.rules),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xffFFF8E6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffFDE3A7))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_d.rules ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, key: const ValueKey('errand-rules'), color: const Color(0xff9A6700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  tr('الحاجات مش من الممنوعات: ${widget.home.banned}. الكابتن يصوّر كل شي ياخذه.',
                      'The items are not banned: ${widget.home.banned}. The captain photographs everything he takes.'),
                  style: IcStyle.t(12.5, w: FontWeight.w700, c: const Color(0xff9A6700))),
            ),
          ]),
        ),
      );
}
