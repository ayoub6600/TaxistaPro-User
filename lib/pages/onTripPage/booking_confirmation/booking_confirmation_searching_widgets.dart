part of '../booking_confirmation.dart';

const _searchBlue = Color(0xff1677FF);
const _searchNavy = Color(0xff102A56);
const _searchMuted = Color(0xff7B8BA8);
const _searchMint = Color(0xff15C79A);

double _searchingSheetHeight(Size media) {
  final compact = media.height < 720;
  return (media.height * (compact ? 0.58 : 0.52)).clamp(390.0, 510.0);
}

class _NearbyDriverCandidate {
  const _NearbyDriverCandidate({required this.data, required this.distance});

  final Map<String, dynamic> data;
  final double distance;

  String get driverId => (data['id'] ?? data['driver_id']).toString();

  double? get counterOffer =>
      double.tryParse(data['counter_offer']?.toString() ?? '');

  double? get counterOfferBase =>
      double.tryParse(data['counter_offer_base']?.toString() ?? '');

  String get counterOfferCurrency =>
      data['counter_offer_currency']?.toString() ?? 'LYD';

  String get revealKey =>
      (data['id'] ?? data['driver_id'] ?? avatarUrl ?? name).toString();

  String get name {
    final rawName = data['name'] ??
        data['driver_name'] ??
        data['first_name'] ??
        data['full_name'];
    final value = rawName?.toString().trim() ?? '';
    if (value.isEmpty) return '';
    return value.split(RegExp(r'\s+')).first;
  }

  String? get avatarUrl {
    final raw = data['profile_picture'] ??
        data['profile_image'] ??
        data['avatar'] ??
        data['image'];
    final value = raw?.toString().trim() ?? '';
    return value.startsWith('http://') || value.startsWith('https://')
        ? value
        : null;
  }
}

List<_NearbyDriverCandidate> _nearbySearchCandidates({
  required List<dynamic> source,
  required dynamic serviceType,
  required int transportType,
  required double pickupLatitude,
  required double pickupLongitude,
}) {
  final candidates = <_NearbyDriverCandidate>[];

  for (final raw in source) {
    if (raw is! Map) continue;
    final driver = Map<String, dynamic>.from(raw);
    if (!_searchFlagIsOn(driver['is_active']) ||
        !_searchFlagIsOn(driver['is_available'])) {
      continue;
    }

    final transport = driver['transport_type']?.toString();
    final supportsTransport = transportType != 0 ||
        transport == null ||
        transport == 'taxi' ||
        transport == 'both';
    if (!supportsTransport || !_searchDriverSupports(driver, serviceType)) {
      continue;
    }

    final updatedAt = int.tryParse(driver['updated_at']?.toString() ?? '');
    if (updatedAt == null ||
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(updatedAt))
                .inMinutes >
            2) {
      continue;
    }

    final location = driver['l'];
    if (location is! List || location.length < 2) continue;
    final latitude = double.tryParse(location[0].toString());
    final longitude = double.tryParse(location[1].toString());
    if (latitude == null || longitude == null) continue;

    candidates.add(
      _NearbyDriverCandidate(
        data: driver,
        distance: calculateDistance(
          pickupLatitude,
          pickupLongitude,
          latitude,
          longitude,
        ),
      ),
    );
  }

  candidates.sort((a, b) => a.distance.compareTo(b.distance));
  return candidates;
}

