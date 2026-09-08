// ignore_for_file: no_leading_underscores_for_local_identifiers, unrelated_type_equality_checks

part of '../functions.dart';

Future<List> getPolylines(plat, plng, dlat, dlng) async {
  final requestGeneration = ++_polylineRequestGeneration;
  final routePoints = <LatLng>[];
  final Box cacheBox = Hive.box('geocoding_cache');

  String pickLat = '';
  String pickLng = '';
  String dropLat = '';
  String dropLng = '';

  if (plat == '' && dlat == '') {
    if (userRequestData.isEmpty ||
        userRequestData['poly_line'] == null ||
        userRequestData['poly_line'] == '') {
      for (var i = 1; i < addressList.length; i++) {
        pickLat = addressList[i - 1].latlng.latitude.toString();
        pickLng = addressList[i - 1].latlng.longitude.toString();
        dropLat = addressList[i].latlng.latitude.toString();
        dropLng = addressList[i].latlng.longitude.toString();

        String cacheKey = 'polyline_${pickLat}_$pickLng|${dropLat}_$dropLng';

        if (cacheBox.containsKey(cacheKey)) {
          polyString = cacheBox.get(cacheKey);
          _appendRouteSegment(routePoints, decodePolylinePoints(polyString));
          continue;
        }

        try {
          http.Response value;

          Uri url = Uri.parse(
              'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey');

          Map<String, String> headers = Platform.isAndroid
              ? {
                  'X-Android-Package': packageName,
                  'X-Android-Cert': signKey,
                }
              : {
                  'X-IOS-Bundle-Identifier': packageName,
                };

          value = await http.get(url, headers: headers);

          if (value.statusCode == 200) {
            var steps = jsonDecode(value.body)['routes'][0]['overview_polyline']
                ['points'];

            if (i == 1) {
              polyString = steps;
            } else {
              polyString = '${polyString}poly$steps';
            }

            _appendRouteSegment(routePoints, decodePolylinePoints(steps));
            cacheBox.put(cacheKey, steps);
          }
        } catch (e) {
          if (e is SocketException) {
            internet = false;
          }
        }
      }
    } else {
      List poly = userRequestData['poly_line'].toString().split('poly');
      for (var i = 0; i < poly.length; i++) {
        _appendRouteSegment(routePoints, decodePolylinePoints(poly[i]));
      }
    }
  } else {
    String cacheKey = 'polyline_${plat}_$plng|${dlat}_$dlng';

    if (cacheBox.containsKey(cacheKey)) {
      polyString = cacheBox.get(cacheKey);
      _appendRouteSegment(routePoints, decodePolylinePoints(polyString));
    } else {
      try {
        http.Response value;

        Uri url = Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?origin=$plat%2C$plng&destination=$dlat%2C$dlng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey');

        Map<String, String> headers = Platform.isAndroid
            ? {
                'X-Android-Package': packageName,
                'X-Android-Cert': signKey,
              }
            : {
                'X-IOS-Bundle-Identifier': packageName,
              };

        value = await http.get(url, headers: headers);

        if (value.statusCode == 200) {
          var steps = jsonDecode(value.body)['routes'][0]['overview_polyline']
              ['points'];

          polyString = steps;
          _appendRouteSegment(routePoints, decodePolylinePoints(steps));

          cacheBox.put(cacheKey, steps);
        }
      } catch (e) {
        if (e is SocketException) {
          internet = false;
        }
      }
    }
  }

  // Route requests can overlap during rebuilds and driver updates. Only the
  // newest complete response is allowed to paint the map; otherwise points
  // from two responses get joined by an incorrect straight line.
  if (requestGeneration == _polylineRequestGeneration) {
    await _paintRouteProgressively(routePoints, requestGeneration);
  }

  polyGot = false;
  return polyList;
}

// getPolylines(plat, plng, dlat, dlng) async {
//   polyList.clear();
//   String pickLat = '';
//   String pickLng = '';
//   String dropLat = '';

//   String dropLng = '';
//   if (plat == '' && dlat == '') {
//     if (userRequestData.isEmpty ||
//         userRequestData['poly_line'] == null ||
//         userRequestData['poly_line'] == '') {
//       for (var i = 1; i < addressList.length; i++) {
//         pickLat = addressList[i - 1].latlng.latitude.toString();
//         pickLng = addressList[i - 1].latlng.longitude.toString();
//         dropLat = addressList[i].latlng.latitude.toString();
//         dropLng = addressList[i].latlng.longitude.toString();
//         try {
//           http.Response value;

//           if (Platform.isIOS) {
//             value = await http.get(
//                 Uri.parse(
//                     'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey'),
//                 headers: {
//                   'X-Android-Package': packageName,
//                   'X-Android-Cert': signKey
//                 });
//           } else {
//             value = await http.get(
//                 Uri.parse(
//                     'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey'),
//                 headers: {'X-IOS-Bundle-Identifier': packageName});
//           }

