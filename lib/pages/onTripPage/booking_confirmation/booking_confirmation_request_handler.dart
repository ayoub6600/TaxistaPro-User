part of '../booking_confirmation.dart';

mixin _BookingConfirmationRequestHandler
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationScheduledRequest,
        _BookingConfirmationImmediateRequest {
  Future<void> handleRideRequest(Size media, GeoHasher geo) async {
    if ((widget.type == 2) ||
        (((rentalOption.isEmpty &&
                        (etaDetails[choosenVehicle]['user_wallet_balance'] >=
                                etaDetails[choosenVehicle]['total'] &&
                            etaDetails[choosenVehicle]['has_discount'] ==
                                false) ||
                    (rentalOption.isEmpty &&
                        etaDetails[choosenVehicle]['has_discount'] == true &&
                        etaDetails[choosenVehicle]['user_wallet_balance'] >=
                            etaDetails[choosenVehicle]['discounted_totel'])) ||
                (rentalOption.isEmpty &&
                    etaDetails[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] !=
                        'wallet')) ||
            ((rentalOption.isNotEmpty &&
                    (etaDetails[0]['user_wallet_balance'] >=
                        rentalOption[choosenVehicle]['fare_amount']) &&
                    rentalOption[choosenVehicle]['has_discount'] == false) ||
                (rentalOption.isNotEmpty &&
                    rentalOption[choosenVehicle]['has_discount'] == true &&
                    etaDetails[0]['user_wallet_balance'] >=
                        rentalOption[choosenVehicle]['discounted_totel']) ||
                rentalOption.isNotEmpty &&
                    rentalOption[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] !=
                        'wallet'))) {
      if (((widget.type == null)
              ? (etaDetails[choosenVehicle]['enable_bidding'] == true)
              : false) ||
          isOutStation) {
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
          print('isOutStation14');
          setState(() {
            _showInfoInt = choosenVehicle;
          });
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
        }
      } else {
        setState(() {
          isLoading = true;
        });
        print('isOutStation15');
        dynamic result;
        if (choosenVehicle != null) {
          if (confirmRideLater == true) {
            await submitScheduledRide();
          } else {
            result = await submitImmediateRide();
          }
          if (result == 'logout') {
            navigateLogout();
          } else if (result == 'success') {
            timer();
          }
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        islowwalletbalance = true;
      });
    }
  }
}
