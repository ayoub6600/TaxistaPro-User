import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _giftBlue = Color(0xff0873FF);
const _giftNavy = Color(0xff10213F);

/// Branded one-time welcome reward shown when a signup gift is credited.
class SignupWelcomeGiftDialog extends StatefulWidget {
  const SignupWelcomeGiftDialog({
    super.key,
    required this.reward,
    required this.isArabic,
  });

  final String reward;
  final bool isArabic;

  @override
  State<SignupWelcomeGiftDialog> createState() =>
      _SignupWelcomeGiftDialogState();
}

class _SignupWelcomeGiftDialogState extends State<SignupWelcomeGiftDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff073D91).withOpacity(.24),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hero(isArabic),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic
                          ? 'أهلًا بك في تاكسيستا!'
                          : 'Welcome to Taxista!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: _giftNavy,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isArabic
                          ? 'هذه هديتك الترحيبية، جاهزة لرحلتك الأولى.'
                          : 'Your welcome gift is ready for your first ride.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: const Color(0xff7888A2),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xffF0F7FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xffD9EAFF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded,
                              color: _giftBlue, size: 19),
                          const SizedBox(width: 8),
                          Text(
                            isArabic
                                ? 'تُخصم تلقائيًا من أول رحلة'
                                : 'Automatically applied to your first ride',
                            style: GoogleFonts.cairo(
                              color: _giftNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff1595FF), _giftBlue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _giftBlue.withOpacity(.28),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'ابدأ رحلتك' : 'Let’s ride',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool isArabic) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff1595FF), Color(0xff0862E8)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            width: 250,
            height: 250,
            top: 35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.09),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 50,
            child: _sparkle(Icons.auto_awesome_rounded, 20, .76),
          ),
          Positioned(
            right: 29,
            top: 63,
            child: _sparkle(Icons.star_rounded, 23, .64),
          ),
          Positioned(
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withOpacity(.27)),
              ),
              child: Text(
                isArabic ? 'هدية ترحيبية' : 'WELCOME GIFT',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isArabic ? 0 : .8,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 * _floatController.value),
              child: child,
            ),
            child: Image.asset(
              'assets/images/driver_offer_mascot.png',
              height: 142,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff063D95).withOpacity(.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: _giftBlue, size: 18),
                  const SizedBox(width: 7),
                  Text(
                    '${widget.reward} ${isArabic ? 'دينار' : 'LYD'}',
                    style: GoogleFonts.cairo(
                      color: _giftBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sparkle(IconData icon, double size, double opacity) => Icon(
        icon,
        color: Colors.white.withOpacity(opacity),
        size: size,
      );
}
