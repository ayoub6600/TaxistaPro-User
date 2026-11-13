import 'dart:io';
import '../../functions/tr.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../functions/freight_api.dart';
import '../../functions/intercity_api.dart' show IcPlace, IntercityApi, IntercityResult;
import '../NavigatorPages/upcoming_scheduled_rides.dart';
import '../intercity/intercity_fare_page.dart' show IcFareBar;
import '../intercity/intercity_style.dart';
import '../onTripPage/open_booked_ride.dart';
import '../onTripPage/place_on_map.dart';
import '../onTripPage/trip_place.dart';

/// «الشحن · شن تنقل؟»: what he moves (and photos of it), the vehicle class, workers, the floors at
/// each end and whether there is a lift, where from and to, now or at a time, and his price — the
/// admin's suggested price line by line, which he may raise or lower in the range. The owners of
/// that class answer with their price, exactly as on any negotiated ride.
class FreightPage extends StatefulWidget {
  const FreightPage({super.key, required this.home, required this.pick, this.send, this.quote, this.pickPlace});

  final FreightHome home;
  final IcPlace pick;

  /// tests replace the network and the map
  final Future<IntercityResult> Function(Map<String, Object?> body)? send;
  final Future<FreightQuote?> Function(String cls, int workers, int floors)? quote;
  final Future<IcPlace?> Function(TripPointRole role)? pickPlace;

