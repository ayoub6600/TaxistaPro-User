part of '../map_page.dart';

extension _MapHomeBottomSheet on _MapsState {
  Widget buildMapHomeBottomSheet(Size media) {
    if (_bottom == 1) {
      return Positioned.fill(child: buildExpandedHomeSheet(media));
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: buildCollapsedHomeSheet(media),
    );
  }
}
