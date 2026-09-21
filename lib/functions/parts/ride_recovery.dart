part of '../functions.dart';

// Missed-ride recovery: rider-facing side. When a ride enters recovery
// (userRequestData['recovery_active']), a nearby driver may go "ready" -
// this fetches those pending offers and lets the rider confirm/decline one.
List pendingRecoveryOffers = [];

// The single recovery offer (if any) currently presented to this rider for
// Home-level display - independent of a known request_id and independent of
// push delivery. This is the sole source of truth the Home card renders
// from; the push notification is only a nudge to re-fetch it sooner.
Map<String, dynamic>? pendingRecoveryOfferForRider;

Future<String> fetchPendingRecoveryOfferForRider() async {
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/request/recovery/pending-offer'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      pendingRecoveryOfferForRider =
          (data is Map) ? Map<String, dynamic>.from(data) : null;
      return 'success';
    }
    if (response.statusCode == 401) return 'logout';
  } catch (_) {}
  return 'failure';
}

Future<String> fetchPendingRecoveryOffers(String requestId) async {
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/request/recovery/offers?request_id=$requestId'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      pendingRecoveryOffers = jsonDecode(response.body)['data'] ?? [];
      return 'success';
    }
    if (response.statusCode == 401) return 'logout';
  } catch (_) {}
  return 'failure';
}

Future<String> confirmRecoveryDriver(int offerId) async {
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/request/recovery/confirm-driver'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'offer_id': offerId}),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      pendingRecoveryOffers = [];
      if (pendingRecoveryOfferForRider?['offer_id'] == offerId) {
        pendingRecoveryOfferForRider = null;
      }
      return 'success';
    }
    return decoded['message']?.toString() ?? 'تعذر تأكيد السائق';
  } catch (_) {
    return 'تعذر تأكيد السائق. تحقق من اتصالك.';
  }
}

Future<String> rejectRecoveryDriver(int offerId) async {
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/request/recovery/reject-driver'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'offer_id': offerId}),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      pendingRecoveryOffers.removeWhere((o) => o['offer_id'] == offerId);
      if (pendingRecoveryOfferForRider?['offer_id'] == offerId) {
        pendingRecoveryOfferForRider = null;
      }
      return 'success';
    }
    return decoded['message']?.toString() ?? 'تعذر رفض السائق';
  } catch (_) {
    return 'تعذر رفض السائق. تحقق من اتصالك.';
  }
}
