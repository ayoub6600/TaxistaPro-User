import 'dart:io';
import '../../functions/tr.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../functions/freight_api.dart';
import '../../functions/money_label.dart';
import '../../functions/intercity_api.dart' show IcPlace, IntercityApi, IntercityResult;
import '../NavigatorPages/upcoming_scheduled_rides.dart';
import '../intercity/intercity_fare_page.dart' show IcFareBar;
import '../intercity/intercity_style.dart';
import '../onTripPage/open_booked_ride.dart';
import '../onTripPage/place_on_map.dart';
import '../onTripPage/trip_place.dart';
import '../parcels/parcel_map.dart';

/// «النقل» (owner 2026-11-26, like Porter): where from and where to first, on the real map; then every
/// vehicle of the city with its photo and its suggested price for this move (the city's default chosen),
/// workers, when (now, in an hour…), what moves with optional photos, the floors, and his price — the
/// owners of that vehicle accept it or send their offer.
class FreightPage extends StatefulWidget {
  const FreightPage({super.key, required this.home, required this.pick, this.send, this.quotes, this.pickPlace, this.map});

  final FreightHome home;
  final IcPlace pick;

  /// tests replace the network and the map
  final Future<IntercityResult> Function(Map<String, Object?> body)? send;
  final Future<Map<String, FreightQuote>?> Function(int workers, int floors)? quotes;
  final Future<IcPlace?> Function(TripPointRole role)? pickPlace;
  final Widget Function(IcPlace pick, IcPlace? drop)? map;

  static Future<void> open(BuildContext context, {required FreightHome home, required IcPlace pick}) {
    if (!home.enabled) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('${FreightHome.homeNameOf(FreightApi.notifier.value, true)} مش متاح في مدينتك حاليًا.', '${FreightHome.homeNameOf(FreightApi.notifier.value, false)} is not available in your city yet.'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => FreightPage(home: home, pick: pick)));
  }

  static const icons = {'pickup': '🛻', 'van': '🚚', 'truck': '🚛'};

  @override
  State<FreightPage> createState() => _FreightPageState();
}

class _When {
  const _When(this.label, this.at);
  final String label;
  final DateTime? Function() at; // null = now
}

class _FreightPageState extends State<FreightPage> {
  String? _category;
  final _items = TextEditingController();
  final List<File> _photos = [];
  late String? _class = widget.home.defaultClass;
  int _workers = 0;
  int _pickFloor = 0;
  bool _pickLift = false;
  int _dropFloor = 0;
  bool _dropLift = false;
  late IcPlace _pick = widget.pick;
  IcPlace? _drop;
  int _when = 0;
  DateTime? _custom;
  Map<String, FreightQuote> _quotes = const {};
  num? _fare;
  bool _quoting = false;
  bool _busy = false;
  String? _error;

