import 'package:flutter/material.dart';
import '../../functions/tr.dart';

import '../../functions/intercity_api.dart';
import 'intercity_pay.dart';
import 'intercity_style.dart';
import 'intercity_wait_page.dart';

/// ج · سيارة كاملة: riders, his price (inside the admin's range), time, note, bag → «اطلب عروض السائقين»
class IntercityFarePage extends StatefulWidget {
  const IntercityFarePage({
    super.key,
    required this.home,
    required this.pick,
    required this.route,
    this.drop,
    this.send,
    this.again,
  });

  final IntercityHome home;
  final IcPlace pick;
  final IntercityRoute route;
  final IcPlace? drop;

  /// «نفس السفرة مرة ثانية»: riders, bag, round trip and price filled from last time
  final IntercityLastTrip? again;

  /// tests replace the network call
  final Future<IntercityResult> Function(Map<String, Object?> booking)? send;

  @override
  State<IntercityFarePage> createState() => _IntercityFarePageState();
}

class _IcTime {
  const _IcTime(this.label, this.at);
  final String label;
  final DateTime Function() at;
}

class _IntercityFarePageState extends State<IntercityFarePage> {
  Map? _quote;
  late int _passengers = widget.again?.passengers ?? 1;
  late bool _round = (widget.again?.roundTrip ?? false) && widget.home.roundTripOn && widget.route.roundTrip != null;
  late int _wait = widget.again?.waitHours ?? 4;
  late num _fare = widget.again?.price ?? (_round ? (widget.route.roundTrip!['suggested'] as num? ?? widget.route.suggested) : widget.route.suggested);
  late bool _bag = widget.again?.bigBag ?? false;

  /// «الزبون يختار»: what he picked; «online»/«cash» decide on their own
  bool _choseOnline = false;
  IcPayment get _pay => widget.home.payment;
  bool get _payOnline => _pay.onlineFor(true, chose: _choseOnline);
  String _note = '';
  int _time = 0;
  DateTime? _custom;
  bool _busy = false;
  String? _error;

