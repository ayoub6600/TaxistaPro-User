// ignore_for_file: no_leading_underscores_for_local_identifiers, unrelated_type_equality_checks

part of '../functions.dart';

Map<String, dynamic> userDetails = {};
List favAddress = [];
List tripStops = [];
List banners = [];
bool ismulitipleride = false;
bool polyGot = false;
bool changeBound = false;
//user current state

getUserDetails({id}) async {
  dynamic result;
  try {
    var response = await http.get(
      (ismulitipleride)
          ? Uri.parse('${url}api/v1/user?current_ride=$id')
          : Uri.parse('${url}api/v1/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}'
      },
    );
    if (response.statusCode == 200) {
      userDetails =
          Map<String, dynamic>.from(jsonDecode(response.body)['data']);
      debugPrint('Authenticated API request started');
      print("------>url ${url}api/v1/user?current_ride=$id");
      print("------>banners ${userDetails['bannerImage']['data']}");

      favAddress = userDetails['favouriteLocations']['data'];
      sosData = userDetails['sos']['data'];
      if (mapType == '') {
        mapType = userDetails['map_type'];
      }
      if (outStationPushStream == null) {
        outStationPush();
      }
      if (userDetails['bannerImage']['data'].toString().startsWith('{')) {
        banners.clear();
        banners.add(userDetails['bannerImage']['data']);
        print("------>banners ${banners}");
      } else {
        banners = userDetails['bannerImage']['data'];
      }
      if (userDetails['onTripRequest'] != null) {
        addressList.clear();
        if (userRequestData.isEmpty ||
            userRequestData['accepted_at'] !=
                userDetails['onTripRequest']['data']['accepted_at']) {
          polyline.clear();
          fmpoly.clear();
        } else if (userRequestData.isEmpty ||
            userRequestData['is_driver_arrived'] !=
                userDetails['onTripRequest']['data']['is_driver_arrived']) {
          polyline.clear();
          fmpoly.clear();
        }

        userRequestData = userDetails['onTripRequest']['data'];
        if (userRequestData['is_driver_arrived'] == 1 && polyline.isEmpty) {
          polyGot = true;
          getPolylines('', '', '', '');
          changeBound = true;
        }
        if (userRequestData['transport_type'] == 'taxi') {
          choosenTransportType = 0;
        } else {
          choosenTransportType = 1;
        }
        tripStops =
            userDetails['onTripRequest']['data']['requestStops']['data'];
        addressList.add(AddressList(
            id: '1',
            type: 'pickup',
            address: userRequestData['pick_address'],
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            name: userRequestData['pickup_poc_name'],
            pickup: true,
            number: userRequestData['pickup_poc_mobile'],
            instructions: userRequestData['pickup_poc_instruction']));
        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 2).toString(),
                type: 'drop',
                pickup: false,
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                name: tripStops[i]['poc_name'],
                number: tripStops[i]['poc_mobile'],
                instructions: tripStops[i]['poc_instruction']));
          }
        } else if (userDetails['onTripRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              pickup: false,
              address: userRequestData['drop_address'],
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              name: userRequestData['drop_poc_name'],
              number: userRequestData['drop_poc_mobile'],
              instructions: userRequestData['drop_poc_instruction']));
        }
        // if (userRequestData['accepted_at'] != null) {
        //   getCurrentMessages();
        // }
        if (userRequestData.isNotEmpty) {
          if (rideStreamUpdate == null ||
              rideStreamUpdate?.isPaused == true ||
              rideStreamStart == null ||
              rideStreamStart?.isPaused == true) {
            streamRide();
          }
        } else {
          if (rideStreamUpdate != null ||
              rideStreamUpdate?.isPaused == false ||
              rideStreamStart != null ||
              rideStreamStart?.isPaused == false) {
            rideStreamUpdate?.cancel();
            rideStreamUpdate = null;
            rideStreamStart?.cancel();
            rideStreamStart = null;
          }
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else if (userDetails['metaRequest'] != null) {
        addressList.clear();
        userRequestData = userDetails['metaRequest']['data'];
        tripStops = userDetails['metaRequest']['data']['requestStops']['data'];
        addressList.add(AddressList(
            id: '1',
            type: 'pickup',
            address: userRequestData['pick_address'],
            pickup: true,
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            name: userRequestData['pickup_poc_name'],
            number: userRequestData['pickup_poc_mobile'],
            instructions: userRequestData['pickup_poc_instruction']));

        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 2).toString(),
                type: 'drop',
                pickup: false,
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                name: tripStops[i]['poc_name'],
                number: tripStops[i]['poc_mobile'],
                instructions: tripStops[i]['poc_instruction']));
          }
        } else if (userDetails['metaRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              address: userRequestData['drop_address'],
              pickup: false,
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              name: userRequestData['drop_poc_name'],
              number: userRequestData['drop_poc_mobile'],
              instructions: userRequestData['drop_poc_instruction']));
        }
        if (polyline.isEmpty) {
          polyGot = true;
          getPolylines('', '', '', '');
          changeBound = true;
        }

        if (userRequestData['transport_type'] == 'taxi') {
          choosenTransportType = 0;
        } else {
          choosenTransportType = 1;
        }

        if (requestStreamStart == null ||
            requestStreamStart?.isPaused == true ||
            requestStreamEnd == null ||
            requestStreamEnd?.isPaused == true) {
          streamRequest();
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else {
        chatList.clear();
        if (userRequestData.isNotEmpty) {
          polyline.clear();
          fmpoly.clear();
        }
        userRequestData = {};

        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        rideStreamUpdate?.cancel();
        rideStreamStart?.cancel();
        requestStreamEnd = null;
        requestStreamStart = null;
        rideStreamUpdate = null;
        rideStreamStart = null;
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      }
      if (userDetails['active'] == false) {
        isActive = 'false';
      } else {
        isActive = 'true';
      }
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

class BearerClass {
  final String type;
  final String token;
  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingChat {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingKey {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingLogin {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();
ValueNotifyingChat valueNotifierChat = ValueNotifyingChat();
ValueNotifyingKey valueNotifierKey = ValueNotifyingKey();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();
ValueNotifyingLogin valueNotifierLogin = ValueNotifyingLogin();
ValueNotifyingTimer valueNotifierTimer = ValueNotifyingTimer();

class ValueNotifyingTimer {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

//sound
AudioCache audioPlayer = AudioCache();
AudioPlayer audioPlayers = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

Future<String?> geoCoding(double lat, double lng) async {
  final String cacheKey = '$lat,$lng';
  final Box cacheBox = Hive.box('geocoding_cache');

  // التحقق من الكاش
  final cachedData = cacheBox.get(cacheKey);
  if (cachedData != null) {
    final int cachedTimestamp = cachedData['timestamp'];
    final DateTime cachedTime =
        DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
    final Duration difference = DateTime.now().difference(cachedTime);

    if (difference.inDays < 7) {
      return cachedData['address'];
    } else {
      cacheBox.delete(cacheKey); // حذف الكاش المنتهي
    }
  }

  dynamic result;
  try {
    http.Response val;

    if (mapType == 'google') {
      if (Platform.isAndroid) {
        val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
          headers: {
            'X-Android-Package': packageName,
            'X-Android-Cert': signKey
          },
        );
      } else {
        val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
          headers: {'X-IOS-Bundle-Identifier': packageName},
        );
      }
    } else {
      val = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json'),
      );
    }

    if (val.statusCode == 200) {
      if (mapType == 'google') {
        result = jsonDecode(val.body)['results'][0]['formatted_address'];
      } else {
        result = jsonDecode(val.body)['display_name'].toString();
      }

      // حفظ العنوان في الكاش مع التوقيت
      cacheBox.put(cacheKey, {
        'address': result,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return result;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }

  return result;
}

// geoCoding(double lat, double lng) async {
//   dynamic result;
//   try {
//     http.Response val;

//     if (mapType == 'google') {
//       if (Platform.isAndroid) {
//         val = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
//             headers: {
//               'X-Android-Package': packageName,
//               'X-Android-Cert': signKey
//             });
//       } else {
//         val = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
//             headers: {'X-IOS-Bundle-Identifier': packageName});
//       }
//     } else {
//       val = await http.get(
//         Uri.parse(
//             'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json'),
//       );
//     }
//     if (val.statusCode == 200) {
//       if (mapType == 'google') {
//         result = jsonDecode(val.body)['results'][0]['formatted_address'];
//       } else {
//         result = jsonDecode(val.body)['display_name'].toString();
//       }
//       return result;
//     }
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }

//lang
getlangid() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-my-lang'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bearerToken[0].token}',
            },
            body: jsonEncode({"lang": choosenLanguage}));

    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
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
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get address auto fill data
List storedAutoAddress = [];
List addAutoFill = [];

Future<void> getAutocomplete(input, sessionToken, lat, lng) async {
  final Box cacheBox = Hive.box('autocomplete_cache');
  final String cacheKey = '$input-$lat-$lng';

  addAutoFill.clear();

  // ✅ تحقق من وجود الكاش وصلاحية البيانات (يوم واحد)
  if (cacheBox.containsKey(cacheKey)) {
    final cachedData = cacheBox.get(cacheKey);
    final int timestamp = cachedData['timestamp'] ?? 0;
    final DateTime cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cachedTime).inHours < 24) {
      addAutoFill = List<Map<String, dynamic>>.from(cachedData['data']);
      valueNotifierHome.incrementNotifier();
      return;
    } else {
      cacheBox.delete(cacheKey); // حذف الكاش المنتهي
    }
  }

  try {
    if (mapType == 'google') {
      http.Response val;

      Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapkey&location=$lat%2C$lng&radius=10000&sessionToken=$sessionToken',
      );

      Map<String, String> headers = Platform.isAndroid
          ? {
              'X-Android-Package': packageName,
              'X-Android-Cert': signKey,
            }
          : {
              'X-IOS-Bundle-Identifier': packageName,
            };

      val = await http.get(url, headers: headers);

      if (val.statusCode == 200) {
        var result = jsonDecode(val.body);

        for (var element in result['predictions']) {
          final placeId = element['place_id'];
          final description = element['description'];

          addAutoFill.add({
            'place': placeId,
            'description': description,
            'lat': '',
            'lon': '',
          });

          if (storedAutoAddress.where((e) => e['place'] == placeId).isEmpty) {
            storedAutoAddress.add({
              'place': placeId,
              'description': description,
              'lat': '',
              'lon': '',
            });
          }
        }

        // ✅ حفظ في الكاش
        cacheBox.put(cacheKey, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': addAutoFill,
        });
      }

      pref.setString('autoAddress', jsonEncode(storedAutoAddress));
    } else {
      var result = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$input&format=json'));

      for (var element in jsonDecode(result.body)) {
        addAutoFill.add({
          'place': element['place_id'].toString(),
          'description': element['display_name'],
          'secondary': '',
          'lat': element['lat'],
          'lon': element['lon'],
        });
      }

      // ✅ حفظ في الكاش
      cacheBox.put(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': addAutoFill,
      });
    }

    valueNotifierHome.incrementNotifier();
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

