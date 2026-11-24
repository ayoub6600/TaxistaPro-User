import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/onTripPage/booking_confirmation.dart';

void main() {
  test('the trip length the rider reads above the services', () {
    expect(tripLengthWords({'distance': 1.04, 'time': 4.2}, true), 'مسافة رحلتك 1.0 كم · حوالي 4 دقائق');
    expect(tripLengthWords({'distance': '23.6', 'time': 31}, true), 'مسافة رحلتك 24 كم · حوالي 31 دقيقة');
    expect(tripLengthWords({'distance': 7.4}, false), 'Your trip: 7.4 km');
    expect(tripLengthWords({'distance': 0}, true), isNull);
  });
}