  static DateTime _day(int plus, int hour) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + plus, hour);
  }

  final List<_IcTime> _times = [
    _IcTime(tr('أقرب وقت (خلال ساعة)', 'As soon as possible (within an hour)'), () => DateTime.now().add(const Duration(minutes: 45))),
    _IcTime(tr('بكرة 7:00 الصبح', 'Tomorrow 7:00 am'), () => _day(1, 7)),
    _IcTime(tr('بكرة 2:00 الظهر', 'Tomorrow 2:00 pm'), () => _day(1, 14)),
  ];

  /// «ذهاب ورجوع»: the admin's round-trip range, else the one-way one
  Map? get _roundBlock => (_quote?['round_trip'] is Map ? _quote!['round_trip'] as Map : null) ?? widget.route.roundTrip;
  bool get _roundOffered => widget.home.roundTripOn && _roundBlock != null;
  num _pick(String k, num oneWay) => _round && _roundBlock != null ? ((_roundBlock![k] as num?) ?? oneWay) : oneWay;
  num get _min => _pick('min', (_quote?['min'] as num?) ?? widget.route.min);
  num get _max => _pick('max', (_quote?['max'] as num?) ?? widget.route.max);
  num get _suggested => _pick('suggested', (_quote?['suggested'] as num?) ?? widget.route.suggested);
  int get _maxWait => ((_roundBlock?['max_wait_hours'] as num?)?.toInt() ?? widget.home.maxWaitHours).clamp(1, 12);
  int? get _travel => (_quote?['travel_minutes'] as num?)?.toInt() ?? widget.route.travelMinutes;

  /// the hours he can ask the driver to wait: 2, 4, 6… up to the admin's longest
  List<int> get _waits {
    final out = <int>[for (var h = 2; h < _maxWait; h += 2) h];
    return [...out, _maxWait];
  }

  /// «ترجع حوالي 6:00 بالليل»
  String get _returnLabel {
    final back = _start.add(Duration(minutes: _travel ?? 0, hours: _wait));
    // «حوالي» to the quarter hour: 8:22 reads as 8:30
    final q = DateTime(back.year, back.month, back.day, back.hour, ((back.minute + 7) ~/ 15) * 15);
    return IntercityApi.dayLabel(IntercityApi.wallClock(q));
  }

  void _setRound(bool on) {
    if (on == _round) return;
    setState(() {
      _round = on;
      if (_wait > _maxWait) _wait = _maxWait;
      _fare = _suggested;
    });
  }
  num get _step => _max - _min >= 100 ? 10 : 5;
  num? get _hint => (_quote?['accepted_from'] as num?) ?? widget.route.acceptedFrom;
  DateTime get _start => _time < _times.length ? _times[_time].at() : (_custom ?? DateTime.now().add(const Duration(hours: 2)));
  String get _timeLabel => _time < _times.length ? _times[_time].label : IntercityApi.dayLabel(IntercityApi.wallClock(_custom!));
  IcPlace get _drop => widget.drop ?? IcPlace(widget.route.lat, widget.route.lng, tr('${widget.route.to} · وسط المدينة', '${widget.route.to} · city centre'));

  @override
  void initState() {
    super.initState();
    if (widget.drop != null) _loadQuote();
  }

  Future<void> _loadQuote() async {
    final q = await IntercityApi.quote(widget.pick.lat, widget.pick.lng, _drop.lat, _drop.lng);
    if (!mounted || q == null) return;
    setState(() {
      _quote = q;
      // last time's price stays; otherwise the price for this exact drop
      if (widget.again == null) _fare = _suggested;
      _fare = _fare.clamp(_min, _max);
    });
  }

  Future<void> _pickTime() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: IcSheet(children: [
          Text(tr('متى تسافر؟', 'When do you travel?'), style: IcStyle.t(21, w: FontWeight.w900)),
          const SizedBox(height: 10),
          for (var i = 0; i <= _times.length; i++) ...[
            IcChoiceRow(text: i < _times.length ? _times[i].label : tr('يوم وساعة ثانيين…', 'Another day and time…'), selected: _time == i, onTap: () => Navigator.pop(ctx, i)),
            const SizedBox(height: 6),
          ],
          Text(tr('الحجز من الآن حتى ${widget.home.horizonDays} أيام قدام.', 'Book from now up to ${widget.home.horizonDays} days ahead.'), style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
        ]),
      ),
    );
    if (chosen == null || !mounted) return;
    if (chosen < _times.length) {
      setState(() => _time = chosen);
      return;
    }
    final now = DateTime.now();
    final day = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: now.add(Duration(days: widget.home.horizonDays)), initialDate: now.add(const Duration(days: 1)));
    if (day == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (time == null || !mounted) return;
    setState(() {
      _custom = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _time = _times.length;
    });
  }

  Future<void> _pickNote() async {
    final c = TextEditingController(text: _note);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: (appRtl ? TextDirection.rtl : TextDirection.ltr),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: IcSheet(children: [
            Text(tr('ملاحظة للسائق', 'Note for the driver'), style: IcStyle.t(21, w: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              autofocus: true,
              maxLength: 200,
              minLines: 3,
              maxLines: 4,
              style: IcStyle.t(14, w: FontWeight.w600),
              decoration: InputDecoration(
                hintText: tr('مثلًا: عندي كرسي أطفال، أو نستناك قدام الجامع', 'e.g. I have a child seat, or we wait in front of the mosque'),
                hintStyle: IcStyle.t(13, w: FontWeight.w500, c: IcStyle.muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            Text(tr('ما تكتبش رقم تليفون: الرقم يتوقف قبل ما يوصل للسائق.', 'Do not write a phone number: it is removed before it reaches the driver.'), style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
            const SizedBox(height: 10),
            IcButton(text: tr('تم', 'Done'), onTap: () => Navigator.pop(ctx, c.text.trim())),
          ]),
        ),
      ),
    );
    c.dispose();
    if (saved != null && mounted) setState(() => _note = saved);
  }

  Future<void> _send() async {
    final zt = widget.home.zoneTypeId;
    if (zt == null || zt.isEmpty) {
      setState(() => _error = tr('الخدمة مش جاهزة في مدينتك. جرّب بعد شوي.', 'The service is not ready in your city. Try again soon.'));
      return;
    }
    final booking = <String, Object?>{
      'zone_type_id': zt, 'drop': _drop, 'start': _start, 'fare': _fare, 'passengers': _passengers, 'big_bag': _bag, 'note': _note,
      'wait_hours': _round ? _wait : null,
      'pay_online': _payOnline,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = widget.send != null
        ? await widget.send!(booking)
        : await IntercityApi.requestCar(
            zoneTypeId: zt,
            pickLat: widget.pick.lat,
            pickLng: widget.pick.lng,
            pickAddress: widget.pick.address,
            dropLat: _drop.lat,
            dropLng: _drop.lng,
            dropAddress: _drop.address,
            start: _start,
            fare: _fare,
            passengers: _passengers,
            bigBag: _bag,
            note: _note,
            waitHours: _round ? _wait : null,
            payOnline: _payOnline,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.message);
      return;
    }
    final id = r.data is Map ? '${(r.data as Map)['id'] ?? ''}' : '';
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => IntercityWaitPage(
        rideId: id,
        from: widget.home.from,
        to: widget.route.to,
        fare: _fare,
        max: _max,
        step: _step,
        summary: [
          _timeLabel,
          '$_passengers ${_passengers == 1 ? tr('راكب', 'passenger') : tr('ركاب', 'passengers')}',
          if (_round) tr('ذهاب ورجوع · يستناك $_wait س', 'Round trip · waits $_wait h'),
        ].join(' · '),
        pickAddress: widget.pick.address,
        dropAddress: _drop.address,
        note: _note,
        payOnline: _payOnline,
        payment: _pay,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return IcScaffold(
      title: '${widget.home.from} ← ${widget.route.to}',
      mapHeight: 200,
      bottom: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_error != null) ...[
          Text(_error!, textAlign: TextAlign.center, style: IcStyle.t(13.5, c: const Color(0xffD92D20))),
          const SizedBox(height: 6),
        ],
        IcButton(text: tr('اطلب عروض السائقين', 'Ask drivers for offers'), busy: _busy, onTap: _send),
      ]),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.again != null ? tr('نفس سفرتك مرة ثانية', 'Your trip again') : tr('سيارة كاملة', 'Whole car'), style: IcStyle.t(21, w: FontWeight.w900)),
              Text(widget.again != null ? tr('عبّينا كل شي. اختار الوقت بس', 'We filled everything in. Just choose the time') : tr('حدد عدد الركاب وأجرتك', 'Set the passengers and your fare'),
                  style: IcStyle.t(13.5, w: FontWeight.w600, c: IcStyle.muted)),
            ]),
          ),
          const IcIconTile(icon: Icons.directions_car_filled_rounded, background: IcStyle.blue, color: Colors.white, size: 50),
        ]),
        if (_roundOffered) ...[
          const SizedBox(height: 12),
          IcTripKind(round: _round, onChanged: _setRound),
          if (_round) ...[
            const SizedBox(height: 8),
            IcWaitCard(waits: _waits, wait: _wait, back: _returnLabel, onWait: (h) => setState(() => _wait = h)),
          ],
        ],
        const SizedBox(height: 12),
        Row(children: [
          for (var n = 1; n <= widget.home.maxPassengers; n++) ...[
            if (n > 1) const SizedBox(width: 8),
            Expanded(
              child: IcChip(fill: true, text: n == _passengers && n > 1 ? tr('$n ركاب', '$n passengers') : '$n', selected: n == _passengers, onTap: () => setState(() => _passengers = n)),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        if (widget.again != null && widget.again!.priceChanged) ...[
          IcPriceChanged(was: widget.again!.paid, now: widget.again!.price),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Expanded(child: Text(_round ? tr('أجرة الذهاب والرجوع', 'Round-trip fare') : tr('أجرة رحلتك', 'Your fare'), style: IcStyle.t(17, w: FontWeight.w900))),
          Text(tr('المقترحة LYD ${IcStyle.money(_suggested)}', 'Suggested LYD ${IcStyle.money(_suggested)}'), style: IcStyle.t(13, w: FontWeight.w800, c: IcStyle.blue)),
        ]),
        const SizedBox(height: 6),
        IcFareBar(
          value: _fare,
          onPlus: _fare + _step <= _max ? () => setState(() => _fare += _step) : null,
          onMinus: _fare - _step >= _min ? () => setState(() => _fare -= _step) : null,
        ),
        const SizedBox(height: 4),
        Text(tr('من ${IcStyle.money(_min)} إلى ${IcStyle.money(_max)} · السعر لوسط ${widget.route.to}، أبعد يزيد شوية', 'From ${IcStyle.money(_min)} to ${IcStyle.money(_max)} · the price to central ${widget.route.to}, a bit more further away'),
            style: IcStyle.t(12, w: FontWeight.w600, c: IcStyle.muted)),
        if (_pay.choiceFor(true)) ...[
          const SizedBox(height: 10),
          IcPayChoice(online: _choseOnline, onChanged: (v) => setState(() => _choseOnline = v)),
        ],
        if (_payOnline) ...[
          const SizedBox(height: 8),
          IcPayNote(
              text: _pay.depositPercent < 100
                  ? tr('عربون ${_pay.depositPercent}٪ من محفظتك لما تختار الكابتن، والباقي نقدًا · رصيدك LYD ${IcStyle.money(_pay.balance)}', 'A ${_pay.depositPercent}% deposit from your wallet when you choose the captain, the rest in cash · balance LYD ${IcStyle.money(_pay.balance)}')
                  : tr('تدفع من محفظتك لما تختار الكابتن · رصيدك LYD ${IcStyle.money(_pay.balance)}', 'You pay from your wallet when you choose the captain · balance LYD ${IcStyle.money(_pay.balance)}')),
        ],
        if (_hint != null) ...[
          const SizedBox(height: 4),
          Text(
            _fare < _hint! ? tr('سعرك أقل من اللي تنقبل بيه الطلبات عادة (من LYD ${IcStyle.money(_hint!)})', 'Your price is lower than what requests are usually accepted at (from LYD ${IcStyle.money(_hint!)})') : tr('أغلب الطلبات تنقبل من LYD ${IcStyle.money(_hint!)} وفوق 👍', 'Most requests are accepted from LYD ${IcStyle.money(_hint!)} up 👍'),
            key: const ValueKey('ic-hint'),
            style: IcStyle.t(12.5, w: FontWeight.w800, c: _fare < _hint! ? const Color(0xffB45309) : const Color(0xff16803C)),
          ),
        ],
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xffEEF2F7)),
        IcRow(icon: Icons.schedule_rounded, text: _timeLabel, onTap: _pickTime),
        IcRow(icon: Icons.chat_bubble_outline_rounded, text: _note.isEmpty ? tr('ملاحظة للسائق', 'Note for the driver') : _note, muted: _note.isEmpty, onTap: _pickNote),
        IcRow(
          icon: Icons.luggage_outlined,
          text: tr('شنطة كبيرة', 'Big bag'),
          trailing: Switch.adaptive(value: _bag, activeTrackColor: IcStyle.blue, onChanged: (v) => setState(() => _bag = v)),
          onTap: () => setState(() => _bag = !_bag),
          last: true,
        ),
      ],
    );
  }
}

