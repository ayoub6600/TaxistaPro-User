import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/functions.dart' show getUserDetails, geoCoding, mapType, userRequestData;
import '../../functions/intercity_api.dart' show IcPlace, IntercityResult;
import '../../functions/parcel_api.dart';
import '../intercity/intercity_style.dart';
import '../onTripPage/trip_map_picker.dart';
import '../onTripPage/trip_place.dart';

/// «توصيل · شن تبعت؟»: the size, where it goes (on the map), who receives it, who pays, the admin's
/// price for it, and the rules agreed once. Booking it makes a ride the nearest parcel driver takes.
class ParcelPage extends StatefulWidget {
  const ParcelPage({super.key, required this.home, required this.pick, this.send, this.pickDrop});

  final ParcelHome home;
  final IcPlace pick;

  /// tests replace the network and the map
  final Future<IntercityResult> Function(Map<String, Object?> parcel)? send;
  final Future<IcPlace?> Function()? pickDrop;

  static Future<void> open(BuildContext context, {required ParcelHome home, required IcPlace pick}) {
    if (!home.enabled) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('التوصيل مش متاح في مدينتك حاليًا.', textDirection: TextDirection.rtl)));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => ParcelPage(home: home, pick: pick)));
  }

  static Timer? _watch;

  /// A booked parcel has no searching screen of its own: look every 8 seconds (for 3 minutes)
  /// until a driver took it, so the home screen turns into the ride with the delivery code.
  static void watchForDriver() {
    _watch?.cancel();
    var left = 22;
    unawaited(Future(() => getUserDetails()));
    _watch = Timer.periodic(const Duration(seconds: 8), (t) async {
      if (--left <= 0 || userRequestData.isNotEmpty) {
        t.cancel();
        return;
      }
      await getUserDetails();
      if (userRequestData.isNotEmpty) t.cancel();
    });
  }

  static const labels = {'small': 'صغير', 'medium': 'متوسط', 'large': 'كبير'};
  static const hints = {'small': 'ظرف أو علبة', 'medium': 'شنطة أو كرتونة', 'large': 'الكرسي الخلفي'};
  static const icons = {'small': '✉️', 'medium': '👜', 'large': '📦'};

  @override
  State<ParcelPage> createState() => _ParcelPageState();
}

class _ParcelPageState extends State<ParcelPage> {
  String _size = 'medium';
  IcPlace? _drop;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  String _payer = 'sender';
  bool _rules = false;
  num? _price;
  num? _km;
  bool _quoting = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseDrop() async {
    final place = widget.pickDrop != null
        ? await widget.pickDrop!()
        : await Navigator.of(context).push<TripPlace?>(MaterialPageRoute(
            builder: (_) => TripMapPicker(
              rtl: true,
              role: TripPointRole.destination,
              initialCenter: LatLng(widget.pick.lat, widget.pick.lng),
              reverseGeocode: (p) => geoCoding(p.latitude, p.longitude),
              // the same map the home screen uses
              useGoogleMap: mapType == 'google',
            ),
          )).then((p) => p?.coordinates == null ? null : IcPlace(p!.coordinates!.latitude, p.coordinates!.longitude, p.address));
    if (place == null || !mounted) return;
    setState(() => _drop = place);
    _quote();
  }

  Future<void> _quote() async {
    final d = _drop;
    if (d == null) return;
    setState(() {
      _quoting = true;
      _error = null;
    });
    final r = await ParcelApi.quote(widget.pick.lat, widget.pick.lng, d.lat, d.lng, _size);
    if (!mounted) return;
    setState(() {
      _quoting = false;
      if (r.ok && r.data is Map) {
        _price = (r.data as Map)['price'] as num?;
        _km = (r.data as Map)['km'] as num?;
      } else {
        _price = null;
        _error = r.message;
      }
    });
  }

  /// before choosing where: the size's own fixed part, so he sees what it costs from
  num? _from(String size) {
    final s = widget.home.sizes.where((e) => e['size'] == size);
    return s.isEmpty ? null : s.first['base'] as num?;
  }

