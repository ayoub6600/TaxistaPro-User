// ignore_for_file: invalid_use_of_protected_member
part of '../map_page.dart';

extension _MapCollapsedSheet on _MapsState {
  /// The home pickup: the phone's own place. The map's centre never is (owner 2026-11-24).
  LatLng get _homePickupPoint => currentLocation is LatLng ? currentLocation as LatLng : center;

  /// where a service page starts from: the phone's place and its address when it is known
  IcPlace _servicePickup() {
    final at = _homePickupPoint;
    final pickup = addressList.where((e) => e.type == 'pickup');
    return IcPlace(at.latitude, at.longitude, pickup.isNotEmpty ? pickup.first.address : '');
  }

  Widget buildCollapsedHomeSheet(Size media) {
    final rtl = languageDirection == 'rtl';
    final at = _homePickupPoint;

    // each service opens where the admin opened it for the rider's city (asked again after 3 minutes
    // or about 2 km; panning the map does not ask)
    unawaited(IntercityApi.refresh(at.latitude, at.longitude));
    unawaited(ParcelApi.refresh(at.latitude, at.longitude));
    unawaited(TowApi.refresh(at.latitude, at.longitude));
    unawaited(FreightApi.refresh(at.latitude, at.longitude));

    return ValueListenableBuilder<FreightHome?>(
      valueListenable: FreightApi.notifier,
      builder: (context, freight, _) => ValueListenableBuilder<TowHome?>(
        valueListenable: TowApi.notifier,
        builder: (context, tow, _) => ValueListenableBuilder<ParcelHome?>(
          valueListenable: ParcelApi.notifier,
          builder: (context, parcels, _) => ValueListenableBuilder<IntercityHome?>(
            valueListenable: IntercityApi.notifier,
            builder: (context, intercity, _) => RiderHomeSheet(
              rtl: rtl,
              expanded: _homeSheetExpanded,
              services: HomeServices.build(
                rtl: rtl,
                freight: freight,
                parcels: parcels,
                tow: tow,
                onFreight: freight == null || !freight.enabled ? null : () => FreightPage.open(context, home: freight, pick: _servicePickup()),
                onTow: tow == null || !tow.enabled ? null : () => TowPage.open(context, home: tow, pick: _servicePickup()),
                onDelivery: parcels == null || !parcels.enabled ? null : () => ParcelPage.open(context, home: parcels, pick: _servicePickup()),
                onTravel: intercity == null || !intercity.enabled ? null : () => IntercityFlow.start(context, home: intercity, pick: _servicePickup()),
                onSoon: (what) => ScaffoldMessenger.maybeOf(context)
                    ?.showSnackBar(SnackBar(content: Text('$what قريبًا في تاكسيستا.', textDirection: TextDirection.rtl))),
                onRideWithoutDestination: _openRideWithoutDestination,
              ),
              more: _homeMore(rtl),
              onWhereTo: () => runDestinationEntryOnce(() => prepareDestinationEntry(media)),
              onPlaces: () => showHomePlacesSheet(context, rtl: rtl, places: _homePlaces(media)),
              above: (context, expanded) => _homeSheetAbove(media, expanded),
            ),
          ),
        ),
      ),
    );
  }

  /// «خدمات أخرى»: other pages the app already has (the same ones the menu opens), never the services
  /// of the row again. Each one only where it exists for this rider (the wallet as in the menu).
  List<HomeService> _homeMore(bool rtl) {
    void open(Widget page) => guardedPush(context, MaterialPageRoute(builder: (_) => page));
    final wallet = userDetails['owner_id'] == null && userDetails['show_wallet_feature_on_mobile_app'].toString() == '1';
    return [
      HomeService(
        id: 'scheduled',
        label: rtl ? 'رحلاتي المجدولة' : 'Scheduled rides',
        icon: Icons.event_available_rounded,
        color: HomeServices.indigo,
        onTap: () => open(const UpcomingScheduledRidesPage()),
      ),
      HomeService(
        id: 'recurring',
        label: rtl ? 'مشاويري الثابتة' : 'Recurring rides',
        icon: Icons.repeat_rounded,
        color: HomeServices.violet,
        onTap: () => open(const RecurringRidesPage()),
      ),
      if (wallet)
        HomeService(
          id: 'wallet',
          label: rtl ? 'المحفظة وشحن الرصيد' : 'Wallet & top-up',
          icon: Icons.account_balance_wallet_rounded,
          color: HomeServices.sky,
          onTap: () => open(const WalletPage()),
        ),
      HomeService(
        id: 'gifts',
        label: rtl ? 'الهدايا والعروض' : 'Gifts & offers',
        icon: Icons.card_giftcard_rounded,
        color: HomeServices.pink,
        onTap: () => open(const MyGiftsPage()),
      ),
      HomeService(
        id: 'rewards',
        label: rtl ? 'مكافآتي' : 'My rewards',
        icon: Icons.emoji_events_rounded,
        color: HomeServices.amber,
        onTap: () => open(const RewardsPage()),
      ),
      HomeService(
        id: 'invite',
        label: rtl ? 'ادعُ صديقًا' : 'Invite a friend',
        icon: Icons.group_add_rounded,
        color: HomeServices.green,
        onTap: () => open(const ReferralPage()),
      ),
      HomeService(
        id: 'posts',
        label: rtl ? 'منشورات تاكسيستا' : 'Taxista posts',
        icon: Icons.campaign_rounded,
        color: HomeServices.orange,
        onTap: () => open(const PostsFeedPage()),
      ),
      HomeService(
        id: 'support',
        label: rtl ? 'الدعم والمحادثة' : 'Support chat',
        icon: Icons.support_agent_rounded,
        color: HomeServices.slate,
        onTap: () => open(const SupportPage()),
      ),
    ];
  }

