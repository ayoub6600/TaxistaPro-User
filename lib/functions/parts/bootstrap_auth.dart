// ignore_for_file: no_leading_underscores_for_local_identifiers, unrelated_type_equality_checks

part of '../functions.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;
int waitingTime = 0;
String gender = '';
String signupServiceLocationId = '';
String signupZoneId = '';
String packageName = '';
String signKey = '';

// This cleanup branch defaults to the local backend so a plain VS Code Run
// does not accidentally authenticate against production.
String url = const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8002/',
);

String mapkey = (platform == TargetPlatform.android)
    ? 'AIzaSyCLVX-Jnqqo89cZ2xQ6CJflSueG-laba7g'
    : 'AIzaSyCLVX-Jnqqo89cZ2xQ6CJflSueG-laba7g';

String mapType = '';
getCountryCode() async {
  dynamic result;
  try {
    // اطبع الـ base url
    debugPrint('Base URL: $url');

    // جهّز الـ Uri بشكل آمن (بالتعامل مع الشرط / تلقائياً)
    final Uri uri = Uri.parse(url).resolve('api/v1/countries-new').replace(
      queryParameters: {
        if (choosenLanguage.isNotEmpty) 'lang': choosenLanguage,
      },
    );
    debugPrint('Requesting GET $uri');

    final response = await http.get(uri);

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];

      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint('Error response: ${response.statusCode} - ${response.body}');
      result = 'error';
    }
  } catch (e) {
    debugPrint('Exception in getCountryCode: $e');
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    } else {
      result = 'error';
    }
  }
  return result;
}

// getCountryCode() async {
//   dynamic result;
//   try {
//     final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

//     if (response.statusCode == 200) {
//       countries = jsonDecode(response.body)['data']['countries']['data'];

//       phcode =
//           (countries.where((element) => element['default'] == true).isNotEmpty)
//               ? countries.indexWhere((element) => element['default'] == true)
//               : 0;
//       result = 'success';
//     } else {
//       debugPrint(response.body);
//       result = 'error';
//     }
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }

//check internet connection

checkInternetConnection() {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

getDetailsOfDevice() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    darktheme();

    pref = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint(e.toString());
  }
}

darktheme() async {
  if (isDarkTheme == true) {
    page = Colors.black;
    textColor = Colors.white;
    buttonColor = Colors.white;
    loaderColor = Colors.white;
    hintColor = Colors.white.withOpacity(0.3);
  } else {
    page = Colors.white;
    textColor = Colors.black;
    buttonColor = theme;
    loaderColor = theme;
    hintColor = const Color(0xff12121D).withOpacity(0.3);
  }
  boxshadow = BoxShadow(
      blurRadius: 2, color: textColor.withOpacity(0.2), spreadRadius: 2);

  if (isDarkTheme == true) {
    await rootBundle.loadString('assets/dark.json').then((value) {
      mapStyle = value;
    });
  } else {
    await rootBundle.loadString('assets/map_style_black.json').then((value) {
      mapStyle = value;
    });
  }
  valueNotifierHome.incrementNotifier();
}

// dynamic timerLocation;
dynamic locationAllowed;

bool positionStreamStarted = false;
StreamSubscription<Position>? positionStream;

LocationSettings locationSettings = (platform == TargetPlatform.android)
    ? AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      )
    : AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 100,
      );

positionStreamData() {
  positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
    positionStream = null;
    positionStream?.cancel();
  }).listen((Position? position) {
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
    } else {
      positionStream!.cancel();
    }
  });
}

//validate email already exist

validateEmail(email) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile'),
        body: (values == 0) ? {'mobile': email} : {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = languages[choosenLanguage]['text_email_already_taken'];
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
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'العربية', 'code': 'ar'},
  {'name': 'English (US)', 'code': 'en'},
];

//getting country code

List countries = [];

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