  String? get _missing {
    if (_drop == null) return 'اختار وين يوصل الطرد.';
    if (_name.text.trim().isEmpty) return 'اكتب اسم المستلم.';
    if (_phone.text.replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'اكتب رقم المستلم.';
    if (!_rules) return 'أكّد إن الطرد مش من الممنوعات.';
    return null;
  }

  Future<void> _send() async {
    final why = _missing;
    if (why != null) {
      setState(() => _error = why);
      return;
    }
    final d = _drop!;
    final parcel = <String, Object?>{
      'size': _size, 'drop': d, 'receiver_name': _name.text.trim(), 'receiver_phone': _phone.text.trim(), 'note': _note.text.trim(), 'payer': _payer,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null
        ? await widget.send!(parcel)
        : await ParcelApi.create(
            pickLat: widget.pick.lat, pickLng: widget.pick.lng, pickAddress: widget.pick.address,
            dropLat: d.lat, dropLng: d.lng, dropAddress: d.address, size: _size,
            receiverName: _name.text.trim(), receiverPhone: _phone.text.trim(), note: _note.text, payer: _payer, payment: 'cash');
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    // the parcel is a ride now: the home screen follows it like any ride once a driver takes it
    if (widget.send == null) ParcelPage.watchForDriver();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(r.message, textDirection: TextDirection.rtl)));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.home.currency;
    return IcScaffold(
      title: 'توصيل · ${widget.home.city}',
      mapHeight: 150,
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('parcel-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        IcButton(text: _price == null ? 'اطلب توصيل' : 'اطلب توصيل · $cur ${IcStyle.money(_price!)}', busy: _busy, onTap: _send),
      ]),
      children: [
        Text('شن تبعت؟ 📦', style: IcStyle.t(22, w: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: [
          for (final s in const ['small', 'medium', 'large']) ...[
            if (s != 'small') const SizedBox(width: 8),
            Expanded(child: _sizeCard(s, cur)),
          ],
        ]),
        const SizedBox(height: 12),
        _row(Icons.place_rounded, _drop == null ? 'وين يوصل؟' : _drop!.address.isEmpty ? 'المكان على الخريطة' : _drop!.address, _chooseDrop,
            muted: _drop == null, key: const ValueKey('parcel-drop')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _field(_name, 'اسم المستلم', const ValueKey('parcel-name'))),
          const SizedBox(width: 8),
          Expanded(child: _field(_phone, 'رقم المستلم', const ValueKey('parcel-phone'), phone: true)),
        ]),
        const SizedBox(height: 8),
        _field(_note, 'ملاحظة: الدور، البوابة… (اختياري)', const ValueKey('parcel-note')),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: Text('مين يدفع؟', style: IcStyle.t(15, w: FontWeight.w900))),
          IcChip(text: 'أنا', selected: _payer == 'sender', onTap: () => setState(() => _payer = 'sender')),
          IcChip(text: 'المستلم (نقدًا)', selected: _payer == 'receiver', onTap: () => setState(() => _payer = 'receiver')),
        ]),
        const SizedBox(height: 12),
        if (_drop != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Text('${ParcelPage.labels[_size]}${_km != null ? ' · ${IcStyle.money(_km!)} كم' : ''}', style: IcStyle.t(13.5, w: FontWeight.w700, c: IcStyle.muted))),
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
                child: Text('الطرد مش من الممنوعات: ${widget.home.banned}. الكابتن يصوّره عند الاستلام، والمستلم يعطيه كود التسليم.',
                    style: IcStyle.t(12.5, w: FontWeight.w700, c: const Color(0xff9A6700))),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sizeCard(String s, String cur) {
    final on = s == _size;
    final from = _from(s);
    return Semantics(
      button: true,
      selected: on,
      label: ParcelPage.labels[s],
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          setState(() => _size = s);
          _quote();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xffF5F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? IcStyle.blue : IcStyle.line, width: on ? 2 : 1.5),
          ),
          child: Column(children: [
            Text(ParcelPage.icons[s]!, style: const TextStyle(fontSize: 24)),
            Text(ParcelPage.labels[s]!, style: IcStyle.t(14.5, w: FontWeight.w900)),
            Text(ParcelPage.hints[s]!, textAlign: TextAlign.center, style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
            if (from != null) Text('من $cur ${IcStyle.money(from)}', style: IcStyle.t(11.5, w: FontWeight.w800, c: IcStyle.blue)),
          ]),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback onTap, {bool muted = false, Key? key}) => InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: IcStyle.line, width: 1.5)),
          child: Row(children: [
            Icon(icon, color: const Color(0xffE11D48)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14.5, c: muted ? IcStyle.muted : IcStyle.navy))),
            const Icon(Icons.chevron_left_rounded, color: IcStyle.muted),
          ]),
        ),
      );

  Widget _field(TextEditingController c, String hint, Key key, {bool phone = false}) => TextField(
        key: key,
        controller: c,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        textDirection: phone ? TextDirection.ltr : TextDirection.rtl,
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
