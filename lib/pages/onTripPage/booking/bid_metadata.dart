part of '../bookingwidgets.dart';

Map<String, dynamic> _buildBidMetadata({
  required dynamic geoHash,
  required dynamic price,
  required bool isOutStationRide,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  return {
    'user_id': userDetails['id'].toString(),
    'price': price,
    'g': geoHash,
    'user_name': userDetails['name'],
    'updated_at': ServerValue.timestamp,
    'user_img': userDetails['profile_picture'],
    'vehicle_type': userRequestData['vehicle_type_id'],
    'request_id': userRequestData['id'],
    'request_no': userRequestData['request_number'],
    'pick_address': userRequestData['pick_address'],
    'drop_address': userRequestData['drop_address'],
    'trip_stops': dropStopList.isEmpty ? 'null' : jsonEncode(dropStopList),
    'goods': userRequestData['transport_type'] != 'taxi' &&
            userRequestData['goods_type'] != '-'
        ? '${userRequestData['goods_type']} - '
            '${userRequestData['goods_type_quantity']}'
        : 'null',
    'pick_lat': userRequestData['pick_lat'],
    'drop_lat': userRequestData['drop_lat'],
    'pick_lng': userRequestData['pick_lng'],
    'drop_lng': userRequestData['drop_lng'],
    'currency': userDetails['currency_symbol'],
    if (fromDate != null)
      'trip_start_time': DateFormat('d-MMM-y, h:mm a').format(fromDate),
    if (toDate != null)
      'return_time': DateFormat('d-MMM-y, h:mm a').format(toDate),
    if (fromDate != null) 'is_later': true,
    'is_out_station': isOutStationRide,
    'distance': etaDetails[choosenVehicle]['distance'].toString(),
    'is_pet_available': addPetPreferences == true,
    'is_luggage_available': addLuggagePreferences == true,
  };
}
