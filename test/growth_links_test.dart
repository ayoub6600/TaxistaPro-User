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

  test('the countdown reads in days, then hours:minutes:seconds, and ends at zero', () {
    expect(MyGiftsPageCountdown.text(const Duration(days: 1, hours: 3, minutes: 5)), 'باقي 1 يوم و03:05');
    expect(MyGiftsPageCountdown.text(const Duration(hours: 5, minutes: 4, seconds: 9)), 'باقي 05:04:09');
    expect(MyGiftsPageCountdown.text(Duration.zero), 'انتهت');
  });
}