  /// «بدون وجهة»: the open ride, no destination asked
  Future<void> _openRideWithoutDestination() async {
    final at = _homePickupPoint;
    if (!await confirmOpenRide(context, at.latitude, at.longitude) || !mounted) return;
    ismulitipleride = false;
    setState(() {
      rideWithoutDestination = true;
      rentalRide = false;
    });
    guardedPush(context, MaterialPageRoute(builder: (_) => PickupLocation()));
  }

  /// «أماكني»: home, work and the recent destinations (the same actions as the old home cards)
  List<HomeQuickDestination> _homePlaces(Size media) {
    final rtl = languageDirection == 'rtl';
    final home = quickFavorite('Home');
    final work = quickFavorite('Work');
    final addAddressLabel = languages[choosenLanguage]['text_tap_add_address']?.toString() ?? (rtl ? 'أضف عنواناً' : 'Add address');
    final recents = <Map<dynamic, dynamic>>[];
    final seen = <String>{};
    for (final r in recentSearchesList.reversed) {
      final address = r is Map ? r['address']?.toString().trim() ?? '' : '';
      if (address.isEmpty || !seen.add(address.toLowerCase())) continue;
      recents.add(r as Map<dynamic, dynamic>);
      if (recents.length == 4) break;
    }
    return [
      HomeQuickDestination(
        label: languages[choosenLanguage]['text_home']?.toString() ?? (rtl ? 'المنزل' : 'Home'),
        subtitle: home?['pick_address']?.toString() ?? addAddressLabel,
        icon: Icons.home_rounded,
        accent: theme,
        isConfigured: home != null,
        onTap: () => runDestinationEntryOnce(() => useQuickFavorite(media, 'Home')),
      ),
      HomeQuickDestination(
        label: languages[choosenLanguage]['text_work']?.toString() ?? (rtl ? 'العمل' : 'Work'),
        subtitle: work?['pick_address']?.toString() ?? addAddressLabel,
        icon: Icons.work_rounded,
        accent: const Color(0xFF6E55C8),
        isConfigured: work != null,
        onTap: () => runDestinationEntryOnce(() => useQuickFavorite(media, 'Work')),
      ),
      for (final recent in recents)
        HomeQuickDestination(
          label: recent['address'].toString().split(',').first.trim(),
          subtitle: recent['address'].toString().split(',').skip(1).join(',').trim(),
          icon: Icons.history_rounded,
          accent: const Color(0xFF14A47B),
          onTap: () => runDestinationEntryOnce(() => selectRecentDestination(recent)),
        ),
    ];
  }

  /// What floats over the map just above the home sheet. Pulled up, only the gift stays, as an icon.
  /// The pieces stay in the tree while hidden, so nothing reloads when the sheet moves.
  Widget _homeSheetAbove(Size media, bool expanded) {
    final at = _homePickupPoint;
    Widget hide(Widget child) => Visibility(visible: !expanded, maintainState: true, child: child);
    final bookings = _homeBookingsCard(media);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      hide(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(alignment: AlignmentDirectional.centerEnd, child: MapRecenterButton(onTap: recenterMap)),
      )),
      if (bookings != null) hide(bookings),
      // «12 كابتن متصل في مصراتة توا» / the honest line (real captains only; nothing while the city has it off)
      hide(const HomeCaptainsChip()),
      hide(const HomeNoCaptainsLine()),
      // a Taxista gift with its countdown (nothing when the rider has none)
      hide(const GiftBanner()),
      DailyGiftBar(key: const ValueKey('daily-gift'), lat: at.latitude, lng: at.longitude, iconOnly: expanded),
    ]);
  }

  /// A booking belongs to the rider, not to the current map camera (it stays while the map moves).
  Widget? _homeBookingsCard(Size media) {
    if (activeRiderBookings.isEmpty && userDetails['has_ongoing_ride'] != true) return null;
    final rtl = languageDirection == 'rtl';
    final allLater = activeRiderBookings.isNotEmpty &&
        activeRiderBookings.every((item) => item is Map && (item['is_later'] == true || item['is_later'] == 1));
    final first = activeRiderBookings.isNotEmpty && activeRiderBookings.first is Map ? activeRiderBookings.first as Map : null;
    final oneLater = activeRiderBookings.length == 1 && first != null && (first['is_later'] == true || first['is_later'] == 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await guardedPush(
              context,
              MaterialPageRoute(
                  builder: (context) => activeRiderBookings.isNotEmpty ? const ActiveRiderBookingsPage() : const OnGoingRides()));
          await getActiveRiderBookings();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff102A56), Color(0xff1965BF)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  allLater ? (rtl ? 'رحلتك المجدولة' : 'Your scheduled ride') : (rtl ? 'حجوزاتك القائمة' : 'Your bookings'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  oneLater
                      ? '${_bookingWhen(first)} · ${first['driver_id'] == null ? (rtl ? 'متاحة للسائقين' : 'Available to drivers') : (rtl ? 'أكدها السائق' : 'Driver confirmed')}'
                      : (rtl
                          ? '${activeRiderBookings.length} حجوزات · عرض التفاصيل'
                          : '${activeRiderBookings.length} bookings · View details'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xffDCEBFF), fontSize: 12),
                ),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 17),
          ]),
        ),
      ),
    );
  }
}