// getAutocomplete(input, sessionToken, lat, lng) async {
//   try {
//     addAutoFill.clear();
//     if (mapType == 'google') {
//       http.Response val;
//       if (Platform.isAndroid) {
//         val = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapkey&location=$lat%2C$lng&radius=10000&sessionToken=$sessionToken'),
//             headers: {
//               'X-Android-Package': packageName,
//               'X-Android-Cert': signKey
//             });
//       } else {
//         val = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapkey&location=$lat%2C$lng&radius=10000&sessionToken=$sessionToken'),
//             headers: {'X-IOS-Bundle-Identifier': packageName});
//       }

//       if (val.statusCode == 200) {
//         var result = jsonDecode(val.body);
//         for (var element in result['predictions']) {
//           addAutoFill.add({
//             'place': element['place_id'],
//             'description': element['description'],
//             'lat': '',
//             'lon': ''
//           });
//           if (storedAutoAddress
//               .where((element) => element['place'] == element['place_id'])
//               .isEmpty) {
//             storedAutoAddress.add({
//               'place': element['place_id'],
//               'description': element['description'],
//               'lat': '',
//               'lon': ''
//             });
//           }
//         }
//       }

//       pref.setString('autoAddress', jsonEncode(storedAutoAddress).toString());
//     } else {
//       var result = await http.get(Uri.parse(
//           'https://nominatim.openstreetmap.org/search?q=$input&format=json'));
//       for (var element in jsonDecode(result.body)) {
//         addAutoFill.add({
//           'place': element['place_id'],
//           'description': element['display_name'],
//           'secondary': '',
//           'lat': element['lat'],
//           'lon': element['lon']
//         });
//       }
//     }
//     valueNotifierHome.incrementNotifier();
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//     }
//   }
// }

