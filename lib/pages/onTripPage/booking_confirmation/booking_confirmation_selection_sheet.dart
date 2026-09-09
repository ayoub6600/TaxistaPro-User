part of '../booking_confirmation.dart';

mixin _BookingConfirmationSelectionSheet
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationVehicleServices,
        _BookingConfirmationRentalOptions,
        _BookingConfirmationRequestAction,
        _BookingConfirmationVehicleOptions,
        _BookingConfirmationBookingControls {
  Widget buildRideSelectionSheet(
    Size media,
    Query fdb,
    GeoHasher geo,
  ) {
    return (isLoading == false &&
            addressList.isNotEmpty &&
            etaDetails.isNotEmpty &&
            userRequestData.isEmpty &&
            noDriverFound == false &&
            tripReqError == false &&
            dropConfirmed == true &&
            lowWalletBalance == false)
        ? (_chooseGoodsType == true || choosenTransportType == 0)
            ? Positioned(
                bottom: 0 + MediaQuery.of(context).viewInsets.bottom,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.only(
                      top: media.width * 0.02, bottom: media.width * 0.0),
                  width: media.width * 1,
                  height: bookingSheetHeight(media),
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25)),
                      color: page),
                  child: (isRentalRide == true && etaDetails.isNotEmpty)
                      ? buildRentalPackageSelector(media)
                      : (isRentalRide == false && etaDetails.isNotEmpty)
                          ? Column(
                              children: [
                                ...buildVehicleOptions(media, fdb),
                                buildBookingControls(media, geo),
                              ],
                            )
                          : Container(),
                ))
            : Container()
        : Container();
  }
}
