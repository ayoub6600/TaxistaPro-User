import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/money_label.dart';

void main() {
  test('a ride in Libya reads in dinars', () {
    expect(moneyLabel('LYD', arabic: true), 'دينار');
    expect(moneyLabel('د.ل', arabic: true), 'دينار');
    expect(moneyLabel('LYD', arabic: false), 'LYD');
  });

  test('a ride in Egypt never reads in dinars', () {
    expect(moneyLabel('EGP', arabic: true), 'جنيه');
    expect(moneyLabel('£', arabic: true), 'جنيه');
    expect(moneyLabel('EGP', arabic: false), 'EGP');
  });

  test('another currency shows as it came, and a missing one stays the old default', () {
    expect(moneyLabel('TND', arabic: true), 'TND');
    expect(moneyLabel(null, arabic: true), 'دينار');
  });
}
