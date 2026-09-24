part of '../booking_confirmation.dart';

double minimumRiderOffer(double fairFare, double discountPercent) {
  final bounded = discountPercent.clamp(0, 50).toDouble();
  return (fairFare * (1 - bounded / 100) * 100).round() / 100;
}

// This is only a client-side freshness check. The backend still verifies the
// signature, route and fare before it accepts the booking.
bool currentImmediateFareQuote(String? token, Map<String, dynamic> booking,
    {DateTime? now}) {
  if (token == null || token.isEmpty) return false;
  try {
    final encoded = token.split('.').first;
    final quote =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(encoded))))
            as Map<String, dynamic>;
    final issued = (quote['issued'] as num).toInt();
    final age = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000 - issued;
    if (age < -10 || age > 840) return false;
    double rounded(dynamic value) =>
        ((value as num).toDouble() * 1000000).round() / 1000000;
    bool samePoint(dynamic point, dynamic latitude, dynamic longitude) =>
        point is List &&
        point.length == 2 &&
        (point[0] as num).toDouble() == rounded(latitude) &&
        (point[1] as num).toDouble() == rounded(longitude);
    final stops = booking['stops'] == null
        ? <dynamic>[]
        : jsonDecode(booking['stops'].toString()) as List;
    final quoteStops = quote['stops'] as List;
    return quote['zone'].toString() == booking['vehicle_type'].toString() &&
        (quote['immediate'] as num).toDouble() ==
            double.parse(booking['request_eta_amount'].toString()) &&
        samePoint(quote['pick'], booking['pick_lat'], booking['pick_lng']) &&
        samePoint(quote['drop'], booking['drop_lat'], booking['drop_lng']) &&
        quoteStops.length == stops.length &&
        List.generate(
            stops.length,
            (index) => samePoint(quoteStops[index], stops[index]['latitude'],
                stops[index]['longitude'])).every((same) => same);
  } catch (_) {
    return false;
  }
}

Map<String, dynamic> immediateOfferQuoteInput(Map<String, dynamic> booking) {
  return {
    'pick_lat': booking['pick_lat'],
    'pick_lng': booking['pick_lng'],
    'drop_lat': booking['drop_lat'],
    'drop_lng': booking['drop_lng'],
    'ride_type': 1,
    'transport_type': 'taxi',
    if (booking.containsKey('stops')) 'stops': booking['stops'],
  };
}

void applyImmediateRiderProposal(Map<String, dynamic> booking, double amount) {
  booking.remove('is_bid_ride');
  booking.remove('offerred_ride_fare');
  booking['rider_proposed_fare'] = amount;
}
