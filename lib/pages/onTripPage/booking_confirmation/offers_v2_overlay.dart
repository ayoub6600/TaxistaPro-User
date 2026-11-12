part of '../booking_confirmation.dart';

/// «العروض والبحث» v2 — the search screen for a negotiated ride when the admin turned it on.
/// Two minutes (the admin's) with a bar instead of the long countdown; raise the price while
/// waiting; accept automatically up to a price; wide offer cards with «غالي شوية» / «قبول»;
/// the favourite driver first; «العب وأنت تستنى» keeps playing with the best offer pinned above it;
/// Taxista's captain talks while he waits and asks «مازلت تدوّر؟» when the time is up.
class _OffersV2Overlay extends StatefulWidget {
  const _OffersV2Overlay({
    required this.drivers,
    required this.remainingSeconds,
    required this.isRtl,
    required this.onMenu,
    required this.onSupport,
    required this.onAcceptOffer,
    required this.onCancel,
  });

  final List<NearbyDriverCandidate> drivers;
  final int remainingSeconds;
  final bool isRtl;
  final VoidCallback onMenu;
  final VoidCallback onSupport;
  final Future<bool> Function(NearbyDriverCandidate driver) onAcceptOffer;
  final Future<void> Function() onCancel;

  @override
  State<_OffersV2Overlay> createState() => _OffersV2OverlayState();
}

