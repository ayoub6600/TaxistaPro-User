// ignore_for_file: invalid_use_of_protected_member
part of '../map_page.dart';

extension _MapHomeOverlays on _MapsState {
  /// every home card keeps 10 px around it: the gap between cards, and the room for a × on a corner
  Widget _homeCardGap(Widget card) => Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 0), child: card);

  /// a small × on the card's top-left corner (inside the card's room, so all of it can be tapped)
  Widget _closable(Widget card, VoidCallback onClose) => Stack(children: [
        _homeCardGap(card),
        Positioned(
          top: 0,
          left: 0,
          child: Semantics(
            button: true,
            label: languageDirection == 'rtl' ? 'إغلاق' : 'Close',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xffDCE3EE)),
                      boxShadow: const [BoxShadow(color: Color(0x2610213F), blurRadius: 4, offset: Offset(0, 1))],
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xff55678A)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);

  List<Widget> buildMapHomeOverlays(Size media) {
    return <Widget>[
      buildRecoveryOfferCard(media),
      // one column: a new card moves the others down and never covers them. They step aside while
      // the home sheet is pulled up over the map.
      if (scheduledOfferSummary.hasOffers ||
          (_bottom == 0 &&
              (RecurringApi.pendingTomorrow(RecurringApi.rides.value) != null ||
                  ContestsApi.homePost.value != null ||
                  PostsApi.homePost.value != null ||
                  AmbassadorsApi.homeCard.value != null ||
                  activePromotionCampaigns.isNotEmpty)))
        Positioned(
          top: MediaQuery.of(context).padding.top + 72,
          left: 6,
          right: 6,
          child: ValueListenableBuilder<bool>(
            valueListenable: _homeSheetExpanded,
            builder: (context, up, child) => IgnorePointer(
              ignoring: up && _bottom == 0,
              child: AnimatedOpacity(opacity: up && _bottom == 0 ? 0 : 1, duration: const Duration(milliseconds: 180), child: child),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.height * 0.4),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (scheduledOfferSummary.hasOffers)
                    _homeCardGap(ScheduledOfferBanner(
                      summary: scheduledOfferSummary,
                      rtl: languageDirection == 'rtl',
                      onTap: _openScheduledOffers,
                    )),
                  if (_bottom == 0) ...[
                    // tomorrow's recurring day comes first (it has a deadline), then the contest, then the campaigns
                    if (RecurringApi.pendingTomorrow(RecurringApi.rides.value) != null)
                      _homeCardGap(RecurringTomorrowBanner(
                        ride: RecurringApi.pendingTomorrow(RecurringApi.rides.value)!['ride'] as Map<String, dynamic>,
                        next: RecurringApi.pendingTomorrow(RecurringApi.rides.value)!['next'] as Map<String, dynamic>,
                      )),
                    // the × closes this announcement only; «شوف» opens the post
                    if (PostsApi.homePost.value != null)
                      _closable(PostHomeCard(post: PostsApi.homePost.value!), PostsApi.dismissHome),
                    if (ContestsApi.homePost.value != null)
                      _closable(ContestHomeCard(post: ContestsApi.homePost.value!), () => unawaited(ContestsApi.dismissHome())),
                    // «سفراء تاكسيستا»: «شوف» opens the page, its own × hides it here for 7 days
                    if (AmbassadorsApi.homeCard.value != null) _homeCardGap(AmbassadorHomeCard(card: AmbassadorsApi.homeCard.value!)),
                    if (activePromotionCampaigns.isNotEmpty)
                      _homeCardGap(_PromotionStrip(campaigns: activePromotionCampaigns, rtl: languageDirection == 'rtl')),
                  ],
                ]),
              ),
            ),
          ),
        ),
      // «من أين»: the mascot waits in the middle and the map moves the pickup under it. Elsewhere it
      // stands on the pickup as a map marker (see map_pickup_adjust.dart).
      if (_pickupAdjust)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: media.height,
          child: IgnorePointer(
            child: Column(children: [
              SizedBox(height: (media.height / 2) - riderMascotHeight - riderMascotBubbleAllowance),
              RiderMascotBubble(
                text: _isPickingLocation ? (languageDirection == 'rtl' ? 'يحدد نقطة اللقاء' : 'Choosing the meeting point') : _riderFirstName(),
              ),
              const SizedBox(height: 4),
              Image.asset(
                riderMascotAsset,
                width: riderMascotWidth,
                height: riderMascotHeight,
                cacheWidth: (riderMascotWidth * MediaQuery.of(context).devicePixelRatio).round(),
                fit: BoxFit.contain,
              ),
            ]),
          ),
        ),
      (contactus == true)
          ? Positioned(
              right: 10,
              top: 120 + media.width * 0.1,
              child: InkWell(
                onTap: () async {},
                child: Container(
                    padding: const EdgeInsets.all(10),
                    height: media.width * 0.3,
                    width: media.width * 0.45,
                    decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.2),
                              spreadRadius: 2)
                        ],
                        color: page,
                        borderRadius:
                            BorderRadius.circular(media.width * 0.02)),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            makingPhoneCall(userDetails['contact_us_mobile1']);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(
                                    Icons.call,
                                    color: textColor,
                                  )),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    userDetails['contact_us_mobile1'],
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            makingPhoneCall(userDetails['contact_us_mobile1']);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(Icons.call, color: textColor)),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    userDetails['contact_us_mobile2'],
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            openBrowser(
                                userDetails['contact_us_link'].toString());
                          },
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 20,
                                  child: Icon(Icons.vpn_lock_rounded,
                                      color: textColor)),
                              Expanded(
                                  flex: 80,
                                  child: Text(
                                    languages[choosenLanguage]['text_goto_url'],
                                    maxLines: 1,
                                    style: GoogleFonts.notoSans(
                                        fontSize: media.width * fourteen,
                                        color: textColor),
                                  ))
                            ],
                          ),
                        )
                      ],
                    )),
              ),
            )
          : const SizedBox(),
      (_bottom == 0)
          ? Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 18,
              right: 18,
              child: SizedBox(
                width: media.width - 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) => MapFloatingMenuButton(
                        onTap: Scaffold.of(context).openDrawer,
                      ),
                    ),
                    if (banners.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: const MapAdvertisementBanner(compact: true),
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const SizedBox(width: 12),
                    // the notifications, one tap from home (they were only in the menu)
                    MapFloatingMenuButton(
                      icon: Icons.notifications_none_rounded,
                      label: languageDirection == 'rtl' ? 'الإشعارات' : 'Notifications',
                      badge: int.tryParse('${userDetails['notifications_count'] ?? 0}') ?? 0,
                      onTap: () {
                        guardedPush(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
                        setState(() => userDetails['notifications_count'] = 0);
                      },
                    ),
                  ],
                ),
              ))
          : const SizedBox(),
    ];
  }
}

