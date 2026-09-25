part of '../functions.dart';

// Rider-facing scheduled-ride management (الرحلات القادمة).
List activeRiderBookings = [];

/// Separate admin-priced scheduled quote. Immediate and destination-less
/// bookings keep their own ETA; never fabricate a scheduled premium locally.
num scheduledQuotedFare(Map eta) =>
    eta['has_discount'] == true && eta['scheduled_discounted_total'] is num
        ? eta['scheduled_discounted_total'] as num
        : (eta['scheduled_total'] is num) ? eta['scheduled_total'] as num :
            (eta['total'] is num) ? eta['total'] as num : 0;

num quotedFareForPayment(Map eta, {required bool scheduled, required bool discounted}) {
  if (scheduled) {
    if (discounted && eta['scheduled_discounted_total'] is num) {
      return eta['scheduled_discounted_total'] as num;
    }
    return eta['scheduled_total'] is num
        ? eta['scheduled_total'] as num : scheduledQuotedFare(eta);
  }
  final value = eta[discounted ? 'discounted_totel' : 'total'];
  return value is num ? value : 0;
}

Future<String> getActiveRiderBookings() async {
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/request/active'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      activeRiderBookings = jsonDecode(response.body)['data'] as List;
      userDetails['rider_active_ride_count'] = activeRiderBookings.length;
      userDetails['has_ongoing_ride'] = activeRiderBookings.isNotEmpty;
      valueNotifierHome.incrementNotifier();
      return 'success';
    }
    if (response.statusCode == 401) return 'logout';
    return 'failure';
  } catch (_) {
    return 'failure';
  }
}

List upcomingScheduledRides = [];
Map<String, dynamic> upcomingScheduledRidesPage = {};

/// Pending driver offers per scheduled ride id, read straight from the
/// upcoming-rides payload (the server sends them with each ride, so opening the
/// page costs no extra request per ride).
Map<String, List<ScheduledOffer>> scheduledCounterOffers = {};

/// What the Home banner shows: how many drivers have priced the rider's
/// scheduled rides, the earliest such ride and the lowest price.
ScheduledOfferSummary scheduledOfferSummary = ScheduledOfferSummary.none;

/// Set by a tapped offer push; Home opens the scheduled rides page once.
bool openScheduledOffersRequested = false;

final PollGate _offerSummaryGate =
    PollGate(minInterval: const Duration(seconds: 45));

void _rebuildScheduledOfferState() {
  scheduledCounterOffers = {
    for (final ride in upcomingScheduledRides)
      if (ride is Map && ride['id'] != null && ride['driver_id'] == null)
        ride['id'].toString(): offersOfRide(ride),
  };
  scheduledOfferSummary = summarizeScheduledOffers(upcomingScheduledRides);
}

/// One light refresh of "does a driver have an offer for me?" - shared with a
/// refresh already in flight, at most every 45 seconds unless [force]d by a
/// push notification (which is the reason it costs nothing to keep Home
/// current: no periodic polling).
Future<void> refreshScheduledOfferSummary({bool force = false}) async {
  if (bearerToken.isEmpty) return;
  try {
    await _offerSummaryGate.run(() async {
      await getUpcomingScheduledRides();
      valueNotifierHome.incrementNotifier();
    }, force: force);
  } catch (_) {
    // The banner is a convenience; the scheduled page still works on demand.
  }
}

Future<String> _answerScheduledOffer(String action, ScheduledOffer offer) async {
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/request/scheduled/offers/$action'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'offer_id': offer.offerId}),
    ).timeout(const Duration(seconds: 20));
    if (offerAnswerOf(response.statusCode) == OfferAnswer.done) return 'success';
    try {
      final message = jsonDecode(response.body)['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {}
    return 'العرض لم يعد متاحاً';
  } catch (_) {
    return 'تعذر إرسال ردك. تحقق من اتصالك.';
  }
}

Future<String> acceptScheduledCounterOffer(ScheduledOffer offer) =>
    _answerScheduledOffer('accept', offer);

Future<String> rejectScheduledCounterOffer(ScheduledOffer offer) =>
    _answerScheduledOffer('reject', offer);

getUpcomingScheduledRides() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/request/scheduled/upcoming'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      upcomingScheduledRides = jsonDecode(response.body)['data'];
      upcomingScheduledRidesPage = jsonDecode(response.body)['meta'];
      upcomingScheduledRides.removeWhere((element) => element.isEmpty);
      _rebuildScheduledOfferState();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    upcomingScheduledRides.removeWhere((element) => element.isEmpty);
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getUpcomingScheduledRidesPages(id) async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/request/scheduled/upcoming?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        upcomingScheduledRides.add(element);
      });
      upcomingScheduledRidesPage = jsonDecode(response.body)['meta'];
      upcomingScheduledRides.removeWhere((element) => element.isEmpty);
      _rebuildScheduledOfferState();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    upcomingScheduledRides.removeWhere((element) => element.isEmpty);
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getScheduledRideDetail(id) async {
  dynamic result;
  dynamic data;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/request/scheduled/$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      data = jsonDecode(response.body)['data'];
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return {'result': result, 'data': data};
}

// newDateTime must be a DateTime; formatted the same way the existing
// ride-later flow already sends trip_start_time to the backend.
rescheduleScheduledRide(requestId, DateTime newDateTime) async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/scheduled/reschedule'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'request_id': requestId,
              'trip_start_time': newDateTime.toString().substring(0, 19),
            }));
    if (response.statusCode == 200) {
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {}
      result = decoded is Map && decoded['message'] != null
          ? decoded['message']
          : 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}
