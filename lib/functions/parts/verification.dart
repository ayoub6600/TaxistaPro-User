// ignore_for_file: no_leading_underscores_for_local_identifiers, unrelated_type_equality_checks

part of '../functions.dart';

paymentMethod(payment) async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/user/payment-method'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'request_id': userRequestData['id'],
              'payment_opt': (payment == 'card')
                  ? 0
                  : (payment == 'cash')
                      ? 1
                      : (payment == 'wallet')
                          ? 2
                          : 4
            }));
    if (response.statusCode == 200) {
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'modified_by_user': ServerValue.timestamp});
      ismulitipleride = true;
      await getUserDetails(id: userRequestData['id']);
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

String isemailmodule = '1';
bool isCheckFireBaseOTP = true;
bool isMobileOtpSignIn = true;
bool isMobileOtpSignUp = true;
getemailmodule() async {
  dynamic res;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/common/modules'),
    );

    if (response.statusCode == 200) {
      isemailmodule = jsonDecode(response.body)['enable_email_otp'];
      isCheckFireBaseOTP = jsonDecode(response.body)['firebase_otp_enabled'];
      isMobileOtpSignIn =
          jsonDecode(response.body)['mobile_otp_enabled_for_login'];
      isMobileOtpSignUp =
          jsonDecode(response.body)['mobile_otp_enabled_for_signup'];

      res = 'success';
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      res = 'no internet';
    }
  }

  return res;
}

sendOTPtoMobile(String mobile, String countryCode, {String? channel}) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/mobile-otp'), body: {
      'mobile': mobile,
      'country_code': countryCode,
      if (channel != null) 'channel': channel,
    });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

validateSmsOtp(String mobile, String otp) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/validate-otp'),
        body: {'mobile': mobile, 'otp': otp});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

List outStationList = [];
outStationListFun() async {
  dynamic result;
  try {
    final response = await http.get(
        Uri.parse('${url}api/v1/request/outstation_rides'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});

    if (response.statusCode == 200) {
      outStationList = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    outStationList.removeWhere((element) => element.isEmpty);
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }

  return result;
}

List loginImages = [];
getLandingImages() async {
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];
      loginImages.clear();
      List _images = jsonDecode(response.body)['data']['onboarding']['data'];
      for (var element in _images) {
        if (element['screen'] == 'user') {
          loginImages.add(element);
        }
      }
      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

Future<void> saveListToPrefs(List<dynamic> list) async {
  final prefs = await SharedPreferences.getInstance();
  // Serialize the list to JSON
  final jsonString = json.encode(list);
  // Save the JSON string to shared preferences
  await prefs.setString('outstationpush', jsonString);
}

// Define a function to load the list from shared preferences
Future<List<dynamic>> loadListFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  // Get the JSON string from shared preferences
  final jsonString = prefs.getString('outstationpush');
  if (jsonString != null) {
    // Parse the JSON string back into a list
    final List<dynamic> list = json.decode(jsonString);
    return list;
  }
  // Return an empty list if no data was found in shared preferences
  return [];
}

List outStationDriver = [];

//push notification
dynamic outStationPushStream;
outStationPush() async {
  outStationPushStream = FirebaseDatabase.instance
      .ref()
      .child('bid-meta')
      .orderByChild('user_id')
      .equalTo(userDetails['id'].toString())
      .onValue
      .listen((event) async {
    if (jsonDecode(jsonEncode(event.snapshot.value)) != null) {
      Map rides = jsonDecode(jsonEncode(event.snapshot.value));
      rides.forEach((key, value) {
        if (value['drivers'] != null) {
          Map drivers = value['drivers'];
          drivers.forEach((k, v) {
            if (outStationDriver
                .where((e) => e['id'] == key && e['driver'] == k)
                .isEmpty) {
              outStationDriver
                  .add({'id': key, 'driver': k, 'price': v['price']});
              saveListToPrefs(outStationDriver);
              // pref.setString('outstationpush', json.encode(outStationDriver));
              RemoteNotification noti = RemoteNotification(
                  title: languages[choosenLanguage]['text_got_new_driver'],
                  body:
                      '${v['driver_name']} ${languages[choosenLanguage]['text_bid_ride_amount_of']} ${v['price']}');
              showRideNotification(noti);
            }
          });
        }
      });
    }
  });
}
