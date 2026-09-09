part of '../booking_confirmation.dart';

mixin _BookingConfirmationRequestAction
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationRequestHandler {
  Widget buildRideRequestButton(Size media, GeoHasher geo) {
    return Button(
        borcolor: Colors.black,
        onTap: () => handleRideRequest(media, geo),
        text: (confirmRideLater == true || isOutStation)
            ? languages[choosenLanguage]['text_schedule']
            : languages[choosenLanguage]['text_book_now']);
  }
}