/// the campaigns above the map, compact: one card, swipe to the next; small dots when there are more
class _PromotionStrip extends StatefulWidget {
  const _PromotionStrip({required this.campaigns, required this.rtl});
  final List<Map<String, dynamic>> campaigns;
  final bool rtl;

  @override
  State<_PromotionStrip> createState() => _PromotionStripState();
}

class _PromotionStripState extends State<_PromotionStrip> {
  int _page = 0;
  // each card takes ~78% of the width, so the next campaign («الرحلة الخامسة») peeks beside it
  final _pager = PageController(viewportFraction: .78);

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.campaigns;
    if (list.length == 1) return _RiderPromotionHomeCard(campaign: list.first, rtl: widget.rtl);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: 52,
        child: PageView.builder(
          controller: _pager,
          padEnds: false,
          itemCount: list.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _RiderPromotionHomeCard(campaign: list[i], rtl: widget.rtl, compact: true),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < list.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == _page ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _page ? const Color(0xff0873FF) : Colors.white.withValues(alpha: .85),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
          ),
      ]),
    ]);
  }
}

class _RiderPromotionHomeCard extends StatelessWidget {
  const _RiderPromotionHomeCard({required this.campaign, required this.rtl, this.compact = false});

  final Map<String, dynamic> campaign;
  final bool rtl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isSignup = campaign['type'] == 'signup_bonus';
    final reward =
        (campaign['reward_amount'] as num?)?.toStringAsFixed(0) ?? '0';
    final currency = rtl ? 'دينار' : 'LYD';
    final rides = (campaign['completed_rides'] as num?)?.toInt() ?? 0;
    final target = (campaign['required_rides'] as num?)?.toInt() ?? 0;
    final credited = campaign['signup_bonus_credited'] == true;
    final title = isSignup
        ? (credited
            ? (rtl
                ? 'أضفنا $reward $currency إلى محفظتك'
                : '$reward LYD added to your wallet')
            : (rtl
                ? 'عرض ترحيبي بقيمة $reward $currency'
                : 'Welcome offer: $reward LYD'))
        : ('${campaign['name'] ?? ''}'.trim().isNotEmpty
            ? '${campaign['name']}'
            : (rtl ? 'مكافأة الرحلات: $reward $currency' : 'Ride reward: $reward $currency'));
    final subtitle = isSignup
        ? (credited
            ? (rtl
                ? 'سيُخصم تلقائيًا من أول رحلة'
                : 'Applied automatically to your first ride')
            : (rtl
                ? 'عرض خاص للحسابات الجديدة'
                : 'A special offer for new accounts'))
        : (rtl
            ? 'أكملت $rides من $target${target > rides ? ' · باقي ${target - rides}' : ''} · المكافأة $reward $currency'
            : '$rides of $target rides completed');

    final ring = !isSignup && target > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        // the campaign opens «مكافآتي» (its rules, its progress)
        onTap: () => guardedPush(context, MaterialPageRoute(builder: (_) => const RewardsPage())),
        child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
          ],
          border: Border.all(color: const Color(0xffDCEBFF)),
        ),
        child: Row(
          children: [
            if (ring)
              RideProgressRing(done: rides, target: target, size: compact ? 34 : 40)
            else
              CircleAvatar(
                radius: compact ? 16 : 19,
                backgroundColor: const Color(0xffE8F5EE),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: Color(0xff159668), size: 19),
              ),
            SizedBox(width: compact ? 8 : 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff10264A),
                          fontSize: compact ? 12 : 13)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: const Color(0xff687994), fontSize: compact ? 10 : 11)),
                ],
              ),
            ),
            if (!compact) const SizedBox(width: 8),
            if (!compact) Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: const Color(0xff1677F8)),
          ],
        ),
      ),
      ),
    );
  }
}

/// «63» inside a ring that fills toward the campaign's target (the number is the server's count)
class RideProgressRing extends StatelessWidget {
  const RideProgressRing({super.key, required this.done, required this.target, this.size = 46});

  final int done;
  final int target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox.square(
        dimension: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: 4.5,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xffE7EFFA),
              color: const Color(0xff0873FF),
            ),
          ),
          Text('$done',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xff10264A))),
        ]),
      ),
    );
  }
}

/// «غدًا 7:15 ص» from the booking's raw time; the server's own text when it has none
String _bookingWhen(Map item) {
  final t = parseTripStart(item);
  if (t == null) return '${item['trip_start_time'] ?? ''}';
  return scheduleRelativeLabel(t, isRtl: languageDirection == 'rtl');
}