class _OffersV2OverlayState extends State<_OffersV2Overlay> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _tick;
  final AudioPlayer _offerAudio = AudioPlayer();
  final Map<String, int> _firstSeen = {}; // offer key → when this phone first saw it (ms)
  final Set<String> _tooHigh = {}; // offers he answered «غالي شوية» (hidden at once)
  final Set<String> _announced = {};
  String? _accepting;
  double? _raise;
  bool _sending = false;
  bool? _auto;
  bool _played = false;
  String? _toast;
  Timer? _toastTimer;

  String get _requestId => '${userRequestData['id'] ?? ''}';
  double get _myFare => OffersV2.currentFare(userRequestData);
  double get _step => OffersV2.step(userDetails);
  String get _currency => '${userRequestData['requested_currency_symbol'] ?? userRequestData['requested_currency_code'] ?? ''}';

  @override
  void initState() {
    super.initState();
    RideGamesHost.configure().then((_) {
      if (mounted) setState(() {});
    });
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    // the offers' time left and the favourite's head start move every second
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _toastTimer?.cancel();
    _pulse.dispose();
    unawaited(_offerAudio.dispose());
    super.dispose();
  }

  String _key(NearbyDriverCandidate d) => '${d.driverId}:${d.counterOffer}';

  double _leftRatio(NearbyDriverCandidate d) {
    final total = OffersV2.offerSeconds(userRequestData) * 1000;
    final sent = d.bidTime ?? _firstSeen[_key(d)] ?? DateTime.now().millisecondsSinceEpoch;
    return 1 - (DateTime.now().millisecondsSinceEpoch - sent) / total;
  }

  /// the offers to show: not answered, still in time; the favourite first, then the cheapest, the nearest
  List<NearbyDriverCandidate> _offers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = <NearbyDriverCandidate>[];
    for (final d in widget.drivers) {
      if (d.counterOffer == null || _tooHigh.contains(_key(d))) continue;
      _firstSeen.putIfAbsent(_key(d), () => now);
      if (_leftRatio(d) <= 0) continue;
      if (_announced.add(_key(d))) {
        unawaited(_offerAudio.play(AssetSource('audio/offer_received.mp3'), volume: 0.8));
        HapticFeedback.mediumImpact();
      }
      list.add(d);
    }
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      final p = (a.counterOffer ?? 0).compareTo(b.counterOffer ?? 0);
      return p != 0 ? p : (a.etaMinutes ?? 99).compareTo(b.etaMinutes ?? 99);
    });
    return list;
  }

  void _say(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _accept(NearbyDriverCandidate d) async {
    if (_accepting != null) return;
    setState(() => _accepting = d.revealKey);
    final ok = await widget.onAcceptOffer(d);
    if (mounted && !ok) setState(() => _accepting = null);
  }

  Future<void> _tooHighFor(NearbyDriverCandidate d) async {
    setState(() => _tooHigh.add(_key(d)));
    final name = d.name.isEmpty ? 'الكابتن' : d.name;
    _say('قلنا ل$name بلطف إن ${OffersV2.money(d.counterOffer ?? 0)} غالي شوية عليك. لو نزّل سعره يرجعلك عرضه.');
    final ok = await refuseDriverOffer(_requestId, d.driverId, reason: 'too_high');
    if (!ok && mounted) {
      setState(() => _tooHigh.remove(_key(d)));
      _say('ما وصلش ردك. جرّب مرة ثانية.');
    }
  }

  Future<void> _sendRaise(double fare) async {
    if (_sending) return;
    setState(() => _sending = true);
    final r = await OffersV2.raise(_requestId, fare);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!r.ok) {
      _say(r.message.isEmpty ? 'ما قدرناش نغيّر السعر.' : r.message);
      return;
    }
    userRequestData['rider_proposed_fare'] = fare;
    userRequestData['offerred_ride_fare'] = fare;
    _raise = null;
    _restartSearch();
    _say('سعرك صار $_currency ${OffersV2.money(fare)}، وبعتناه من جديد للكباتن القريبين.');
  }

  void _restartSearch() {
    offersV2Asking = false;
    timing = OffersV2.searchSeconds(userRequestData, userDetails);
    valueNotifierBook.incrementNotifier();
  }

  Future<void> _keepSearching() async {
    if (_sending) return;
    setState(() => _sending = true);
    final r = await OffersV2.keepSearching(_requestId);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _restartSearch();
    } else {
      _say(r.message.isEmpty ? 'ما قدرناش نكمّل البحث.' : r.message);
    }
  }

  Future<void> _toggleAuto(bool on) async {
    final max = _myFare + _step * 2;
    setState(() => _auto = on);
    final r = await OffersV2.autoAccept(_requestId, on ? max : null);
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _auto = !on);
      _say(r.message.isEmpty ? 'ما قدرناش نشغّل القبول التلقائي.' : r.message);
    } else if (on) {
      _say('أول عرض لين $_currency ${OffersV2.money(max)} نقبله لك تلقائيًا.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    RideGamesHost.sync(context);
    final offers = _offers();
    final playing = RideGamesHost.enabledWhileSearching && RideGamesHost.boxOpen;
    final viewers = widget.drivers.where((d) => d.targeted).length;
    final sheetHeight = (media.height * 0.68).clamp(500.0, 660.0).toDouble();
    final total = OffersV2.searchSeconds(userRequestData, userDetails);
    final left = offersV2Asking ? 0 : widget.remainingSeconds;
    final fav = OffersV2.favorite(userRequestData);
    final auto = _auto ?? OffersV2.autoAcceptMax(userRequestData) != null;

    String? badgeFor(int i, NearbyDriverCandidate d) {
      if (d.isFavorite) return 'favorite';
      final firstPlain = offers.indexWhere((o) => !o.isFavorite);
      return i == firstPlain ? 'best' : null;
    }

    return Directionality(
      textDirection: widget.isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Stack(children: [
        Positioned(
          top: top + 96,
          left: 0,
          right: 0,
          bottom: sheetHeight - 24,
          child: IgnorePointer(child: Center(child: _SearchRadarPulse(animation: _pulse))),
        ),
        Positioned(top: top + 12, left: 18, child: _SearchingMapButton(icon: Icons.menu_rounded, semanticLabel: 'خيارات الطلب', onTap: widget.onMenu)),
        Positioned(top: top + 12, right: 18, child: _SearchingMapButton(icon: Icons.headset_mic_rounded, semanticLabel: 'الدعم', onTap: widget.onSupport)),
        Positioned(top: top + 17, left: 92, right: 92, child: const _TaxistaWordmark()),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: sheetHeight,
            padding: EdgeInsets.fromLTRB(16, 10, 16, max(12, bottom + 8)),
            decoration: BoxDecoration(
              color: page,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: const Color(0xff15386B).withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, -10))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0xffC9D2E0), borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      offers.isEmpty ? 'ندوّرلك على كابتن' : (offers.length == 1 ? 'وصلك عرض من كابتن' : 'وصلتك ${offers.length} عروض'),
                      style: GoogleFonts.cairo(color: _searchNavy, fontSize: 21, fontWeight: FontWeight.w900, height: 1.25),
                    ),
                    Row(children: [
                      Flexible(
                        child: Text(
                          viewers == 0 ? 'جارٍ التواصل مع الكباتن القريبين' : (viewers == 1 ? 'كابتن قريب يشوف طلبك' : '$viewers كباتن قريبين يشوفوا طلبك'),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(color: _searchMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _LoadingDots(animation: _pulse),
                    ]),
                  ]),
                ),
                Text(OffersV2.clock(left),
                    textDirection: ui.TextDirection.ltr,
                    style: GoogleFonts.cairo(color: _searchNavy, fontSize: 26, fontWeight: FontWeight.w900, fontFeatures: const [ui.FontFeature.tabularFigures()])),
                const SizedBox(width: 4),
                _TitleMenuButton(onTap: widget.onMenu),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (left / max(total, 1)).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xffE3E9F2),
                  color: _searchBlue,
                ),
              ),
              if (fav != null) ...[const SizedBox(height: 8), _favoriteRow(fav, offers)],
              const SizedBox(height: 8),
              _stepper(),
              if (RideGamesHost.enabledWhileSearching) ...[
                const SizedBox(height: 8),
                if (playing) ...[
                  if (offers.isNotEmpty) ...[
                    _OfferStripV2(
                      top: offers.first,
                      count: offers.length,
                      currency: _currency,
                      leftRatio: _leftRatio(offers.first),
                      onAccept: () => _accept(offers.first),
                      onShowAll: () => setState(() => RideGamesHost.boxOpen = false),
                    ),
                    const SizedBox(height: 8),
                  ],
                  WaitingGamesBox(
                    status: RideGamesHost.status,
                    controller: RideGamesHost.controller,
                    height: (media.height * 0.22).clamp(140.0, 210.0).toDouble(),
                    onClose: () => setState(() => RideGamesHost.boxOpen = false),
                  ),
                ] else
                  PlayWhileWaitingButton(
                    label: _played ? 'كمّل اللعب' : 'العب وأنت تستنى',
                    onTap: () => setState(() {
                      RideGamesHost.boxOpen = true;
                      _played = true;
                    }),
                  ),
              ],
              if (OffersV2.autoAcceptAllowed(userDetails)) ...[const SizedBox(height: 8), _autoRow(auto)],
              const SizedBox(height: 8),
              Expanded(
                child: playing
                    ? const SizedBox.shrink()
                    : offers.isEmpty
                        ? _captainSays()
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: offers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final d = offers[i];
                              return _OfferCardV2(
                                driver: d,
                                myFare: _myFare,
                                currency: _currency,
                                badge: badgeFor(i, d),
                                leftRatio: _leftRatio(d),
                                isAccepting: _accepting == d.revealKey,
                                locked: _accepting != null,
                                onAccept: () => _accept(d),
                                onTooHigh: () => _tooHighFor(d),
                                onTap: () {},
                              );
                            },
                          ),
              ),
            ]),
          ),
        ),
        if (offersV2Asking) ...[
          Positioned.fill(child: ColoredBox(color: _searchNavy.withValues(alpha: 0.5))),
          Align(alignment: Alignment.bottomCenter, child: _askSheet(bottom)),
        ],
        if (_toast != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: bottom + 24,
            child: Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: _searchNavy, borderRadius: BorderRadius.circular(18)),
                child: Text(_toast!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.5)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _favoriteRow(Map fav, List<NearbyDriverCandidate> offers) {
    final name = '${fav['name'] ?? ''}'.trim();
    final total = int.tryParse('${fav['seconds_left'] ?? ''}') ?? 0;
    // seconds_left was true when the ride was read; count down from the screen's own clock
    final firstAt = _firstSeen.putIfAbsent('fav', () => DateTime.now().millisecondsSinceEpoch);
    final left = max(0, total - (DateTime.now().millisecondsSinceEpoch - firstAt) ~/ 1000);
    final answered = offers.any((o) => o.driverId == '${fav['driver_id']}');
    final text = left > 0 && !answered ? 'طلبك عنده أول، قبل باقي الكباتن' : 'شاف طلبك أول، وتوا طلبك عند كل الكباتن القريبين';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xffFFF1F3), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.favorite_rounded, color: Color(0xffE11D48), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$name ', style: const TextStyle(fontWeight: FontWeight.w900)),
              TextSpan(text: 'سائقك المفضل · $text'),
            ]),
            style: GoogleFonts.cairo(color: _searchNavy, fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
        if (left > 0 && !answered)
          Text(OffersV2.clock(left), textDirection: ui.TextDirection.ltr, style: GoogleFonts.cairo(color: const Color(0xffBE123C), fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _stepper() {
    final now = _myFare;
    final value = _raise ?? now;
    Widget sq(String t, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(child: Text(t, style: GoogleFonts.cairo(color: onTap == null ? const Color(0xffB8C4D8) : _searchBlue, fontSize: 22, fontWeight: FontWeight.w900))),
              ),
            ),
          ),
        );
    final changed = value > now;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xffF3F7FE), borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        sq('−', 'نقّص', changed ? () => setState(() => _raise = max(now, value - _step)) : null),
        Expanded(
          child: Text('$_currency ${OffersV2.money(value)}',
              textAlign: TextAlign.center,
              textDirection: ui.TextDirection.ltr,
              style: GoogleFonts.cairo(color: _searchNavy, fontSize: 19, fontWeight: FontWeight.w900)),
        ),
        sq('+', 'زيد', () => setState(() => _raise = value + _step)),
        const SizedBox(width: 6),
        SizedBox(
          height: 42,
          child: FilledButton(
            onPressed: changed && !_sending ? () => _sendRaise(value) : null,
            style: FilledButton.styleFrom(
              backgroundColor: _searchBlue,
              disabledBackgroundColor: const Color(0xffD5DEEB),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(changed ? 'أرسل ${OffersV2.money(value)}' : 'سعرك',
                style: GoogleFonts.cairo(color: changed ? Colors.white : const Color(0xff8492A8), fontSize: 14, fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }

  Widget _autoRow(bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xffF3F7FE), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'اقبل تلقائيًا أول عرض لين '),
                TextSpan(text: '$_currency ${OffersV2.money(_myFare + _step * 2)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
              style: GoogleFonts.cairo(color: _searchNavy, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Switch.adaptive(value: on, activeColor: _searchBlue, onChanged: (v) => _toggleAuto(v)),
        ]),
      );

  Widget _captainSays() => Align(
        alignment: AlignmentDirectional.topStart,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Image.asset(_offerMascotAsset, width: 86, height: 92, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(width: 86)),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: _searchBlue,
                borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(18), topEnd: Radius.circular(18), bottomEnd: Radius.circular(18), bottomStart: Radius.circular(4)),
              ),
              child: Text('ندوّرلك على أحسن كابتن قريب منك. أول ما واحد يبعت سعره يظهر هنا 👇',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.55)),
            ),
          ),
        ]),
      );

  Widget _askSheet(double bottom) {
    final more = _myFare + _step * 2;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 16, max(16, bottom + 10)),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: const Color(0xffE3E9F2), borderRadius: BorderRadius.circular(99)))),
        Image.asset(_offerMascotAsset, height: 98, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 20)),
        Text('مازلت تدوّر على رحلة؟', textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _searchNavy, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('الكباتن القريبين شافوا طلبك. لو تزيد شوية على سعرك، تجيك عروض أكثر.',
            textAlign: TextAlign.center, style: GoogleFonts.cairo(color: _searchMuted, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.6)),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _sending ? null : _keepSearching,
            style: FilledButton.styleFrom(backgroundColor: _searchBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('كمّل البحث', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: TextButton(
            onPressed: _sending ? null : () => _sendRaise(more),
            style: TextButton.styleFrom(backgroundColor: const Color(0xffF3F7FE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: Text('زيد ${OffersV2.money(_step * 2)} وكمّل · $_currency ${OffersV2.money(more)}',
                style: GoogleFonts.cairo(color: _searchNavy, fontSize: 15.5, fontWeight: FontWeight.w800)),
          ),
        ),
        TextButton(
          onPressed: _sending ? null : widget.onCancel,
          child: Text('ألغِ الطلب', style: GoogleFonts.cairo(color: const Color(0xffD92D20), fontSize: 14.5, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
