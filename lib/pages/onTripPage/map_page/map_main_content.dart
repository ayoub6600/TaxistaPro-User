part of '../map_page.dart';

extension _MapMainContent on _MapsState {
  Widget buildMapMainContent(Size media) {
    return Container(
      color: page,
      height: media.height,
      width: media.width,
      child: Column(
        mainAxisAlignment: state == '1' || state == '2'
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          switch (state) {
            '1' => buildLocationDisabledState(media),
            '2' => buildLocationPermissionState(media),
            '3' => buildMapHomeState(media),
            _ => const SizedBox(),
          },
        ],
      ),
    );
  }
}
