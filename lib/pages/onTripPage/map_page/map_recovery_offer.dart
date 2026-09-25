part of '../map_page.dart';

/// Home-level visibility for a missed-ride recovery offer (see
/// findPresentedOfferForRider() on the backend): a driver went "ready" on a
/// ride the rider had already cancelled with a flagged reason. Unlike the
/// still-searching dialog in booking_confirmation_controller.dart (which
/// only fires while the rider is still on that page), this must surface on
/// the Home screen since the rider has already left that page by the time
/// this can happen - polling here, not push delivery alone, is the source
/// of truth.
extension _MapRecoveryOffer on _MapsState {
  /// The Home recovery card's countdown and refresh. There is exactly one
  /// ticker per page (starting it again replaces it), it counts the visible
  /// offer down locally, and it only talks to the backend when recovery is
  /// enabled - at most every 20 seconds, and never more than the poll gate
  /// allows (an expired offer is re-checked once, not once a second).
  void startRecoveryOfferTicker() {
    _recoveryOfferTicker?.cancel();
    _recoveryOfferTickCount = 0;
    _recoveryOfferTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;

      final offer = pendingRecoveryOfferForRider;
      if (offer != null) {
        final remaining = (offer['expires_in_seconds'] is num)
            ? (offer['expires_in_seconds'] as num).toInt()
            : 0;
        if (remaining <= 0) {
          // Never trust the client clock alone for expiry - re-check with
          // the backend (gated: one request, not one per tick).
          unawaited(fetchPendingRecoveryOfferForRider().then((_) {
            if (mounted) setState(() {});
          }));
        } else {
          offer['expires_in_seconds'] = remaining - 1;
          if (mounted) setState(() {});
        }
      }

      _recoveryOfferTickCount++;
      if (_recoveryOfferTickCount % 20 == 0) {
        final beforeId = pendingRecoveryOfferForRider?['offer_id'];
        await fetchPendingRecoveryOfferForRider();
        if (mounted && pendingRecoveryOfferForRider?['offer_id'] != beforeId) {
          setState(() {});
        }
      }
    });
  }

  Future<void> confirmRecoveryOfferFromHome() async {
    final offer = pendingRecoveryOfferForRider;
    if (offer == null) return;
    final offerId = offer['offer_id'] is int
        ? offer['offer_id'] as int
        : int.tryParse(offer['offer_id'].toString()) ?? 0;
    final requestId = offer['request_id']?.toString();

    final result = await confirmRecoveryDriver(offerId);
    if (!mounted) return;

    if (result == 'success') {
      if (requestId != null && requestId.isNotEmpty) {
        await refreshUserRequestState(requestId);
      }
      if (!mounted) return;
      // Same convention as opening an accepted ride from "حجوزاتك القائمة"
      // (active_rider_bookings.dart) - a fresh BookingConfirmation's own
      // initState() clears userRequestData whenever ismulitipleride is
      // false and accepted_at is already set, on the assumption that's
      // stale leftover data from a previous session rather than the ride
      // this exact push is meant to resume. refreshUserRequestState()
      // above resets ismulitipleride to false itself once it completes,
      // so it must be set back to true here, after the fetch and before
      // the push, or the accepted-ride UI it just fetched gets wiped the
      // instant the page mounts and the rider is left looking at the
      // booking/search screen instead.
      ismulitipleride = true;
      final type = userRequestData['is_rental'] == true
          ? 1
          : userRequestData['drop_address'] == null
              ? 2
              : null;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => BookingConfirmation(type: type)),
        (_) => false,
      );
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> declineRecoveryOfferFromHome() async {
    final offer = pendingRecoveryOfferForRider;
    if (offer == null) return;
    final offerId = offer['offer_id'] is int
        ? offer['offer_id'] as int
        : int.tryParse(offer['offer_id'].toString()) ?? 0;

    await rejectRecoveryDriver(offerId);
    if (mounted) setState(() {});
  }

  String _recoveryCountdownText(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget buildRecoveryOfferCard(Size media) {
    final offer = pendingRecoveryOfferForRider;
    if (offer == null || _bottom != 0) return const SizedBox();

    final rtl = languageDirection == 'rtl';
    final fare = offer['fare'];
    final currency = offer['currency_symbol']?.toString() ?? '';
    final remaining = (offer['expires_in_seconds'] is num)
        ? (offer['expires_in_seconds'] as num).toInt()
        : 0;

    return Positioned(
      left: 12,
      right: 12,
      bottom: media.width * 1.12,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff1965BF).withOpacity(0.25)),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff1965BF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_taxi_rounded, color: Color(0xff1965BF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languages[choosenLanguage]['text_recovery_card_title'] ??
                            (rtl ? 'سائق متاح الآن' : 'A driver is available now'),
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        languages[choosenLanguage]['text_recovery_card_body'] ??
                            (rtl
                                ? 'وجدنا سائقًا متاحًا لرحلتك السابقة. هل ما زلت تحتاج الرحلة؟'
                                : 'We found an available driver for your previous ride. Do you still need it?'),
                        style: GoogleFonts.cairo(fontSize: 12.5, color: hintColor),
                      ),
                    ],
                  ),
                ),
                if (remaining > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xff00BCD4).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _recoveryCountdownText(remaining),
                      style: const TextStyle(
                        color: Color(0xff00838F),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.035),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (offer['pickup_address'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(fontSize: 12.5, color: textColor),
                        ),
                      ),
                    ],
                  ),
                  if ((offer['destination_address'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.square_rounded, size: 9, color: Color(0xffEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (offer['destination_address'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 12.5, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if ((offer['driver_name'] ?? '').toString().isNotEmpty) ...[
                  const Icon(Icons.person_rounded, size: 16, color: Color(0xff1965BF)),
                  const SizedBox(width: 4),
                  Text(
                    (offer['driver_name'] ?? '').toString(),
                    style: GoogleFonts.cairo(fontSize: 12.5, color: textColor, fontWeight: FontWeight.w700),
                  ),
                ],
                if ((offer['vehicle_type_name'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.directions_car_filled_rounded, size: 16, color: Color(0xff1965BF)),
                  const SizedBox(width: 4),
                  Text(
                    (offer['vehicle_type_name'] ?? '').toString(),
                    style: GoogleFonts.cairo(fontSize: 12.5, color: textColor),
                  ),
                ],
                const Spacer(),
                if (fare != null)
                  Text(
                    '${languages[choosenLanguage]['text_recovery_card_fare'] ?? (rtl ? 'الأجرة التقديرية' : 'Estimated fare')}: $fare $currency',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: const Color(0xff1965BF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: declineRecoveryOfferFromHome,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: textColor.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      languages[choosenLanguage]['text_recovery_card_decline'] ??
                          (rtl ? 'لا، شكرًا' : 'No, thanks'),
                      style: GoogleFonts.cairo(color: textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: confirmRecoveryOfferFromHome,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xff1965BF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      languages[choosenLanguage]['text_recovery_card_confirm'] ??
                          (rtl ? 'نعم، أريد الرحلة' : 'Yes, I need the ride'),
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
