import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/pulse_api.dart';

void main() {
  test('a reminder push becomes a destination to confirm, never a booking', () {
    PulseBookingIntent.pending.value = null;
    PulseBookingIntent.fromPush({'push_type': 'pulse-reminder', 'drop_lat': '32.34', 'drop_lng': '15.05', 'drop_address': 'الجامعة'});
    expect(PulseBookingIntent.pending.value, {'pick_lat': 32.34, 'pick_lng': 15.05, 'pick_address': 'الجامعة'});

    PulseBookingIntent.pending.value = null;
    PulseBookingIntent.fromPush({'push_type': 'pulse-reminder', 'drop_lat': '', 'drop_lng': ''});
    expect(PulseBookingIntent.pending.value, isNull, reason: 'a routine without a destination opens nothing');

    PulseBookingIntent.fromPush({'push_type': 'pulse-reminder', 'drop_lat': '32.34', 'drop_lng': '15.05'});
    expect(PulseBookingIntent.pending.value?['pick_address'], 'وجهتك المعتادة');
  });

  test('without reminders switched on, the app never sends its position', () async {
    PulsePresence.remindersOn = false;
    await PulsePresence.report(); // returns before touching the location service or the network
  });

  test('server answers are read safely', () {
    const r = PulseResult(200, {'success': true, 'data': [{'id': 1}, 'x']});
    expect(r.ok, isTrue);
    expect(r.list.length, 1);
    expect(const PulseResult(0, {}).message, 'انقطع الاتصال بالخادم.');
    expect(const PulseResult(409, {'success': false, 'code': 'fare_confirmation_needed', 'message': 'أكّد'}).code, 'fare_confirmation_needed');
  });
}
