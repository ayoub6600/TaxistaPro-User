import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../functions/functions.dart' show AddressList, ismulitipleride, polyList, userDetails, userRequestData;
import '../../functions/intercity_api.dart' show IcPlace;
import '../../functions/parcel_api.dart';
import '../../functions/service_kind.dart';
import '../../functions/tr.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/map_page.dart' show addressList, choosenTransportType, pickupAddressConfirmation, rentalRide, rideWithoutDestination;
import '../parcels/parcel_page.dart';

/// «🔁 اطلبها مرة ثانية» from the trip history (owner 2026-11-19): a parcel opens the parcels page
/// filled (both places, the receiver, the size); a ride opens the booking with the same pickup and
/// destination, the way the home screen books a chosen destination. The time, the car and the price
/// are chosen again there; stops of the old ride are not carried over.
class HistoryAgain {
  static double? _n(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

  static IcPlace? _place(Map ride, String side) {
    final lat = _n(ride['${side}_lat']), lng = _n(ride['${side}_lng']);
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return IcPlace(lat, lng, '${ride['${side}_address'] ?? ''}');
  }

  static IcPlace? pick(Map ride) => _place(ride, 'pick');
  static IcPlace? drop(Map ride) => _place(ride, 'drop');

  /// only a parcel or an ordinary ride with both places (not a rental, not a trip between cities, a
  /// tow or a freight: those have their own pages and questions)
  static bool can(Map ride) {
    final k = ServiceKind.of(ride);
    if (!k.isParcel && !k.isRide) return false;
    if (ride['is_rental'] == true || ride['is_rental'] == 1) return false;
    return pick(ride) != null && drop(ride) != null;
  }

  static Future<void> open(BuildContext context, Map ride) async {
    if (!can(ride)) return;
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] != 1 && userRequestData['is_cancelled'] != 1) {
      _say(context, tr('عندك طلب شغّال الآن. كمّله أو ألغيه الأول.', 'You have a request running now. Finish or cancel it first.'));
      return;
    }
    if (ServiceKind.of(ride).isParcel) return _parcel(context, ride);
    _ride(context, ride);
  }

  static void _say(BuildContext context, String text) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text, textDirection: appRtl ? TextDirection.rtl : TextDirection.ltr)));

  static Future<void> _parcel(BuildContext context, Map ride) async {
    final p = pick(ride)!, d = drop(ride)!;
    if (ParcelApi.notifier.value == null) await ParcelApi.refresh(p.lat, p.lng);
    if (!context.mounted) return;
    final home = ParcelApi.notifier.value;
    if (home == null) {
      _say(context, tr('ما قدرناش نفتح التوصيل الآن، جرّب بعد شوية.', 'We could not open delivery now, try again shortly.'));
      return;
    }
    final parcel = ride['parcel'] is Map ? ride['parcel'] as Map : const {};
    await ParcelPage.open(context,
        home: home,
        pick: p,
        pickIsHere: false,
        drop: d,
        receiverName: '${parcel['receiver_name'] ?? ''}'.trim().isEmpty ? null : '${parcel['receiver_name']}'.trim(),
        receiverPhone: '${parcel['receiver_phone'] ?? ''}'.trim().isEmpty ? null : '${parcel['receiver_phone']}'.trim(),
        size: parcel['size'] is String ? parcel['size'] as String : null);
  }

  /// the same globals the home screen fills before it opens the booking (map_destination_state.dart)
  static void _ride(BuildContext context, Map ride) {
    final p = pick(ride)!, d = drop(ride)!;
    addressList
      ..clear()
      ..add(AddressList(
          id: '1', type: 'pickup', address: p.address, pickup: true, latlng: LatLng(p.lat, p.lng), name: userDetails['name'], number: userDetails['mobile']))
      ..add(AddressList(id: '2', type: 'drop', address: d.address, pickup: false, latlng: LatLng(d.lat, d.lng)));
    pickupAddressConfirmation = p.address;
    polyList.clear();
    rideWithoutDestination = false;
    rentalRide = false;
    choosenTransportType = 0;
    ismulitipleride = false;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => BookingConfirmation()), (_) => false);
  }
}
