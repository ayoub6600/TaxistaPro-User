part of '../booking_confirmation.dart';

const _searchBlue = Color(0xff1677FF);
const _searchNavy = Color(0xff102A56);
const _searchMuted = Color(0xff7B8BA8);

double _searchingSheetHeight(Size media) {
  final compact = media.height < 720;
  return (media.height * (compact ? 0.58 : 0.52)).clamp(390.0, 510.0);
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
    required this.onAcceptOffer,
  });

  final List<NearbyDriverCandidate> drivers;
  final _RideFareData? fare;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRtl;
  final VoidCallback onMenu;
  final VoidCallback onSupport;
  final Future<bool> Function(NearbyDriverCandidate driver) onAcceptOffer;

  @override
  State<_SearchingDriverOverlay> createState() =>
      _SearchingDriverOverlayState();
}

class _SearchingDriverOverlayState extends State<_SearchingDriverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final Map<String, NearbyDriverCandidate> _revealedDrivers = {};
  final Map<String, Timer> _driverRevealTimers = {};
  final AudioPlayer _driverRevealAudio = AudioPlayer();
  final AudioPlayer _offerReceivedAudio = AudioPlayer();
  final Set<String> _announcedOffers = {};
  DateTime? _lastRevealSoundAt;
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
          _announceOffer(refreshed);
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
        // A driver revealed with an offer already on it is not news: only the
        // "driver is here" sound plays, and the offer is marked as announced
        // so a later resync does not replay the coin drop.
        _markOfferAnnounced(latest);
        unawaited(_playDriverRevealSound());
      });
    }
  }

  String? _offerKey(NearbyDriverCandidate driver) {
    final offer = driver.counterOffer;
    return offer == null ? null : '${driver.revealKey}:$offer';
  }

  void _markOfferAnnounced(NearbyDriverCandidate driver) {
    final key = _offerKey(driver);
    if (key != null) _announcedOffers.add(key);
  }

  /// Plays the coin drop once per distinct offer. Rebuilds, stream resyncs and
  /// repeated Firebase events for the same amount stay silent.
  void _announceOffer(NearbyDriverCandidate driver) {
    final key = _offerKey(driver);
    if (key == null || !_announcedOffers.add(key)) return;
    unawaited(_playOfferReceivedSound());
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

  Future<void> _playOfferReceivedSound() async {
    await _offerReceivedAudio.stop();
    await _offerReceivedAudio.play(
      AssetSource('audio/offer_received.mp3'),
      volume: 0.8,
    );
  }

  @override
  void dispose() {
    for (final timer in _driverRevealTimers.values) {
      timer.cancel();
    }
    _driverRevealTimers.clear();
    unawaited(_driverRevealAudio.dispose());
    unawaited(_offerReceivedAudio.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _acceptOffer(NearbyDriverCandidate driver) async {
    if (_acceptingOfferKey != null) return;
    setState(() => _acceptingOfferKey = driver.revealKey);
    final accepted = await widget.onAcceptOffer(driver);
    if (mounted && !accepted) setState(() => _acceptingOfferKey = null);
  }

  Future<void> _showDriverDetails(NearbyDriverCandidate driver) async {
    final isRtl = widget.isRtl;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: _DriverDetailsSheet(
          driver: driver,
          isRtl: isRtl,
          isAccepting: _acceptingOfferKey == driver.revealKey,
          onAccept: driver.counterOffer == null
              ? null
              : () {
                  Navigator.pop(sheetContext);
                  _acceptOffer(driver);
                },
        ),
      ),
    );
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
    final offeringDrivers = revealedDrivers
        .where((driver) => driver.counterOffer != null)
        .toList(growable: false);
    // Only drivers the dispatcher actually put the request in front of may be
    // shown as viewing it. Nearby drivers that were never notified stay on the
    // map only.
    final viewingDrivers = revealedDrivers
        .where((driver) => driver.counterOffer == null && driver.targeted)
        .toList(growable: false);

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
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
                        Positioned(
                          left: 0,
                          child: _TitleMenuButton(onTap: widget.onMenu),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _subtitle(revealedDrivers.length),
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
                    child: offeringDrivers.isEmpty && viewingDrivers.isEmpty
                        ? _WaitingForNearbyDrivers(isRtl: widget.isRtl)
                        : SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (offeringDrivers.isNotEmpty) ...[
                                  _DriverGroupHeader(
                                    text: widget.isRtl
                                        ? (offeringDrivers.length == 1
                                            ? 'عرض واحد تم استلامه'
                                            : '${offeringDrivers.length} عروض تم استلامها')
                                        : '${offeringDrivers.length} offer${offeringDrivers.length == 1 ? '' : 's'} received',
                                  ),
                                  SizedBox(height: compact ? 6 : 8),
                                  SizedBox(
                                    height: compact ? 158 : 168,
                                    child: offeringDrivers.length <= 3
                                        ? Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                for (var index = 0;
                                                    index <
                                                        offeringDrivers.length;
                                                    index++) ...[
                                                  if (index > 0)
                                                    const SizedBox(width: 10),
                                                  _OfferCard(
                                                    driver:
                                                        offeringDrivers[index],
                                                    isRtl: widget.isRtl,
                                                    isAccepting:
                                                        _acceptingOfferKey ==
                                                            offeringDrivers[
                                                                    index]
                                                                .revealKey,
                                                    onAccept: () =>
                                                        _acceptOffer(
                                                            offeringDrivers[
                                                                index]),
                                                    onTap: () =>
                                                        _showDriverDetails(
                                                            offeringDrivers[
                                                                index]),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          )
                                        : ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            padding: EdgeInsets.zero,
                                            itemCount: offeringDrivers.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 10),
                                            itemBuilder: (context, index) {
                                              final driver =
                                                  offeringDrivers[index];
                                              return _OfferCard(
                                                driver: driver,
                                                isRtl: widget.isRtl,
                                                isAccepting:
                                                    _acceptingOfferKey ==
                                                        driver.revealKey,
                                                onAccept: () =>
                                                    _acceptOffer(driver),
                                                onTap: () =>
                                                    _showDriverDetails(driver),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                                if (viewingDrivers.isNotEmpty) ...[
                                  SizedBox(height: compact ? 8 : 11),
                                  _DriverGroupHeader(
                                    text: widget.isRtl
                                        ? (viewingDrivers.length == 1
                                            ? 'سائق واحد يشاهد الطلب الآن'
                                            : '${viewingDrivers.length} سائقين يشاهدون الطلب الآن')
                                        : '${viewingDrivers.length} driver${viewingDrivers.length == 1 ? '' : 's'} viewing your request',
                                  ),
                                  SizedBox(height: compact ? 6 : 8),
                                  SizedBox(
                                    height: compact ? 58 : 64,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.zero,
                                      itemCount: viewingDrivers.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        final driver = viewingDrivers[index];
                                        return _ViewingDriverAvatar(
                                          driver: driver,
                                          isRtl: widget.isRtl,
                                          onTap: () =>
                                              _showDriverDetails(driver),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
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

class _TitleMenuButton extends StatelessWidget {
  const _TitleMenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF2F5FA),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 30,
          child: Icon(Icons.more_horiz_rounded, color: _searchNavy, size: 19),
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

class _DriverGroupHeader extends StatelessWidget {
  const _DriverGroupHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: _searchNavy,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
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
