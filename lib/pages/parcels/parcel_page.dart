import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/functions.dart' show bearerToken, getWalletHistory, walletBalance;
import '../../functions/errand_api.dart';
import '../../functions/intercity_api.dart' show IcPlace, IntercityResult;
import '../../functions/parcel_api.dart';
import '../../functions/parcel_saved.dart';
import '../../functions/tr.dart';
import '../common/price_mode_box.dart';
import '../intercity/intercity_style.dart';
import '../onTripPage/open_booked_ride.dart';
import '../onTripPage/trip_place.dart' show TripPointRole;
import 'errand/errand_draft.dart';
import 'errand/errand_mode_switch.dart';
import 'errand/errand_view.dart';
import 'parcel_confirm_sheet.dart';
import 'parcel_map.dart';
import 'parcel_options.dart';
import 'parcel_places.dart';
import 'parcel_save_sheet.dart';
import 'parcel_saved_chips.dart';
import 'parcel_size_card.dart';
import 'parcel_title.dart';

/// «نوصلولك طرود»: the real map on top (where the captain takes it → where it goes, owner 2026-11-19),
/// both places editable (saved places one tap away), the size with its price for this distance, the
/// receiver (saved ones one tap away), who pays and how, the delivery code or none, and the rules
/// agreed once. Nothing is sent before «أكّد الطلب» on the summary. Booking it makes a ride the
/// nearest parcel driver takes.
class ParcelPage extends StatefulWidget {
  const ParcelPage({
    super.key,
    required this.home,
    required this.pick,
    this.pickIsHere = true,
    this.drop,
    this.receiverName,
    this.receiverPhone,
    this.size,
    this.send,
    this.pickDrop,
    this.quote,
    this.map,
    this.balance,
    this.errandPlace,
    this.errandQuote,
    this.errandSend,
  });

  final ParcelHome home;
  final IcPlace pick;

  /// «اطلبها مرة ثانية»: the last parcel's places, receiver and size
  final bool pickIsHere;
  final IcPlace? drop;
  final String? receiverName;
  final String? receiverPhone;
  final String? size;

  /// tests replace the network, the map and the wallet
  final Future<IntercityResult> Function(Map<String, Object?> parcel)? send;
  final Future<(IcPlace, IcPlace?)?> Function(TripPointRole role)? pickDrop;
  final Future<IntercityResult> Function(IcPlace pick, IcPlace drop, String size)? quote;
  final Widget Function(IcPlace pick, IcPlace? drop)? map;
  final num? Function()? balance;

  /// tests replace «مشوار بوقفات»'s search and network (see ErrandView)
  final Future<IcPlace?> Function(int? index)? errandPlace;
  final Future<IntercityResult> Function(List<IcPlace> stops, IcPlace drop)? errandQuote;
  final Future<IntercityResult> Function(List<ErrandStopData> stops, IcPlace drop)? errandSend;

  static Future<void> open(BuildContext context,
      {required ParcelHome home, required IcPlace pick, bool pickIsHere = true, IcPlace? drop, String? receiverName, String? receiverPhone, String? size}) {
    if (!home.enabled) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(tr('التوصيل مش متاح في مدينتك حاليًا.', 'Delivery is not available in your city yet.'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ParcelPage(home: home, pick: pick, pickIsHere: pickIsHere, drop: drop, receiverName: receiverName, receiverPhone: receiverPhone, size: size)));
  }

  static const sizes = ['small', 'medium', 'large'];

  @override
  State<ParcelPage> createState() => _ParcelPageState();
}

