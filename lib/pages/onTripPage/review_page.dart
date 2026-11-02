import 'package:flutter/material.dart';

import '../../community/community_api.dart';
import '../../community/ride_wrap_up.dart';
import '../../functions/functions.dart';
import '../login/login.dart';
import 'map_page.dart';

/// The end of a ride: the "ختام الرحلة" card over the invoice (rating, then the after-ride
/// extras), then the map. Opened with [RideWrapUp.route] so the invoice stays behind it.
class Review extends StatefulWidget {
  const Review({super.key});

  @override
  State<Review> createState() => _ReviewState();
}

double review = 0.0;
String feedback = '';

class _ReviewState extends State<Review> {
  // kept from the start: the ride data is refreshed while the card is open
  late final String? _rideId = userRequestData['id']?.toString();
  late final Map _driver = userRequestData['driverDetail'] is Map && userRequestData['driverDetail']['data'] is Map
      ? userRequestData['driverDetail']['data'] as Map
      : const {};
  bool _leaving = false;

  @override
  void initState() {
    review = 0.0;
    feedback = '';
    super.initState();
    if (_rideId == null) WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  //navigate
  Future<void> navigate() async {
    if (_leaving) return;
    _leaving = true;
    await refreshUserRequestState();
    if (!mounted) return;
    dropStopList.clear();
    addressList.clear();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Maps()),
        (route) => false);
  }

  Future<dynamic> _rate(double stars, String note) async {
    review = stars;
    feedback = note;
    return userRating();
  }

  @override
  Widget build(BuildContext context) {
    final rideId = _rideId;
    if (rideId == null) return const SizedBox.shrink();
    return RideWrapUp(
      role: 'rider',
      requestId: rideId,
      peerName: (_driver['name'] ?? '').toString(),
      peerPhoto: _driver['profile_picture']?.toString(),
      canSkipRating: true,
      sendRating: _rate,
      sendAfterRide: (c) => CommunityApi.submitAfterRide(
        rideId,
        favorite: c['favorite'] as bool?,
        badges: (c['badges'] as List?)?.cast<String>() ?? const [],
        comment: c['comment'] as String?,
        gift: c['gift'] == true,
        giftReason: c['gift_reason'] as String?,
      ),
      onFinished: navigate,
      onLogout: navigateLogout,
    );
  }
}
