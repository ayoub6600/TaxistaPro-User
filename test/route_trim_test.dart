import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:taxista/functions/route_trim.dart';

void main() {
  // A straight road in Misrata going north, a point every ~111 m.
  final road = [
    for (var i = 0; i <= 10; i++) LatLng(32.3700 + i * 0.001, 15.0900),
  ];

  test('the line starts at the car and drops what it already passed', () {
    // The car is a bit past the 4th point, a few metres off the centre line.
    const car = LatLng(32.37345, 15.09003);
    final trimmed = trimRouteToCar(road, car);
    expect(trimmed.first, car);
    expect(trimmed[1], road[4]);
    expect(trimmed.last, road.last);
    expect(trimmed.length, 1 + road.length - 4);
  });

  test('the car at the start keeps the whole road', () {
    final trimmed = trimRouteToCar(road, road.first);
    expect(trimmed.first, road.first);
    expect(trimmed.sublist(1), road.sublist(1));
  });

  test('running it again for the same place changes nothing', () {
    const car = LatLng(32.37345, 15.09);
    final once = trimRouteToCar(road, car);
    final twice = trimRouteToCar(once, car);
    expect(twice, once);
  });

  test('near the end only the car and the destination are left', () {
    const car = LatLng(32.37995, 15.09);
    expect(trimRouteToCar(road, car), [car, road.last]);
  });

  test('a car far from the road leaves the route as it is', () {
    const car = LatLng(32.40, 15.12); // kilometres away
    expect(identical(trimRouteToCar(road, car), road), isTrue);
  });

  test('a road that comes back near itself: the car is on the first pass', () {
    // Out east 5 points, then back west 30 m north of the way out.
    final loop = [
      for (var i = 0; i <= 5; i++) LatLng(32.37, 15.09 + i * 0.001),
      for (var i = 5; i >= 0; i--) LatLng(32.37027, 15.09 + i * 0.001),
    ];
    const car = LatLng(32.37010, 15.0915); // on the way out, between 1 and 2
    final trimmed = trimRouteToCar(loop, car);
    expect(trimmed[1], loop[2]);
    expect(trimmed.length, 1 + loop.length - 2);
  });

  test('too short a route is returned untouched', () {
    final single = [road.first];
    expect(trimRouteToCar(single, road.last), single);
  });
}