class _ParcelPageState extends State<ParcelPage> {
  late String _size = ParcelPage.sizes.contains(widget.size) ? widget.size! : 'medium';
  late IcPlace _pick = widget.pick;
  late bool _pickIsHere = widget.pickIsHere;
  late IcPlace? _drop = widget.drop;
  late final _name = TextEditingController(text: widget.receiverName ?? '');
  late final _phone = TextEditingController(text: widget.receiverPhone ?? '');
  final _note = TextEditingController();
  String _payer = 'sender';
  // «التسليم بكود»: on unless he turns it off
  bool _needsCode = true;
  bool _rules = false;
  num? _price;
  // every size's price for this distance, so each card shows its own
  Map<String, num> _prices = {};
  // «طريقة السعر»: offers when the admin says so, or his default when the rider chooses
  late bool _offers = widget.home.startWithOffers;
  num? _fare;
  num? _km;
  bool _quoting = false;
  bool _busy = false;
  String? _error;
  List<SavedReceiver> _receivers = [];
  List<SavedPickPlace> _places = [];
  // «مشوار بوقفات»: the second way the page works; its stops stay when he switches back and forth
  bool _errand = false;
  final _errandDraft = ErrandDraft();

  @override
  void initState() {
    super.initState();
    _loadSaved();
    // the wallet decides how «أنا» pays: read it once when the app has not yet
    if (widget.balance == null && walletBalance.isEmpty && bearerToken.isNotEmpty) {
      getWalletHistory().then((_) {
        if (mounted) setState(() {});
      });
    }
    if (_drop != null) WidgetsBinding.instance.addPostFrameCallback((_) => _quote());
  }

  Future<void> _loadSaved() async {
    final r = await ParcelSaved.receivers();
    final p = await ParcelSaved.places();
    if (mounted) {
      setState(() {
        _receivers = r;
        _places = p;
      });
    }
  }