List<_NearbyDriverCandidate> _prioritizeTargetedDrivers(
  List<_NearbyDriverCandidate> nearby,
  dynamic requestMetadata,
  dynamic counterOfferMetadata,
) {
  final offers = <String, Map<String, dynamic>>{};
  if (counterOfferMetadata is Map) {
    for (final value in counterOfferMetadata.values) {
      if (value is! Map || value['driver_id'] == null) continue;
      if (value['is_rejected']?.toString() != 'none') continue;
      final offer = Map<String, dynamic>.from(value);
      offers[offer['driver_id'].toString()] = offer;
    }
  }

  _NearbyDriverCandidate withOffer(_NearbyDriverCandidate candidate) {
    final offer = offers[candidate.driverId];
    if (offer == null) return candidate;
    return _NearbyDriverCandidate(
      data: {
        ...candidate.data,
        if (offer['driver_name'] != null) 'name': offer['driver_name'],
        if (offer['driver_img'] != null) 'profile_picture': offer['driver_img'],
        'counter_offer': offer['price'],
        'counter_offer_base': offer['base_price'],
        'counter_offer_currency': offer['currency'],
      },
      distance: candidate.distance,
    );
  }

  final metadataEntries = <Map<String, dynamic>>[];
  if (requestMetadata is Map) {
    final root = Map<dynamic, dynamic>.from(requestMetadata);
    if (root['driver_id'] != null) {
      metadataEntries.add(Map<String, dynamic>.from(root));
    }
    for (final value in root.values) {
      if (value is Map && value['driver_id'] != null) {
        metadataEntries.add(Map<String, dynamic>.from(value));
      }
    }
  }

  final targeted = <_NearbyDriverCandidate>[];
  final targetedIds = <String>{};
  for (final metadata in metadataEntries) {
    final id = metadata['driver_id']?.toString();
    if (id == null || id.isEmpty || !targetedIds.add(id)) continue;
    final matchingIndex = nearby.indexWhere(
      (candidate) => candidate.data['id']?.toString() == id,
    );
    if (matchingIndex >= 0) {
      targeted.add(withOffer(nearby[matchingIndex]));
    } else {
      final offer = offers[id];
      targeted.add(
        _NearbyDriverCandidate(
          data: {
            'id': id,
            if (offer?['driver_name'] != null)
              'name': offer!['driver_name']
            else if (metadata['name'] != null)
              'name': metadata['name'],
            if (offer?['driver_img'] != null)
              'profile_picture': offer!['driver_img']
            else if (metadata['profile_picture'] != null)
              'profile_picture': metadata['profile_picture'],
            if (offer != null) ...{
              'counter_offer': offer['price'],
              'counter_offer_base': offer['base_price'],
              'counter_offer_currency': offer['currency'],
            },
          },
          distance: double.infinity,
        ),
      );
    }
  }

  return [
    ...targeted,
    ...nearby
        .where(
          (candidate) =>
              !targetedIds.contains(candidate.data['id']?.toString()),
        )
        .map(withOffer),
    ...offers.entries
        .where((entry) =>
            !targetedIds.contains(entry.key) &&
            !nearby.any((candidate) => candidate.driverId == entry.key))
        .map(
          (entry) => _NearbyDriverCandidate(
            data: {
              'id': entry.key,
              'name': entry.value['driver_name'],
              'profile_picture': entry.value['driver_img'],
              'counter_offer': entry.value['price'],
              'counter_offer_base': entry.value['base_price'],
              'counter_offer_currency': entry.value['currency'],
            },
            distance: double.infinity,
          ),
        ),
  ];
}

bool _searchFlagIsOn(dynamic value) =>
    value == true || value == 1 || value?.toString() == '1';

bool _searchDriverSupports(Map<String, dynamic> driver, dynamic serviceType) {
  if (serviceType == null) return true;
  final expected = serviceType.toString();
  final types = driver['vehicle_types'];
  if (types is List && types.any((type) => type.toString() == expected)) {
    return true;
  }
  return driver['vehicle_type']?.toString() == expected;
}

class _SearchingDriverOverlay extends StatefulWidget {
  const _SearchingDriverOverlay({
    required this.drivers,
    required this.fare,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRtl,
    required this.onMenu,
    required this.onSupport,
    required this.onCancel,
    required this.onAcceptOffer,
  });

  final List<_NearbyDriverCandidate> drivers;
  final _RideFareData? fare;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRtl;
  final VoidCallback onMenu;
  final VoidCallback onSupport;
  final Future<void> Function() onCancel;
  final Future<bool> Function(_NearbyDriverCandidate driver) onAcceptOffer;

  @override
  State<_SearchingDriverOverlay> createState() =>
      _SearchingDriverOverlayState();
}

