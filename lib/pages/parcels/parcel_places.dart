import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/functions.dart' show addAutoFill, geoCoding, geoCodingForLatLng, getAutocomplete, mapType;
import '../../functions/intercity_api.dart' show IcPlace;
import '../../functions/tr.dart';
import '../onTripPage/map_page.dart' show mapStyle;
import '../intercity/intercity_style.dart';
import '../onTripPage/trip_location_search.dart';
import '../onTripPage/trip_map_picker.dart';
import '../onTripPage/trip_place.dart';
import 'parcel_pins.dart';

/// «من وين ياخذها الكابتن» / «لوين توصل»: two clear rows; a tap opens the booking's own search + map.
class ParcelPlaces extends StatelessWidget {
  const ParcelPlaces({super.key, required this.pick, required this.drop, required this.onTap, this.pickIsHere = false});

  final IcPlace pick;
  final IcPlace? drop;
  final bool pickIsHere;
  final void Function(TripPointRole role) onTap;

  static TripCopy get copy => TripCopy(
        title: tr('من وين لوين؟ 📦', 'From where to where? 📦'),
        labels: [tr('من وين ياخذها الكابتن', 'Where the captain picks it up'), tr('لوين توصل', 'Where it goes')],
        asks: [tr('وين الكابتن ياخذ الطرد منك؟', 'Where does the captain take the parcel?'), tr('لوين نوصلوا الطرد؟', 'Where should the parcel go?')],
        confirm: tr('تمام، هذا المكانين', 'Done, these two places'),
        mapHints: [
          tr('حط الدبوس الأخضر وين الكابتن يستلم الطرد منك.', 'Put the green pin where the captain picks the parcel up.'),
          tr('حط الدبوس الأحمر وين يوصل الطرد: باب البيت أو المحل.', 'Put the red pin where the parcel goes: the door of the house or shop.')
        ],
        mapConfirm: [tr('الكابتن ياخذها من هنا', 'Picked up here'), tr('توصل هنا', 'Delivered here')],
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: IcStyle.line, width: 1.5)),
        child: Column(children: [
          _row(
              TripPointRole.pickup,
              ParcelPin.pickColor,
              copy.labels[0],
              pickIsHere
                  ? tr('مكانك الآن${pick.address.isEmpty ? '' : ' · ${pick.address}'}', 'Where you are${pick.address.isEmpty ? '' : ' · ${pick.address}'}')
                  : _name(pick),
              false,
              const ValueKey('parcel-pick')),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 19),
            child: Row(children: [
              Container(width: 2, height: 14, color: IcStyle.line),
              const SizedBox(width: 10),
              const Expanded(child: Divider(height: 1, color: IcStyle.line)),
            ]),
          ),
          _row(TripPointRole.destination, ParcelPin.dropColor, copy.labels[1], drop == null ? tr('اختار المكان', 'Choose the place') : _name(drop!),
              drop == null, const ValueKey('parcel-drop')),
        ]),
      );

  static String _name(IcPlace p) => p.address.isEmpty ? tr('المكان على الخريطة', 'The place on the map') : p.address;

  Widget _row(TripPointRole role, Color color, String label, String text, bool muted, Key key) => Material(
      // the place still to choose is tinted in its colour: that's the next tap
      color: muted ? color.withValues(alpha: .06) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: key,
        onTap: () => onTap(role),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 4)]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: IcStyle.t(12, w: FontWeight.w800, c: color)),
                Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IcStyle.t(14.5, w: muted ? FontWeight.w600 : FontWeight.w800, c: muted ? IcStyle.muted : IcStyle.navy)),
              ]),
            ),
            const Icon(Icons.chevron_left_rounded, color: IcStyle.muted),
          ]),
        ),
      ));

  /// the booking's search screen (search, or the map) with the parcels' words; null when he goes back
  static Future<(IcPlace, IcPlace?)?> choose(BuildContext context, {required IcPlace pick, IcPlace? drop, required TripPointRole role}) {
    TripPlace t(IcPlace p) => TripPlace(address: p.address, coordinates: LatLng(p.lat, p.lng));
    IcPlace back(TripPlace p) => IcPlace(p.coordinates!.latitude, p.coordinates!.longitude, p.address);
    final session = '${DateTime.now().millisecondsSinceEpoch}${math.Random().nextInt(9999)}';
    final near = LatLng(pick.lat, pick.lng);
    return Navigator.of(context).push<(IcPlace, IcPlace?)>(MaterialPageRoute(
      builder: (ctx) => TripLocationSearch(
        rtl: appRtl,
        copy: copy,
        initialRole: role,
        initialSelection: TripSelection(pickup: t(pick), destination: drop == null ? null : t(drop)),
        recentPlaces: const [],
        favoritePlaces: const [],
        searchPlaces: (q) async {
          await getAutocomplete(q, session, near.latitude, near.longitude);
          return [
            for (final e in List.of(addAutoFill))
              if (e is Map && '${e['description'] ?? ''}'.isNotEmpty)
                TripPlace(address: '${e['description']}', placeId: '${e['place'] ?? ''}', coordinates: TripPlace.parseCoordinates(e['lat'], e['lon'])),
          ];
        },
        resolvePlace: (p) async {
          final id = p.placeId;
          if (id == null || id.isEmpty) return null;
          final at = await geoCodingForLatLng(id, session);
          final c = at == null ? null : TripPlace.parseCoordinates(at['lat'], at['lng']);
          return c == null ? null : TripPlace(address: p.address, coordinates: c, placeId: id);
        },
        pickOnMap: (r, current) => Navigator.of(ctx).push<TripPlace?>(MaterialPageRoute(
          builder: (_) => TripMapPicker(
            rtl: appRtl,
            role: r,
            copy: copy,
            initialCenter: current?.coordinates ?? near,
            initialPlace: current,
            reverseGeocode: (p) => geoCoding(p.latitude, p.longitude),
            useGoogleMap: mapType == 'google',
            mapStyle: mapStyle.isEmpty ? null : mapStyle,
          ),
        )),
        onConfirm: (s) => Navigator.of(ctx).pop((back(s.pickup!), s.destination == null ? null : back(s.destination!))),
        onClose: () => Navigator.of(ctx).maybePop(),
      ),
    ));
  }
}
