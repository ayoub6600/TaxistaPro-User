import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation.dart';

void main() {
  test('confirmation camera starts on the local route, not the world', () {
    const pickup = LatLng(32.370, 15.092);
    const destination = LatLng(32.430, 15.220);
    const oldFallback = LatLng(41.4219057, -102.0840772);

    final camera =
        initialBookingCameraForRoute([pickup, destination], oldFallback, false);

    expect(camera.target.latitude, closeTo(32.400, 0.000001));
    expect(camera.target.longitude, closeTo(15.156, 0.000001));
    expect(camera.zoom, 11);
  });

  test('single-point booking starts at pickup even with stale fallback', () {
    const pickup = LatLng(32.370, 15.092);
    final camera =
        initialBookingCameraForRoute([pickup], const LatLng(0, 0), false);
    expect(camera.target, pickup);
  });

  test('services camera starts closer to a short pickup-to-drop route', () {
    final camera = initialBookingCameraForRoute([
      const LatLng(32.370, 15.092),
      const LatLng(32.373, 15.094),
    ], const LatLng(0, 0), true);
    expect(camera.target.latitude, closeTo(32.3715, 0.000001));
    expect(camera.zoom, 14);
  });

  test('pending request uses its own places, never the previous route', () {
    const stale = [LatLng(41.42, -102.08), LatLng(0, 0)];
    final points = bookingRequestCameraPoints({
      'pick_lat': '32.370',
      'pick_lng': '15.092',
      'drop_lat': '32.430',
      'drop_lng': '15.220',
    }, stale);
    expect(
        points, [const LatLng(32.370, 15.092), const LatLng(32.430, 15.220)]);
  });
}
