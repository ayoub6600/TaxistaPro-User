part of '../bookingwidgets.dart';

mixin _CreateRequestActions on State<CreateRequestBottomSheet> {
  final TextEditingController yourAmount = TextEditingController();
  String fareError = '';
  bool iscondition = false;

  void _finishRequestSubmission() {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      iscondition = false;
    });
  }

  Future<void> _submitRegularRequest() async {
    if (yourAmount.text.isNotEmpty) {
      var g = widget.geo.encode(
          addressList
              .firstWhere((element) => element.type == 'pickup')
              .latlng
              .longitude,
          addressList
              .firstWhere((element) => element.type == 'pickup')
              .latlng
              .latitude);
      dynamic result;
      FocusManager.instance.primaryFocus?.unfocus();
      if ((yourAmount.text.isNotEmpty &&
              double.parse(yourAmount.text) >=
                  double.parse(
                      etaDetails[widget.showInfoInt]['total'].toString())) ||
          widget.isOneWayTrip) {
        if (!iscondition) {
          setState(() {
            isLoading = true;
          });

          if (choosenVehicle != null) {
            if (isOutStation && !iscondition) {
              iscondition = true;
              if (choosenTransportType == 0) {
                result = await createRequestLater(
                    jsonEncode({
                      'pick_lat': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .latitude,
                      'poly_line': polyString,
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
                      'is_pet_available':
                          (addPetPreferences == false) ? false : true,
                      'is_luggage_available':
                          (addLuggagePreferences == false) ? false : true,
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
                          .lastWhere((e) => e.type == 'drop')
                          .address,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                      'offerred_ride_fare': yourAmount.text,
                      'is_bid_ride': 1,
                      'trip_start_time':
                          widget.fromDate.toString().substring(0, 19),
                      if (widget.toDate != null) 'is_round_trip': true,
                      if (widget.toDate != null)
                        'return_time':
                            widget.toDate.toString().substring(0, 19),
                      'is_later': true,
                      'is_out_station': true,
                      if (dropStopList.isNotEmpty)
                        'stops': jsonEncode(dropStopList),
                    }),
                    'api/v1/request/create');
              } else {
                iscondition = true;
                result = await createRequestLater(
                    jsonEncode({
                      'pick_lat': addressList[0].latlng.latitude,
                      'pick_lng': addressList[0].latlng.longitude,
                      'drop_lat':
                          addressList[addressList.length - 1].latlng.latitude,
                      'poly_line': polyString,
                      'drop_lng':
                          addressList[addressList.length - 1].latlng.longitude,
                      'vehicle_type': etaDetails[choosenVehicle]
                          ['zone_type_id'],
                      'ride_type': 1,
                      'is_pet_available':
                          (addPetPreferences == false) ? false : true,
                      'is_luggage_available':
                          (addLuggagePreferences == false) ? false : true,
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
                      'drop_address':
                          addressList[addressList.length - 1].address,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                      'pickup_poc_name': addressList[0].name,
                      'pickup_poc_mobile': addressList[0].number,
                      'pickup_poc_instruction': addressList[0].instructions,
                      'drop_poc_name': addressList[addressList.length - 1].name,
                      'drop_poc_mobile':
                          addressList[addressList.length - 1].number,
                      'drop_poc_instruction':
                          addressList[addressList.length - 1].instructions,
                      'goods_type_id': selectedGoodsId.toString(),
                      'goods_type_quantity': goodsSize,
                      'offerred_ride_fare': yourAmount.text,
                      'is_bid_ride': 1,
                      'trip_start_time':
                          widget.fromDate.toString().substring(0, 19),
                      if (widget.toDate != null) 'is_round_trip': true,
                      if (widget.toDate != null)
                        'return_time':
                            widget.toDate.toString().substring(0, 19),
                      'is_later': true,
                      'is_out_station': true,
                      if (dropStopList.isNotEmpty)
                        'stops': jsonEncode(dropStopList),
                    }),
                    (userDetails['is_delivery_app'] != null &&
                            userDetails['is_delivery_app'] == true)
                        ? 'api/v1/request/create'
                        : 'api/v1/request/delivery/create');
              }
            } else {
              iscondition = true;

              if (widget.type != 1) {
                if (etaDetails[choosenVehicle]['has_discount'] == false) {
                  if (choosenTransportType == 0) {
                    result = await createRequest(
                        (addressList
                                .where((element) => element.type == 'drop')
                                .isNotEmpty)
                            ? jsonEncode({
                                'pick_lat': addressList
                                    .firstWhere((e) => e.type == 'pickup')
                                    .latlng
                                    .latitude,
                                'poly_line': polyString,
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
                                'is_pet_available':
                                    (addPetPreferences == false) ? false : true,
                                'is_luggage_available':
                                    (addLuggagePreferences == false)
                                        ? false
                                        : true,
                                'payment_opt': (etaDetails[choosenVehicle]
                                                ['payment_type']
                                            .toString()
                                            .split(',')
                                            .toList()[payingVia] ==
                                        'card')
                                    ? 0
                                    : (etaDetails[choosenVehicle]
                                                    ['payment_type']
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
                                'offerred_ride_fare': yourAmount.text,
                                'is_bid_ride': 1,
                                'stops': jsonEncode(dropStopList),
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
                                'is_pet_available':
                                    (addPetPreferences == false) ? false : true,
                                'is_luggage_available':
                                    (addLuggagePreferences == false)
                                        ? false
                                        : true,
                                'payment_opt': (etaDetails[choosenVehicle]
                                                ['payment_type']
                                            .toString()
                                            .split(',')
                                            .toList()[payingVia] ==
                                        'card')
                                    ? 0
                                    : (etaDetails[choosenVehicle]
                                                    ['payment_type']
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
                                'offerred_ride_fare': yourAmount.text,
                                'is_bid_ride': 1
                              }),
                        'api/v1/request/create');
                  } else {
                    if (dropStopList.isNotEmpty) {
                      result = await createRequest(
                          jsonEncode({
                            'pick_lat': addressList[0].latlng.latitude,
                            'pick_lng': addressList[0].latlng.longitude,
                            'poly_line': polyString,
                            'drop_lat': addressList[addressList.length - 1]
                                .latlng
                                .latitude,
                            'drop_lng': addressList[addressList.length - 1]
                                .latlng
                                .longitude,
                            'vehicle_type': etaDetails[choosenVehicle]
                                ['zone_type_id'],
                            'ride_type': 1,
                            'is_pet_available':
                                (addPetPreferences == false) ? false : true,
                            'is_luggage_available':
                                (addLuggagePreferences == false) ? false : true,
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
                            'pick_address': addressList[0].address,
                            'drop_address':
                                addressList[addressList.length - 1].address,
                            'request_eta_amount': etaDetails[choosenVehicle]
                                ['total'],
                            'pickup_poc_name': addressList[0].name,
                            'pickup_poc_mobile': addressList[0].number,
                            'pickup_poc_instruction':
                                addressList[0].instructions,
                            'drop_poc_name':
                                addressList[addressList.length - 1].name,
                            'drop_poc_mobile':
                                addressList[addressList.length - 1].number,
                            'drop_poc_instruction':
                                addressList[addressList.length - 1]
                                    .instructions,
                            'goods_type_id': selectedGoodsId.toString(),
                            'stops': jsonEncode(dropStopList),
                            'goods_type_quantity': goodsSize,
                            'offerred_ride_fare': yourAmount.text,
                            'is_bid_ride': 1
                          }),
                          (userDetails['is_delivery_app'] != null &&
                                  userDetails['is_delivery_app'] == true)
                              ? 'api/v1/request/create'
                              : 'api/v1/request/delivery/create');
                    } else {
                      result = await createRequest(
                          jsonEncode({
                            'pick_lat': addressList[0].latlng.latitude,
                            'poly_line': polyString,
                            'pick_lng': addressList[0].latlng.longitude,
                            'drop_lat': addressList[addressList.length - 1]
                                .latlng
                                .latitude,
                            'drop_lng': addressList[addressList.length - 1]
                                .latlng
                                .longitude,
                            'vehicle_type': etaDetails[choosenVehicle]
                                ['zone_type_id'],
                            'ride_type': 1,
                            'is_pet_available':
                                (addPetPreferences == false) ? false : true,
                            'is_luggage_available':
                                (addLuggagePreferences == false) ? false : true,
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
                            'pick_address': addressList[0].address,
                            'drop_address':
                                addressList[addressList.length - 1].address,
                            'request_eta_amount': etaDetails[choosenVehicle]
                                ['total'],
                            'pickup_poc_name': addressList[0].name,
                            'pickup_poc_mobile': addressList[0].number,
                            'pickup_poc_instruction':
                                addressList[0].instructions,
                            'drop_poc_name':
                                addressList[addressList.length - 1].name,
                            'drop_poc_mobile':
                                addressList[addressList.length - 1].number,
                            'drop_poc_instruction':
                                addressList[addressList.length - 1]
                                    .instructions,
                            'goods_type_id': selectedGoodsId.toString(),
                            'goods_type_quantity': goodsSize,
                            'offerred_ride_fare': yourAmount.text,
                            'is_bid_ride': 1
                          }),
                          (userDetails['is_delivery_app'] != null &&
                                  userDetails['is_delivery_app'] == true)
                              ? 'api/v1/request/create'
                              : 'api/v1/request/delivery/create');
                    }
                  }
                } else {
                  if (choosenTransportType == 0) {
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
                                'poly_line': polyString,
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
                                'is_pet_available':
                                    (addPetPreferences == false) ? false : true,
                                'is_luggage_available':
                                    (addLuggagePreferences == false)
                                        ? false
                                        : true,
                                'payment_opt': (etaDetails[choosenVehicle]
                                                ['payment_type']
                                            .toString()
                                            .split(',')
                                            .toList()[payingVia] ==
                                        'card')
                                    ? 0
                                    : (etaDetails[choosenVehicle]
                                                    ['payment_type']
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
                                'offerred_ride_fare': yourAmount.text,
                                'is_bid_ride': 1,
                                'stops': jsonEncode(dropStopList),
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
                                'is_pet_available':
                                    (addPetPreferences == false) ? false : true,
                                'is_luggage_available':
                                    (addLuggagePreferences == false)
                                        ? false
                                        : true,
                                'payment_opt': (etaDetails[choosenVehicle]
                                                ['payment_type']
                                            .toString()
                                            .split(',')
                                            .toList()[payingVia] ==
                                        'card')
                                    ? 0
                                    : (etaDetails[choosenVehicle]
                                                    ['payment_type']
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
                                'offerred_ride_fare': yourAmount.text,
                                'is_bid_ride': 1
                              }),
                        'api/v1/request/create');
                  } else {
                    if (dropStopList.isNotEmpty) {
                      result = await createRequest(
                          jsonEncode({
                            'pick_lat': addressList[0].latlng.latitude,
                            'poly_line': polyString,
                            'pick_lng': addressList[0].latlng.longitude,
                            'drop_lat': addressList[addressList.length - 1]
                                .latlng
                                .latitude,
                            'drop_lng': addressList[addressList.length - 1]
                                .latlng
                                .longitude,
                            'vehicle_type': etaDetails[choosenVehicle]
                                ['zone_type_id'],
                            'ride_type': 1,
                            'is_pet_available':
                                (addPetPreferences == false) ? false : true,
                            'is_luggage_available':
                                (addLuggagePreferences == false) ? false : true,
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
                            'pick_address': addressList[0].address,
                            'drop_address':
                                addressList[addressList.length - 1].address,
                            'request_eta_amount': etaDetails[choosenVehicle]
                                ['total'],
                            'pickup_poc_name': addressList[0].name,
                            'pickup_poc_mobile': addressList[0].number,
                            'pickup_poc_instruction':
                                addressList[0].instructions,
                            'drop_poc_name':
                                addressList[addressList.length - 1].name,
                            'drop_poc_mobile':
                                addressList[addressList.length - 1].number,
                            'drop_poc_instruction':
                                addressList[addressList.length - 1]
                                    .instructions,
                            'goods_type_id': selectedGoodsId.toString(),
                            'stops': jsonEncode(dropStopList),
                            'goods_type_quantity': goodsSize,
                            'offerred_ride_fare': yourAmount.text,
                            'is_bid_ride': 1
                          }),
                          (userDetails['is_delivery_app'] != null &&
                                  userDetails['is_delivery_app'] == true)
                              ? 'api/v1/request/create'
                              : 'api/v1/request/delivery/create');
                    } else {
                      result = await createRequest(
                          jsonEncode({
                            'pick_lat': addressList[0].latlng.latitude,
                            'pick_lng': addressList[0].latlng.longitude,
                            'poly_line': polyString,
                            'drop_lat': addressList[addressList.length - 1]
                                .latlng
                                .latitude,
                            'drop_lng': addressList[addressList.length - 1]
                                .latlng
                                .longitude,
                            'vehicle_type': etaDetails[choosenVehicle]
                                ['zone_type_id'],
                            'ride_type': 1,
                            'is_pet_available':
                                (addPetPreferences == false) ? false : true,
                            'is_luggage_available':
                                (addLuggagePreferences == false) ? false : true,
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
                            'pick_address': addressList[0].address,
                            'drop_address':
                                addressList[addressList.length - 1].address,
                            'request_eta_amount': etaDetails[choosenVehicle]
                                ['total'],
                            'pickup_poc_name': addressList[0].name,
                            'pickup_poc_mobile': addressList[0].number,
                            'pickup_poc_instruction':
                                addressList[0].instructions,
                            'drop_poc_name':
                                addressList[addressList.length - 1].name,
                            'drop_poc_mobile':
                                addressList[addressList.length - 1].number,
                            'drop_poc_instruction':
                                addressList[addressList.length - 1]
                                    .instructions,
                            'goods_type_id': selectedGoodsId.toString(),
                            'goods_type_quantity': goodsSize,
                            'offerred_ride_fare': yourAmount.text,
                            'is_bid_ride': 1
                          }),
                          (userDetails['is_delivery_app'] != null &&
                                  userDetails['is_delivery_app'] == true)
                              ? 'api/v1/request/create'
                              : 'api/v1/request/delivery/create');
                    }
                  }
                }
              } else {
                if (rentalOption[choosenVehicle]['has_discount'] == false) {
                  if (choosenTransportType == 0) {
                    result = await createRequest(
                        jsonEncode({
                          'pick_lat': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                          'poly_line': polyString,
                          'pick_lng': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                          'vehicle_type': rentalOption[choosenVehicle]
                              ['zone_type_id'],
                          'ride_type': 1,
                          'is_pet_available':
                              (addPetPreferences == false) ? false : true,
                          'is_luggage_available':
                              (addLuggagePreferences == false) ? false : true,
                          'payment_opt': (rentalOption[choosenVehicle]
                                          ['payment_type']
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
                          'pick_address': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .address,
                          'request_eta_amount': rentalOption[choosenVehicle]
                              ['fare_amount'],
                          'rental_pack_id': etaDetails[rentalChoosenOption]
                              ['id'],
                          'offerred_ride_fare': yourAmount.text,
                          'is_bid_ride': 1
                        }),
                        'api/v1/request/create');
                  } else {
                    result = await createRequest(
                        jsonEncode({
                          'pick_lat': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                          'poly_line': polyString,
                          'pick_lng': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                          'vehicle_type': rentalOption[choosenVehicle]
                              ['zone_type_id'],
                          'ride_type': 1,
                          'is_pet_available':
                              (addPetPreferences == false) ? false : true,
                          'is_luggage_available':
                              (addLuggagePreferences == false) ? false : true,
                          'payment_opt': (rentalOption[choosenVehicle]
                                          ['payment_type']
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
                          'pick_address': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .address,
                          'request_eta_amount': rentalOption[choosenVehicle]
                              ['fare_amount'],
                          'rental_pack_id': etaDetails[rentalChoosenOption]
                              ['id'],
                          'pickup_poc_name': addressList[0].name,
                          'pickup_poc_mobile': addressList[0].number,
                          'pickup_poc_instruction': addressList[0].instructions,
                          'goods_type_id': selectedGoodsId.toString(),
                          'goods_type_quantity': goodsSize,
                          'offerred_ride_fare': yourAmount.text,
                          'is_bid_ride': 1
                        }),
                        (userDetails['is_delivery_app'] != null &&
                                userDetails['is_delivery_app'] == true)
                            ? 'api/v1/request/create'
                            : 'api/v1/request/delivery/create');
                  }
                } else {
                  if (choosenTransportType == 0) {
                    result = await createRequest(
                        jsonEncode({
                          'pick_lat': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                          'poly_line': polyString,
                          'pick_lng': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                          'vehicle_type': rentalOption[choosenVehicle]
                              ['zone_type_id'],
                          'ride_type': 1,
                          'is_pet_available':
                              (addPetPreferences == false) ? false : true,
                          'is_luggage_available':
                              (addLuggagePreferences == false) ? false : true,
                          'payment_opt': (rentalOption[choosenVehicle]
                                          ['payment_type']
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
                          'pick_address': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .address,
                          'promocode_id': rentalOption[choosenVehicle]
                              ['promocode_id'],
                          'request_eta_amount': rentalOption[choosenVehicle]
                              ['fare_amount'],
                          'rental_pack_id': etaDetails[rentalChoosenOption]
                              ['id'],
                          'offerred_ride_fare': yourAmount.text,
                          'is_bid_ride': 1
                        }),
                        'api/v1/request/create');
                  } else {
                    result = await createRequest(
                        jsonEncode({
                          'pick_lat': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .latitude,
                          'poly_line': polyString,
                          'pick_lng': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .latlng
                              .longitude,
                          'vehicle_type': rentalOption[choosenVehicle]
                              ['zone_type_id'],
                          'ride_type': 1,
                          'is_pet_available':
                              (addPetPreferences == false) ? false : true,
                          'is_luggage_available':
                              (addLuggagePreferences == false) ? false : true,
                          'payment_opt': (rentalOption[choosenVehicle]
                                          ['payment_type']
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
                          'pick_address': addressList
                              .firstWhere((e) => e.type == 'pickup')
                              .address,
                          'promocode_id': rentalOption[choosenVehicle]
                              ['promocode_id'],
                          'request_eta_amount': rentalOption[choosenVehicle]
                              ['fare_amount'],
                          'rental_pack_id': etaDetails[rentalChoosenOption]
                              ['id'],
                          'goods_type_id': selectedGoodsId.toString(),
                          'goods_type_quantity': goodsSize,
                          'pickup_poc_name': addressList[0].name,
                          'pickup_poc_mobile': addressList[0].number,
                          'pickup_poc_instruction': addressList[0].instructions,
                          'offerred_ride_fare': yourAmount.text,
                          'is_bid_ride': 1
                        }),
                        (userDetails['is_delivery_app'] != null &&
                                userDetails['is_delivery_app'] == true)
                            ? 'api/v1/request/create'
                            : 'api/v1/request/delivery/create');
                  }
                }
              }
            }
          }
        }
      } else if (isOutStation && widget.isOneWayTrip == false) {
        if (!iscondition) {
          iscondition = true;
          setState(() {
            isLoading = true;
          });

          if (choosenVehicle != null) {
            if (isOutStation) {
              if (choosenTransportType == 0) {
                result = await createRequestLater(
                    jsonEncode({
                      'pick_lat': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .latitude,
                      'pick_lng': addressList
                          .firstWhere((e) => e.type == 'pickup')
                          .latlng
                          .longitude,
                      'poly_line': polyString,
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
                      'is_pet_available':
                          (addPetPreferences == false) ? false : true,
                      'is_luggage_available':
                          (addLuggagePreferences == false) ? false : true,
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
                          .lastWhere((e) => e.type == 'drop')
                          .address,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                      'offerred_ride_fare': yourAmount.text,
                      'is_bid_ride': 1,
                      'trip_start_time':
                          widget.fromDate.toString().substring(0, 19),
                      if (dropStopList.isNotEmpty)
                        'stops': jsonEncode(dropStopList),
                      if (widget.toDate != null) 'is_round_trip': true,
                      if (widget.toDate != null)
                        'return_time':
                            widget.toDate.toString().substring(0, 19),
                      'is_later': true,
                      'is_out_station': true,
                    }),
                    'api/v1/request/create');
              } else {
                result = await createRequestLater(
                    jsonEncode({
                      'pick_lat': addressList[0].latlng.latitude,
                      'pick_lng': addressList[0].latlng.longitude,
                      'drop_lat':
                          addressList[addressList.length - 1].latlng.latitude,
                      'drop_lng':
                          addressList[addressList.length - 1].latlng.longitude,
                      'poly_line': polyString,
                      'vehicle_type': etaDetails[choosenVehicle]
                          ['zone_type_id'],
                      'ride_type': 1,
                      'is_pet_available':
                          (addPetPreferences == false) ? false : true,
                      'is_luggage_available':
                          (addLuggagePreferences == false) ? false : true,
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
                      'drop_address':
                          addressList[addressList.length - 1].address,
                      'request_eta_amount': etaDetails[choosenVehicle]['total'],
                      'pickup_poc_name': addressList[0].name,
                      'pickup_poc_mobile': addressList[0].number,
                      'pickup_poc_instruction': addressList[0].instructions,
                      'drop_poc_name': addressList[addressList.length - 1].name,
                      'drop_poc_mobile':
                          addressList[addressList.length - 1].number,
                      'drop_poc_instruction':
                          addressList[addressList.length - 1].instructions,
                      if (dropStopList.isNotEmpty)
                        'stops': jsonEncode(dropStopList),
                      'goods_type_id': selectedGoodsId.toString(),
                      'goods_type_quantity': goodsSize,
                      'offerred_ride_fare': yourAmount.text,
                      'is_bid_ride': 1,
                      'trip_start_time':
                          widget.fromDate.toString().substring(0, 19),
                      if (widget.toDate != null) 'is_round_trip': true,
                      if (widget.toDate != null)
                        'return_time':
                            widget.toDate.toString().substring(0, 19),
                      'is_later': true,
                      'is_out_station': true,
                    }),
                    (userDetails['is_delivery_app'] != null &&
                            userDetails['is_delivery_app'] == true)
                        ? 'api/v1/request/create'
                        : 'api/v1/request/delivery/create');
              }
            }
          }
        }
      } else {
        if (yourAmount.text != '') {
          setState(() {
            fareError = 'offered ride fare must be greater than minimum fare';
          });
        }
      }

      _handleCreatedRequest(result: result, geoHash: g);
    }
  }
}