/// «ذهاب بس | ذهاب ورجوع ⇄»
class IcTripKind extends StatelessWidget {
  const IcTripKind({super.key, required this.round, required this.onChanged});

  final bool round;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget side(String text, bool on, bool value) => Expanded(
          child: Semantics(
            button: true,
            selected: on,
            label: text,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: on ? [BoxShadow(color: IcStyle.navy.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Text(text, style: IcStyle.t(14.5, w: FontWeight.w900, c: on ? IcStyle.blue : IcStyle.muted)),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: IcStyle.soft, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [side(tr('ذهاب بس', 'One way'), !round, false), const SizedBox(width: 4), side(tr('ذهاب ورجوع ⇄', 'Round trip ⇄'), round, true)]),
    );
  }
}

/// ⏳ «الكابتن يستناك»: how many hours, and when he heads back
class IcWaitCard extends StatelessWidget {
  const IcWaitCard({super.key, required this.waits, required this.wait, required this.back, required this.onWait});

  final List<int> waits;
  final int wait;
  final String back;
  final ValueChanged<int> onWait;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(color: const Color(0xffFFF8E6), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffFDE3A7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Text('⏳', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('نفس اليوم · الكابتن يستناك', 'Same day · the captain waits for you'), style: IcStyle.t(15, w: FontWeight.w900)),
              Text(tr('ترجع حوالي $back', 'Back around $back'), key: const ValueKey('ic-back'), style: IcStyle.t(12.5, w: FontWeight.w700, c: const Color(0xff9A6700))),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (final h in waits) ...[
            if (h != waits.first) const SizedBox(width: 6),
            Expanded(child: IcChip(fill: true, text: tr('$h س', '$h h'), selected: h == wait, onTap: () => onWait(h))),
          ],
        ]),
      ]),
    );
  }
}

