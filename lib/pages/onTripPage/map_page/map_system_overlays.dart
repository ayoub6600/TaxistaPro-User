part of '../map_page.dart';

extension _MapSystemOverlays on _MapsState {
  List<Widget> buildMapSystemOverlays() {
    return <Widget>[
      (_loading == true || state == '')
          ? const Positioned(top: 0, child: Loading())
          : const SizedBox(),
      (internet == false)
          ? Positioned(
              top: 0,
              child: NoInternet(
                onTap: () {
                  setState(() {
                    internetTrue();
                    getUserDetails();
                  });
                },
              ))
          : const SizedBox(),
      if (_showLaunchOverlay)
        Positioned.fill(
          child: TaxiLaunchOverlay(
            mapReady: _mapReadyForLaunch,
            onRevealStarted: _startColdLaunchCamera,
            onFinished: () {
              if (mounted) {
                setState(() => _showLaunchOverlay = false);
              }
            },
          ),
        ),
    ];
  }
}