  num? get _balance => widget.balance != null ? widget.balance!() : (walletBalance.isEmpty ? null : num.tryParse('${walletBalance['wallet_balance']}'));

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    _errandDraft.dispose();
    super.dispose();
  }

  Future<void> _choose(TripPointRole role) async {
    final r = widget.pickDrop != null ? await widget.pickDrop!(role) : await ParcelPlaces.choose(context, pick: _pick, drop: _drop, role: role, saved: _places);
    if (r == null || !mounted) return;
    setState(() {
      if (r.$1.lat != _pick.lat || r.$1.lng != _pick.lng) _pickIsHere = false;
      _pick = r.$1;
      _drop = r.$2;
    });
    _quote();
  }

  void _pickSaved(SavedPickPlace s) {
    setState(() {
      _pick = s.place;
      _pickIsHere = false;
    });
    _quote();
  }

  void _said(String text) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text, textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr)));

  Future<void> _removePlace(SavedPickPlace s) async {
    final left = await ParcelSaved.removePlace(s);
    if (!mounted) return;
    setState(() => _places = left);
    _said(tr('شلنا «${s.label}» من أماكنك المحفوظة.', 'Removed «${s.label}» from your saved places.'));
  }

  Future<void> _removeReceiver(SavedReceiver r) async {
    final left = await ParcelSaved.removeReceiver(r);
    if (!mounted) return;
    setState(() => _receivers = left);
    _said(tr('شلنا ${r.name} من المستلمين المحفوظين.', 'Removed ${r.name} from your saved receivers.'));
  }

  Future<void> _quote() async {
    final d = _drop;
    if (d == null) return;
    final asked = (_pick, d);
    setState(() {
      _quoting = true;
      _error = null;
    });
    final ask = widget.quote ?? (IcPlace p, IcPlace q, String size) => ParcelApi.quote(p.lat, p.lng, q.lat, q.lng, size);
    final all = await Future.wait([for (final s in ParcelPage.sizes) ask(_pick, d, s)]);
    if (!mounted || asked != (_pick, _drop)) return;
    setState(() {
      _quoting = false;
      _prices = {
        for (var i = 0; i < 3; i++)
          if (all[i].ok && all[i].data is Map && (all[i].data as Map)['price'] is num) ParcelPage.sizes[i]: (all[i].data as Map)['price'] as num,
      };
      final mine = all[ParcelPage.sizes.indexOf(_size)];
      _km = mine.data is Map ? (mine.data as Map)['km'] as num? : _km;
      _setPrice();
      if (_price == null) _error = mine.message;
    });
  }

  void _setPrice() {
    _price = _prices[_size];
    if (_price != null) _fare = PriceModeBox.start(_price!);
  }

  /// before choosing where: the size's own fixed part, so he sees what it costs from
  num? _from(String size) {
    final s = widget.home.sizes.where((e) => e['size'] == size);
    return s.isEmpty ? null : s.first['base'] as num?;
  }

  String? get _missing {
    if (_drop == null) return tr('اختار وين يوصل الطرد.', 'Choose where the parcel goes.');
    if (_quoting) return tr('استنى شوية، نحسبوا السعر.', 'One moment, pricing.');
    if (_name.text.trim().isEmpty) return tr('اكتب اسم المستلم.', 'Write the receiver\'s name.');
    if (_phone.text.replaceAll(RegExp(r'[^0-9]'), '').length < 8) return tr('اكتب رقم المستلم.', 'Write the receiver\'s number.');
    if (!_rules) return tr('أكّد إن الطرد مش من الممنوعات.', 'Confirm the parcel is not a banned item.');
    return null;
  }

  String _senderLine(String cur) => ParcelPay.senderLine(price: _offers ? (_fare ?? _price) : _price, balance: _balance, offers: _offers, currency: cur);

  ParcelSummary _summary(String cur) => ParcelSummary(
        from: _pick.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : _pick.address,
        to: _drop!.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : _drop!.address,
        receiver: _name.text.trim(),
        phone: _phone.text.trim(),
        size: '${ParcelSizeCard.icons[_size]} ${ParcelSizeCard.labels[_size]}',
        price: _price == null
            ? tr('يتحسب عند الطلب', 'Priced when you order')
            : _offers
                ? tr('سعرك $cur ${IcStyle.money(_fare ?? _price!)} · الكباتن يقبلوه أو يبعتوا عروضهم', 'Your price $cur ${IcStyle.money(_fare ?? _price!)} · captains accept it or offer theirs')
                : '$cur ${IcStyle.money(_price!)}',
        pay: _payer == 'receiver' ? tr('المستلم · ${ParcelPay.receiverLine()}', 'The receiver · ${ParcelPay.receiverLine()}') : tr('أنا · ${_senderLine(cur)}', 'Me · ${_senderLine(cur)}'),
        needsCode: _needsCode,
      );

  /// the only way an order leaves the phone: the request button, then «أكّد الطلب» on the summary
  Future<void> _send() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final why = _missing;
    if (why != null) {
      setState(() => _error = why);
      return;
    }
    setState(() => _error = null);
    if (!await ParcelConfirmSheet.show(context, _summary(widget.home.currency)) || !mounted) return;
    final d = _drop!;
    final name = _name.text.trim(), phone = _phone.text.trim(), pick = _pick;
    final parcel = <String, Object?>{
      'size': _size, 'pick': pick, 'drop': d, 'receiver_name': name, 'receiver_phone': phone, 'note': _note.text.trim(), 'payer': _payer,
      'payment': 'auto', 'needs_code': _needsCode,
      if (_offers) 'fare': _fare,
    };
    setState(() => _busy = true);
    final r = widget.send != null
        ? await widget.send!(parcel)
        : await ParcelApi.create(
            pickLat: pick.lat, pickLng: pick.lng, pickAddress: pick.address,
            dropLat: d.lat, dropLng: d.lng, dropAddress: d.address, size: _size,
            receiverName: name, receiverPhone: phone, note: _note.text, payer: _payer, needsCode: _needsCode, offerFare: _offers ? _fare : null);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    _said(r.message);
    // «نحفظ المستلم / مكان الاستلام للمرات الجاية؟» — only what is new
    await ParcelSaveSheet.maybeShow(context, name: name, phone: phone, pick: pick);
    if (!mounted) return;
    // the parcel is a ride now: the same searching screen as any ride
    if (widget.send == null) {
      await openBookedRide(context);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _setMode(bool errand) => setState(() {
        _errand = errand;
        _error = null;
        if (errand && _errandDraft.stops.isEmpty) _errandDraft.add();
      });

  @override
  Widget build(BuildContext context) {
    final errand = ErrandConfig.of(widget.home);
    final errandOn = errand != null && errand.enabled;
    if (_errand && errandOn) {
      final map = widget.map;
      return ErrandView(
        home: widget.home,
        config: errand,
        pick: _pick,
        pickIsHere: _pickIsHere,
        draft: _errandDraft,
        onMode: _setMode,
        saved: _places,
        choosePlace: widget.errandPlace,
        quote: widget.errandQuote,
        send: widget.errandSend,
        map: map == null ? null : (stops, drop) => map(stops.isEmpty ? drop : stops.first, drop),
        balance: widget.balance,
      );
    }
    final cur = widget.home.currency;
    final top = MediaQuery.of(context).padding.top;
    return IcScaffold(
      title: tr('${ParcelHome.homeNameOf(widget.home, true)} · ${widget.home.city}', '${ParcelHome.homeNameOf(widget.home, false)} · ${widget.home.city}'),
      mapHeight: 290,
      map: Stack(children: [
        Positioned.fill(
          child: widget.map?.call(_pick, _drop) ??
              ParcelMap(pick: LatLng(_pick.lat, _pick.lng), drop: _drop == null ? null : LatLng(_drop!.lat, _drop!.lng), topInset: top, bottomInset: 30),
        ),
        // how far and how much, on the map itself
        PositionedDirectional(
          bottom: 44,
          end: 14,
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _chip(cur)),
        ),
      ]),
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('parcel-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        if (_price != null)
          PriceModeBox(
            mode: widget.home.priceMode, offers: _offers, onOffers: (v) => setState(() => _offers = v),
            suggested: _price!, fare: _fare, onFare: (v) => setState(() => _fare = v),
            minPercent: widget.home.offerMinPercent, maxPercent: widget.home.offerMaxPercent, currency: cur,
          ),
        IcButton(
            key: const ValueKey('parcel-request'),
            text: _price == null
                ? tr('اطلب توصيل', 'Request delivery')
                : _offers
                    ? tr('اطلب عروض · $cur ${IcStyle.money(_fare ?? _price!)}', 'Ask for offers · $cur ${IcStyle.money(_fare ?? _price!)}')
                    : tr('اطلب توصيل · $cur ${IcStyle.money(_price!)}', 'Request delivery · $cur ${IcStyle.money(_price!)}'),
            busy: _busy,
            onTap: _send),
      ]),
      children: [
        if (errandOn) ...[
          ErrandModeSwitch(errand: false, name: errand.name, onChanged: _setMode),
          const SizedBox(height: 10),
        ],
        ParcelTitle(words: widget.home.words(appRtl)),
        const SizedBox(height: 10),
        ParcelPlaces(pick: _pick, drop: _drop, pickIsHere: _pickIsHere, onTap: _choose),
        ParcelPlaceChips(places: _places, current: _pickIsHere ? null : _pick, onPick: _pickSaved, onRemove: _removePlace),
        const SizedBox(height: 14),
        Text(tr('شن تبعت؟', 'What are you sending?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(children: [
          for (final s in ParcelPage.sizes) ...[
            if (s != 'small') const SizedBox(width: 8),
            Expanded(
              child: ParcelSizeCard(
                size: s,
                selected: s == _size,
                currency: cur,
                price: _prices[s],
                from: _from(s),
                onTap: () => setState(() {
                  _size = s;
                  _setPrice();
                }),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        ParcelReceiverChips(
          receivers: _receivers,
          onPick: (r) => setState(() {
            _name.text = r.name;
            _phone.text = r.phone;
          }),
          onRemove: _removeReceiver,
        ),
        Row(children: [
          Expanded(child: _field(_name, tr('اسم المستلم', 'Receiver\'s name'), const ValueKey('parcel-name'))),
          const SizedBox(width: 8),
          Expanded(child: _field(_phone, tr('رقم المستلم', 'Receiver\'s number'), const ValueKey('parcel-phone'), phone: true)),
        ]),
        const SizedBox(height: 8),
        _field(_note, tr('ملاحظة: الدور، البوابة… (اختياري)', 'Note: floor, gate… (optional)'), const ValueKey('parcel-note')),
        const SizedBox(height: 12),
        ParcelPayer(payer: _payer, onPayer: (v) => setState(() => _payer = v), senderLine: _senderLine(cur)),
        const SizedBox(height: 10),
        ParcelCodeSwitch(value: _needsCode, onChanged: (v) => setState(() => _needsCode = v)),
        const SizedBox(height: 12),
        if (_drop != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(
                  child: Text('${ParcelSizeCard.labels[_size]}${_km != null ? tr(' · السعر حسب المسافة (${IcStyle.money(_km!)} كم)', ' · priced by distance (${IcStyle.money(_km!)} km)') : ''}',
                      style: IcStyle.t(13.5, w: FontWeight.w700, c: IcStyle.muted))),
              _quoting
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_price == null ? '—' : '$cur ${IcStyle.money(_price!)}', key: const ValueKey('parcel-price'), style: IcStyle.t(22, w: FontWeight.w900)),
            ]),
          ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => setState(() => _rules = !_rules),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xffFFF8E6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffFDE3A7))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_rules ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, key: const ValueKey('parcel-rules'), color: const Color(0xff9A6700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    _needsCode
                        ? tr('الطرد مش من الممنوعات: ${widget.home.banned}. الكابتن يصوّره عند الاستلام، والمستلم يعطيه كود التسليم.',
                            'The parcel is not one of the banned items: ${widget.home.banned}. The captain photographs it at pick-up, and the receiver gives him the delivery code.')
                        : tr('الطرد مش من الممنوعات: ${widget.home.banned}. الكابتن يصوّره عند الاستلام وعند التسليم.',
                            'The parcel is not one of the banned items: ${widget.home.banned}. The captain photographs it at pick-up and at delivery.'),
                    style: IcStyle.t(12.5, w: FontWeight.w700, c: const Color(0xff9A6700))),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  /// «4.2 كم · 8.5 د.ل» on the map, or what to do next
  Widget _chip(String cur) {
    final text = _drop == null
        ? tr('اختار لوين توصل 👇', 'Choose where it goes 👇')
        : _quoting
            ? tr('نحسبوا السعر…', 'Pricing…')
            : _price == null
                ? null
                : '${_km != null ? tr('${IcStyle.money(_km!)} كم · ', '${IcStyle.money(_km!)} km · ') : ''}$cur ${IcStyle.money(_price!)}';
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: ValueKey(text),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x29102A56), blurRadius: 10)]),
      child: Text(text, style: IcStyle.t(13.5, w: FontWeight.w900, c: _drop == null ? IcStyle.navy : IcStyle.blue)),
    );
  }

  /// a tap anywhere else closes the keyboard, so the page stops moving under his finger (the request
  /// button sat right under «مين يدفع؟» while the keyboard was up)
  Widget _field(TextEditingController c, String hint, Key key, {bool phone = false}) => TextField(
        key: key,
        controller: c,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        textInputAction: TextInputAction.done,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textDirection: phone ? TextDirection.ltr : (appRtl ? TextDirection.rtl : TextDirection.ltr),
        style: IcStyle.t(14, w: FontWeight.w700),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
        ),
      );
}
