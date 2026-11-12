import 'package:http/http.dart' as http;

import 'functions.dart';

/// The rider's no to a driver's higher price.
/// [reason] 'too_high' = «غالي شوية» (the server tells the driver gently and lets him come back once lower)
Future<bool> refuseDriverOffer(String requestId, String driverId, {String? reason}) async {
  try {
    final r = await http.post(
      Uri.parse('${url}api/v1/request/next-ride-offer/refuse'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'},
      body: {'request_id': requestId, 'driver_id': driverId, if (reason != null) 'reason': reason},
    ).timeout(const Duration(seconds: 12));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  }
}
