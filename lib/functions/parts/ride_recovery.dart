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

// The Home card is polled, so it is rate-disciplined: one request in flight,
// never more often than every 8 seconds unless a push says something changed
// (force), and a hard pause when the server answers 429. This endpoint used
// to be hit ~90 times a minute, which starved Cancel/Accept of their budget.
final PollGate _pendingOfferGate = PollGate(minInterval: const Duration(seconds: 8));

/// Recovery only exists when the admin enabled a recovery window; with it
/// off there is nothing to poll for.
bool get recoveryPollingEnabled =>
    (int.tryParse(userDetails['missed_ride_recovery_window_seconds']?.toString() ?? '') ?? 0) > 0;

Future<String> fetchPendingRecoveryOfferForRider({bool force = false}) async {
  if (!recoveryPollingEnabled && !force) return 'skipped';
  final result = await _pendingOfferGate.run<String>(() async {
    try {
      final response = await http.get(
        Uri.parse('${url}api/v1/request/recovery/pending-offer'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        pendingRecoveryOfferForRider =
            (data is Map) ? Map<String, dynamic>.from(data) : null;
        return 'success';
      }
      if (response.statusCode == 401) return 'logout';
      if (response.statusCode == 429) {
        _pendingOfferGate.backOff(
            retryAfterOf(response.headers) ?? const Duration(seconds: 30));
        return 'throttled';
      }
    } catch (_) {}
    return 'failure';
  }, force: force);
  return result ?? 'skipped';
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
