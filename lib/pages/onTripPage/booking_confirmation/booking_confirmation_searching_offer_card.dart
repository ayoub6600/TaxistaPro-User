part of '../booking_confirmation.dart';

const _offerMascotAsset = 'assets/images/driver_offer_mascot.png';

String _formatMoney(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.driver,
    required this.isRtl,
    required this.isAccepting,
    required this.onAccept,
    required this.onTap,
  });

  final NearbyDriverCandidate driver;
  final bool isRtl;
  final bool isAccepting;
  final VoidCallback onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offer = driver.counterOffer ?? 0;
    final currency = driver.counterOfferCurrency;
    return TweenAnimationBuilder<double>(
      key: ValueKey('offer-card-${driver.revealKey}-$offer'),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + (value.clamp(0.0, 1.0) * 0.15),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 136,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffE6ECF6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff15386B).withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OfferSpeechBubble(
                text: isRtl
                    ? 'أقدر أوصلك بـ ${_formatMoney(offer)} $currency'
                    : 'I can get you there for ${_formatMoney(offer)} $currency',
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 46,
                child: Center(
                  child: SizedBox(
                    width: 66,
                    height: 46,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Image.asset(
                            _offerMascotAsset,
                            width: 34,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        Positioned(
                          left: 26,
                          bottom: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xff66E7DC), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipOval(
                                    child: _DriverPortrait(driver: driver)),
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff15C79A),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                driver.name.isEmpty
                    ? (isRtl ? 'سائق قريب' : 'Nearby driver')
                    : driver.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: _searchNavy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              _OfferAcceptButton(
                isRtl: isRtl,
                isAccepting: isAccepting,
                onTap: isAccepting ? null : onAccept,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferSpeechBubble extends StatelessWidget {
  const _OfferSpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _searchBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(width: 8, height: 8, color: _searchBlue),
          ),
        ),
      ],
    );
  }
}

class _OfferAcceptButton extends StatelessWidget {
  const _OfferAcceptButton({
    required this.isRtl,
    required this.isAccepting,
    required this.onTap,
  });

  final bool isRtl;
  final bool isAccepting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffE6FBF5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: isAccepting
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isRtl ? 'قبول عرض' : 'Accept',
                  style: GoogleFonts.cairo(
                    color: const Color(0xff087F65),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
