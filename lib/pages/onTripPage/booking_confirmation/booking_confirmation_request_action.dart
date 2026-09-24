part of '../booking_confirmation.dart';

mixin _BookingConfirmationRequestAction
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationRequestHandler {
  // Visual-only redesign: same handleRideRequest() call and same label
  // logic as before, restyled to the reference's blue -> cyan gradient CTA
  // with a leading circular arrow badge (mirrored for RTL/LTR).
  Widget buildRideRequestButton(Size media, GeoHasher geo) {
    final isArabic = choosenLanguage == 'ar';
    final label = (confirmRideLater == true || isOutStation)
        ? languages[choosenLanguage]['text_schedule']
        : languages[choosenLanguage]['text_book_now'];

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
          child: Row(
            children: [
              if (isArabic) const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isArabic) const Spacer(),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isArabic
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  color: theme,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
