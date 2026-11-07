import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/growth/growth_api.dart';
import 'package:taxista/growth/my_gifts_page.dart';

void main() {
  test('only a gift link opens «هداياي»', () {
    expect(GrowthLinks.refFrom('/offers/AbC123'), 'AbC123');
    expect(GrowthLinks.refFrom('https://taxista.aljidartech.com/offers/AbC123?utm=x'), 'AbC123');
    expect(GrowthLinks.refFrom('/offers/'), isNull);
    expect(GrowthLinks.refFrom('/offers/../../admin'), isNull);
    expect(GrowthLinks.refFrom('/'), isNull);
    expect(GrowthLinks.refFrom(null), isNull);
  });

  test('the countdown reads in words for days, a clock under a day, and ends at zero', () {
    expect(MyGiftsPageCountdown.text(const Duration(days: 1, hours: 23, minutes: 41)), 'باقي يوم و23 ساعة');
    expect(MyGiftsPageCountdown.text(const Duration(days: 2)), 'باقي يومين');
    expect(MyGiftsPageCountdown.text(const Duration(days: 6, hours: 1)), 'باقي 6 أيام و1 ساعة');
    expect(MyGiftsPageCountdown.text(const Duration(hours: 5, minutes: 4, seconds: 9)), 'باقي \u206605:04:09\u2069');
    expect(MyGiftsPageCountdown.text(Duration.zero), 'انتهت');
  });
}
