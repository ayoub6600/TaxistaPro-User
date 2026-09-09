part of '../booking_confirmation.dart';

mixin _BookingConfirmationImmediateRequest
    on State<BookingConfirmation>, _BookingConfirmationController {
  Future<dynamic> submitImmediateRide() async {
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

            result = await createRequest(
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
            result = await createRequest(
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
            result = await createRequest(
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
            result = await createRequest(
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

            result = await createRequest(
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
            result = await createRequest(
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
            result = await createRequest(
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
            result = await createRequest(
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
          result = await createRequest(
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
          result = await createRequest(
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
          result = await createRequest(
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
          result = await createRequest(
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
