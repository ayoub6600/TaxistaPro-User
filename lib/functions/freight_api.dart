import 'dart:convert';
import 'dart:io';
import 'tr.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';
import 'intercity_api.dart' show IntercityResult;

/// A vehicle class the admin opened in the city: its service, what it carries, its base price.
class FreightClass {
  FreightClass(this.raw);
  final Map raw;

  String get key => '${raw['key']}';
  String get zoneTypeId => '${raw['zone_type_id'] ?? ''}';
  static const _en = {'pickup': 'Pickup', 'van': 'Closed van', 'truck': 'Truck'};

  /// the admin writes Arabic; English by key
  String get label => tr('${raw['label'] ?? ''}', _en[key] ?? '${raw['label'] ?? ''}');
  String get load => tr('${raw['load'] ?? ''}', '${raw['load'] ?? ''}'.replaceAll('حتى', 'up to').replaceAll('طن', 't'));
  String get box => '${raw['box'] ?? ''}';
  num get base => (raw['base'] as num?) ?? 0;
}

/// «الشحن» where he stands: open or not, what he can move, the classes, worker and floor prices.
const _categoriesEn = {'furniture': 'Furniture', 'appliances': 'Appliances', 'building': 'Building materials', 'shop': 'Shop goods', 'other': 'Something else'};

class FreightHome {
  FreightHome(this.raw);
  final Map raw;

  bool get enabled => raw['enabled'] == true;
  String get city => '${raw['city'] ?? ''}';
  String get currency => '${raw['currency'] ?? 'LYD'}';
  int get maxWorkers => (raw['max_workers'] as num?)?.toInt() ?? 4;
  int get horizonDays => (raw['horizon_days'] as num?)?.toInt() ?? 7;
  int get maxPhotos => (raw['max_photos'] as num?)?.toInt() ?? 3;
  int get freeLoadingMinutes => (raw['free_loading_minutes'] as num?)?.toInt() ?? 20;
  num get workerPrice => (raw['worker_price'] as num?) ?? 0;
  num get floorPrice => (raw['floor_price'] as num?) ?? 0;
  List<(String, String)> get categories => [
        for (final c in (raw['categories'] as List? ?? const []))
          if (c is Map) ('${c['key']}', tr('${c['label']}', _categoriesEn['${c['key']}'] ?? '${c['label']}')),
      ];
  List<FreightClass> get classes => [for (final c in (raw['classes'] as List? ?? const [])) if (c is Map) FreightClass(c)];
}

/// The suggested price line by line, and the range he may ask in.
class FreightQuote {
  FreightQuote(this.raw);
  final Map raw;

  num get suggested => (raw['suggested'] as num?) ?? 0;
  num get min => (raw['min'] as num?) ?? 0;
  num get max => (raw['max'] as num?) ?? 0;
  num get km => (raw['km'] as num?) ?? 0;
  num get base => (raw['base'] as num?) ?? 0;
  num get distance => (raw['distance'] as num?) ?? 0;
  num get workers => (raw['workers'] as num?) ?? 0;
  num get floors => (raw['floors'] as num?) ?? 0;
}

class FreightApi {
  static final notifier = ValueNotifier<FreightHome?>(null);
  static DateTime? _askedAt;
  static double? _lat, _lng;

  static Map<String, String> get _headers =>
      {'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json', 'Content-Type': 'application/json'};

  /// asked again when the last answer is old (3 minutes) or he moved (about 2 km); never before sign-in
  static Future<void> refresh(double lat, double lng) async {
    if (bearerToken.isEmpty) return;
    final moved = _lat == null || (lat - _lat!).abs() > 0.02 || (lng - _lng!).abs() > 0.02;
    if (_askedAt != null && !moved && DateTime.now().difference(_askedAt!) < const Duration(minutes: 3)) return;
    _askedAt = DateTime.now();
    _lat = lat;
    _lng = lng;
    try {
      final r = await http
          .get(Uri.parse('${url}api/v1/request/freight').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'}), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final d = r.statusCode == 200 ? jsonDecode(r.body)['data'] : null;
      if (d is Map) {
        notifier.value = FreightHome(d);
      } else {
        _askedAt = null;
      }
    } catch (_) {
      _askedAt = null;
    }
  }

  static Future<IntercityResult> _post(String path, Map body) async {
    try {
      final r = await http.post(Uri.parse('$url$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 25));
      final j = jsonDecode(r.body);
      final ok = r.statusCode == 200 && j is Map && j['success'] == true;
      String msg = j is Map ? '${j['message'] ?? ''}' : '';
      if (!ok && j is Map && j['errors'] is Map) {
        final first = (j['errors'] as Map).values.first;
        if (first is List && first.isNotEmpty) msg = '${first.first}';
      }
      return IntercityResult(ok, msg.isEmpty ? (ok ? tr('تم', 'Done') : tr('ما قدرناش، جرّب مرة ثانية.', 'We could not do it, try again.')) : msg, j is Map ? j['data'] : null);
    } catch (_) {
      return IntercityResult(false, tr('تعذر الاتصال. تأكد من الإنترنت.', 'No connection. Check the internet.'));
    }
  }

  static Future<FreightQuote?> quote(double pLat, double pLng, double dLat, double dLng, String cls, int workers, int floors) async {
    final r = await _post('api/v1/request/freight/quote',
        {'pick_lat': pLat, 'pick_lng': pLng, 'drop_lat': dLat, 'drop_lng': dLng, 'freight_class': cls, 'workers': workers, 'floors': floors});
    return r.ok && r.data is Map ? FreightQuote(r.data as Map) : null;
  }

  /// a negotiated ride on the class's service; the owners answer with their price
  static Future<IntercityResult> create(Map<String, Object?> body) => _post('api/v1/request/create', body);

  /// a photo of the load, after the request (up to three)
  static Future<bool> photo(String rideId, File file) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('${url}api/v1/request/freight/$rideId/photo'))
        ..headers.addAll({'Authorization': 'Bearer ${bearerToken[0].token}', 'Accept': 'application/json'})
        ..files.add(await http.MultipartFile.fromPath('image', file.path));
      final r = await req.send().timeout(const Duration(seconds: 40));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// the market wall clock the server expects
  static String wallClock(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:00';
  }
}
