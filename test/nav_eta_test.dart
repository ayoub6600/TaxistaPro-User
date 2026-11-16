import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/nav_eta.dart';

/// «يوصلك خلال X دقائق» from the captain's in-app navigation when it is fresh and for this ride.
void main() {
  final now = DateTime.fromMillisecondsSinceEpoch(1000000000);
  Map node(int s, int agoMs, String ride) => {'nav_eta_s': s, 'nav_eta_at': now.millisecondsSinceEpoch - agoMs, 'nav_ride': ride};
  test('fresh and for this ride', () {
    expect(navEtaMinutes(node(240, 0, 'r1'), 'r1', now: now), 4);
    expect(navEtaMinutes(node(240, 60000, 'r1'), 'r1', now: now), 3, reason: 'a minute has passed since');
    expect(navEtaMinutes(node(30, 60000, 'r1'), 'r1', now: now), 0);
  });
  test('ignored when old, for another ride or missing', () {
    expect(navEtaMinutes(node(240, 130000, 'r1'), 'r1', now: now), isNull);
    expect(navEtaMinutes(node(240, 0, 'r2'), 'r1', now: now), isNull);
    expect(navEtaMinutes({'l': [1, 2]}, 'r1', now: now), isNull);
    expect(navEtaMinutes(null, 'r1', now: now), isNull);
  });
}
