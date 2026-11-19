import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'intercity_api.dart' show IcPlace;

/// A receiver he sends parcels to often (owner 2026-11-19: «نحفظ المستلم للمرات الجاية؟»).
class SavedReceiver {
  const SavedReceiver(this.name, this.phone);

  final String name;
  final String phone;

  /// the same person: the number's digits decide, whatever the spaces or the name's spelling
  static String digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');
  bool same(String name, String phone) => digits(phone) == digits(this.phone) && name.trim() == this.name.trim();

  Map<String, String> toJson() => {'name': name, 'phone': phone};
  static SavedReceiver? fromJson(Object? j) => j is Map && '${j['name'] ?? ''}'.trim().isNotEmpty && '${j['phone'] ?? ''}'.trim().isNotEmpty
      ? SavedReceiver('${j['name']}'.trim(), '${j['phone']}'.trim())
      : null;
}

/// A place the captain takes parcels from (البيت، المحل، الشغل، or his own name).
class SavedPickPlace {
  const SavedPickPlace(this.label, this.place);

  final String label;
  final IcPlace place;

  /// about 60 m: the same door
  bool near(IcPlace p) => (p.lat - place.lat).abs() < 0.0006 && (p.lng - place.lng).abs() < 0.0006;

  String get icon => switch (label) { 'البيت' || 'Home' => '🏠', 'المحل' || 'Shop' => '🏪', 'الشغل' || 'Work' => '💼', _ => '📍' };

  Map<String, Object> toJson() => {'label': label, 'lat': place.lat, 'lng': place.lng, 'address': place.address};
  static SavedPickPlace? fromJson(Object? j) {
    if (j is! Map || '${j['label'] ?? ''}'.trim().isEmpty) return null;
    final lat = (j['lat'] as num?)?.toDouble(), lng = (j['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return SavedPickPlace('${j['label']}'.trim(), IcPlace(lat, lng, '${j['address'] ?? ''}'));
  }
}

/// Saved receivers and pickup places, on the phone only (shared_preferences), the newest first, 10 each.
class ParcelSaved {
  static const max = 10;
  static const _receiversKey = 'parcel_saved_receivers';
  static const _placesKey = 'parcel_saved_places';

  static Future<List<T>> _read<T>(String key, T? Function(Object?) from) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      return [
        for (final e in (list is List ? list : const []))
          if (from(e) case final v?) v
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(String key, List<Object> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(items));
  }

  static Future<List<SavedReceiver>> receivers() => _read(_receiversKey, SavedReceiver.fromJson);

  static Future<bool> hasReceiver(String name, String phone) async => (await receivers()).any((r) => r.same(name, phone));

  /// on top; the same number written again replaces the old line
  static Future<List<SavedReceiver>> saveReceiver(String name, String phone) async {
    final list = (await receivers())..removeWhere((r) => SavedReceiver.digits(r.phone) == SavedReceiver.digits(phone));
    list.insert(0, SavedReceiver(name.trim(), phone.trim()));
    final out = list.take(max).toList();
    await _write(_receiversKey, [for (final r in out) r.toJson()]);
    return out;
  }

  static Future<List<SavedReceiver>> removeReceiver(SavedReceiver r) async {
    final list = (await receivers())..removeWhere((e) => e.same(r.name, r.phone));
    await _write(_receiversKey, [for (final e in list) e.toJson()]);
    return list;
  }

  static Future<List<SavedPickPlace>> places() => _read(_placesKey, SavedPickPlace.fromJson);

  static Future<bool> hasPlace(IcPlace p) async => (await places()).any((s) => s.near(p));

  /// on top; the same label (or the same door) replaces the old one
  static Future<List<SavedPickPlace>> savePlace(String label, IcPlace p) async {
    final list = (await places())..removeWhere((s) => s.label == label.trim() || s.near(p));
    list.insert(0, SavedPickPlace(label.trim(), p));
    final out = list.take(max).toList();
    await _write(_placesKey, [for (final s in out) s.toJson()]);
    return out;
  }

  static Future<List<SavedPickPlace>> removePlace(SavedPickPlace s) async {
    final list = (await places())..removeWhere((e) => e.label == s.label && e.near(s.place));
    await _write(_placesKey, [for (final e in list) e.toJson()]);
    return list;
  }
}