/// the repeat card's price moved: «السعر تغيّر · كان 160، توا 170»
class IcPriceChanged extends StatelessWidget {
  const IcPriceChanged({super.key, required this.was, required this.now});

  final num was;
  final num now;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('ic-price-changed'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xffFFF4E0), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xffB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: tr('السعر تغيّر · كان ', 'The price changed · it was ')),
              TextSpan(text: 'LYD ${IcStyle.money(was)}', style: const TextStyle(decoration: TextDecoration.lineThrough)),
              TextSpan(text: tr('، توا LYD ${IcStyle.money(now)}', ', now LYD ${IcStyle.money(now)}')),
            ]), style: IcStyle.t(13, w: FontWeight.w800, c: const Color(0xffB45309))),
          ),
        ]),
      );
}

/// − price + in a light blue bar
class IcFareBar extends StatelessWidget {
  const IcFareBar({super.key, required this.value, required this.onPlus, required this.onMinus, this.compact = false});

  final num value;
  final VoidCallback? onPlus;
  final VoidCallback? onMinus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 42.0 : 50.0;
    Widget sq(String s, VoidCallback? f, String label) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: compact ? Colors.white : IcStyle.soft,
            borderRadius: BorderRadius.circular(compact ? h / 2 : 16),
            child: InkWell(
              onTap: f,
              borderRadius: BorderRadius.circular(compact ? h / 2 : 16),
              child: SizedBox(width: h, height: h, child: Center(child: Text(s, style: IcStyle.t(24, w: FontWeight.w900, c: f == null ? const Color(0xffB8C4D8) : IcStyle.blue)))),
            ),
          ),
        );
    return Row(children: [
      sq('+', onPlus, tr('زيادة', 'Increase')),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: compact ? Colors.white : const Color(0xffEAF2FF), borderRadius: BorderRadius.circular(compact ? 14 : 16)),
          child: Text('LYD ${IcStyle.money(value)}', style: IcStyle.t(compact ? 21 : 24, w: FontWeight.w900)),
        ),
      ),
      const SizedBox(width: 8),
      sq('−', onMinus, tr('نقص', 'Decrease')),
    ]);
  }
}

class IcRow extends StatelessWidget {
  const IcRow({super.key, required this.icon, required this.text, required this.onTap, this.trailing, this.muted = false, this.last = false});

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool muted;
  final bool last;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xffEEF2F7)))),
          child: Row(children: [
            Icon(icon, size: 21, color: IcStyle.navy),
            const SizedBox(width: 10),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: IcStyle.t(15, c: muted ? IcStyle.muted : IcStyle.navy))),
            trailing ?? const Icon(Icons.chevron_left_rounded, color: IcStyle.muted),
          ]),
        ),
      );
}

class IcChoiceRow extends StatelessWidget {
  const IcChoiceRow({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffEAF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? IcStyle.blue : IcStyle.line, width: selected ? 2 : 1.5),
          ),
          child: Text(text, style: IcStyle.t(15, c: selected ? IcStyle.blue : IcStyle.navy)),
        ),
      );
}