class _SearchingDriverOverlayState extends State<_SearchingDriverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final Map<String, _NearbyDriverCandidate> _revealedDrivers = {};
  final Map<String, Timer> _driverRevealTimers = {};
  final AudioPlayer _driverRevealAudio = AudioPlayer();
  DateTime? _lastRevealSoundAt;
  bool _isCancelling = false;
  String? _acceptingOfferKey;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _syncDriverReveals();
  }

  @override
  void didUpdateWidget(covariant _SearchingDriverOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDriverReveals();
  }

  void _syncDriverReveals() {
    final currentByKey = {
      for (final driver in widget.drivers) driver.revealKey: driver,
    };

    for (final key in _driverRevealTimers.keys.toList()) {
      if (!currentByKey.containsKey(key)) {
        _driverRevealTimers.remove(key)?.cancel();
      }
    }
    _revealedDrivers.removeWhere((key, _) => !currentByKey.containsKey(key));
    for (final entry in _revealedDrivers.entries.toList()) {
      final refreshed = currentByKey[entry.key];
      if (refreshed != null) {
        final previousOffer = entry.value.counterOffer;
        _revealedDrivers[entry.key] = refreshed;
        if (refreshed.counterOffer != null &&
            refreshed.counterOffer != previousOffer) {
          unawaited(_playDriverRevealSound());
        }
      }
    }

    var revealIndex = 0;
    for (final driver in widget.drivers) {
      final key = driver.revealKey;
      if (_revealedDrivers.containsKey(key) ||
          _driverRevealTimers.containsKey(key)) {
        continue;
      }
      final delay = Duration(milliseconds: 3000 + (revealIndex * 350));
      revealIndex++;
      _driverRevealTimers[key] = Timer(delay, () {
        _driverRevealTimers.remove(key);
        if (!mounted) return;
        final latest = widget.drivers
            .where((candidate) => candidate.revealKey == key)
            .firstOrNull;
        if (latest == null) return;
        setState(() => _revealedDrivers[key] = latest);
        unawaited(_playDriverRevealSound());
      });
    }
  }

  Future<void> _playDriverRevealSound() async {
    final now = DateTime.now();
    if (_lastRevealSoundAt != null &&
        now.difference(_lastRevealSoundAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRevealSoundAt = now;
    await _driverRevealAudio.stop();
    await _driverRevealAudio.play(
      AssetSource('audio/driver_reveal_pop.mp3'),
      volume: 0.65,
    );
  }

  @override
  void dispose() {
    for (final timer in _driverRevealTimers.values) {
      timer.cancel();
    }
    _driverRevealTimers.clear();
    unawaited(_driverRevealAudio.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    try {
      await widget.onCancel();
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _acceptOffer(_NearbyDriverCandidate driver) async {
    if (_acceptingOfferKey != null) return;
    setState(() => _acceptingOfferKey = driver.revealKey);
    final accepted = await widget.onAcceptOffer(driver);
    if (mounted && !accepted) setState(() => _acceptingOfferKey = null);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final compact = media.height < 720;
    final sheetHeight = _searchingSheetHeight(media);
    final revealedDrivers = widget.drivers
        .where((driver) => _revealedDrivers.containsKey(driver.revealKey))
        .toList(growable: false);
    final activeDrivers = revealedDrivers.take(3).toList(growable: false);
    final queuedDrivers =
        revealedDrivers.skip(3).take(3).toList(growable: false);

    return Directionality(
      textDirection: widget.isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            top: topPadding + 96,
            left: 0,
            right: 0,
            bottom: sheetHeight - 24,
            child: IgnorePointer(
              child: Center(
                child: _SearchRadarPulse(animation: _pulseController),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 18,
            child: _SearchingMapButton(
              icon: Icons.menu_rounded,
              semanticLabel: widget.isRtl ? 'خيارات الطلب' : 'Request options',
              onTap: widget.onMenu,
            ),
          ),
          Positioned(
            top: topPadding + 12,
            right: 18,
            child: _SearchingMapButton(
              icon: Icons.headset_mic_rounded,
              semanticLabel: widget.isRtl ? 'الدعم' : 'Support',
              onTap: widget.onSupport,
            ),
          ),
          Positioned(
            top: topPadding + 17,
            left: 92,
            right: 92,
            child: const _TaxistaWordmark(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: sheetHeight,
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 22,
                11,
                compact ? 18 : 22,
                max(14, MediaQuery.paddingOf(context).bottom + 10),
              ),
              decoration: BoxDecoration(
                color: page,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff15386B).withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffC9D2E0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  SizedBox(height: compact ? 13 : 18),
                  Text(
                    widget.isRtl
                        ? 'قريبًا سيتم قبول طلبك'
                        : 'Your ride will be accepted soon',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: _searchNavy,
                      fontSize: compact ? 21 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _subtitle(activeDrivers.length),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            color: _searchMuted,
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LoadingDots(animation: _pulseController),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 12),
                  if (widget.fare != null) ...[
                    _RideFareBadge(
                      fare: widget.fare!,
                      isRtl: widget.isRtl,
                    ),
                    SizedBox(height: compact ? 8 : 11),
                  ],
                  _SearchTimer(
                    remainingSeconds: widget.remainingSeconds,
                    totalSeconds: widget.totalSeconds,
                    isRtl: widget.isRtl,
                  ),
                  SizedBox(height: compact ? 9 : 13),
                  Expanded(
                    child: activeDrivers.isEmpty
                        ? _WaitingForNearbyDrivers(isRtl: widget.isRtl)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: activeDrivers
                                    .map(
                                      (driver) => _ActiveDriverAvatar(
                                        driver: driver,
                                        animation: _pulseController,
                                        isRtl: widget.isRtl,
                                        isAccepting: _acceptingOfferKey ==
                                            driver.revealKey,
                                        onAcceptOffer: () =>
                                            _acceptOffer(driver),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              if (queuedDrivers.isNotEmpty) ...[
                                SizedBox(height: compact ? 7 : 10),
                                _QueuedDriversRow(
                                  drivers: queuedDrivers,
                                  isRtl: widget.isRtl,
                                ),
                              ],
                            ],
                          ),
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  SizedBox(
                    width: double.infinity,
                    height: compact ? 48 : 52,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _searchBlue,
                        side: const BorderSide(color: _searchBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isCancelling
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: _searchBlue,
                              ),
                            )
                          : Text(
                              widget.isRtl ? 'إلغاء الطلب' : 'Cancel request',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(int visibleCount) {
    if (!widget.isRtl) {
      return visibleCount == 0
          ? 'We are contacting nearby drivers now'
          : 'Your request is being shown to the nearest drivers';
    }
    return visibleCount == 0
        ? 'جارٍ التواصل مع السائقين القريبين'
        : 'طلبك ظاهر الآن لأقرب $visibleCount سائقين';
  }
}

class _TaxistaWordmark extends StatelessWidget {
  const _TaxistaWordmark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Taxista'),
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: Transform.translate(
                  offset: const Offset(1, -2),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _searchBlue,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 1,
          style: GoogleFonts.nunitoSans(
            color: _searchBlue,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchingMapButton extends StatelessWidget {
  const _SearchingMapButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        shape: const CircleBorder(),
        elevation: 5,
        shadowColor: const Color(0xff14315F).withValues(alpha: 0.20),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 54,
            child: Icon(icon, color: _searchNavy, size: 25),
          ),
        ),
      ),
    );
  }
}

class _SearchRadarPulse extends StatelessWidget {
  const _SearchRadarPulse({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _SearchRadarPainter(animation.value),
            child: const SizedBox.square(
              dimension: 190,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _searchBlue,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x551677FF),
                        blurRadius: 18,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: SizedBox.square(
                    dimension: 25,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: 9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchRadarPainter extends CustomPainter {
  const _SearchRadarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var index = 0; index < 3; index++) {
      final phase = (progress + index / 3) % 1;
      final radius = 24 + phase * (size.shortestSide * 0.46 - 24);
      final opacity = (1 - phase) * 0.24;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = _searchBlue.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: pi * 2,
        colors: [
          Colors.transparent,
          _searchBlue.withValues(alpha: 0.03),
          _searchBlue.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0, 0.58, 0.88, 1],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, size.shortestSide * 0.45, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SearchRadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (animation.value + index * 0.22) % 1;
            final opacity = 0.28 + (sin(phase * pi) * 0.72);
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _searchBlue.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _SearchTimer extends StatelessWidget {
  const _SearchTimer({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRtl,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final safeTotal = max(totalSeconds, 1);
    final progress = (remainingSeconds / safeTotal).clamp(0.0, 1.0);
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final time =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: _searchBlue.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: _searchBlue, size: 19),
          const SizedBox(width: 7),
          Text(
            time,
            textDirection: ui.TextDirection.ltr,
            style: GoogleFonts.nunitoSans(
              color: _searchNavy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: _searchBlue,
                backgroundColor: _searchBlue.withValues(alpha: 0.13),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            isRtl ? 'وقت البحث' : 'Search time',
            style: GoogleFonts.cairo(
              color: _searchMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDriverAvatar extends StatelessWidget {
  const _ActiveDriverAvatar({
    required this.driver,
    required this.animation,
    required this.isRtl,
    required this.isAccepting,
    required this.onAcceptOffer,
  });

  final _NearbyDriverCandidate driver;
  final Animation<double> animation;
  final bool isRtl;
  final bool isAccepting;
  final VoidCallback onAcceptOffer;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('driver-reveal-${driver.revealKey}'),
      duration: const Duration(milliseconds: 680),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.62 + (value.clamp(0.0, 1.0) * 0.38),
          child: child,
        ),
      ),
      child: SizedBox(
        width: driver.counterOffer == null ? 86 : 104,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final glow = 7 + sin(animation.value * pi) * 5;
                return Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xff66E7DC), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _searchMint.withValues(alpha: 0.22),
                        blurRadius: glow,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _DriverPortrait(driver: driver)),
                  Positioned(
                    right: -1,
                    bottom: 1,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: _searchMint,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -5,
                    bottom: -5,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        color: _searchBlue,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              driver.name.isEmpty
                  ? (isRtl ? 'سائق قريب' : 'Nearby driver')
                  : driver.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: _searchNavy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (driver.counterOffer != null) ...[
              const SizedBox(height: 4),
              _DriverCounterOfferChip(
                driver: driver,
                isRtl: isRtl,
                isAccepting: isAccepting,
                onTap: onAcceptOffer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverCounterOfferChip extends StatelessWidget {
  const _DriverCounterOfferChip({
    required this.driver,
    required this.isRtl,
    required this.isAccepting,
    required this.onTap,
  });

  final _NearbyDriverCandidate driver;
  final bool isRtl;
  final bool isAccepting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offer = driver.counterOffer!;
    final base = driver.counterOfferBase;
    final currency = driver.counterOfferCurrency;
    String money(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return TweenAnimationBuilder<double>(
      key: ValueKey('offer-${driver.revealKey}-$offer'),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.55, end: 1),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Material(
        color: const Color(0xffE6FBF5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAccepting ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: isAccepting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Text(
                        isRtl
                            ? 'يقبل بـ ${money(offer)} $currency'
                            : 'Accepts for ${money(offer)} $currency',
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          color: const Color(0xff087F65),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        base == null
                            ? (isRtl ? 'اضغط للقبول' : 'Tap to accept')
                            : (isRtl
                                ? 'بدل ${money(base)} • قبول'
                                : 'Instead of ${money(base)} • Accept'),
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          color: _searchMuted,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DriverPortrait extends StatelessWidget {
  const _DriverPortrait({required this.driver});

  final _NearbyDriverCandidate driver;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffE8F4FF), Color(0xffD9FFF7)],
        ),
      ),
      child: const Icon(Icons.person_rounded, color: _searchBlue, size: 35),
    );
    final avatar = driver.avatarUrl;
    if (avatar == null) return fallback;
    return ClipOval(
      child: Image.network(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _QueuedDriversRow extends StatelessWidget {
  const _QueuedDriversRow({required this.drivers, required this.isRtl});

  final List<_NearbyDriverCandidate> drivers;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRtl ? 'بعدها' : 'Next',
          style: GoogleFonts.cairo(
            color: _searchMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        ...drivers.asMap().entries.map((entry) {
          return Container(
            width: 29,
            height: 29,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xffECF1F8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffD9E2EF)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.key + 4}',
              style: GoogleFonts.nunitoSans(
                color: _searchMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isRtl ? 'في حال لم يقبل أحد' : 'if no driver accepts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: _searchMuted.withValues(alpha: 0.78),
              fontSize: 9.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitingForNearbyDrivers extends StatelessWidget {
  const _WaitingForNearbyDrivers({required this.isRtl});

  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xffF5F8FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_taxi_rounded, color: _searchBlue, size: 24),
            const SizedBox(width: 10),
            Text(
              isRtl
                  ? 'نوسّع نطاق البحث عن سائق'
                  : 'Expanding the driver search',
              style: GoogleFonts.cairo(
                color: _searchNavy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
