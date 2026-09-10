part of '../booking_confirmation.dart';

// Driver identity presentation: portrait, viewing-now chip and the
// tap-through details sheet.
class _DriverPortrait extends StatelessWidget {
  const _DriverPortrait({required this.driver});

  final NearbyDriverCandidate driver;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffE8F4FF), Color(0xffD9FFF7)],
        ),
      ),
      child: const Icon(Icons.person_rounded, color: _searchBlue, size: 35),
    );
    final avatar = driver.avatarUrl;
    if (avatar == null) return fallback;
    return ClipOval(
      child: Image.network(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _ViewingDriverAvatar extends StatelessWidget {
  const _ViewingDriverAvatar({
    required this.driver,
    required this.isRtl,
    required this.onTap,
  });

  final NearbyDriverCandidate driver;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('viewing-${driver.revealKey}'),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border:
                      Border.all(color: const Color(0xffE0E6F0), width: 1.5),
                ),
                child: ClipOval(child: _DriverPortrait(driver: driver)),
              ),
              const SizedBox(height: 3),
              Text(
                isRtl ? 'يرى الطلب الآن' : 'Viewing now',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: _searchMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverDetailsSheet extends StatelessWidget {
  const _DriverDetailsSheet({
    required this.driver,
    required this.isRtl,
    required this.isAccepting,
    required this.onAccept,
  });

  final NearbyDriverCandidate driver;
  final bool isRtl;
  final bool isAccepting;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final vehicle =
        [driver.vehicleMake, driver.vehicleModel].whereType<String>().join(' ');
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _searchNavy.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xff66E7DC), width: 2),
              ),
              child: ClipOval(child: _DriverPortrait(driver: driver)),
            ),
            const SizedBox(height: 10),
            Text(
              driver.name.isEmpty
                  ? (isRtl ? 'سائق قريب' : 'Nearby driver')
                  : driver.name,
              style: GoogleFonts.cairo(
                color: _searchNavy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (driver.rating != null || driver.completedTrips != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (driver.rating != null) ...[
                    const Icon(Icons.star_rounded,
                        color: Color(0xffFFB020), size: 16),
                    const SizedBox(width: 3),
                    Text(
                      driver.rating!.toStringAsFixed(1),
                      style: GoogleFonts.cairo(
                        color: _searchNavy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (driver.rating != null && driver.completedTrips != null)
                    const SizedBox(width: 10),
                  if (driver.completedTrips != null)
                    Text(
                      isRtl
                          ? '${driver.completedTrips} رحلة مكتملة'
                          : '${driver.completedTrips} completed trips',
                      style: GoogleFonts.cairo(
                        color: _searchMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
            if (vehicle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F8FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car_filled_rounded,
                        color: _searchBlue, size: 17),
                    const SizedBox(width: 7),
                    Text(
                      vehicle,
                      style: GoogleFonts.cairo(
                        color: _searchNavy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (driver.counterOffer != null) ...[
              const SizedBox(height: 14),
              Text(
                isRtl
                    ? 'السعر المقترح: ${_formatMoney(driver.counterOffer!)} ${driver.counterOfferCurrency}'
                    : 'Offered fare: ${_formatMoney(driver.counterOffer!)} ${driver.counterOfferCurrency}',
                style: GoogleFonts.cairo(
                  color: const Color(0xff087F65),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _searchNavy,
                      side: const BorderSide(color: Color(0xffD9E2EF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isRtl ? 'إغلاق' : 'Close',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (onAccept != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: isAccepting ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: _searchBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isAccepting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isRtl ? 'قبول عرض' : 'Accept offer',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