//           if (value.statusCode == 200) {
//             debugPrint('stepsoto ${value.body}');
//             var steps = jsonDecode(value.body)['routes'][0]['overview_polyline']
//                 ['points'];
//             debugPrint('stepsoto $steps');
//             if (i == 1) {
//               polyString = steps;
//             } else {
//               polyString = '${polyString}poly$steps';
//             }
//             decodeEncodedPolyline(steps);
//           } else {}
//         } catch (e) {
//           if (e is SocketException) {
//             internet = false;
//           }
//         }
//       }
//     } else {
//       List poly = userRequestData['poly_line'].toString().split('poly');
//       for (var i = 0; i < poly.length; i++) {
//         decodeEncodedPolyline(poly[i]);
//       }
//     }
//   } else {
//     try {
//       http.Response value;

//       if (Platform.isAndroid) {
//         value = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/directions/json?origin=$plat%2C$plng&destination=$dlat%2C$dlng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey'),
//             headers: {
//               'X-Android-Package': packageName,
//               'X-Android-Cert': signKey
//             });
//       } else {
//         value = await http.get(
//             Uri.parse(
//                 'https://maps.googleapis.com/maps/api/directions/json?origin=$plat%2C$plng&destination=$dlat%2C$dlng&avoid=ferries|indoor&alternatives=true&mode=driving&key=$mapkey'),
//             headers: {'X-IOS-Bundle-Identifier': packageName});
//       }
//       if (value.statusCode == 200) {
//         var steps =
//             jsonDecode(value.body)['routes'][0]['overview_polyline']['points'];

//         // debugPrintWrapped(steps.toString());
//         polyString = steps;
//         decodeEncodedPolyline(steps);
//       } else {}
//     } catch (e) {
//       if (e is SocketException) {
//         internet = false;
//       }
//     }
//   }
//   polyGot = false;
//   return polyList;
// }

class RouteInfo {
  final int distance;
  final String summary;
  final List steps;

  RouteInfo({
    required this.distance,
    required this.summary,
    required this.steps,
  });
}

//polyline decode

Set<Polyline> polyline = {};

List<LatLng> decodePolylinePoints(String encoded) {
  final points = <LatLng>[];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
  }

  return points;
}

void _appendRouteSegment(List<LatLng> route, List<LatLng> segment) {
  if (segment.isEmpty) return;
  final startsAtPreviousPoint = route.isNotEmpty && route.last == segment.first;
  route.addAll(startsAtPreviousPoint ? segment.skip(1) : segment);
}

Future<void> _paintRouteProgressively(
    List<LatLng> route, int requestGeneration) async {
  polyList = List<LatLng>.from(route);
  if (route.length < 2) {
    polyline.clear();
    valueNotifierBook.incrementNotifier();
    return;
  }

  const frameCount = 14;
  for (var frame = 1; frame <= frameCount; frame++) {
    if (requestGeneration != _polylineRequestGeneration) return;
    final visibleCount = ((route.length * frame) / frameCount)
        .ceil()
        .clamp(2, route.length)
        .toInt();
    polyline = {
      Polyline(
        polylineId: const PolylineId('active_route'),
        color: const Color(0xFF1677FF),
        visible: true,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        points: route.take(visibleCount).toList(growable: false),
      ),
    };
    valueNotifierBook.incrementNotifier();
    if (frame != frameCount) {
      await Future<void>.delayed(const Duration(milliseconds: 22));
    }
  }
}

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  final points = decodePolylinePoints(encoded);
  polyList = List<LatLng>.from(points);

  polyline = {
    Polyline(
      polylineId: const PolylineId('active_route'),
      color: const Color(0xFF1677FF),
      visible: true,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      points: polyList,
    ),
  };

  valueNotifierBook.incrementNotifier();
  return points
      .map((point) => PointLatLng(point.latitude, point.longitude))
      .toList(growable: false);
}

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      // ignore: unnecessary_null_comparison
      : assert(latitude != null),
        // ignore: unnecessary_null_comparison
        assert(longitude != null),
        // ignore: unnecessary_this, prefer_initializing_formals
        this.latitude = latitude,
        // ignore: unnecessary_this, prefer_initializing_formals
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}

//get goods list
List goodsTypeList = [];

