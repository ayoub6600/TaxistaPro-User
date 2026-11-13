import 'package:flutter/material.dart';

import '../../functions/functions.dart' show getUserDetails, userRequestData;
import '../../functions/ride_watch.dart';
import 'booking_confirmation.dart';

/// After a request made from its own page (a parcel, a tow…): the same searching screen as any ride
/// — «نبحث لك…», the cancel button, then the driver on his way — exactly as when the app is opened
/// again while a ride is searching. If the profile is not back yet, the home screen follows it.
Future<void> openBookedRide(BuildContext context) async {
  final nav = Navigator.of(context);
  try {
    await getUserDetails();
  } catch (_) {}
  if (userRequestData.isNotEmpty) {
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => BookingConfirmation()), (_) => false);
  } else {
    RideWatch.untilDriver();
    nav.maybePop();
  }
}
