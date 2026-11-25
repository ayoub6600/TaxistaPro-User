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

  test('the rider reads «11 د.ل»: amount first, no «.00», never «LYD» (owner 2026-11-25)', () {
    expect(moneyAmount(11.0), '11');
    expect(moneyAmount('11.00'), '11');
    expect(moneyAmount(11.5), '11.50');
    expect(moneyAmount('7.25'), '7.25');
    expect(moneyAmount(0), '0');
    expect(moneyAmount(-4), '-4');
    expect(moneyText(11, 'LYD', arabic: true), '11 د.ل');
    expect(moneyText('15.00', 'LYD', arabic: true), '15 د.ل');
    expect(moneyText(40, 'EGP', arabic: true), '40 ج.م');
    expect(moneyText(11, 'LYD', arabic: false), '11 LYD');
  });
}
