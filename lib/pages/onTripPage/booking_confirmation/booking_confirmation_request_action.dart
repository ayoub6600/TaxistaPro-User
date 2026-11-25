part of '../booking_confirmation.dart';

mixin _BookingConfirmationRequestAction
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationRequestHandler {
  // Same handleRideRequest() call and label logic as before: the blue -> cyan
  // gradient CTA with its words centred (no arrow badge since 2026-11-24).
  Widget buildRideRequestButton(Size media, GeoHasher geo) {
    final isArabic = choosenLanguage == 'ar';
    // design v2: the button says what is asked and for how much («اطلب اقتصادي · 12 LYD», «أرسل عرضك
    // · 15 LYD»); a scheduled / outstation ride keeps its own words
    var label = (confirmRideLater == true || isOutStation)
        ? languages[choosenLanguage]['text_schedule']
        : languages[choosenLanguage]['text_book_now'];
    if (confirmRideLater != true && !isOutStation && choosenVehicle != null && widget.type == null && choosenTransportType == 0) {
      try {
        final service = etaDetails[choosenVehicle];
        final fare = chosenFareForService(choosenVehicle);
        final amount = fare == fare.roundToDouble() ? fare.toStringAsFixed(0) : fare.toStringAsFixed(2);
        // with an old balance the label shows what he will hand the captain; the offer itself stays the fare
        final prior = bookingPriorBalance(choosenVehicle);
        final money = prior?.total ?? '$amount ${moneyShort(service['currency'], arabic: isArabic)}'.trim();
        if (fare > 0) {
          label = canAdjustSelectedFare(choosenVehicle)
              ? (isArabic ? 'أرسل عرضك · $money' : 'Send your offer · $money')
              : (isArabic ? 'اطلب ${service['name'] ?? ''} · $money' : 'Request ${service['name'] ?? ''} · $money');
        }
      } catch (_) {}
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => handleRideRequest(media, geo),
        child: Container(
          width: media.width * 0.9,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [theme, themeCyan],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // owner 2026-11-24: no arrow badge, the words alone in the middle
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
