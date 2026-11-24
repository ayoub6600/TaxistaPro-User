// ignore_for_file: invalid_use_of_protected_member
part of '../map_page.dart';

extension _MapPageView on _MapsState {
  Widget buildMapPage(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return PopScope(
      canPop: _bottom != 1 && !_pickupAdjust,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // back from «من أين» returns to the trip editor; back from the editor returns home
        if (_pickupAdjust) {
          cancelPickupAdjust();
        } else if (_bottom == 1) {
          _closeDestinationEditor();
        }
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (_isDarkTheme != isDarkTheme && _controller != null) {
                _controller!.setMapStyle(mapStyle);
                _isDarkTheme = isDarkTheme;
              }
              // app updates: remember a ride in progress; offer the startup's update with no ride
              riderHomeUpdateHook(context,
                  tripInProgress: userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null &&
                      userRequestData['is_completed'] != 1 &&
                      userRequestData['is_cancelled'] != 1,
                  requestOpen: userRequestData.isNotEmpty,
                  chosenLanguage: choosenLanguage);
              if (openScheduledOffersRequested) {
                openScheduledOffersRequested = false;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _openScheduledOffers();
                });
              }
              if (isGeneral == true) {
                isGeneral = false;
                if (lastNotification != latestNotification) {
                  lastNotification = latestNotification;
                  pref.setString('lastNotification', latestNotification);
                  latestNotification = '';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    guardedPush(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationPage()));
                  });
                }
              }

              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  drawer: const NavDrawer(),
                  body: Stack(
                    children: [
                      buildMapMainContent(media),
                      ...buildMapBlockingOverlays(media),
                      buildMapModeSheet(media),
                      ...buildMapSystemOverlays(),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }
}
