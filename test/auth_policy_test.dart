import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/login/auth/auth_policy.dart';

void main() {
  test('reads country-specific OTP policy from the API', () {
    final policy = CountryAuthPolicy.fromApi(2, {
      'id': 8,
      'name': 'Libya',
      'code': 'ly',
      'dial_code': '+218',
      'dial_min_length': 9,
      'dial_max_length': 10,
      'signup_otp_channel': 'whatsapp',
      'service_locations': [
        {
          'id': 'libya-service',
          'name': 'ليبيا',
          'zones': [
            {'id': 'tripoli', 'name': 'طرابلس'},
            {'id': 'misrata', 'name': 'مصراتة'},
          ],
        },
      ],
    });

    expect(policy.code, 'LY');
    expect(policy.channel, SignupOtpChannel.whatsapp);
    expect(policy.areas.map((area) => area.name), ['طرابلس', 'مصراتة']);
    expect(policy.areas.first.serviceLocationId, 'libya-service');
  });

  test('uses safe defaults for an older backend response', () {
    final policy = CountryAuthPolicy.fromApi(0, const {});

    expect(policy.channel, SignupOtpChannel.sms);
  });

  test('registration flow is phone then OTP for every country', () {
    const expected = [
      SignupField.name,
      SignupField.country,
      SignupField.area,
      SignupField.email,
      SignupField.password,
      SignupField.phone,
      SignupField.otp,
      SignupField.gender,
    ];

    // The flow takes no country input at all, so nothing a country's API
    // policy says (email, WhatsApp, SMS, ...) can fork it.
    expect(signupFlowFor(), expected);
  });

  test('skips country and area after current location is resolved', () {
    expect(
      signupFlowFor(locationResolved: true),
      [
        SignupField.name,
        SignupField.email,
        SignupField.password,
        SignupField.phone,
        SignupField.otp,
        SignupField.gender,
      ],
    );
  });

  test('email OTP never comes before the phone in registration', () {
    // An Egypt-style policy that still advertises email as its channel must
    // parse without reintroducing an email-first registration flow or an
    // email requirement.
    final policy = CountryAuthPolicy.fromApi(0, {
      'signup_otp_channel': 'email',
      'email_optional': false,
    });

    expect(policy.channel, SignupOtpChannel.email);
    final flow = signupFlowFor();
    expect(flow.indexOf(SignupField.phone),
        lessThan(flow.indexOf(SignupField.otp)));
  });

  test('suggests Gmail only after a compatible at-sign prefix', () {
    expect(gmailSuggestionFor('taxista@'), 'taxista@gmail.com');
    expect(gmailSuggestionFor('taxista@gm'), 'taxista@gmail.com');
    expect(gmailSuggestionFor('taxista@gmail.com'), isNull);
    expect(gmailSuggestionFor('taxista@yahoo'), isNull);
  });
}
