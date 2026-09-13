part of '../functions.dart';

// Rider-facing scheduled-ride management (الرحلات القادمة).
List upcomingScheduledRides = [];
Map<String, dynamic> upcomingScheduledRidesPage = {};

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
    var response = await http.post(
        Uri.parse('${url}api/v1/request/scheduled/reschedule'),
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
