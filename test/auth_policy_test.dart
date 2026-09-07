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
      'email_optional': true,
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
    expect(policy.emailOptional, isTrue);
    expect(policy.areas.map((area) => area.name), ['طرابلس', 'مصراتة']);
    expect(policy.areas.first.serviceLocationId, 'libya-service');
  });

  test('falls back to SMS when email OTP is selected but email was skipped',
      () {
    final policy = CountryAuthPolicy.fromApi(0, {
      'signup_otp_channel': 'email',
      'email_optional': true,
    });

    expect(policy.channelFor(hasEmail: false), SignupOtpChannel.sms);
    expect(policy.channelFor(hasEmail: true), SignupOtpChannel.email);
  });

  test('uses safe defaults for an older backend response', () {
    final policy = CountryAuthPolicy.fromApi(0, const {});

    expect(policy.channel, SignupOtpChannel.sms);
    expect(policy.emailOptional, isTrue);
  });

  test('email verification happens before phone for an email country', () {
    final policy = CountryAuthPolicy.fromApi(0, {
      'signup_otp_channel': 'email',
      'email_optional': false,
    });

    expect(
      signupFlowFor(policy, hasEmail: true),
      [
        SignupField.name,
        SignupField.country,
        SignupField.area,
        SignupField.email,
        SignupField.password,
        SignupField.otp,
        SignupField.phone,
        SignupField.gender,
      ],
    );
  });

  test('skips country and area after current location is resolved', () {
    final policy = CountryAuthPolicy.fromApi(0, {
      'signup_otp_channel': 'email',
      'email_optional': false,
    });

    expect(
      signupFlowFor(policy, hasEmail: true, locationResolved: true),
      [
        SignupField.name,
        SignupField.email,
        SignupField.password,
        SignupField.otp,
        SignupField.phone,
        SignupField.gender,
      ],
    );
  });

  test('phone comes before OTP for a WhatsApp country', () {
    final policy = CountryAuthPolicy.fromApi(0, {
      'signup_otp_channel': 'whatsapp',
      'email_optional': true,
    });

    expect(
      signupFlowFor(policy, hasEmail: false),
      [
        SignupField.name,
        SignupField.country,
        SignupField.area,
        SignupField.email,
        SignupField.password,
        SignupField.phone,
        SignupField.otp,
        SignupField.gender,
      ],
    );
  });

  test('suggests Gmail only after a compatible at-sign prefix', () {
    expect(gmailSuggestionFor('taxista@'), 'taxista@gmail.com');
    expect(gmailSuggestionFor('taxista@gm'), 'taxista@gmail.com');
    expect(gmailSuggestionFor('taxista@gmail.com'), isNull);
    expect(gmailSuggestionFor('taxista@yahoo'), isNull);
  });
}
