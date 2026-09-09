part of '../booking_confirmation.dart';

mixin _BookingConfirmationModalOverlays
    on
        State<BookingConfirmation>,
        _BookingConfirmationController,
        _BookingConfirmationMarkerSnapshots,
        _BookingConfirmationStatusOverlays,
        _BookingConfirmationSelectionSheet,
        _BookingConfirmationRequestHandler,
        _BookingConfirmationPendingRequest,
        _BookingConfirmationActiveRide {
  List<Widget> buildModalOverlays(Size media, Query fdb, GeoHasher geo) {
    return [
      if (!(userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null))
        PositionedDirectional(
          top: MediaQuery.of(context).padding.top + 12,
          start: 18,
          child: BookingBackButton(
            enabled: true,
            onPressed: () => handleBookingBack(context),
          ),
        ),
      buildNoDriverOverlay(
        onRetry: () async {
          setState(() {
            noDriverFound = false;
            isLoading = true;
          });
          await handleRideRequest(media, geo);
        },
      ),
      buildTripErrorOverlay(),
      buildServiceUnavailableOverlay(),
      buildLowWalletOverlay(),
      buildPaymentMethodOverlay(),
      buildPendingRequestOverlay(media),
      buildActiveRideSheet(media),
      (_cancelling == true)
          ? CancellationSheet(
              reasons: cancelReasonsList
                  .map((item) => item['reason'].toString())
                  .toList(),
              selectedReason: _cancelReason,
              otherValue: 'others',
              copy: Map<String, dynamic>.from(languages[choosenLanguage]),
              errorText: _cancellingError,
              onReasonSelected: (reason) {
                setState(() {
                  _cancelReason = reason;
                  _cancellingError = '';
                });
              },
              onCustomReasonChanged: (reason) {
                _cancelCustomReason = reason;
                if (_cancellingError.isNotEmpty) {
                  setState(() {
                    _cancellingError = '';
                  });
                }
              },
              onKeepRide: () {
                setState(() {
                  _cancelling = false;
                  _cancellingError = '';
                });
              },
              onConfirmCancellation: _confirmCancellation,
            )
          : Container(),
      (_dateTimePicker)
          ? RideDatePickerOverlay(
              minimumDate: DateTime.now().add(
                Duration(
                  minutes: int.parse(
                    userDetails['user_can_make_a_ride_after_x_miniutes'],
                  ),
                ),
              ),
              maximumDate: DateTime.now().add(
                const Duration(days: 4),
              ),
              confirmText: languages[choosenLanguage]['text_confirm'],
              onChanged: (value) {
                choosenDateTime = value;
              },
              onClose: () {
                setState(() {
                  _dateTimePicker = false;
                });
              },
              onConfirm: () {
                setState(() {
                  _dateTimePicker = false;
                });
              },
            )
          : const SizedBox.shrink(),
      (_isDateTimebottom >= 0)
          ? RideScheduleSheet(
              height: _dateTimeHeight,
              isOneWay: isOneWayTrip,
              isSelectingOutbound: isFromDate,
              outboundDate: fromDate,
              returnDate: toDate,
              minimumOutboundDate: DateTime.now().add(
                Duration(
                  minutes: int.parse(
                    userDetails['user_can_make_a_ride_after_x_miniutes'],
                  ),
                ),
              ),
              copy: languages[choosenLanguage],
              onDismiss: () {
                setState(() {
                  _dateTimeHeight = 0;
                });
                Future.delayed(
                  const Duration(milliseconds: 220),
                  () {
                    if (mounted) {
                      setState(() {
                        _isDateTimebottom = -1000;
                      });
                    }
                  },
                );
              },
              onSelectOutbound: () {
                setState(() {
                  isFromDate = true;
                  toDate = null;
                });
              },
              onSelectReturn: () {
                setState(() {
                  isFromDate = false;
                  toDate = fromDate.add(
                    const Duration(
                      days: 1,
                      minutes: 10,
                    ),
                  );
                });
              },
              onOutboundChanged: (value) {
                fromDate = value;
              },
              onReturnChanged: (value) {
                toDate = value;
              },
              onContinue: () {
                if (!isOneWayTrip && toDate == null) {
                  setState(() {
                    isFromDate = false;
                    toDate = fromDate.add(
                      const Duration(
                        days: 1,
                        minutes: 10,
                      ),
                    );
                  });
                  return;
                }

                setState(() {
                  nofromdate = true;
                  _dateTimeHeight = 0;
                });
                if (toDate != null) {
                  dateDifference = toDate!.difference(fromDate);
                  daysDifferenceRoundedUp =
                      (dateDifference.inHours / 24).ceil();
                }
                Future.delayed(
                  const Duration(milliseconds: 220),
                  () {
                    if (mounted) {
                      setState(() {
                        _isDateTimebottom = -1000;
                      });
                    }
                  },
                );
              },
            )
          : const SizedBox.shrink(),
      (showSos)
          ? SosSheet(
              copy: languages[choosenLanguage],
              contacts: sosData,
              notificationSent: notifyCompleted,
              onClose: () {
                setState(() {
                  notifyCompleted = false;
                  showSos = false;
                });
              },
              onNotifyAdmin: () async {
                setState(() {
                  notifyCompleted = false;
                });
                final sent = await notifyAdmin();
                if (mounted && sent == true) {
                  setState(() {
                    notifyCompleted = true;
                  });
                }
              },
              onCall: makingPhoneCall,
            )
          : const SizedBox.shrink(),
      (_locationDenied)
          ? LocationPermissionSheet(
              message: languages[choosenLanguage]['text_open_loc_settings'],
              openSettingsText: languages[choosenLanguage]
                  ['text_open_settings'],
              doneText: languages[choosenLanguage]['text_done'],
              onClose: () {
                setState(() {
                  _locationDenied = false;
                });
              },
              onOpenSettings: perm.openAppSettings,
              onDone: () {
                setState(() {
                  _locationDenied = false;
                  isLoading = true;
                });
                if (locationAllowed &&
                    (positionStream == null || positionStream!.isPaused)) {
                  positionStreamData();
                }
              },
            )
          : const SizedBox.shrink(),
      ((!_chooseGoodsType &&
                  userRequestData.isEmpty &&
                  addressList.isNotEmpty &&
                  choosenTransportType == 1) ||
              (!dropConfirmed && userRequestData.isEmpty))
          ? TripDetailsSheet(
              addresses: addressList,
              copy: languages[choosenLanguage],
              isRtl: languageDirection == 'rtl',
              canAddStop: addressList.length < 5 && widget.type != 1,
              onAddStop: () {
                _editTripLocation('add stop');
              },
              onEdit: (index) {
                _editTripLocation(index);
              },
              onDelete: _deleteDestination,
              onReorder: _reorderDestinations,
              onConfirm: _confirmTripDetails,
            )
          : const SizedBox.shrink(),
      (_editUserDetails)
          ? RiderContactSheet(
              copy: languages[choosenLanguage],
              nameController: pickerName,
              numberController: pickerNumber,
              instructionsController: instructions,
              onClose: () {
                setState(() {
                  _editUserDetails = false;
                });
              },
              onPickContact: () async {
                final picked = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PickContact(from: '1'),
                  ),
                );
                if (mounted && picked == true) {
                  setState(() {
                    pickerName.text = pickedName;
                    pickerNumber.text = pickedNumber;
                  });
                }
              },
              onConfirm: () {
                setState(() {
                  addressList[0].name = pickerName.text.trim();
                  addressList[0].number = pickerNumber.text.trim();
                  addressList[0].instructions = instructions.text.trim().isEmpty
                      ? null
                      : instructions.text.trim();
                  _editUserDetails = false;
                });
              },
            )
          : const SizedBox.shrink(),
      if (_cancel)
        BookingStatusSheet(
          title: languages[choosenLanguage]['text_cancel_confirmation'],
          actionLabel: languages[choosenLanguage]['text_confirm'],
          secondaryActionLabel: languages[choosenLanguage]['text_cancel'],
          icon: Icons.cancel_outlined,
          onSecondaryAction: () {
            setState(() {
              _cancel = false;
            });
          },
          onAction: () async {
            setState(() {
              isLoading = true;
            });
            final result = await cancelRequest();
            updateAmount.clear();
            if (!mounted) return;
            if (result == 'logout') {
              navigateLogout();
              return;
            }
            setState(() {
              isLoading = false;
              _cancel = false;
            });
          },
        ),
      (requestCancelledByDriver == true)
          ? BookingStatusSheet(
              title: languages[choosenLanguage]['text_drivercancelled'],
              actionLabel: languages[choosenLanguage]['text_ok'],
              icon: Icons.event_busy_rounded,
              onAction: () async {
                setState(() {
                  requestCancelledByDriver = false;
                  if (userRequestData['is_bid_ride'].toString() == '1') {
                    userRequestData = {};
                  }
                });
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Maps(),
                  ),
                  (_) => false,
                );
              },
            )
          : Container(),
      (isLoading == true)
          ? const Positioned(top: 0, child: Loading())
          : Container(),
      (internet == false)
          ? Positioned(
              top: 0,
              child: NoInternet(
                onTap: () {
                  setState(() {
                    internetTrue();
                  });
                },
              ))
          : Container(),
      buildPickupMarkerSnapshot(media),
      buildDropMarkerSnapshots(media),
      buildDistanceMarkerSnapshot(media)
    ];
  }
}
