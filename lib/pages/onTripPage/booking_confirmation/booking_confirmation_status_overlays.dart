part of '../booking_confirmation.dart';

mixin _BookingConfirmationStatusOverlays
    on State<BookingConfirmation>, _BookingConfirmationController {
  Widget buildNoDriverOverlay({required Future<void> Function() onRetry}) {
    if (!noDriverFound) return Container();

    return BookingStatusSheet(
      title: languages[choosenLanguage]['text_nodriver'],
      actionLabel: languages[choosenLanguage]['text_tryagain'],
      icon: Icons.local_taxi_rounded,
      onAction: () async {
        setState(() {
          noDriverFound = false;
        });
        await onRetry();
      },
    );
  }

  /// Shown instead of the immediate no-driver-found screen while the
  /// backend keeps this ride open for a missed-ride recovery window
  /// (recovery_active on userRequestData) - "still trying", not "gave up".
  /// The rider can still bail out early via the action button; if they
  /// don't, either a driver gets confirmed (this ride's timer stops on its
  /// own - see the accepted_at check in timer()) or the window closes and
  /// noDriverFound takes over normally.
  Widget buildStillSearchingOverlay() {
    if (!stillSearchingForDriver) return Container();

    return BookingStatusSheet(
      title: languages[choosenLanguage]['text_still_searching'] ??
          (choosenLanguage == 'ar'
              ? 'نكمل نلقالك سواق...'
              : 'Still looking for a driver...'),
      actionLabel: languages[choosenLanguage]['text_cancel'] ??
          (choosenLanguage == 'ar' ? 'إلغاء' : 'Cancel'),
      icon: Icons.search_rounded,
      accentColor: const Color(0xff1677FF),
      onAction: () async {
        var val = await cancelRequest();
        setState(() {
          stillSearchingForDriver = false;
        });
        if (val == 'logout') {
          navigateLogout();
        }
      },
    );
  }

  Widget buildTripErrorOverlay() {
    if (!tripReqError) return Container();

    return BookingStatusSheet(
      title: tripError,
      actionLabel: languages[choosenLanguage]['text_tryanother'],
      icon: Icons.sync_problem_rounded,
      onAction: () async {
        setState(() {
          tripReqError = false;
        });
      },
    );
  }

  Widget buildServiceUnavailableOverlay() {
    if (!serviceNotAvailable) return Container();

    return BookingStatusSheet(
      title: languages[choosenLanguage]['text_no_service'],
      actionLabel: languages[choosenLanguage]['text_tryagain'],
      icon: Icons.location_off_rounded,
      accentColor: const Color(0xffF59E0B),
      onAction: () async {
        setState(() {
          serviceNotAvailable = false;
          isLoading = true;
        });

        final val = widget.type != 1
            ? await etaRequest(outstation: isOutStation)
            : await rentalEta();
        if (!mounted) return;
        if (val == 'logout') {
          navigateLogout();
          return;
        }

        setState(() {
          isLoading = false;
          dropConfirmed = val == true && etaDetails.isNotEmpty;
          serviceNotAvailable = !dropConfirmed;
        });
      },
    );
  }

  Widget buildLowWalletOverlay() {
    if (!islowwalletbalance) return Container();

    return BookingStatusSheet(
      title: languages[choosenLanguage]['text_wallet_balance_low'],
      actionLabel: languages[choosenLanguage]['text_ok'],
      icon: Icons.account_balance_wallet_rounded,
      accentColor: const Color(0xffF59E0B),
      onAction: () async {
        setState(() {
          islowwalletbalance = false;
        });
      },
    );
  }

  Widget buildPaymentMethodOverlay() {
    if (!_choosePayment) return Container();

    return PaymentMethodSheet(
      methods: (widget.type != 1
              ? etaDetails[choosenVehicle]['payment_type']
              : rentalOption[choosenVehicle]['payment_type'])
          .toString()
          .split(',')
          .where((method) => method.trim().isNotEmpty)
          .map((method) => method.trim())
          .toList(),
      selectedIndex: payingVia,
      copy: Map<String, dynamic>.from(languages[choosenLanguage]),
      promoController: promoKey,
      promoStatus: promoStatus is int ? promoStatus as int : null,
      onClose: () {
        setState(() {
          _choosePayment = false;
          promoKey.clear();
          promoCode = '';
        });
      },
      onMethodSelected: (index) {
        setState(() {
          payingVia = index;
        });
      },
      onPromoChanged: (value) {
        setState(() {
          promoCode = value;
        });
      },
      onPromoRemoved: () async {
        setState(() {
          isLoading = true;
          promoStatus = null;
          promoCode = '';
          promoKey.clear();
        });
        final val = widget.type != 1
            ? await etaRequest(outstation: isOutStation)
            : await rentalEta();
        if (!mounted) return;
        if (val == 'logout') {
          navigateLogout();
          return;
        }
        setState(() {
          isLoading = false;
        });
      },
      onConfirm: () async {
        if (promoCode.trim().isEmpty) {
          setState(() {
            _choosePayment = false;
          });
          return;
        }
        setState(() {
          isLoading = true;
        });
        final val = widget.type != 1
            ? await etaRequestWithPromo(outstation: isOutStation)
            : await rentalRequestWithPromo();
        if (!mounted) return;
        if (val == 'logout') {
          navigateLogout();
          return;
        }
        setState(() {
          isLoading = false;
        });
      },
    );
  }
}
