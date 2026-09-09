part of '../booking_confirmation.dart';

mixin _BookingConfirmationScheduledRequest
    on State<BookingConfirmation>, _BookingConfirmationController {
  Future<void> submitScheduledRide() async {
    if (widget.type != 1) {
      if (etaDetails[choosenVehicle]['has_discount'] == false) {
        dynamic val;
        setState(() {
          isLoading = true;
        });
        if (choosenTransportType == 0) {
          print('createRequestLater 1234');
          var jsonPayload = (addressList
                  .where((element) => element.type == 'drop')
                  .isNotEmpty)
              ? {
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
                  'poly_line': polyString,
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
                  'pick_address':
                      addressList.firstWhere((e) => e.type == 'pickup').address,
                  'drop_address':
                      addressList.firstWhere((e) => e.type == 'drop').address,
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': 1,
                  'stops': jsonEncode(dropStopList),
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'is_pet_available':
                      (addPetPreferences == false) ? false : true,
                  'is_luggage_available':
                      (addLuggagePreferences == false) ? false : true
                }
              : {
                  'pick_lat': addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
                  'pick_lng': addressList
                      .firstWhere((e) => e.type == 'pickup')
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
                  'pick_address':
                      addressList.firstWhere((e) => e.type == 'pickup').address,
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': 1,
                  'request_eta_amount': etaDetails[choosenVehicle]['total'],
                  'is_pet_available':
                      (addPetPreferences == false) ? false : true,
                  'is_luggage_available':
                      (addLuggagePreferences == false) ? false : true
                };

          print('JSON Payload: $jsonPayload');

          val = await createRequestLater(
              jsonEncode(jsonPayload), 'api/v1/request/create');

          print("------------>11111");
        } else {
          print("------------>22222");
          if (dropStopList.isNotEmpty) {
            val = await createRequestLater(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'poly_line': polyString,
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
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': 1,
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
            print("------------>3333333");
            val = await createRequestLater(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'poly_line': polyString,
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
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': 1,
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
        setState(() {
          if (val == 'success') {
            isLoading = false;
            showModalBottomSheet(
                context: context,
                isScrollControlled: false,
                isDismissible: false,
                builder: (context) {
                  return const SuccessPopUp();
                });
          }
        });
      } else {
        dynamic val;
        setState(() {
          isLoading = true;
        });

        if (choosenTransportType == 0) {
          val = await createRequestLater(
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
                          .firstWhere((e) => e.type == 'drop')
                          .latlng
                          .latitude,
                      'drop_lng': addressList
                          .firstWhere((e) => e.type == 'drop')
                          .latlng
                          .longitude,
                      'vehicle_type': etaDetails[choosenVehicle]
                          ['zone_type_id'],
                      'poly_line': polyString,
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
                      'pick_address': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .address,
                      'drop_address': addressList
                          .firstWhere((e) => e.type == 'drop')
                          .address,
                      'promocode_id': etaDetails[choosenVehicle]
                          ['promocode_id'],
                      'trip_start_time':
                          choosenDateTime.toString().substring(0, 19),
                      'is_later': true,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
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
                      'pick_address': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .address,
                      'promocode_id': etaDetails[choosenVehicle]
                          ['promocode_id'],
                      'trip_start_time':
                          choosenDateTime.toString().substring(0, 19),
                      'is_later': true,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                      'is_pet_available':
                          (addPetPreferences == false) ? false : true,
                      'is_luggage_available':
                          (addLuggagePreferences == false) ? false : true
                    }),
              'api/v1/request/create');
        } else {
          if (dropStopList.isNotEmpty) {
            val = await createRequestLater(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
                  'ride_type': 1,
                  'poly_line': polyString,
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
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': true,
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
            val = await createRequestLater(
                jsonEncode({
                  'pick_lat': addressList[0].latlng.latitude,
                  'pick_lng': addressList[0].latlng.longitude,
                  'drop_lat':
                      addressList[addressList.length - 1].latlng.latitude,
                  'drop_lng':
                      addressList[addressList.length - 1].latlng.longitude,
                  'poly_line': polyString,
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
                  'trip_start_time':
                      choosenDateTime.toString().substring(0, 19),
                  'is_later': true,
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
        setState(() {
          if (val == 'success') {
            isLoading = false;
            showModalBottomSheet(
                context: context,
                isScrollControlled: false,
                isDismissible: false,
                builder: (context) {
                  return const SuccessPopUp();
                });
          }
        });
      }
    } else {
      if (rentalOption[choosenVehicle]['has_discount'] == false) {
        dynamic val;
        setState(() {
          isLoading = true;
        });

        if (choosenTransportType == 0) {
          val = await createRequestLater(
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
                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                'is_later': 1,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'is_pet_available': (addPetPreferences == false) ? false : true,
                'is_luggage_available':
                    (addLuggagePreferences == false) ? false : true
              }),
              'api/v1/request/create');
        } else {
          val = await createRequestLater(
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
                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                'is_later': 1,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'goods_type_id': selectedGoodsId.toString(),
                'goods_type_quantity': goodsSize,
                'pickup_poc_name': addressList[0].name,
                'pickup_poc_mobile': addressList[0].number,
                'pickup_poc_instruction': addressList[0].instructions,
              }),
              'api/v1/request/delivery/create');
        }

        if (val == 'success') {
          setState(() {
            if (val == 'success') {
              isLoading = false;
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  isDismissible: false,
                  builder: (context) {
                    return const SuccessPopUp();
                  });
            }
          });
        } else if (val == 'logout') {
          navigateLogout();
        }
      } else {
        dynamic val;
        setState(() {
          isLoading = true;
        });

        if (choosenTransportType == 0) {
          val = await createRequestLater(
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
                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                'is_later': 1,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'is_pet_available': (addPetPreferences == false) ? false : true,
                'is_luggage_available':
                    (addLuggagePreferences == false) ? false : true
              }),
              'api/v1/request/create');
        } else {
          val = await createRequestLater(
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
                'trip_start_time': choosenDateTime.toString().substring(0, 19),
                'is_later': 1,
                'request_eta_amount': rentalOption[choosenVehicle]
                    ['fare_amount'],
                'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
                'goods_type_id': selectedGoodsId.toString(),
                'goods_type_quantity': goodsSize,
                'pickup_poc_name': addressList[0].name,
                'pickup_poc_mobile': addressList[0].number,
                'pickup_poc_instruction': addressList[0].instructions,
              }),
              'api/v1/request/delivery/create');
        }

        if (val == 'success') {
          setState(() {
            if (val == 'success') {
              isLoading = false;
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: false,
                  isDismissible: false,
                  builder: (context) {
                    return const SuccessPopUp();
                  });
            }
          });
        } else if (val == 'logout') {
          navigateLogout();
        }
      }
    }
  }
}
