import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/repeat_choice.dart';

void main() {
  setUp(RepeatChoice.clear);

  test('a preset selects its days and says them', () {
    RepeatChoice.preset = 'workdays';
    expect(RepeatChoice.selected, {6, 0, 1, 2, 3, 4});
    expect(RepeatChoice.daysLine, 'كل يوم من السبت إلى الخميس');
    RepeatChoice.preset = 'daily';
    expect(RepeatChoice.selected.length, 7);
    expect(RepeatChoice.daysLine, 'كل يوم');
  });

  test('tapping a day turns a preset into his own list, in week order', () {
    RepeatChoice.preset = 'workdays';
    RepeatChoice.toggleDay(4);
    expect(RepeatChoice.preset, 'custom');
    expect(RepeatChoice.selected, {6, 0, 1, 2, 3});
    expect(RepeatChoice.daysLine, 'كل السبت، الأحد، الاثنين، الثلاثاء، الأربعاء');
  });

  test('no day chosen cannot be sent; off always can', () {
    expect(RepeatChoice.readyToSend, isTrue);
    RepeatChoice.preset = 'custom';
    expect(RepeatChoice.readyToSend, isFalse);
    RepeatChoice.toggleDay(5);
    expect(RepeatChoice.readyToSend, isTrue);
  });

  test('the clock reads the way people say it', () {
    expect(RepeatChoice.clock(DateTime(2026, 11, 10, 8)), '8:00 ص');
    expect(RepeatChoice.clock(DateTime(2026, 11, 10, 12, 30)), '12:30 م');
    expect(RepeatChoice.clock(DateTime(2026, 11, 10, 0, 5)), '12:05 ص');
  });
}