getGoodsList() async {
  dynamic result;
  goodsTypeList.clear();
  try {
    var response = await http.get(Uri.parse('${url}api/v1/common/goods-types'));
    if (response.statusCode == 200) {
      goodsTypeList = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//drop stops list
List<DropStops> dropStopList = <DropStops>[];

class DropStops {
  String order;
  double latitude;
  double longitude;
  String? pocName;
  String? pocNumber;
  dynamic pocInstruction;
  String address;

  DropStops(
      {required this.order,
      required this.latitude,
      required this.longitude,
      this.pocName,
      this.pocNumber,
      this.pocInstruction,
      required this.address});

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'poc_name': pocName,
        'poc_mobile': pocNumber,
        'poc_instruction': pocInstruction,
        'address': address,
      };
}

List etaDetails = [];

//eta request

etaRequest({transport, outstation}) async {
  etaDetails.clear();
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: (addressList
                    .where((element) => element.type == 'drop')
                    .isNotEmpty &&
                dropStopList.isEmpty)
            ? jsonEncode({
                'pick_lat': (userRequestData.isNotEmpty)
                    ? userRequestData['pick_lat']
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude,
                'pick_lng': (userRequestData.isNotEmpty)
                    ? userRequestData['pick_lng']
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude,
                'drop_lat': (userRequestData.isNotEmpty)
                    ? userRequestData['drop_lat']
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude,
                'drop_lng': (userRequestData.isNotEmpty)
                    ? userRequestData['drop_lng']
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude,
                'ride_type': 1,
                'transport_type': (transport == null)
                    ? (choosenTransportType == 0)
                        ? 'taxi'
                        : 'delivery'
                    : transport,
                'is_outstation': outstation
              })
            : (dropStopList.isNotEmpty &&
                    addressList
                        .where((element) => element.type == 'drop')
                        .isNotEmpty)
                ? jsonEncode({
                    'pick_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lat']
                        : addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .latlng
                            .latitude,
                    'pick_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lng']
                        : addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .latlng
                            .longitude,
                    'drop_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['drop_lat']
                        : addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .latitude,
                    'drop_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['drop_lng']
                        : addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .longitude,
                    'stops': jsonEncode(dropStopList),
                    'ride_type': 1,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    'is_outstation': outstation
                  })
                : jsonEncode({
                    'pick_lat': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lat']
                        : addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .latlng
                            .latitude,
                    'pick_lng': (userRequestData.isNotEmpty)
                        ? userRequestData['pick_lng']
                        : addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .latlng
                            .longitude,
                    'ride_type': 1,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    'is_outstation': outstation
                  }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      if (etaDetails.isEmpty) {
        serviceNotAvailable = true;
        debugPrint(
            'ETA returned no active vehicle types for the selected zone.');
        valueNotifierBook.incrementNotifier();
        valueNotifierHome.incrementNotifier();
        return false;
      }
      choosenVehicle = (etaDetails
              .where((element) => element['is_default'] == true)
              .isNotEmpty)
          ? etaDetails.indexWhere((element) => element['is_default'] == true)
          : 0;
      result = true;
      valueNotifierBook.incrementNotifier();
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] ==
          "service not available with this location") {
        serviceNotAvailable = true;
      }
      result = false;
    }
    return result;
  } catch (e) {
    debugPrint('ETA request failed: $e');
    if (e is SocketException) {
      internet = false;
    }
    return false;
  }
}

etaRequestWithPromo({outstation}) async {
  dynamic result;
  // etaDetails.clear();
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: (addressList
                    .where((element) => element.type == 'drop')
                    .isNotEmpty &&
                dropStopList.isEmpty)
            ? jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'drop_lat': addressList
                    .firstWhere((e) => e.type == 'drop')
                    .latlng
                    .latitude,
                'drop_lng': addressList
                    .firstWhere((e) => e.type == 'drop')
                    .latlng
                    .longitude,
                'ride_type': 1,
                'promo_code': promoCode,
                'transport_type':
                    (choosenTransportType == 0) ? 'taxi' : 'delivery',
                'is_outstation': outstation
              })
            : (dropStopList.isNotEmpty &&
                    addressList
                        .where((element) => element.type == 'drop')
                        .isNotEmpty)
                ? jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude,
                    'drop_lat': addressList
                        .firstWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude,
                    'drop_lng': addressList
                        .firstWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude,
                    'stops': jsonEncode(dropStopList),
                    'ride_type': 1,
                    'promo_code': promoCode,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    'is_outstation': outstation
                  })
                : jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude,
                    'ride_type': 1,
                    'promo_code': promoCode,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery',
                    'is_outstation': outstation
                  }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      // promoCode = '';
      couponerror = true;
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

//rental eta request

rentalEta() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/list-packages'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'pick_lat': (userRequestData.isNotEmpty)
                  ? userRequestData['pick_lat']
                  : addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
              'pick_lng': (userRequestData.isNotEmpty)
                  ? userRequestData['pick_lng']
                  : addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .longitude,
              'transport_type':
                  (choosenTransportType == 0) ? 'taxi' : 'delivery'
            }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      choosenVehicle = 0;
      result = true;
      valueNotifierBook.incrementNotifier();
      // debugPrintWrapped('rental eta ' + response.body);
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = false;
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

bool couponerror = false;
rentalRequestWithPromo() async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/request/list-packages'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
          'pick_lng': addressList
              .firstWhere((e) => e.type == 'pickup')
              .latlng
              .longitude,
          'ride_type': 1,
          'promo_code': promoCode,
          'transport_type': (choosenTransportType == 0) ? 'taxi' : 'delivery'
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      couponerror = true;
      // promoCode = '';
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

//calculate distance

calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}
