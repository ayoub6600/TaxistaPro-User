import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/functions.dart';

/// Contract tests for the rider's phone-bearing auth calls. The backend
/// resolves accounts by country + number (riders in different countries can
/// share local digits), so every one of these carries the `country` dial code.
/// Registration OTP takes `country` + `mobile` (+ `otp`) and no `uuid`.
void main() {
  late List<http.Request> requests;

  Future<T> withBackend<T>(
    Future<T> Function() body, {
    int status = 200,
    Object responseBody = const {'success': true, 'message': 'success'},
  }) {
    requests = [];
    return http.runWithClient(
      body,
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(responseBody), status,
            headers: {'content-type': 'application/json'});
      }),
    );
  }

  for (final country in const [
    ('+218', '912345678'),
    ('+20', '1012345678'),
  ]) {
    final dialCode = country.$1;
    final mobile = country.$2;

    test('send-otp posts country and mobile only ($dialCode)', () async {
      final result = await withBackend(
        () => sendRegistrationOtp(dialCode, mobile),
      );

      expect(result, 'success');
      expect(requests, hasLength(1));
      expect(requests.single.method, 'POST');
      expect(
          requests.single.url.path, endsWith('api/v1/user/register/send-otp'));
      expect(
          requests.single.bodyFields, {'country': dialCode, 'mobile': mobile});
    });

    test('validate-otp posts country, mobile and otp, never a uuid ($dialCode)',
        () async {
      final result = await withBackend(
        () => validateRegistrationOtp(dialCode, mobile, '123456'),
      );

      expect(result, 'success');
      expect(requests, hasLength(1));
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path,
          endsWith('api/v1/user/register/validate-otp'));
      expect(requests.single.bodyFields, {
        'country': dialCode,
        'mobile': mobile,
        'otp': '123456',
      });
      expect(requests.single.bodyFields.containsKey('uuid'), isFalse);
    });
  }

  test('a wrong code surfaces the backend validation message', () async {
    final result = await withBackend(
      () => validateRegistrationOtp('+20', '1012345678', '000000'),
      status: 422,
      responseBody: {
        'success': false,
        'errors': {
          'otp': ['The otp provided is invalid.'],
        },
      },
    );

    expect(result, 'The otp provided is invalid.');
  });

  test('a resend cooldown surfaces the backend message', () async {
    final result = await withBackend(
      () => sendRegistrationOtp('+218', '912345678'),
      status: 400,
      responseBody: {
        'success': false,
        'message': 'Please wait before requesting another code.',
      },
    );

    expect(result, 'Please wait before requesting another code.');
  });

  test('an unparseable failure falls back to a generic message', () async {
    requests = [];
    final result = await http.runWithClient(
      () => sendRegistrationOtp('+218', '912345678'),
      () => MockClient((_) async => http.Response('<html>oops</html>', 500)),
    );

    expect(result, 'something went wrong');
  });

  group('forgot-password phone calls carry the country dial code', () {
    test('validate-otp sends country alongside mobile and otp', () async {
      await withBackend(
        () => validateSmsOtp('1012345678', '123456', countryDialCode: '+20'),
      );

      expect(requests.single.url.path, endsWith('api/v1/validate-otp'));
      expect(requests.single.bodyFields, {
        'mobile': '1012345678',
        'otp': '123456',
        'country': '+20',
      });
    });

    test('update-password sends country for a phone reset', () async {
      await withBackend(
        () => updatePassword('912345678', 'new-password', false,
            countryDialCode: '+218'),
      );

      expect(requests.single.url.path, endsWith('api/v1/user/update-password'));
      expect(requests.single.bodyFields, {
        'mobile': '912345678',
        'country': '+218',
        'password': 'new-password',
      });
    });

    test('update-password by email does not send a country', () async {
      await withBackend(
        () => updatePassword('rider@example.com', 'new-password', true,
            countryDialCode: '+20'),
      );

      expect(requests.single.bodyFields, {
        'email': 'rider@example.com',
        'password': 'new-password',
      });
    });
  });

  test('validate-mobile-for-login sends country with the mobile', () async {
    await withBackend(
      () => verifyUser('912345678', 0, '', '', false, false,
          countryDialCode: '+218'),
      responseBody: {'success': false},
    );

    expect(requests.single.url.path,
        endsWith('api/v1/user/validate-mobile-for-login'));
    expect(requests.single.bodyFields, {
      'mobile': '912345678',
      'country': '+218',
    });
  });
}