  static Future<void> open(BuildContext context, {required FreightHome home, required IcPlace pick}) {
    if (!home.enabled) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('الشحن مش متاح في مدينتك حاليًا.', 'Freight is not available in your city yet.'), textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr))));
      return Future.value();
    }
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => FreightPage(home: home, pick: pick)));
  }

  static const icons = {'pickup': '🛻', 'van': '🚐', 'truck': '🚚'};

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
  late String? _class = widget.home.classes.length == 1 ? widget.home.classes.first.key : null;
  int _workers = 0;
  int _pickFloor = 0;
  bool _pickLift = false;
  int _dropFloor = 0;
  bool _dropLift = false;
  late IcPlace _pick = widget.pick;
  IcPlace? _drop;
  int _when = 0;
  DateTime? _custom;
  FreightQuote? _quote;
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
    _When(tr('بعد ساعتين', 'In two hours'), () => DateTime.now().add(const Duration(hours: 2))),
    _When(tr('بكرة 9 الصبح', 'Tomorrow 9 am'), () => _day(1, 9)),
  ];

  @override
  void dispose() {
    _items.dispose();
    super.dispose();
  }

  int get _floorsClimbed => (_pickLift ? 0 : _pickFloor) + (_dropLift ? 0 : _dropFloor);
  num get _step => (_quote?.suggested ?? 0) >= 200 ? 10 : 5;
  DateTime? get _start => _when < _times.length ? _times[_when].at() : _custom;
  String get _whenLabel => _when < _times.length ? _times[_when].label : IntercityApi.dayLabel(FreightApi.wallClock(_custom!));

  Future<void> _requote({bool keepFare = false}) async {
    final d = _drop;
    if (_class == null || d == null) return;
    setState(() {
      _quoting = true;
      _error = null;
    });
    final q = widget.quote != null
        ? await widget.quote!(_class!, _workers, _floorsClimbed)
        : await FreightApi.quote(_pick.lat, _pick.lng, d.lat, d.lng, _class!, _workers, _floorsClimbed);
    if (!mounted) return;
    setState(() {
      _quoting = false;
      _quote = q;
      if (q == null) {
        _error = tr('ما قدرناش نحسب السعر. تأكد إن المكانين داخل ${widget.home.city}.', 'We could not work out the price. Make sure both places are in ${widget.home.city}.');
      } else {
        // a change of class, workers or floors moves the suggested price: his price follows it
        _fare = keepFare && _fare != null ? _fare!.clamp(q.min, q.max) : q.suggested;
      }
    });
  }

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
          Text(tr('صورة الحمولة', 'Photo of the load'), style: IcStyle.t(20, w: FontWeight.w900)),
          Text(tr('الصور تخلي صاحب السيارة يعرف الحمولة ويعطيك سعر صح.', 'Photos help the owner understand the load and give you a fair price.'), style: IcStyle.t(13, w: FontWeight.w600, c: IcStyle.muted)),
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

  Future<void> _pickTime() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: IcSheet(children: [
          Text(tr('متى؟', 'When?'), style: IcStyle.t(21, w: FontWeight.w900)),
          const SizedBox(height: 10),
          for (var i = 0; i <= _times.length; i++) ...[
            InkWell(
              onTap: () => Navigator.pop(ctx, i),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _when == i ? const Color(0xffEAF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _when == i ? IcStyle.blue : IcStyle.line, width: _when == i ? 2 : 1.5),
                ),
                child: Text(i < _times.length ? _times[i].label : tr('يوم وساعة ثانيين…', 'Another day and time…'), style: IcStyle.t(15)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ]),
      ),
    );
    if (chosen == null || !mounted) return;
    if (chosen < _times.length) {
      setState(() => _when = chosen);
      return;
    }
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
    if (_category == null) return tr('اختار شن تنقل.', 'Choose what you are moving.');
    if (_class == null) return tr('اختار السيارة المناسبة.', 'Choose the right vehicle.');
    if (_drop == null) return tr('اختار وين توصل الحمولة.', 'Choose where the load goes.');
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
    return IcScaffold(
      title: tr('الشحن · ${h.city}', 'Freight · ${h.city}'),
      mapHeight: 120,
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, key: const ValueKey('freight-error'), textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        IcButton(text: _fare == null ? tr('اطلب عروض', 'Ask for offers') : tr('اطلب عروض · ${h.currency} ${IcStyle.money(_fare!)}', 'Ask for offers · ${h.currency} ${IcStyle.money(_fare!)}'), busy: _busy, onTap: _send),
      ]),
      children: [
        Text(tr('شن تنقل؟ 🚚', 'What are you moving? 🚚'), style: IcStyle.t(22, w: FontWeight.w900)),
        const SizedBox(height: 8),
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
                  width: 120,
                  height: 64,
                  decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(12), border: Border.all(color: IcStyle.line, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(tr('📷 صور الحمولة\n(${_photos.length} من ${h.maxPhotos})', '📷 Photos of the load\n(${_photos.length} of ${h.maxPhotos})'), textAlign: TextAlign.center, style: IcStyle.t(12, w: FontWeight.w800, c: IcStyle.muted)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Text(tr('السيارة المناسبة', 'The right vehicle'), style: IcStyle.t(15, w: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(children: [
          for (final c in h.classes) ...[
            if (c != h.classes.first) const SizedBox(width: 8),
            Expanded(child: _classCard(c)),
          ],
        ]),
        const SizedBox(height: 14),
        _counter(tr('عمال تحميل', 'Loading workers'), tr('${IcStyle.money(h.workerPrice)} للعامل', '${IcStyle.money(h.workerPrice)} per worker'), _workers, 0, h.maxWorkers, (v) {
          setState(() => _workers = v);
          _requote();
        }, const ValueKey('freight-workers')),
        const SizedBox(height: 10),
        _side(tr('التحميل', 'Pick-up'), _pick.address.isEmpty ? tr('مكانك الحالي', 'Your current place') : _pick.address, _pickFloor, _pickLift, (p) async {
          final x = await _place(TripPointRole.pickup, _pick);
          if (x != null && mounted) {
            setState(() => _pick = x);
            _requote(keepFare: true);
          }
        }, (f) {
          setState(() => _pickFloor = f);
          _requote();
        }, (l) {
          setState(() => _pickLift = l);
          _requote();
        }, 'pick'),
        const SizedBox(height: 10),
        _side(tr('التنزيل', 'Drop-off'), _drop == null ? tr('وين توصل؟', 'Where to?') : (_drop!.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : _drop!.address), _dropFloor, _dropLift, (p) async {
          final x = await _place(TripPointRole.destination, _drop ?? _pick);
          if (x != null && mounted) {
            setState(() => _drop = x);
            _requote();
          }
        }, (f) {
          setState(() => _dropFloor = f);
          _requote();
        }, (l) {
          setState(() => _dropLift = l);
          _requote();
        }, 'drop'),
        const SizedBox(height: 10),
        InkWell(
          key: const ValueKey('freight-when'),
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: IcStyle.line, width: 1.5)),
            child: Row(children: [
              const Icon(Icons.schedule_rounded, color: IcStyle.navy, size: 21),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('الموعد: $_whenLabel', 'Time: $_whenLabel'), style: IcStyle.t(14, w: FontWeight.w700))),
              Text(tr('غيّر', 'Change'), style: IcStyle.t(13, w: FontWeight.w800, c: IcStyle.blue)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        if (_quoting) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
        if (q != null && !_quoting && _fare != null) _price(q),
        const SizedBox(height: 8),
        Text(tr('أول ${h.freeLoadingMinutes} دقيقة تحميل مجانية. الدفع نقدًا لصاحب السيارة. الحمولة لو أكبر من الموصوف، يقدر يعتذر بدون عقوبة.', 'The first ${h.freeLoadingMinutes} minutes of loading are free. Pay the owner in cash. If the load is bigger than described, the owner may decline without penalty.'),
            style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
      ],
    );
  }

  Widget _classCard(FreightClass c) {
    final on = c.key == _class;
    return Semantics(
      button: true,
      selected: on,
      label: c.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          setState(() => _class = c.key);
          _requote();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: on ? const Color(0xffF5F9FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? IcStyle.blue : IcStyle.line, width: on ? 2 : 1.5),
          ),
          child: Column(children: [
            Text(FreightPage.icons[c.key] ?? '🚚', style: const TextStyle(fontSize: 24)),
            Text(c.label, style: IcStyle.t(14, w: FontWeight.w900)),
            Text(c.load, style: IcStyle.t(11, w: FontWeight.w600, c: IcStyle.muted)),
          ]),
        ),
      ),
    );
  }

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

  Widget _side(String title, String place, int floor, bool lift, ValueChanged<void> onPlace, ValueChanged<int> onFloor, ValueChanged<bool> onLift, String key) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          key: ValueKey('freight-$key-place'),
          onTap: () => onPlace(null),
          child: Row(children: [
            Icon(key == 'pick' ? Icons.my_location_rounded : Icons.place_rounded, size: 20, color: key == 'pick' ? const Color(0xff16A34A) : const Color(0xffE11D48)),
            const SizedBox(width: 6),
            Text('$title: ', style: IcStyle.t(13.5, w: FontWeight.w900)),
            Expanded(child: Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(13.5, w: FontWeight.w600))),
            Text(tr('غيّر', 'Change'), style: IcStyle.t(12.5, w: FontWeight.w800, c: IcStyle.blue)),
          ]),
        ),
        const SizedBox(height: 6),
        _counter(tr('الدور', 'Floor'), floor == 0 ? tr('أرضي', 'Ground') : (lift ? tr('فيه مصعد', 'There is a lift') : tr('${IcStyle.money(widget.home.floorPrice)} لكل دور بدون مصعد', '${IcStyle.money(widget.home.floorPrice)} per floor without a lift')), floor, 0, 30, onFloor, ValueKey('freight-$key-floor')),
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
  }

  Widget _price(FreightQuote q) {
    final cur = widget.home.currency;
    Widget line(String a, num v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(children: [
            Expanded(child: Text(a, style: IcStyle.t(12.5, w: FontWeight.w600, c: IcStyle.muted))),
            Text('$cur ${IcStyle.money(v)}', style: IcStyle.t(13, w: FontWeight.w800)),
          ]),
        );
    return Container(
      key: const ValueKey('freight-price'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        line(tr('السيارة', 'The car'), q.base),
        if (q.distance > 0) line(tr('المسافة · ${IcStyle.money(q.km)} كم', 'Distance · ${IcStyle.money(q.km)} km'), q.distance),
        if (q.workers > 0) line(tr('العمال', 'Workers'), q.workers),
        if (q.floors > 0) line(tr('الأدوار بدون مصعد', 'Floors without a lift'), q.floors),
        const Divider(height: 14),
        Row(children: [
          Expanded(child: Text(tr('السعر المقترح', 'Suggested price'), style: IcStyle.t(14, w: FontWeight.w900))),
          Text('$cur ${IcStyle.money(q.suggested)}', style: IcStyle.t(15, w: FontWeight.w900, c: IcStyle.blue)),
        ]),
        const SizedBox(height: 8),
        Text(tr('سعرك (أصحاب السيارات يقبلوه أو يبعتوا عروضهم)', 'Your price (owners accept it or send their offers)'), style: IcStyle.t(12.5, w: FontWeight.w700, c: IcStyle.muted)),
        const SizedBox(height: 4),
        IcFareBar(
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
