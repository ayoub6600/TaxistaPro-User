part of '../booking_confirmation.dart';

mixin _BookingConfirmationImmediateRequest
    on State<BookingConfirmation>, _BookingConfirmationController {
  double? _riderOfferFare;

  Future<dynamic> postImmediateRequest(String payload, String endpoint) async {
    if (_riderOfferFare == null) return createRequest(payload, endpoint);
    final fields = Map<String, dynamic>.from(jsonDecode(payload));
    final fair =
        double.tryParse(fields['request_eta_amount']?.toString() ?? '') ?? 0;
    if (fields.containsKey('drop_lat') &&
        fair > 0 &&
        (_riderOfferFare! - fair).abs() > 0.01) {
      final originalToken =
          etaDetails[choosenVehicle]['fare_quote_token']?.toString();
      if (currentImmediateFareQuote(originalToken, fields)) {
        // Preserve the displayed fair fare. A valid signed quote is already
        // sufficient; fetching ETA again may produce a different route price.
        fields['fare_quote_token'] = originalToken;
      } else {
        // Refresh only an expired/route-changed quote using this booking's route.
        final etaInput = immediateOfferQuoteInput(fields);
        try {
          final response =
              await http.post(Uri.parse('${url}api/v1/request/eta'),
                  headers: {
                    'Authorization': 'Bearer ${bearerToken[0].token}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(etaInput));
          if (response.statusCode != 200) {
            tripError = languages[choosenLanguage]['text_something_went_wrong'];
            tripReqError = true;
            return 'quote_unavailable';
          }
          final quotes = jsonDecode(response.body)['data'] as List;
          final selected = quotes.cast<Map>().where((quote) =>
              quote['zone_type_id'].toString() ==
              fields['vehicle_type'].toString());
          if (selected.isEmpty || selected.first['fare_quote_token'] == null) {
            tripError = languages[choosenLanguage]['text_something_went_wrong'];
            tripReqError = true;
            return 'quote_unavailable';
          }
          final fresh = selected.first;
          final freshFair =
              double.tryParse(fresh['total']?.toString() ?? '') ?? 0;
          if ((freshFair - fair).abs() > 0.02) {
            etaDetails[choosenVehicle] = fresh;
            tripError = languageDirection == 'rtl'
                ? 'تغيّر السعر العادل إلى ${freshFair.toStringAsFixed(2)}. راجع عرضك ثم اطلب الرحلة.'
                : 'The fair fare changed to ${freshFair.toStringAsFixed(2)}. Review your offer and book again.';
            tripReqError = true;
            valueNotifierBook.incrementNotifier();
            return 'quote_changed';
          }
          fields['fare_quote_token'] = fresh['fare_quote_token'];
        } catch (error) {
          debugPrint('Unable to refresh booking quote: $error');
          tripError = languages[choosenLanguage]['text_something_went_wrong'];
          tripReqError = true;
          return 'quote_unavailable';
        }
      }
      // This is a rider proposal on a normal realtime request, not the old
      // bid-meta auction flow. The two workflows must not share is_bid_ride.
      applyImmediateRiderProposal(fields, _riderOfferFare!);
    }
    return createRequest(jsonEncode(fields), endpoint);
  }

  Future<dynamic> submitImmediateRide({double? offerFare}) async {
    _riderOfferFare = offerFare;
    dynamic result;
    print('isOutStation16');

    print("------>url ${url}api/v1/request/delivery/create");
    if (widget.type != 1) {
      if (etaDetails[choosenVehicle]['has_discount'] == false) {
        if (choosenTransportType == 0) {
          dropStopList.clear();
          if (addressList.length > 2) {
            for (var i = 1; i < addressList.length; i++) {
              dropStopList.add(DropStops(
                order: addressList[i].id,
                latitude: addressList[i].latlng.latitude,
                longitude: addressList[i].latlng.longitude,
                address: addressList[i].address,
              ));
            }

            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
                  'pick_lng': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .longitude,
                  'drop_lat': addressList
                      .lastWhere((e) => e.type == 'drop')
                      .latlng
                      .latitude,
                  'drop_lng': addressList
                      .lastWhere((e) => e.type == 'drop')
                      .latlng
                      .longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'stops': jsonEncode(dropStopList),
                  'pick_address':
                      addressList.firstWhere((e) => e.type == 'pickup').address,
                  'drop_address':
                      addressList.lastWhere((e) => e.type == 'drop').address,
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'poly_line': polyString,
                  'is_pet_available':
                      (addPetPreferences == false) ? false : true,
                  'is_luggage_available':
                      (addLuggagePreferences == false) ? false : true
                }),
                'api/v1/request/create');
          } else {
            result = await postImmediateRequest(
                (addressList
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
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .latitude,
                        'drop_lng': addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .longitude,
                        'vehicle_type': etaDetails[choosenVehicle]
                            ['zone_type_id'],
                        'ride_type': 1,
                        'payment_opt': (etaDetails[choosenVehicle]
                                        ['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'card')
                            ? 0
                            : (etaDetails[choosenVehicle]['payment_type']
                                        .toString()
                                        .split(',')
                                        .toList()[payingVia] ==
                                    'cash')
                                ? 1
                                : 2,
                        'pick_address': addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .address,
                        'drop_address': addressList
                            .lastWhere((e) => e.type == 'drop')
                            .address,
                        'request_eta_amount': etaDetails[choosenVehicle]
                            ['total'],
                        'poly_line': polyString,
                        'is_pet_available':
                            (addPetPreferences == false) ? false : true,
                        'is_luggage_available':
                            (addLuggagePreferences == false) ? false : true
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
                        'vehicle_type': etaDetails[choosenVehicle]
                            ['zone_type_id'],
                        'ride_type': 1,
                        'payment_opt': (etaDetails[choosenVehicle]
                                        ['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'card')
                            ? 0
                            : (etaDetails[choosenVehicle]['payment_type']
                                        .toString()
                                        .split(',')
                                        .toList()[payingVia] ==
                                    'cash')
                                ? 1
                                : 2,
                        'pick_address': addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .address,
                        'request_eta_amount': etaDetails[choosenVehicle]
                            ['total'],
                        'is_pet_available':
                            (addPetPreferences == false) ? false : true,
                        'is_luggage_available':
                            (addLuggagePreferences == false) ? false : true
                      }),
                'api/v1/request/create');
          }
        } else {
          if (dropStopList.isNotEmpty) {
            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'pick_address': addressList[0].address,
                  'drop_address': addressList[addressList.length - 1].address,
                  'poly_line': polyString,
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'pickup_poc_name': addressList[0].name,
                  'pickup_poc_mobile': addressList[0].number,
                  'pickup_poc_instruction': addressList[0].instructions,
                  'drop_poc_name': addressList[addressList.length - 1].name,
                  'drop_poc_mobile': addressList[addressList.length - 1].number,
                  'drop_poc_instruction':
                      addressList[addressList.length - 1].instructions,
                  'goods_type_id': selectedGoodsId.toString(),
                  'stops': jsonEncode(dropStopList),
                  'goods_type_quantity': goodsSize
                }),
                'api/v1/request/delivery/create');
          } else {
            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'pick_address': addressList[0].address,
                  'drop_address': addressList[addressList.length - 1].address,
                  'poly_line': polyString,
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'pickup_poc_name': addressList[0].name,
                  'pickup_poc_mobile': addressList[0].number,
                  'pickup_poc_instruction': addressList[0].instructions,
                  'drop_poc_name': addressList[addressList.length - 1].name,
                  'drop_poc_mobile': addressList[addressList.length - 1].number,
                  'drop_poc_instruction':
                      addressList[addressList.length - 1].instructions,
                  'goods_type_id': selectedGoodsId.toString(),
                  'goods_type_quantity': goodsSize
                }),
                'api/v1/request/delivery/create');
          }
        }
      } else {
        if (choosenTransportType == 0) {
          dropStopList.clear();
          if (addressList.length > 2) {
            for (var i = 1; i < addressList.length; i++) {
              dropStopList.add(DropStops(
                order: addressList[i].id,
                latitude: addressList[i].latlng.latitude,
                longitude: addressList[i].latlng.longitude,
                address: addressList[i].address,
              ));
            }

            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
                  'pick_lng': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .longitude,
                  'drop_lat': addressList
                      .lastWhere((e) => e.type == 'drop')
                      .latlng
                      .latitude,
                  'drop_lng': addressList
                      .lastWhere((e) => e.type == 'drop')
                      .latlng
                      .longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'stops': jsonEncode(dropStopList),
                  'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                  'pick_address':
                      addressList.firstWhere((e) => e.type == 'pickup').address,
                  'drop_address':
                      addressList.lastWhere((e) => e.type == 'drop').address,
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'discounted_total': etaDetails[choosenVehicle]
                      ['discounted_totel'],
                  'poly_line': polyString,
                  'is_pet_available':
                      (addPetPreferences == false) ? false : true,
                  'is_luggage_available':
                      (addLuggagePreferences == false) ? false : true
                }),
                'api/v1/request/create');
          } else {
            result = await postImmediateRequest(
                (addressList
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
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .latitude,
                        'drop_lng': addressList
                            .lastWhere((e) => e.type == 'drop')
                            .latlng
                            .longitude,
                        'vehicle_type': etaDetails[choosenVehicle]
                            ['zone_type_id'],
                        'ride_type': 1,
                        'payment_opt': (etaDetails[choosenVehicle]
                                        ['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'card')
                            ? 0
                            : (etaDetails[choosenVehicle]['payment_type']
                                        .toString()
                                        .split(',')
                                        .toList()[payingVia] ==
                                    'cash')
                                ? 1
                                : 2,
                        'pick_address': addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .address,
                        'drop_address': addressList
                            .lastWhere((e) => e.type == 'drop')
                            .address,
                        'promocode_id': etaDetails[choosenVehicle]
                            ['promocode_id'],
                        'request_eta_amount': etaDetails[choosenVehicle]
                            ['total'],
                        'discounted_total': etaDetails[choosenVehicle]
                            ['discounted_totel'],
                        'poly_line': polyString,
                        'is_pet_available':
                            (addPetPreferences == false) ? false : true,
                        'is_luggage_available':
                            (addLuggagePreferences == false) ? false : true
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
                        'vehicle_type': etaDetails[choosenVehicle]
                            ['zone_type_id'],
                        'ride_type': 1,
                        'payment_opt': (etaDetails[choosenVehicle]
                                        ['payment_type']
                                    .toString()
                                    .split(',')
                                    .toList()[payingVia] ==
                                'card')
                            ? 0
                            : (etaDetails[choosenVehicle]['payment_type']
                                        .toString()
                                        .split(',')
                                        .toList()[payingVia] ==
                                    'cash')
                                ? 1
                                : 2,
                        'pick_address': addressList
                            .firstWhere((e) => e.type == 'pickup')
                            .address,
                        'promocode_id': etaDetails[choosenVehicle]
                            ['promocode_id'],
                        'request_eta_amount': etaDetails[choosenVehicle]
                            ['total'],
                        'discounted_total': etaDetails[choosenVehicle]
                            ['discounted_totel'],
                        'is_pet_available':
                            (addPetPreferences == false) ? false : true,
                        'is_luggage_available':
                            (addLuggagePreferences == false) ? false : true
                      }),
                'api/v1/request/create');
          }
        } else {
          if (dropStopList.isNotEmpty) {
            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'pick_address': addressList[0].address,
                  'drop_address': addressList[addressList.length - 1].address,
                  'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'pickup_poc_name': addressList[0].name,
                  'pickup_poc_mobile': addressList[0].number,
                  'pickup_poc_instruction': addressList[0].instructions,
                  'drop_poc_name': addressList[addressList.length - 1].name,
                  'drop_poc_mobile': addressList[addressList.length - 1].number,
                  'drop_poc_instruction':
                      addressList[addressList.length - 1].instructions,
                  'goods_type_id': selectedGoodsId.toString(),
                  'stops': jsonEncode(dropStopList),
                  'goods_type_quantity': goodsSize,
                  'discounted_total': etaDetails[choosenVehicle]
                      ['discounted_totel'],
                  'poly_line': polyString
                }),
                'api/v1/request/delivery/create');
          } else {
            result = await postImmediateRequest(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                              .toString()
                              .split(',')
                              .toList()[payingVia] ==
                          'card')
                      ? 0
                      : (etaDetails[choosenVehicle]['payment_type']
                                  .toString()
                                  .split(',')
                                  .toList()[payingVia] ==
                              'cash')
                          ? 1
                          : 2,
                  'pick_address': addressList[0].address,
                  'drop_address': addressList[addressList.length - 1].address,
                  'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'pickup_poc_name': addressList[0].name,
                  'pickup_poc_mobile': addressList[0].number,
                  'pickup_poc_instruction': addressList[0].instructions,
                  'drop_poc_name': addressList[addressList.length - 1].name,
                  'drop_poc_mobile': addressList[addressList.length - 1].number,
                  'drop_poc_instruction':
                      addressList[addressList.length - 1].instructions,
                  'goods_type_id': selectedGoodsId.toString(),
                  'goods_type_quantity': goodsSize,
                  'discounted_total': etaDetails[choosenVehicle]
                      ['discounted_totel'],
                  'poly_line': polyString
                }),
                'api/v1/request/delivery/create');
          }
        }
      }
    } else {
      print('isOutStation17');
      if (rentalOption[choosenVehicle]['has_discount'] == false) {
        if (choosenTransportType == 0) {
          result = await postImmediateRequest(
              jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                'ride_type': 1,
                'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] ==
                        'card')
                    ? 0
                    : (rentalOption[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'cash')
                        ? 1
                        : 2,
                'pick_address':
                    addressList.firstWhere((e) => e.type == 'pickup').address,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'is_pet_available': (addPetPreferences == false) ? false : true,
                'is_luggage_available':
                    (addLuggagePreferences == false) ? false : true
              }),
              'api/v1/request/create');
        } else {
          result = await postImmediateRequest(
              jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                'ride_type': 1,
                'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] ==
                        'card')
                    ? 0
                    : (rentalOption[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'cash')
                        ? 1
                        : 2,
                'pick_address':
                    addressList.firstWhere((e) => e.type == 'pickup').address,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'pickup_poc_name': addressList[0].name,
                'pickup_poc_mobile': addressList[0].number,
                'pickup_poc_instruction': addressList[0].instructions,
                'goods_type_id': selectedGoodsId.toString(),
                'goods_type_quantity': goodsSize
              }),
              'api/v1/request/delivery/create');
        }
      } else {
        print('isOutStation18');
        print("------>url ${url}api/v1/request/create");
        if (choosenTransportType == 0) {
          result = await postImmediateRequest(
              jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                'ride_type': 1,
                'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] ==
                        'card')
                    ? 0
                    : (rentalOption[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'cash')
                        ? 1
                        : 2,
                'pick_address':
                    addressList.firstWhere((e) => e.type == 'pickup').address,
                'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'discounted_total': rentalOption[choosenVehicle]
                    ['discounted_totel'],
                'is_pet_available': (addPetPreferences == false) ? false : true,
                'is_luggage_available':
                    (addLuggagePreferences == false) ? false : true
              }),
              'api/v1/request/create');
        } else {
          print('isOutStation19');
          result = await postImmediateRequest(
              jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
                'ride_type': 1,
                'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                            .toString()
                            .split(',')
                            .toList()[payingVia] ==
                        'card')
                    ? 0
                    : (rentalOption[choosenVehicle]['payment_type']
                                .toString()
                                .split(',')
                                .toList()[payingVia] ==
                            'cash')
                        ? 1
                        : 2,
                'pick_address':
                    addressList.firstWhere((e) => e.type == 'pickup').address,
                'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'goods_type_id': selectedGoodsId.toString(),
                'goods_type_quantity': goodsSize,
                'pickup_poc_name': addressList[0].name,
                'pickup_poc_mobile': addressList[0].number,
                'pickup_poc_instruction': addressList[0].instructions,
                'discounted_total': rentalOption[choosenVehicle]
                    ['discounted_totel']
              }),
              'api/v1/request/delivery/create');
        }
      }
    }
    return result;
  }
}