// geoCodingForLatLng(id, sessionToken) async {
//   try {
//     http.Response val;
//     if (Platform.isAndroid) {
//       val = await http.get(
//           Uri.parse(
//               'https://maps.googleapis.com/maps/api/place/details/json?placeid=$id&key=$mapkey&sessionToken=$sessionToken'),
//           headers: {
//             'X-Android-Package': packageName,
//             'X-Android-Cert': signKey
//           });
//     } else {
//       val = await http.get(
//           Uri.parse(
//               'https://maps.googleapis.com/maps/api/place/details/json?placeid=$id&key=$mapkey&sessionToken=$sessionToken'),
//           headers: {'X-IOS-Bundle-Identifier': packageName});
//     }

//     if (val.statusCode == 200) {
//       var result = jsonDecode(val.body)['result']['geometry']['location'];
//       return result;
//     }
//   } catch (e) {
//     debugPrint(e.toString());
//   }
// }
Future<Map<String, dynamic>?> geoCodingForLatLng(
    String id, String sessionToken) async {
  final Box cacheBox = Hive.box('geocoding_cache');
  final String cacheKey = 'place_details_$id';

  // ✅ تحقق من الكاش
  if (cacheBox.containsKey(cacheKey)) {
    final cachedData = cacheBox.get(cacheKey);
    final int timestamp = cachedData['timestamp'] ?? 0;
    final DateTime cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    if (DateTime.now().difference(cachedTime).inDays < 7) {
      return Map<String, dynamic>.from(cachedData['data']);
    } else {
      cacheBox.delete(cacheKey); // الكاش منتهي الصلاحية
    }
  }

  try {
    http.Response val;

    Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$id&key=$mapkey&sessionToken=$sessionToken');

    Map<String, String> headers = Platform.isAndroid
        ? {
            'X-Android-Package': packageName,
            'X-Android-Cert': signKey,
          }
        : {
            'X-IOS-Bundle-Identifier': packageName,
          };

    val = await http.get(url, headers: headers);

    if (val.statusCode == 200) {
      var result = jsonDecode(val.body)['result']['geometry']['location'];

      // ✅ تخزين في الكاش
      cacheBox.put(cacheKey, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': result,
      });

      return Map<String, dynamic>.from(result);
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return null;
}

//pickup drop address list

class AddressList {
  String address;
  LatLng latlng;
  String id;
  dynamic type;
  dynamic name;
  dynamic number;
  dynamic instructions;
  bool pickup;

  AddressList(
      {required this.id,
      required this.address,
      required this.latlng,
      required this.pickup,
      this.type,
      this.name,
      this.number,
      this.instructions});

  toJson() {}
}

//get polylines
String polyString = '';
List<LatLng> polyList = [];
int _polylineRequestGeneration = 0;
