import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/rider_password_reset.dart';

class _Recorded {
  _Recorded(this.request);
  final http.Request request;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

RiderPasswordResetApi _apiReturning(
  int status,
  Object? body, {
  List<_Recorded>? log,
}) {
  return RiderPasswordResetApi(
    baseUrl: 'https://api.example.test/',
    client: MockClient((request) async {
      log?.add(_Recorded(request));
      final encoded = body is String ? body : jsonEncode(body);
      return http.Response(encoded, status,
          headers: {'content-type': 'application/json'});
    }),
  );
}

void main() {
  group('helpers', () {
    test('normalizeDialCode canonicalises to +digits', () {
      expect(normalizeDialCode('+218'), '+218');
      expect(normalizeDialCode('20'), '+20');
      expect(normalizeDialCode(' +20 '), '+20');
      expect(normalizeDialCode('abc'), '');
    });

    test('localDigits keeps digits only and does not drop the trunk zero', () {
      expect(localDigits('091 234-5678'), '0912345678');
    });
  });

  // Libya and Egypt riders can share the same local digits: the dial code is
  // what tells the backend which account is meant.
  for (final country in const [
    ('+218', '912345678'),
    ('+20', '1012345678'),
  ]) {
    final dial = country.$1;
    final mobile = country.$2;

    group('rider recovery for $dial', () {
      test('send-otp posts country + mobile to password/rider/send-otp',
          () async {
        final log = <_Recorded>[];
        final result = await _apiReturning(200, {'success': true}, log: log)
            .sendOtp(country: dial, mobile: mobile);

        expect(result.ok, isTrue);
        expect(log.single.request.method, 'POST');
        expect(log.single.request.url.toString(),
            'https://api.example.test/api/v1/password/rider/send-otp');
        expect(log.single.request.headers['Accept'], 'application/json');
        expect(log.single.body, {'country': dial, 'mobile': mobile});
      });

      test('verify-otp returns the reset token and sends the code as typed',
          () async {
        final log = <_Recorded>[];
        final result = await _apiReturning(
                200,
                {
                  'success': true,
                  'data': {'reset_token': 'tok-123'},
                },
                log: log)
            .verifyOtp(country: dial, mobile: mobile, otp: ' 123456 ');

        expect(result.ok, isTrue);
        expect(result.data, 'tok-123');
        expect(
            log.single.request.url.path, '/api/v1/password/rider/verify-otp');
        expect(log.single.body,
            {'country': dial, 'mobile': mobile, 'otp': '123456'});
      });

      test('reset sends token + password + confirmation, never the OTP',
          () async {
        final log = <_Recorded>[];
        final result =
            await _apiReturning(200, {'success': true}, log: log).reset(
          country: dial,
          mobile: mobile,
          resetToken: 'tok-123',
          password: 'new-password',
          passwordConfirmation: 'new-password',
        );

        expect(result.ok, isTrue);
        expect(log.single.request.url.path, '/api/v1/password/rider/reset');
        expect(log.single.body, {
          'country': dial,
          'mobile': mobile,
          'reset_token': 'tok-123',
          'password': 'new-password',
          'password_confirmation': 'new-password',
        });
        expect(log.single.body.containsKey('otp'), isFalse);
      });
    });
  }

  group('failures', () {
    test('a 200 without a reset token is a failure', () async {
      final result = await _apiReturning(200, {'success': true, 'data': {}})
          .verifyOtp(country: '+20', mobile: '1012345678', otp: '123456');
      expect(result.failure, RiderResetFailure.server);
    });

    test(
        '422 wrong code / no such rider is a validation failure with the message',
        () async {
      final result = await _apiReturning(422, {
        'success': false,
        'errors': {
          'otp': ['The code is invalid.'],
        },
      }).verifyOtp(country: '+20', mobile: '1012345678', otp: '000000');

      expect(result.failure, RiderResetFailure.validation);
      expect(result.field, 'otp');
      expect(result.message, 'The code is invalid.');
    });

    test('400 and 429 are rate-limit failures', () async {
      for (final status in [400, 429]) {
        final result = await _apiReturning(status, {'message': 'Wait.'})
            .sendOtp(country: '+218', mobile: '912345678');
        expect(result.failure, RiderResetFailure.rateLimited,
            reason: '$status');
        expect(result.message, 'Wait.');
      }
    });

    test('422 on reset_token means expired or already used', () async {
      final result = await _apiReturning(422, {
        'errors': {
          'reset_token': ['expired'],
        },
      }).reset(
        country: '+218',
        mobile: '912345678',
        resetToken: 'old',
        password: 'new-password',
        passwordConfirmation: 'new-password',
      );
      expect(result.failure, RiderResetFailure.resetTokenInvalid);
    });

    test('422 on password stays a plain validation failure', () async {
      final result = await _apiReturning(422, {
        'errors': {
          'password': ['too short'],
        },
      }).reset(
        country: '+218',
        mobile: '912345678',
        resetToken: 'tok',
        password: 'x',
        passwordConfirmation: 'x',
      );
      expect(result.failure, RiderResetFailure.validation);
    });

    test('network problems and timeouts are reported as network', () async {
      for (final error in <Object>[
        const SocketException('offline'),
        TimeoutException('slow'),
        http.ClientException('dns'),
      ]) {
        final api = RiderPasswordResetApi(
          baseUrl: 'https://api.example.test/',
          client: MockClient((_) async => throw error),
        );
        final result = await api.sendOtp(country: '+20', mobile: '1012345678');
        expect(result.failure, RiderResetFailure.network, reason: '$error');
      }
    });

    test('5xx and non-JSON bodies are server failures', () async {
      expect(
        (await _apiReturning(500, {'message': 'boom'})
                .sendOtp(country: '+20', mobile: '1012345678'))
            .failure,
        RiderResetFailure.server,
      );
      expect(
        (await _apiReturning(200, '<html>oops</html>')
                .sendOtp(country: '+20', mobile: '1012345678'))
            .failure,
        RiderResetFailure.server,
      );
    });
  });
}
