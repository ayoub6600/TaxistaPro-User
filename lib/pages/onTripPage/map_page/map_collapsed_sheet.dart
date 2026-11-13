part of '../map_page.dart';

extension _MapCollapsedSheet on _MapsState {
  Widget buildCollapsedHomeSheet(Size media) {
    final rtl = languageDirection == 'rtl';
    final home = quickFavorite('Home');
    final work = quickFavorite('Work');
    final recent = recentSearchesList.isNotEmpty && recentSearchesList.last is Map ? recentSearchesList.last as Map<dynamic, dynamic> : null;
    final addAddressLabel = languages[choosenLanguage]['text_tap_add_address']?.toString() ?? (rtl ? 'أضف عنواناً' : 'Add address');

    // «سفر» shows where the rider's city has intercity routes
    unawaited(IntercityApi.refresh(_centerLocation.latitude, _centerLocation.longitude));
    // «توصيل» opens where the admin opened parcels for the rider's city
    unawaited(ParcelApi.refresh(_centerLocation.latitude, _centerLocation.longitude));
    // «ونش» opens where the admin opened the tow for the rider's city
    unawaited(TowApi.refresh(_centerLocation.latitude, _centerLocation.longitude));
    // «الشحن» opens where the admin opened a freight class for the rider's city
    unawaited(FreightApi.refresh(_centerLocation.latitude, _centerLocation.longitude));

    return ValueListenableBuilder<FreightHome?>(
      valueListenable: FreightApi.notifier,
      builder: (context, freight, _) => ValueListenableBuilder<TowHome?>(
        valueListenable: TowApi.notifier,
        builder: (context, tow, _) => ValueListenableBuilder<ParcelHome?>(
          valueListenable: ParcelApi.notifier,
          builder: (context, parcels, _) => ValueListenableBuilder<IntercityHome?>(
            valueListenable: IntercityApi.notifier,
            builder: (context, intercity, _) => HomeQuickActions(
              rtl: rtl,
              onFreight: freight == null || !freight.enabled
                  ? null
                  : () {
                      final at = currentLocation is LatLng ? currentLocation as LatLng : center;
                      final pickup = addressList.where((e) => e.type == 'pickup');
                      FreightPage.open(context, home: freight, pick: IcPlace(at.latitude, at.longitude, pickup.isNotEmpty ? pickup.first.address : ''));
                    },
              onTow: tow == null || !tow.enabled
                  ? null
                  : () {
                      final at = currentLocation is LatLng ? currentLocation as LatLng : center;
                      final pickup = addressList.where((e) => e.type == 'pickup');
                      TowPage.open(context, home: tow, pick: IcPlace(at.latitude, at.longitude, pickup.isNotEmpty ? pickup.first.address : ''));
                    },
              onDelivery: parcels == null || !parcels.enabled
                  ? null
                  : () {
                      final at = currentLocation is LatLng ? currentLocation as LatLng : center;
                      final pickup = addressList.where((e) => e.type == 'pickup');
                      ParcelPage.open(context, home: parcels, pick: IcPlace(at.latitude, at.longitude, pickup.isNotEmpty ? pickup.first.address : ''));
                    },
              onTravel: intercity == null || !intercity.enabled
                  ? null
                  : () {
                      final at = currentLocation is LatLng ? currentLocation as LatLng : center;
                      final pickup = addressList.where((e) => e.type == 'pickup');
                      IntercityFlow.start(context, home: intercity, pick: IcPlace(at.latitude, at.longitude, pickup.isNotEmpty ? pickup.first.address : ''));
                    },
              onSoon: (what) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('$what قريبًا في تاكسيستا.', textDirection: TextDirection.rtl))),
              giftLat: _centerLocation.latitude,
              giftLng: _centerLocation.longitude,
              showRideWithoutDestination: true,
              destinations: [
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
                  accent: const Color(0xFF2381E9),
                  isConfigured: work != null,
                  onTap: () => runDestinationEntryOnce(() => useQuickFavorite(media, 'Work')),
                ),
                HomeQuickDestination(
                  label: rtl ? 'مؤخراً' : 'Recent',
                  subtitle: recent?['address']?.toString() ?? (rtl ? 'لا توجد وجهة سابقة' : 'No recent destination'),
                  icon: Icons.history_rounded,
                  accent: const Color(0xFF14A47B),
                  isConfigured: recent != null,
                  onTap: () => runDestinationEntryOnce(() async {
                    if (recent == null) {
                      await prepareDestinationEntry(media);
                    } else {
                      await selectRecentDestination(recent);
                    }
                  }),
                ),
              ],
              onRecurring: RecurringApi.rides.value.isEmpty ? null : () => guardedPush(context, MaterialPageRoute(builder: (_) => const RecurringRidesPage())),
              onChooseDestination: () => runDestinationEntryOnce(() => prepareDestinationEntry(media)),
              onRideWithoutDestination: () async {
                final at = currentLocation is LatLng ? currentLocation as LatLng : center;
                if (!await confirmOpenRide(context, at.latitude, at.longitude) || !mounted) return;
                ismulitipleride = false;
                setState(() {
                  rideWithoutDestination = true;
                  rentalRide = false;
                });
                guardedPush(
                  context,
                  MaterialPageRoute(builder: (_) => PickupLocation()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
