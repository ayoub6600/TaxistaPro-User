import 'intercity_api.dart' show IcPlace, IntercityResult;
import 'parcel_api.dart';
import 'tr.dart';

/// «مشوار بوقفات»: the admin's settings, read from the parcels answer (`data.errand`).
class ErrandConfig {
  ErrandConfig(this.raw, {this.currency = 'LYD'});
  final Map raw;
  final String currency;

  static ErrandConfig? of(ParcelHome home) {
    final e = home.raw['errand'];
    return e is Map ? ErrandConfig(e, currency: home.currency) : null;
  }

  bool get enabled => raw['enabled'] == true;
  String get name {
    final v = '${raw['name'] ?? ''}'.trim();
    return v.isNotEmpty ? v : tr('مشوار بوقفات', 'Errand with stops');
  }

  int get maxStops => ((raw['max_stops'] as num?)?.toInt() ?? 3).clamp(1, 20);
  num get stopFee => raw['stop_fee'] as num? ?? 0;
  int get freeWait => (raw['free_wait'] as num?)?.toInt() ?? 5;
  num get waitPerMin => raw['wait_per_min'] as num? ?? 0;

  Map get _buy => raw['buy'] is Map ? raw['buy'] as Map : const {};
  bool get buyEnabled => _buy['enabled'] == true;
  bool get buyAllowed => buyEnabled && _buy['allowed'] == true;
  num get buyMax => _buy['max'] as num? ?? 0;
  bool get receiptRequired => _buy['receipt_required'] != false;
  int get minRides => (_buy['min_rides'] as num?)?.toInt() ?? 0;
}

/// one stop as the server takes it
class ErrandStopData {
  const ErrandStopData({required this.place, required this.item, this.contactName = '', this.contactPhone = '', this.pays = 'paid'});
  final IcPlace place;
  final String item;
  final String contactName;
  final String contactPhone;

  /// 'paid' (already paid) or 'captain' (the captain pays and he pays him back)
  final String pays;

  Map<String, Object?> toJson() => {
        'lat': place.lat,
        'lng': place.lng,
        'address': place.address,
        'item': item.trim(),
        if (contactName.trim().isNotEmpty) 'contact_name': contactName.trim(),
        if (contactPhone.trim().isNotEmpty) 'contact_phone': contactPhone.trim(),
        'pays': pays,
      };
}

class ErrandApi {
  static Future<IntercityResult> quote(List<IcPlace> stops, IcPlace drop) => ParcelApi.post('api/v1/request/parcels/errand/quote', {
        'stops': [for (final s in stops) {'lat': s.lat, 'lng': s.lng}],
        'drop_lat': drop.lat,
        'drop_lng': drop.lng,
      });

  /// payment 'auto': his wallet when it holds the price, else cash (the server decides)
  static Future<IntercityResult> create(List<ErrandStopData> stops, IcPlace drop) => ParcelApi.post('api/v1/request/parcels/errand', {
        'stops': [for (final s in stops) s.toJson()],
        'drop_lat': drop.lat,
        'drop_lng': drop.lng,
        'drop_address': drop.address,
        'payment': 'auto',
        'accept_rules': true,
      });

  /// «صحيح ✓» / «مش صحيح» on what the captain paid at a stop
  static Future<IntercityResult> answer(Object rideId, int position, bool confirmed) =>
      ParcelApi.post('api/v1/request/errands/$rideId/stops/$position/answer', {'answer': confirmed ? 'confirmed' : 'disputed'});
}

/// «الكابتن دفع عنك»: the push the server sends when the captain reports a payment at a stop. It is
/// only a nudge: the ride's own JSON (the card on the ride screen) is the truth, so the ride is read again.
class ErrandPush {
  static const type = 'errand_purchase';

  static bool handles(Map data) => '${data['push_type'] ?? ''}' == type && '${data['request_id'] ?? ''}'.isNotEmpty;

  /// true when the push is about the ride on screen (the only one the card shows)
  static bool isCurrent(Map data, Map ride) => handles(data) && ride.isNotEmpty && '${ride['id']}' == '${data['request_id']}';
}