  static DateTime _day(int plus, int hour) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + plus, hour);
  }

  final List<_When> _times = [
    _When(tr('الآن', 'Now'), () => null),
    _When(tr('بعد ساعة', 'In an hour'), () => DateTime.now().add(const Duration(hours: 1))),
    _When(tr('بعد ساعتين', 'In two hours'), () => DateTime.now().add(const Duration(hours: 2))),
    _When(tr('بكرة 9 الصبح', 'Tomorrow 9 am'), () => _day(1, 9)),
  ];

  @override
  void dispose() {
    _items.dispose();
    super.dispose();
  }

  String get _cur => widget.home.currency;
  String _money(num v) => moneyText(v, _cur, arabic: appRtl);
  FreightQuote? get _quote => _class == null ? null : _quotes[_class];
  int get _floorsClimbed => (_pickLift ? 0 : _pickFloor) + (_dropLift ? 0 : _dropFloor);
  num get _step => (_quote?.suggested ?? 0) >= 200 ? 10 : 5;
  DateTime? get _start => _when < _times.length ? _times[_when].at() : _custom;
  String get _whenLabel => _when < _times.length ? _times[_when].label : IntercityApi.dayLabel(FreightApi.wallClock(_custom!));

  /// every vehicle's price for this move; his price follows the chosen vehicle's suggested price
  Future<void> _requote({bool keepFare = false}) async {
    final d = _drop;
    if (d == null) return;
    setState(() {
      _quoting = true;
      _error = null;
    });
    final q = widget.quotes != null
        ? await widget.quotes!(_workers, _floorsClimbed)
        : await FreightApi.quotes(_pick.lat, _pick.lng, d.lat, d.lng, _workers, _floorsClimbed);
    if (!mounted) return;
    setState(() {
      _quoting = false;
      if (q == null || q.isEmpty) {
        _quotes = const {};
        _error = tr('ما قدرناش نحسب السعر. تأكد إن المكانين داخل ${widget.home.city}.', 'We could not work out the price. Make sure both places are in ${widget.home.city}.');
        return;
      }
      _quotes = q;
      final mine = _quote;
      if (mine != null) _fare = keepFare && _fare != null ? _fare!.clamp(mine.min, mine.max) : mine.suggested;
    });
  }

  void _pickClass(String key) => setState(() {
        _class = key;
        _fare = _quotes[key]?.suggested;
        _error = null;
      });

  Future<IcPlace?> _place(TripPointRole role, IcPlace around) =>
      widget.pickPlace != null ? widget.pickPlace!(role) : placeOnMap(context, center: LatLng(around.lat, around.lng), role: role);

  Future<void> _addPhoto() async {
    if (_photos.length >= widget.home.maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: IcSheet(children: [
          Text(tr('صورة الحاجات', 'Photo of the things'), style: IcStyle.t(20, w: FontWeight.w900)),
          Text(tr('الصور تسهّل علينا نجيبولك صاحب سيارة يعطيك سعر صح.', 'Photos help us find you an owner who gives a fair price.'), style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
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
    if (x != null && mounted) setState(() => _photos.add(File(x!.path)));
  }

  /// «وقت ثاني»: a day and an hour within the city's booking horizon
  Future<void> _pickOtherTime() async {
    final now = DateTime.now();
    final day = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: now.add(Duration(days: widget.home.horizonDays)), initialDate: now.add(const Duration(days: 1)));
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null || !mounted) return;
    setState(() {
      _custom = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _when = _times.length;
    });
  }

  String? get _missing {
    if (_drop == null) return tr('اختار وين توصل الحاجات.', 'Choose where the things go.');
    if (_class == null) return tr('اختار السيارة المناسبة.', 'Choose the right vehicle.');
    if (_category == null) return tr('اختار شن تنقل.', 'Choose what you are moving.');
    if (_quote == null || _fare == null) return tr('نستنوا السعر…', 'Waiting for the price…');
    return null;
  }

  Future<void> _send() async {
    final why = _missing;
    if (why != null) {
      setState(() => _error = why);
      return;
    }
    final cls = widget.home.classes.firstWhere((c) => c.key == _class);
    final d = _drop!;
    final start = _start;
    final body = <String, Object?>{
      'pick_lat': _pick.lat, 'pick_lng': _pick.lng, 'pick_address': _pick.address.isEmpty ? tr('موقعي', 'My location') : _pick.address,
      'drop_lat': d.lat, 'drop_lng': d.lng, 'drop_address': d.address.isEmpty ? tr('على الخريطة', 'On the map') : d.address,
      'vehicle_type': cls.zoneTypeId, 'ride_type': 1, 'payment_opt': 1,
      'is_later': start == null ? 0 : 1, if (start != null) 'trip_start_time': FreightApi.wallClock(start),
      'freight_class': _class, 'freight_category': _category, if (_items.text.trim().isNotEmpty) 'freight_items': _items.text.trim(),
      'workers': _workers, 'pick_floor': _pickFloor, 'pick_lift': _pickLift ? 1 : 0, 'drop_floor': _dropFloor, 'drop_lift': _dropLift ? 1 : 0,
      'rider_proposed_fare': _fare,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null ? await widget.send!(body) : await FreightApi.create(body);
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _busy = false;
        _error = r.message;
      });
      return;
    }
    if (widget.send == null) {
      final data = r.data is Map ? r.data as Map : const {};
      final ride = data['data'] is Map ? data['data'] as Map : data;
      final id = '${ride['id'] ?? ''}';
      for (final p in _photos) {
        if (id.isNotEmpty) await FreightApi.photo(id, p);
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(start == null ? tr('طلبك وصل لأصحاب السيارات. العروض توصلك الآن 🚚', 'Your request reached the owners. Offers are coming now 🚚') : tr('طلبك محجوز $_whenLabel. العروض توصلك في «الرحلات القادمة» 🚚', 'Your request is booked for $_whenLabel. Offers reach you in «Upcoming rides» 🚚'),
            textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
    if (widget.send != null) {
      Navigator.of(context).maybePop();
    } else if (start == null) {
      await openBookedRide(context);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UpcomingScheduledRidesPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.home;
    final q = _quote;
    final top = MediaQuery.of(context).padding.top;
    return IcScaffold(
      title: tr('${FreightHome.homeNameOf(h, true)} · ${h.city}', '${FreightHome.homeNameOf(h, false)} · ${h.city}'),
      mapHeight: 280,
      // the real map from where he stands, the road to the drop-off once he picks it
      map: widget.map?.call(_pick, _drop) ??
          ParcelMap(pick: LatLng(_pick.lat, _pick.lng), drop: _drop == null ? null : LatLng(_drop!.lat, _drop!.lng), topInset: top, bottomInset: 30, mover: '🚚'),
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('freight-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        IcButton(text: _fare == null ? tr('اطلب عروض', 'Ask for offers') : tr('اطلب عروض · ${_money(_fare!)}', 'Ask for offers · ${_money(_fare!)}'), busy: _busy, onTap: _send),
      ]),
      children: [
        _places(),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(tr('اختار السيارة', 'Choose the vehicle'), style: IcStyle.t(17, w: FontWeight.w900))),
          Text(_drop == null ? tr('حدد التنزيل وتشوف السعر', 'Set the drop-off to see prices') : tr('السعر المقترح لمشوارك', 'Suggested price for your move'),
              style: IcStyle.t(11.5, w: FontWeight.w700, c: IcStyle.muted)),
        ]),
        const SizedBox(height: 6),
        for (final c in h.classes) ...[
          _classRow(c),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        _counter(tr('عمال تحميل', 'Loading workers'), tr('${_money(h.workerPrice)} للعامل', '${_money(h.workerPrice)} per worker'), _workers, 0, h.maxWorkers, (v) {
          setState(() => _workers = v);
          _requote();
        }, const ValueKey('freight-workers')),
        const SizedBox(height: 12),
        Text(tr('متى؟', 'When?'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < _times.length; i++)
            IcChip(key: ValueKey('freight-when-$i'), text: _times[i].label, selected: _when == i, onTap: () => setState(() => _when = i)),
          IcChip(
              key: const ValueKey('freight-when-other'),
              text: _when == _times.length ? _whenLabel : tr('وقت ثاني…', 'Another time…'),
              selected: _when == _times.length,
              onTap: _pickOtherTime),
        ]),
        const SizedBox(height: 14),
        Text(tr('شن تنقل؟ 🚚', 'What are you moving? 🚚'), style: IcStyle.t(17, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in h.categories) IcChip(text: c.$2, selected: _category == c.$1, onTap: () => setState(() => _category = c.$1)),
        ]),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('freight-items'),
          controller: _items,
          maxLength: 200,
          style: IcStyle.t(14, w: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: tr('شن فيها بالضبط؟ مثلًا: غرفة نوم، ثلاجة، 10 كراتين', 'What exactly? e.g. a bedroom, a fridge, 10 boxes'),
            hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: IcStyle.line, width: 1.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
        _photosRow(h),
        const SizedBox(height: 12),
        _floor(tr('دور التحميل', 'Pick-up floor'), _pickFloor, _pickLift, (f) {
          setState(() => _pickFloor = f);
          _requote();
        }, (l) {
          setState(() => _pickLift = l);
          _requote();
        }, 'pick'),
        const SizedBox(height: 8),
        _floor(tr('دور التنزيل', 'Drop-off floor'), _dropFloor, _dropLift, (f) {
          setState(() => _dropFloor = f);
          _requote();
        }, (l) {
          setState(() => _dropLift = l);
          _requote();
        }, 'drop'),
        const SizedBox(height: 14),
        if (_quoting) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
        if (q != null && !_quoting && _fare != null) _price(q),
        const SizedBox(height: 8),
        Text(tr('أصحاب السيارات يشوفوا طلبك وصورك، ويقبلوا سعرك ولا يبعتوا عرضهم. الدفع نقدًا لصاحب السيارة. الحمولة لو أكبر من الموصوف، يقدر يعتذر بدون عقوبة.',
                'Owners see your request and photos, then accept your price or send their offer. Pay the owner in cash. If the load is bigger than described, the owner may decline without penalty.'),
            style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
      ],
    );
  }

  /// where from and where to, each one tap to change
  Widget _places() {
    Widget row(String key, IconData icon, Color color, String title, String place, VoidCallback onTap) => InkWell(
          key: ValueKey('freight-$key-place'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text('$title: ', style: IcStyle.t(13.5, w: FontWeight.w900)),
              Expanded(child: Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(13.5, w: FontWeight.w600))),
              Text(tr('غيّر', 'Change'), style: IcStyle.t(12.5, w: FontWeight.w800, c: IcStyle.blue)),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line, width: 1.5)),
      child: Column(children: [
        row('pick', Icons.my_location_rounded, const Color(0xff16A34A), tr('التحميل', 'Pick-up'), _pick.address.isEmpty ? tr('مكانك الحالي', 'Your current place') : _pick.address, () async {
          final x = await _place(TripPointRole.pickup, _pick);
          if (x != null && mounted) {
            setState(() => _pick = x);
            _requote(keepFare: true);
          }
        }),
        const Divider(height: 1),
        row('drop', Icons.place_rounded, const Color(0xffE11D48), tr('التنزيل', 'Drop-off'),
            _drop == null ? tr('وين توصل؟', 'Where to?') : (_drop!.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : _drop!.address), () async {
          final x = await _place(TripPointRole.destination, _drop ?? _pick);
          if (x != null && mounted) {
            setState(() => _drop = x);
            _requote();
          }
        }),
      ]),
    );
  }

  /// one vehicle: its photo (from the admin) or its sign, name, load, and its price for this move
  Widget _classRow(FreightClass c) {
    final on = c.key == _class;
    final q = _quotes[c.key];
    final picture = c.image == null
        ? Center(child: Text(FreightPage.icons[c.key] ?? '🚚', style: const TextStyle(fontSize: 26)))
        : Image.network(c.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(FreightPage.icons[c.key] ?? '🚚', style: const TextStyle(fontSize: 26))));
    return Semantics(
      button: true,
      selected: on,
      label: c.label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('freight-class-${c.key}'),
        onTap: () => _pickClass(c.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: on ? const Color(0xffF5F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? IcStyle.blue : IcStyle.line, width: on ? 2 : 1.5),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(width: 72, height: 52, color: const Color(0xffEEF4FF), child: picture),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.label, style: IcStyle.t(15.5, w: FontWeight.w900)),
                Text([c.load, if (c.box.isNotEmpty) c.box].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(11.5, w: FontWeight.w600, c: IcStyle.muted)),
              ]),
            ),
            const SizedBox(width: 6),
            Text(q != null ? _money(q.suggested) : tr('من ${_money(c.priceFrom)}', 'from ${_money(c.priceFrom)}'),
                style: IcStyle.t(q != null ? 16.5 : 13, w: FontWeight.w900, c: q != null ? IcStyle.navy : IcStyle.muted)),
          ]),
        ),
      ),
    );
  }

  /// «صوّر الحاجات (اختياري)»: up to three photos, and why they help
  Widget _photosRow(FreightHome h) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (var i = 0; i < _photos.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_photos[i], width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: IcStyle.soft))),
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.removeAt(i)),
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 13, color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            if (_photos.length < h.maxPhotos)
              InkWell(
                key: const ValueKey('freight-photo'),
                onTap: _addPhoto,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 150,
                  height: 64,
                  decoration: BoxDecoration(color: const Color(0xffF7FAFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xff9CB8E6), width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(tr('📷 صوّر الحاجات\n(اختياري · ${_photos.length} من ${h.maxPhotos})', '📷 Photograph them\n(optional · ${_photos.length} of ${h.maxPhotos})'), textAlign: TextAlign.center, style: IcStyle.t(12, w: FontWeight.w800, c: IcStyle.blue)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        Text(tr('الصور اختيارية، بس تسهّل علينا نجيبولك صاحب سيارة يعطيك سعر صح.', 'Photos are optional, but they help us find you an owner with a fair price.'),
            style: IcStyle.t(11.5, w: FontWeight.w700, c: IcStyle.muted)),
      ]);

  Widget _floor(String title, int floor, bool lift, ValueChanged<int> onFloor, ValueChanged<bool> onLift, String key) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _counter(title, floor == 0 ? tr('أرضي', 'Ground') : (lift ? tr('فيه مصعد', 'There is a lift') : tr('${_money(widget.home.floorPrice)} لكل دور بدون مصعد', '${_money(widget.home.floorPrice)} per floor without a lift')),
              floor, 0, 30, onFloor, ValueKey('freight-$key-floor')),
          if (floor > 0)
            InkWell(
              key: ValueKey('freight-$key-lift'),
              onTap: () => onLift(!lift),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(lift ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 20, color: lift ? IcStyle.blue : IcStyle.muted),
                  const SizedBox(width: 6),
                  Text(tr('فيه مصعد', 'There is a lift'), style: IcStyle.t(13, w: FontWeight.w700)),
                ]),
              ),
            ),
        ]),
      );

  Widget _counter(String title, String hint, int value, int min, int max, ValueChanged<int> onChanged, Key key) {
    Widget btn(String s, bool on, VoidCallback f, String label) => Semantics(
          button: true,
          label: '$title $label',
          excludeSemantics: true,
          child: InkWell(
            onTap: on ? f : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(12)),
              child: Text(s, style: IcStyle.t(20, w: FontWeight.w900, c: on ? IcStyle.blue : const Color(0xffB8C4D8))),
            ),
          ),
        );
    return Row(key: key, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: IcStyle.t(14.5, w: FontWeight.w900)),
          Text(hint, style: IcStyle.t(11.5, w: FontWeight.w600, c: IcStyle.muted)),
        ]),
      ),
      btn('−', value > min, () => onChanged(value - 1), tr('نقص', 'Decrease')),
      SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: IcStyle.t(18, w: FontWeight.w900))),
      btn('+', value < max, () => onChanged(value + 1), tr('زيادة', 'Increase')),
    ]);
  }

  Widget _price(FreightQuote q) {
    Widget line(String a, num v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(children: [
            Expanded(child: Text(a, style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted))),
            Text(_money(v), style: IcStyle.t(13, w: FontWeight.w800)),
          ]),
        );
    return Container(
      key: const ValueKey('freight-price'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        line(tr('السيارة', 'The vehicle'), q.base),
        if (q.distance > 0) line(tr('المسافة · ${IcStyle.money(q.km)} كم', 'Distance · ${IcStyle.money(q.km)} km'), q.distance),
        if (q.workers > 0) line(tr('العمال', 'Workers'), q.workers),
        if (q.floors > 0) line(tr('الأدوار بدون مصعد', 'Floors without a lift'), q.floors),
        const Divider(height: 14),
        Row(children: [
          Expanded(child: Text(tr('السعر المقترح', 'Suggested price'), style: IcStyle.t(14, w: FontWeight.w900))),
          Text(_money(q.suggested), style: IcStyle.t(15, w: FontWeight.w900, c: IcStyle.blue)),
        ]),
        const SizedBox(height: 8),
        Text(tr('سعرك (أصحاب السيارات يقبلوه أو يبعتوا عروضهم)', 'Your price (owners accept it or send their offers)'), style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
        const SizedBox(height: 4),
        IcFareBar(
          currency: _cur,
          format: _money,
          value: _fare!,
          onPlus: _fare! + _step <= q.max ? () => setState(() => _fare = _fare! + _step) : null,
          onMinus: _fare! - _step >= q.min ? () => setState(() => _fare = _fare! - _step) : null,
        ),
        const SizedBox(height: 4),
        Text(tr('من ${IcStyle.money(q.min)} إلى ${IcStyle.money(q.max)}', 'From ${IcStyle.money(q.min)} to ${IcStyle.money(q.max)}'), textAlign: TextAlign.center, style: IcStyle.t(11.5, w: FontWeight.w600, c: IcStyle.muted)),
      ]),
    );
  }
}
