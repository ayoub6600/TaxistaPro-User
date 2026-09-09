part of '../booking_confirmation.dart';

mixin _BookingConfirmationMarkerSnapshots
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildPickupMarkerSnapshot(Size media) {
    return Positioned(
      top: media.height * 1.6,
      child: RepaintBoundary(
        key: iconKey,
        child: Column(
          children: [
            _buildAddressLabel(
              media,
              text: userRequestData.isNotEmpty
                  ? userRequestData['pick_address']
                  : addressList
                          .where((element) => element.type == 'pickup')
                          .isNotEmpty
                      ? addressList
                          .firstWhere((element) => element.type == 'pickup')
                          .address
                      : '',
              widthFactor: platform == TargetPlatform.android ? 0.4 : 0.5,
            ),
            const SizedBox(height: 10),
            _buildMarkerIcon(media, pickup: true),
          ],
        ),
      ),
    );
  }

  Widget buildDropMarkerSnapshots(Size media) {
    if (widget.type == 1) return Container();

    return Positioned(
      top: media.height * 2,
      child: Column(
        children: addressList.asMap().entries.map((entry) {
          final i = entry.key;
          iconDropKeys[i] = GlobalKey();

          if (i == 0) return Container();

          return RepaintBoundary(
            key: iconDropKeys[i],
            child: Column(
              children: [
                if (i == addressList.length - 1) ...[
                  _buildAddressLabel(
                    media,
                    text: addressList[i].address,
                    widthFactor: platform == TargetPlatform.android ? 0.5 : 0.7,
                  ),
                  const SizedBox(height: 10),
                  _buildMarkerIcon(media, pickup: false),
                ] else
                  Text(
                    i.toString(),
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * sixteen,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildDistanceMarkerSnapshot(Size media) {
    if (widget.type == 1) return Container();

    return Positioned(
      top: media.height * 2,
      child: RepaintBoundary(
        key: iconDistanceKey,
        child: Stack(
          children: [
            Icon(
              Icons.chat_bubble,
              size: media.width * 0.2,
              color: page,
              shadows: [
                BoxShadow(
                  spreadRadius: 2,
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.2),
                )
              ],
            ),
            if (etaDetails.isNotEmpty && etaDetails[0]['distance'] != null)
              Positioned(
                left: media.width * 0.03,
                top: media.width * 0.03,
                child: Container(
                  width: media.width * 0.14,
                  height: media.width * 0.1,
                  alignment: Alignment.center,
                  child: Text(
                    '${etaDetails[0]['distance']} ${etaDetails[0]['unit_in_words']} ',
                    style: GoogleFonts.notoSans(
                      fontSize: media.width * twelve,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildAddressLabel(
    Size media, {
    required String text,
    required double widthFactor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDarkTheme == true ? const Color(0xff000000) : Colors.white,
            isDarkTheme == true
                ? const Color(0xff808080)
                : const Color(0xffEFEFEF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      width: media.width * widthFactor,
      padding: const EdgeInsets.all(5),
      child: text.isEmpty
          ? Container()
          : Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: GoogleFonts.notoSans(
                color: textColor,
                fontSize: platform == TargetPlatform.android
                    ? media.width * twelve
                    : media.width * sixteen,
              ),
            ),
    );
  }

  Widget _buildMarkerIcon(Size media, {required bool pickup}) {
    final markerSize = platform == TargetPlatform.android
        ? media.width * 0.085
        : media.width * 0.105;
    final color = pickup ? const Color(0xFF16A36A) : const Color(0xFF1677FF);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      height: markerSize,
      width: markerSize,
      alignment: Alignment.center,
      child: Icon(
        pickup ? Icons.my_location_rounded : Icons.flag_rounded,
        color: Colors.white,
        size: markerSize * .52,
      ),
    );
  }
}
