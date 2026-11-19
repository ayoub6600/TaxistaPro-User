import 'package:flutter/material.dart';

import 'tr.dart';

/// What a ride is — «رحلة», «سفر بين المدن», «طرد», «ونش», «شحن» — from the server's service_kind
/// (or, on an older answer, from the blocks it carries), with its own icon, colour and title.
class ServiceKind {
  const ServiceKind._(this.kind);

  final String kind;

  static const kinds = ['ride', 'intercity', 'parcel', 'tow', 'freight'];

  static ServiceKind of(Map ride) {
    final k = '${ride['service_kind'] ?? ''}';
    if (kinds.contains(k)) return ServiceKind._(k);
    if (ride['parcel'] is Map) return const ServiceKind._('parcel');
    if (ride['tow'] is Map) return const ServiceKind._('tow');
    if (ride['freight'] is Map) return const ServiceKind._('freight');
    if (ride['intercity'] is Map || ride['is_out_station'] == 1 || ride['is_out_station'] == true) return const ServiceKind._('intercity');
    return const ServiceKind._('ride');
  }

  /// a wallet line: its service_kind, or its service_label when only that came
  static ServiceKind? ofWalletLine(Map line) {
    final k = '${line['service_kind'] ?? ''}';
    if (kinds.contains(k)) return ServiceKind._(k);
    final l = '${line['service_label'] ?? ''}';
    for (final k in kinds) {
      if (_ar[k] == l) return ServiceKind._(k);
    }
    return null;
  }

  /// «📦 طرد 1234» under a wallet line: the server's service_label (Arabic) with its icon and the trip
  /// number; an older line with a trip number only stays «رحلة 1234»; null when it is no trip's
  static String? walletLine(Map line) {
    final trip = '${line['request_number'] ?? ''}'.trim();
    final k = ofWalletLine(line);
    if (k == null) return trip.isEmpty ? null : tr('رحلة $trip', 'Ride $trip');
    final label = '${line['service_label'] ?? ''}'.trim();
    return [k.icon, label.isNotEmpty && appRtl ? label : k.label, if (trip.isNotEmpty) trip].join(' ');
  }

  static const _icons = {'ride': '🚕', 'intercity': '🛣', 'parcel': '📦', 'tow': '🚛', 'freight': '🚚'};
  static const _ar = {'ride': 'رحلة', 'intercity': 'سفر بين المدن', 'parcel': 'طرد', 'tow': 'ونش', 'freight': 'شحن'};
  static const _en = {'ride': 'Ride', 'intercity': 'Intercity trip', 'parcel': 'Parcel', 'tow': 'Tow', 'freight': 'Freight'};
  static const _colors = {
    'ride': Color(0xff0873FF),
    'intercity': Color(0xff7C3AED),
    'parcel': Color(0xffD97706),
    'tow': Color(0xffB45309),
    'freight': Color(0xff0F766E),
  };

  String get icon => _icons[kind]!;
  String get label => tr(_ar[kind]!, _en[kind]!);
  Color get color => _colors[kind]!;
  bool get isParcel => kind == 'parcel';
  bool get isRide => kind == 'ride';

  /// «📦 طرد لـأحمد», «🚛 ونش», «🚕 رحلة»
  String title(Map ride) {
    final p = ride['parcel'];
    final to = p is Map ? '${p['receiver_name'] ?? ''}'.trim() : '';
    if (isParcel && to.isNotEmpty) return '$icon ${tr('طرد لـ$to', 'Parcel for $to')}';
    return '$icon $label';
  }
}
