import 'dart:io';
import '../../functions/tr.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../functions/intercity_api.dart' show IcPlace, IntercityResult;
import '../../functions/tow_api.dart';
import '../intercity/intercity_style.dart';
import '../common/price_mode_box.dart';
import '../onTripPage/open_booked_ride.dart';
import '../onTripPage/place_on_map.dart';
import '../onTripPage/trip_place.dart';

/// «ساحبة · شن صار للسيارة؟»: what happened and which car (that decides if a flatbed is needed),
/// where the car is and where it goes (a known workshop or any place), an optional photo, the
/// owner's word (and, in an accident, that nobody is hurt or the police allowed it), the fixed
/// price line by line — then the nearest approved tow truck of the right kind is asked.
class TowPage extends StatefulWidget {
  const TowPage({super.key, required this.home, required this.pick, this.send, this.quote, this.pickPlace});

  final TowHome home;
  final IcPlace pick;

  /// tests replace the network and the map
  final Future<IntercityResult> Function(Map<String, Object?> tow)? send;
  final Future<TowQuote?> Function(String condition, String car, IcPlace drop)? quote;
  final Future<IcPlace?> Function(TripPointRole role)? pickPlace;

  static Future<void> open(BuildContext context, {required TowHome home, required IcPlace pick}) {
    if (!home.enabled) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('الساحبة مش متاحة في مدينتك حاليًا.', 'Towing is not available in your city yet.'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => TowPage(home: home, pick: pick)));
  }

  @override
  State<TowPage> createState() => _TowPageState();
}

class _TowPageState extends State<TowPage> {
  static const _amber = Color(0xff9A6700);
  static const _red = Color(0xffB42318);

  String? _condition;
  String? _car;
  late IcPlace _pick = widget.pick;
  TowWorkshop? _workshop;
  IcPlace? _otherDrop;
  final _note = TextEditingController();
  File? _photo;
  bool _owner = false;
  bool _injuries = false;
  TowQuote? _quote;
  // «طريقة السعر»: offers when the admin says so (or he picks it)
  late bool _offers = widget.home.priceMode == 'offers';
  num? _fare;
  bool _quoting = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  IcPlace? get _drop => _workshop != null ? IcPlace(_workshop!.lat, _workshop!.lng, _workshop!.name) : _otherDrop;
  bool get _accident => _condition == 'accident';
  bool get _needsFlatbed =>
      widget.home.conditions.any((c) => c.key == _condition && c.flatbed) || widget.home.cars.any((c) => c.key == _car && c.flatbed);

  Future<void> _requote() async {
    final d = _drop;
    if (_condition == null || _car == null || d == null) return;
    setState(() {
      _quoting = true;
      _error = null;
    });
    final q = widget.quote != null
        ? await widget.quote!(_condition!, _car!, d)
        : await TowApi.quote(_pick.lat, _pick.lng, d.lat, d.lng, _condition!, _car!);
    if (!mounted) return;
    setState(() {
      _quoting = false;
      _quote = q;
      if (q != null) _fare = PriceModeBox.start(q.total);
      if (q == null) _error = tr('ما قدرناش نحسب السعر. تأكد إن المكانين داخل ${widget.home.city}.', 'We could not work out the price. Make sure both places are in ${widget.home.city}.');
    });
  }

  Future<IcPlace?> _place(TripPointRole role, IcPlace around) =>
      widget.pickPlace != null ? widget.pickPlace!(role) : placeOnMap(context, center: LatLng(around.lat, around.lng), role: role);

  Future<void> _changePick() async {
    final p = await _place(TripPointRole.pickup, _pick);
    if (p == null || !mounted) return;
    setState(() => _pick = p);
    _requote();
  }

  Future<void> _chooseOther() async {
    final p = await _place(TripPointRole.destination, _pick);
    if (p == null || !mounted) return;
    setState(() {
      _otherDrop = p;
      _workshop = null;
    });
    _requote();
  }

