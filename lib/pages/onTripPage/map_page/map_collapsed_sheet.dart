part of '../map_page.dart';

extension _MapCollapsedSheet on _MapsState {
  Widget buildCollapsedHomeSheet(Size media) {
    final rtl = languageDirection == 'rtl';
    final home = quickFavorite('Home');
    final work = quickFavorite('Work');
    final recent =
        recentSearchesList.isNotEmpty && recentSearchesList.last is Map
            ? recentSearchesList.last as Map<dynamic, dynamic>
            : null;
    final addAddressLabel =
        languages[choosenLanguage]['text_tap_add_address']?.toString() ??
            (rtl ? 'أضف عنواناً' : 'Add address');

    return HomeQuickActions(
      rtl: rtl,
      showRideWithoutDestination: true,
      destinations: [
        HomeQuickDestination(
          label: languages[choosenLanguage]['text_home']?.toString() ??
              (rtl ? 'المنزل' : 'Home'),
          subtitle: home?['pick_address']?.toString() ?? addAddressLabel,
          icon: Icons.home_rounded,
          accent: theme,
          isConfigured: home != null,
          onTap: () => useQuickFavorite(media, 'Home'),
        ),
        HomeQuickDestination(
          label: languages[choosenLanguage]['text_work']?.toString() ??
              (rtl ? 'العمل' : 'Work'),
          subtitle: work?['pick_address']?.toString() ?? addAddressLabel,
          icon: Icons.work_rounded,
          accent: const Color(0xFF2381E9),
          isConfigured: work != null,
          onTap: () => useQuickFavorite(media, 'Work'),
        ),
        HomeQuickDestination(
          label: rtl ? 'مؤخراً' : 'Recent',
          subtitle: recent?['address']?.toString() ??
              (rtl ? 'لا توجد وجهة سابقة' : 'No recent destination'),
          icon: Icons.history_rounded,
          accent: const Color(0xFF14A47B),
          isConfigured: recent != null,
          onTap: () {
            if (recent == null) {
              prepareDestinationEntry(media);
            } else {
              selectRecentDestination(recent);
            }
          },
        ),
      ],
      onChooseDestination: () async {
        await prepareDestinationEntry(media);
      },
      onRideWithoutDestination: () {
        ismulitipleride = false;
        setState(() {
          rideWithoutDestination = true;
          rentalRide = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PickupLocation()),
        );
      },
    );
  }
}
