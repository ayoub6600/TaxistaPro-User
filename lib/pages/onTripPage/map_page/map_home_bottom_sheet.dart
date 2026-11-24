part of '../map_page.dart';

extension _MapHomeBottomSheet on _MapsState {
  Widget buildMapHomeBottomSheet(Size media) {
    // «من أين»: the map moves the pickup; the trip editor waits behind
    if (_pickupAdjust) return Positioned.fill(child: buildPickupAdjustPanel(media));
    if (_bottom == 1) {
      return Positioned.fill(child: buildExpandedHomeSheet(media));
    }

    return Positioned.fill(child: buildCollapsedHomeSheet(media));
  }
}