  Future<void> _takePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: IcSheet(children: [
          Text(tr('صورة السيارة', 'Photo of the car'), style: IcStyle.t(20, w: FontWeight.w900)),
          Text(tr('تساعد الكابتن يعرف شن يجيب معاه.', 'Helps the captain know what to bring.'), style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
          const SizedBox(height: 10),
          IcButton(text: tr('صوّر الآن 📷', 'Take a photo now 📷'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          const SizedBox(height: 6),
          IcButton(text: tr('من الصور', 'From photos'), ghost: true, onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    XFile? x;
    try {
      x = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1600);
    } catch (_) {
      x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
    }
    if (x != null && mounted) setState(() => _photo = File(x!.path));
  }

  String? get _missing {
    if (_condition == null) return tr('اختار شن صار للسيارة.', 'Choose what happened to the car.');
    if (_car == null) return tr('اختار نوع السيارة.', 'Choose the vehicle type.');
    if (_drop == null) return tr('اختار وين تمشي السيارة.', 'Choose where the car goes.');
    if (_accident && !_injuries) return tr('في الحادث: أكّد إن ما فيش إصابات أو إن الشرطة سمحت.', 'In an accident: confirm there are no injuries or the police allowed it.');
    if (!_owner) return tr('أكّد إن السيارة متاعك أو عندك إذن تحركها.', 'Confirm the car is yours or you have permission to move it.');
    if (_quote == null) return tr('نستنوا السعر…', 'Waiting for the price…');
    return null;
  }

  Future<void> _send() async {
    final why = _missing;
    if (why != null) {
      setState(() => _error = why);
      return;
    }
    final d = _drop!;
    final tow = <String, Object?>{
      'condition': _condition, 'car_type': _car, 'pick': _pick, 'drop': d, 'workshop_id': _workshop?.id, 'note': _note.text.trim(),
      'injuries_cleared': _injuries, 'photo': _photo != null,
      if (_offers) 'fare': _fare,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null
        ? await widget.send!(tow)
        : await TowApi.create(
            pickLat: _pick.lat, pickLng: _pick.lng, pickAddress: _pick.address, dropLat: d.lat, dropLng: d.lng, dropAddress: d.address,
            condition: _condition!, car: _car!, workshopId: _workshop?.id, note: _note.text, injuriesCleared: _injuries, offerFare: _offers ? _fare : null);
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    if (widget.send == null) {
      final id = r.data is Map ? '${(r.data as Map)['id'] ?? ''}' : '';
      if (_photo != null && id.isNotEmpty) await TowApi.photo(id, _photo!);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(r.message, textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
    if (widget.send == null) {
      await openBookedRide(context);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.home;
    final q = _quote;
    return IcScaffold(
      title: tr('ساحبة · ${h.city}', 'Tow truck · ${h.city}'),
      mapHeight: 130,
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('tow-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        if (q != null)
          PriceModeBox(
            mode: h.priceMode, offers: _offers, onOffers: (v) => setState(() => _offers = v),
            suggested: q.total, fare: _fare, onFare: (v) => setState(() => _fare = v),
            minPercent: h.offerMinPercent, maxPercent: h.offerMaxPercent, currency: h.currency,
          ),
        IcButton(
            text: q == null
                ? tr('اطلب ساحبة', 'Request a tow truck')
                : _offers
                    ? tr('اطلب عروض · ${h.currency} ${IcStyle.money(_fare ?? q.total)}', 'Ask for offers · ${h.currency} ${IcStyle.money(_fare ?? q.total)}')
                    : tr('اطلب ساحبة · ${h.currency} ${IcStyle.money(q.total)}', 'Request a tow truck · ${h.currency} ${IcStyle.money(q.total)}'),
            busy: _busy,
            onTap: _send),
      ]),
      children: [
        Text(tr('شن صار للسيارة؟ 🛻', 'What happened to the car? 🛻'), style: IcStyle.t(22, w: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in h.conditions)
            IcChip(text: c.label, selected: _condition == c.key, onTap: () {
              setState(() => _condition = c.key);
              _requote();
            }),
        ]),
        const SizedBox(height: 12),
        Text(tr('نوع السيارة', 'Vehicle type'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in h.cars)
            IcChip(text: c.label, selected: _car == c.key, onTap: () {
              setState(() => _car = c.key);
              _requote();
            }),
        ]),
        if (_needsFlatbed) ...[
          const SizedBox(height: 8),
          _note2(tr('🛻 تحتاج سطحة (السيارة تطلع فوق الساحبة كاملة)', '🛻 Needs a flatbed (the whole car rides on the truck)'), const Color(0xffEAF2FF), IcStyle.blue, key: const ValueKey('tow-flatbed')),
        ],
        if (_accident) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey('tow-accident'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xffFEF3F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffFECDCA))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('⚠️ ${h.emergencyText}', style: IcStyle.t(13.5, w: FontWeight.w800, c: _red)),
              const SizedBox(height: 6),
              _check(_injuries, tr('ما فيش إصابات، أو الشرطة سمحت نحركوا السيارة', 'No injuries, or the police allowed moving the car'), () => setState(() => _injuries = !_injuries), const ValueKey('tow-injuries')),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        Text(tr('السيارة وين؟', 'Where is the car?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        _row(Icons.my_location_rounded, _pick.address.isEmpty ? tr('مكانك الحالي', 'Your current place') : _pick.address, tr('غيّر', 'Change'), _changePick, const ValueKey('tow-pick')),
        const SizedBox(height: 12),
        Text(tr('وين تمشي؟', 'Where to?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        for (final w in h.workshops) ...[
          _choice(w.name, w.address, _workshop?.id == w.id, () {
            setState(() {
              _workshop = w;
              _otherDrop = null;
            });
            _requote();
          }, ValueKey('tow-ws-${w.id}')),
          const SizedBox(height: 6),
        ],
        _choice(_otherDrop == null ? tr('مكان ثاني على الخريطة', 'Another place on the map') : _otherDrop!.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : _otherDrop!.address,
            _otherDrop == null ? tr('البيت، ورشة مش في القائمة…', 'Home, a workshop not on the list…') : tr('غيّر المكان', 'Change the place'), _otherDrop != null, _chooseOther, const ValueKey('tow-other')),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 200,
          style: IcStyle.t(14, w: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: tr('ملاحظة للكابتن (اختياري): قدام المخبز، المفتاح معاي…', 'Note for the captain (optional): in front of the bakery, I have the key…'),
            hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        _row(Icons.photo_camera_outlined, _photo == null ? tr('صورة السيارة (اختياري)', 'Photo of the car (optional)') : tr('تمت إضافة الصورة ✅', 'Photo added ✅'), _photo == null ? tr('أضف', 'Add') : tr('غيّر', 'Change'), _takePhoto,
            const ValueKey('tow-photo')),
        const SizedBox(height: 12),
        if (_quoting) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
        if (q != null && !_quoting) _price(q),
        const SizedBox(height: 10),
        _check(_owner, tr('السيارة متاعي، أو عندي إذن صاحبها نحركها', 'The car is mine, or I have the owner\'s permission to move it'), () => setState(() => _owner = !_owner), const ValueKey('tow-owner')),
        const SizedBox(height: 8),
        Text(
          h.trucksOnline > 0
              ? tr('${h.trucksOnline == 1 ? 'ساحبة وحدة متاحة' : '${h.trucksOnline} ساحبات متاحة'} في ${h.city} الآن', '${h.trucksOnline == 1 ? 'One tow truck' : '${h.trucksOnline} tow trucks'} available in ${h.city} now')
              : tr('كل الساحبات مشغولة الآن. نطلبها وتوصلك أول ما تتوفر وحدة.', 'All tow trucks are busy now. We will request one and it comes as soon as one is free.'),
          textAlign: TextAlign.center,
          style: IcStyle.t(12.5, w: FontWeight.w700, c: h.trucksOnline > 0 ? const Color(0xff16803C) : _amber),
        ),
      ],
    );
  }

  Widget _price(TowQuote q) {
    final cur = widget.home.currency;
    Widget line(String a, num v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(a, style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted))),
            Text('$cur ${IcStyle.money(v)}', style: IcStyle.t(13.5, w: FontWeight.w800)),
          ]),
        );
    return Container(
      key: const ValueKey('tow-price'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        line(tr('رفع السيارة (يشمل مشوار الساحبة لعندك)', 'Lifting the car (includes the truck\'s drive to you)'), q.lift),
        line(tr('المسافة · ${IcStyle.money(q.km)} كم', 'Distance · ${IcStyle.money(q.km)} km'), q.distance),
        if (q.flatbed > 0) line(tr('سطحة', 'Flatbed'), q.flatbed),
        if (q.night > 0) line(tr('زيادة الليل', 'Night extra'), q.night),
        const Divider(height: 14),
        Row(children: [
          Expanded(child: Text(tr('السعر الثابت', 'Fixed price'), style: IcStyle.t(15, w: FontWeight.w900))),
          Text('$cur ${IcStyle.money(q.total)}', style: IcStyle.t(22, w: FontWeight.w900)),
        ]),
        Text(tr('ما يتغيرش في الطريق. نقدًا للكابتن.', 'It does not change on the way. Cash to the captain.'), style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
      ]),
    );
  }

  Widget _note2(String text, Color bg, Color fg, {Key? key}) => Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: IcStyle.t(13, w: FontWeight.w800, c: fg)),
      );

  Widget _check(bool on, String text, VoidCallback onTap, Key key) => InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: on ? IcStyle.blue : IcStyle.muted),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: IcStyle.t(13.5, w: FontWeight.w700))),
          ]),
        ),
      );

  Widget _row(IconData icon, String text, String action, VoidCallback onTap, Key key) => InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: IcStyle.line, width: 1.5)),
          child: Row(children: [
            Icon(icon, color: IcStyle.navy, size: 21),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14, w: FontWeight.w700))),
            Text(action, style: IcStyle.t(13, w: FontWeight.w800, c: IcStyle.blue)),
          ]),
        ),
      );

  Widget _choice(String title, String sub, bool on, VoidCallback onTap, Key key) => InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: on ? const Color(0xffF5F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? IcStyle.blue : IcStyle.line, width: on ? 2 : 1.5),
          ),
          child: Row(children: [
            Icon(on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: on ? IcStyle.blue : IcStyle.muted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(14, w: FontWeight.w800)),
                if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
              ]),
            ),
          ]),
        ),
      );
}
