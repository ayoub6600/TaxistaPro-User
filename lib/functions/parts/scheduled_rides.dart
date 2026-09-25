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
Map<String, List<Map<String, dynamic>>> scheduledCounterOffers = {};

Future<void> getScheduledCounterOffers(String requestId) async {
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/request/scheduled/$requestId/offers'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      scheduledCounterOffers[requestId] = (data as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      valueNotifierBook.incrementNotifier();
    }
  } catch (_) {
    // The scheduled list is still usable offline; refresh on reconnect.
  }
}

Future<String> acceptScheduledCounterOffer(String requestId, Map offer) async {
  try {
    final response = await http.post(
      Uri.parse('${url}api/v1/request/respond-for-bid'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': requestId,
        'driver_id': offer['driver_id'],
        'accepted_ride_fare': offer['offered_fare'],
      }),
    );
    final decoded = jsonDecode(response.body);
    return response.statusCode == 200 && decoded['success'] == true
        ? 'success'
        : decoded['message']?.toString() ?? 'العرض لم يعد متاحاً';
  } catch (_) {
    return 'تعذر قبول العرض. تحقق من اتصالك.';
  }
}

getUpcomingScheduledRides() async {
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/request/scheduled/upcoming'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      upcomingScheduledRides = jsonDecode(response.body)['data'];
      upcomingScheduledRidesPage = jsonDecode(response.body)['meta'];
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
