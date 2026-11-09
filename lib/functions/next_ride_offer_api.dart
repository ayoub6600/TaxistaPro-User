import 'package:http/http.dart' as http;

import 'functions.dart';

/// The rider's no to a higher price from a driver finishing a trip nearby.
Future<bool> refuseNextRideOffer(String requestId, String driverId) async {
  try {
    final r = await http.post(
      Uri.parse('${url}api/v1/request/next-ride-offer/refuse'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'},
      body: {'request_id': requestId, 'driver_id': driverId},
    ).timeout(const Duration(seconds: 12));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}