phoneAuth(String phone) async {
  try {
    credentials = null;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        credentials = credential;
        valueNotifierHome.incrementNotifier();
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          debugPrint('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verId = verificationId;
        resendTokenId = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//get local bearer token

String lastNotification = '';
List recentSearchesList = [];

getLocalData() async {
  dynamic result;
  bearerToken.clear;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (pref.containsKey('lastNotification')) {
      lastNotification = pref.getString('lastNotification');
    }
    if (pref.containsKey('autoAddress')) {
      var val = pref.getString('autoAddress');
      storedAutoAddress = jsonDecode(val);
    }
    if (pref.containsKey('outstationpush')) {
      outStationDriver = await loadListFromPrefs();
    }

    if (pref.containsKey('choosenLanguage')) {
      choosenLanguage = pref.getString('choosenLanguage');
      languageDirection = pref.getString('languageDirection');
      if (choosenLanguage.isNotEmpty) {
        if (pref.containsKey('Bearer')) {
          var tokens = pref.getString('Bearer');
          if (tokens != null) {
            bearerToken.add(BearerClass(type: 'Bearer', token: tokens));
            var responce = await getUserDetails();
            if (responce == true) {
              result = '3';
            } else {
              result = '2';
            }
          } else {
            result = '2';
          }
        } else {
          result = '2';
        }
      } else {
        result = '1';
      }
    } else {
      result = '1';
    }
    if (pref.containsKey('isDarkTheme')) {
      isDarkTheme = pref.getBool('isDarkTheme');
      if (isDarkTheme == true) {
        page = Colors.black;
        textColor = Colors.white;
        buttonColor = Colors.white;
        loaderColor = Colors.white;
        hintColor = Colors.white.withOpacity(0.3);
      } else {
        page = Colors.white;
        textColor = Colors.black;
        buttonColor = theme;
        loaderColor = theme;
        hintColor = const Color(0xff12121D).withOpacity(0.3);
      }
      boxshadow = BoxShadow(
          blurRadius: 2, color: textColor.withOpacity(0.2), spreadRadius: 2);
      if (isDarkTheme == true) {
        mapStyle = await rootBundle.loadString('assets/dark.json');
      } else {
        mapStyle = await rootBundle.loadString('assets/map_style_black.json');
      }
    }
    if (pref.containsKey('recentsearch')) {
      var val = pref.getString('recentsearch');
      recentSearchesList = jsonDecode(val);
    }
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';
      internet = false;
    }
  }
  return result;
}

//register user

List<BearerClass> bearerToken = <BearerClass>[];

void configurePendingUserRegistration({
  required String displayName,
  required String emailAddress,
  required String plainPassword,
  required String mobileNumber,
  required String selectedGender,
  required int countryIndex,
  required String serviceLocationId,
  required String zoneId,
}) {
  name = displayName;
  email = emailAddress;
  password = plainPassword;
  phnumber = mobileNumber;
  gender = selectedGender;
  phcode = countryIndex;
  signupServiceLocationId = serviceLocationId;
  signupZoneId = zoneId;
}

registerUser() async {
  bearerToken.clear();
  dynamic result;
  try {
    String? token;
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        token = await FirebaseMessaging.instance.getToken();
      } else {
        await Future<void>.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          token = await FirebaseMessaging.instance.getToken();
        }
      }
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    var fcm = token.toString();
    final response =
        http.MultipartRequest('POST', Uri.parse('${url}api/v1/user/register'));

    response.headers.addAll({'Content-Type': 'application/json'});
    if (proImageFile1 != null) {
      response.files.add(
          await http.MultipartFile.fromPath('profile_picture', proImageFile1));
    }
    response.fields.addAll({
      "name": name,
      "mobile": phnumber,
      "email": email,
      "password": password,
      "device_token": fcm,
      "country": countries[phcode]['dial_code'],
      "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
      'lang': choosenLanguage,
      'gender': (gender == 'male')
          ? 'male'
          : (gender == 'female')
              ? 'female'
              : 'others',
      'service_location_id': signupServiceLocationId,
      'zone_id': signupZoneId,
    });
    var request = await response.send();
    var respon = await http.Response.fromStream(request);

    if (request.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);
      // if (ischeckownerordriver == 'driver') {
      //   platforms.invokeMethod('login');
      // }
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      pref.setString('Bearer', bearerToken[0].token);
      await getUserDetails();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
      result = 'true';
    } else if (respon.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(respon.body);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

///// Add Balance //////
addBalance(String code) async {
  dynamic result;
  debugPrint('${url}api/v1/user/card-recharge');
  try {
    var response = await http.post(Uri.parse('${url}api/v1/user/card-recharge'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"card_code": code}));
    debugPrint('drops ${response.statusCode}');
    debugPrint('drops ${response.body}');
    if (response.statusCode == 200) {
      result = jsonDecode(response.body)['message'];
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 400) {
      result = languages[choosenLanguage]['card_not_found_text'];
    } else if (response.statusCode == 422) {
      result = languages[choosenLanguage]['card_not_valid'];
    } else {
      debugPrint(response.body);
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//update referral code

updateReferral() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/update/user/referral'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({"refferal_code": referalController.text}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'true';
      } else {
        debugPrint(response.body);
        result = 'false';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

//call firebase otp

otpCall() async {
  dynamic result;
  try {
    var otp = await FirebaseDatabase.instance.ref().child('call_FB_OTP').get();
    result = otp;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no Internet';
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

// verify user already exist

verifyUser(String number, int login, String password, String email, isOtp,
    forgot) async {
  dynamic val;
  debugPrint('drops1 ${url}api/v1/user/validate-mobile-for-login');
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile-for-login'),
        body: (number != '' && email != '')
            ? {"mobile": number, "email": email}
            : (login == 0)
                ? {
                    "mobile": number,
                  }
                : {
                    "email": number,
                  });

    if (response.statusCode == 200) {
      debugPrint('drops2 ');
      val = jsonDecode(response.body)['success'];
      if (val == true) {
        if ((number != '' && email != '') || forgot == true) {
          debugPrint('drops33 ');

          if (forgot == true) {
            val = true;
          } else if (jsonDecode(response.body)['message'] == 'email_exists') {
            val = 'Email Already Exists';
          } else if (jsonDecode(response.body)['message'] == 'mobile_exists') {
            val = 'Mobile Already Exists';
          } else {
            val = 'Email and Mobile Already Exists';
          }
        } else {
          debugPrint('drops4 ');
          var check = await userLogin(number, login, password, isOtp);
          if (check == true) {
            var uCheck = await getUserDetails();
            val = uCheck;
          } else {
            val = check;
          }
        }
      } else {
        debugPrint('drops5 ');
        val = false;
      }
    } else if (response.statusCode == 422) {
      debugPrint('drops ${response.body}');
      var error = jsonDecode(response.body)['errors'];
      val = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint('drops ${response.body}');
      val = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    debugPrint('drops $e');
    if (e is SocketException) {
      val = 'no internet';
      internet = false;
    }
  }
  return val;
}

acceptRequest(body) async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/respond-for-bid'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: body);

    if (response.statusCode == 200) {
      ismulitipleride = true;
      await getUserDetails(id: userRequestData['id']);
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

updatePassword(email, password, loginby) async {
  dynamic result;

  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-password'), body: {
      if (loginby == true) 'email': email,
      if (loginby == false) 'mobile': email,
      'password': password
    });

    print("------>url ${url}api/v1/user/update-password");
    print("------>response ${response.body}");
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = true;
      } else {
        result = jsonDecode(response.body)['message'];
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      try {
        final body = jsonDecode(response.body);
        result = body is Map && body['message'] != null
            ? body['message'].toString()
            : 'تعذر تحديث كلمة المرور.';
      } catch (_) {
        result = 'تعذر تحديث كلمة المرور.';
      }
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//user login
userLogin(number, login, password, isOtp) async {
  bearerToken.clear();
  dynamic result;
  try {
    debugPrint('drops-login ${url}api/v1/user/login');
    String? token;
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        token = await FirebaseMessaging.instance.getToken();
      } else {
        await Future<void>.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          token = await FirebaseMessaging.instance.getToken();
        }
      }
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    var fcm = token.toString();

    var response = await http.post(Uri.parse('${url}api/v1/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: (isOtp == false)
            ? jsonEncode({
                if (login == 0) "mobile": number,
                if (login == 1) "email": number,
                'password': password,
                'device_token': fcm,
                "login_by":
                    (platform == TargetPlatform.android) ? 'android' : 'ios',
              })
            : (login == 0)
                ? jsonEncode({
                    "mobile": number,
                    'device_token': fcm,
                    "login_by": (platform == TargetPlatform.android)
                        ? 'android'
                        : 'ios',
                  })
                : jsonEncode({
                    "email": number,
                    "otp": password,
                    'device_token': fcm,
                    "login_by": (platform == TargetPlatform.android)
                        ? 'android'
                        : 'ios',
                  }));
    debugPrint('drops-login2 ${response.statusCode}');
    if (response.statusCode == 200) {
      debugPrint('drops-login3');

      var jsonVal = jsonDecode(response.body);
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      package = await PackageInfo.fromPlatform();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
    } else if (response.statusCode == 422) {
      debugPrint('drops-login4');

      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint('drops-login5');
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    debugPrint('drops-login6 $e');

    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}
