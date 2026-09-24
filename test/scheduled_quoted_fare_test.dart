import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/functions.dart';

void main() {
  test('scheduled request uses admin-priced quote, immediate payment stays fair', () {
    final eta = <String, dynamic>{'total': 29, 'scheduled_total': 31.90};
    expect(scheduledQuotedFare(eta), 31.90);
    expect(quotedFareForPayment(eta, scheduled: false, discounted: false), 29);
    expect(quotedFareForPayment(eta, scheduled: true, discounted: false), 31.90);
  });

  test('scheduled promo floor is the amount shown to the rider', () {
    final eta = <String, dynamic>{
      'total': 29, 'has_discount': true, 'discounted_totel': 26,
      'scheduled_total': 32, 'scheduled_discounted_total': 29,
    };
    expect(scheduledQuotedFare(eta), 29);
    expect(quotedFareForPayment(eta, scheduled: true, discounted: true), 29);
    expect(quotedFareForPayment(eta, scheduled: true, discounted: false), 32);
  });

  test('destination-less ETA does not synthesize a scheduled premium', () {
    expect(scheduledQuotedFare(<String, dynamic>{'total': 29}), 29);
  });
}
