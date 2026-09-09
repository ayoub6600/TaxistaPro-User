part of '../map_page.dart';

extension _MapHomeState on _MapsState {
  Widget buildMapHomeState(Size media) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          buildLiveMapCanvas(media),
          ...buildMapHomeOverlays(media),
          buildMapHomeBottomSheet(media),
          buildPickupConfirmationOverlay(media),
        ],
      ),
    );
  }
}
