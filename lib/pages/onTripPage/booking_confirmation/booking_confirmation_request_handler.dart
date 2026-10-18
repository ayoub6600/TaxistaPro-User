part of '../booking_confirmation.dart';

mixin _BookingConfirmationRequestHandler
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationScheduledRequest,
        _BookingConfirmationImmediateRequest {
  Future<void> handleRideRequest(Size media, GeoHasher geo) async {
    if (isLoading) return;
    if (choosenVehicle == null) return;
    final eta = etaDetails[choosenVehicle];
    final selectedService =
        rentalOption.isEmpty ? eta : rentalOption[choosenVehicle];
    final selectedFare = rentalOption.isEmpty
        ? payableFareForSelectedService(
            eta,
            scheduled: confirmRideLater &&
                choosenTransportType == 0 &&
                widget.type == null,
            discounted: eta['has_discount'] == true,
          )
        : (double.tryParse((selectedService['has_discount'] == true
                        ? selectedService['discounted_totel']
                        : selectedService['fare_amount'])
                    ?.toString() ??
                '') ??
            0);
    final walletBalance = rentalOption.isEmpty
        ? (double.tryParse(eta['user_wallet_balance']?.toString() ?? '') ?? 0)
        : (double.tryParse(
                etaDetails[0]['user_wallet_balance']?.toString() ?? '') ??
            0);
    if (widget.type == 2 ||
        walletCanCoverOrSplit(selectedService,
            fare: selectedFare, walletBalance: walletBalance)) {
      // Codex/refactor: the older CreateRequestBottomSheet still handles
      // outstation scheduling. In-city taxi rides must use the current
      // signed-quote request flow below, including bidding services.
      if (isOutStation) {
        print('isOutStation11');
        if (isOneWayTrip && nofromdate) {
          setState(() {
            _showInfoInt = choosenVehicle;
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return CreateRequestBottomSheet(
                    type: widget.type,
                    showInfoInt: _showInfoInt,
                    fromDate: fromDate,
                    geo: geo,
                    isOneWayTrip: isOneWayTrip,
                    toDate: toDate,
                    amount: etaDetails[choosenVehicle]['total'].toString(),
                  );
                });
          });
        } else {
          print('isOutStation12');
          if (!nofromdate || toDate == null) {
            setState(() {
              _isDateTimebottom = 0;
              if (!nofromdate) {
                isFromDate = true;
              } else {
                isFromDate = false;
                toDate = fromDate.add(const Duration(days: 1, minutes: 2));
              }
            });
            Future.delayed(const Duration(milliseconds: 200), () {
              setState(() {
                if (isOneWayTrip) {
                  _dateTimeHeight = media.height * 0.45;
                } else {
                  _dateTimeHeight = media.height * 0.5;
                }
              });
            });
          } else {
            print('isOutStation13');
            setState(() {
              _showInfoInt = choosenVehicle;
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return CreateRequestBottomSheet(
                      type: widget.type,
                      showInfoInt: _showInfoInt,
                      fromDate: fromDate,
                      geo: geo,
                      isOneWayTrip: isOneWayTrip,
                      toDate: toDate,
                      amount: etaDetails[choosenVehicle]['total'].toString(),
                    );
                  });
            });
          }
        }
      } else {
        double? riderOffer;
        final eta = etaDetails[choosenVehicle];
        if (canAdjustSelectedFare(choosenVehicle)) {
          riderOffer = chosenFareForService(choosenVehicle);
          if (riderOffer > 0) {
            final paymentChoices = eta['payment_type'].toString().split(',');
            final walletBalance =
                double.tryParse(eta['user_wallet_balance']?.toString() ?? '') ??
                    0;
            if (payingVia < paymentChoices.length &&
                paymentChoices[payingVia] == 'wallet' &&
                riderOffer > walletBalance &&
                !paymentChoices.contains('wallet_and_cash')) {
              setState(() => islowwalletbalance = true);
              return;
            }
          }
        }
        setState(() {
          isLoading = true;
        });
        print('isOutStation15');
        dynamic result;
        if (choosenVehicle != null) {
          if (confirmRideLater == true) {
            await submitScheduledRide(offerFare: riderOffer);
          } else {
            result = await submitImmediateRide(offerFare: riderOffer);
          }
          if (result == 'logout') {
            navigateLogout();
          } else if (result == 'success') {
            timer();
          }
          if (mounted) setState(() => isLoading = false);
        }
      }
    } else {
      setState(() {
        islowwalletbalance = true;
      });
    }
  }
}
