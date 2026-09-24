import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/rider_password_reset.dart';
import 'package:taxista/pages/login/auth/auth_policy.dart';
import 'package:taxista/pages/login/auth/modern_forgot_password.dart';

CountryAuthPolicy _policy(int index, String name, String code, String dial,
        int min, int max, SignupOtpChannel channel) =>
    CountryAuthPolicy(
      index: index,
      id: index + 1,
      name: name,
      code: code,
      dialCode: dial,
      minPhoneLength: min,
      maxPhoneLength: max,
      channel: channel,
      areas: const [],
    );

// Egypt's policy channel is `email`: forgot-password must ignore it - the
// recovery is phone-only for every country.
final _libya =
    _policy(0, 'Libya', 'LY', '+218', 9, 9, SignupOtpChannel.whatsapp);
final _egypt = _policy(1, 'Egypt', 'EG', '+20', 10, 10, SignupOtpChannel.email);

/// A scripted backend: each entry answers the next request to a path suffix.
class _FakeBackend {
  final requests = <({String path, Map<String, dynamic> body})>[];
  final _script = <String, List<http.Response>>{};

  void on(String path, int status, Object body) {
    _script.putIfAbsent(path, () => []).add(http.Response(
        jsonEncode(body), status,
        headers: {'content-type': 'application/json'}));
  }

  RiderPasswordResetApi api() => RiderPasswordResetApi(
        baseUrl: 'https://api.example.test/',
        client: MockClient((request) async {
          final path = request.url.path;
          requests.add((
            path: path,
            body: jsonDecode(request.body) as Map<String, dynamic>,
          ));
          final queue = _script[path.split('/').last];
          if (queue == null || queue.isEmpty) {
            fail('Unexpected request to $path');
          }
          return queue.removeAt(0);
        }),
      );
}

void main() {
  Future<void> openScreen(
    WidgetTester tester,
    _FakeBackend backend, {
    CountryAuthPolicy? initial,
    void Function(bool?)? onResult,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final changed =
                    await Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) => ModernForgotPassword(
                    policies: [_libya, _egypt],
                    initialCountry: initial,
                    api: backend.api(),
                  ),
                ));
                onResult?.call(changed);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> sendCode(WidgetTester tester, String phone) async {
    await tester.enterText(field('Phone number'), phone);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Future<void> verifyCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();
  }

  for (final c in [
    (_libya, '+218', '912345678'),
    (_egypt, '+20', '1012345678'),
  ]) {
    final policy = c.$1;
    final dial = c.$2;
    final phone = c.$3;

    testWidgets(
        'full recovery for ${policy.name}: phone -> code -> new password -> back to login',
        (tester) async {
      final backend = _FakeBackend()
        ..on('send-otp', 200, {'success': true})
        ..on('verify-otp', 200, {
          'success': true,
          'data': {'reset_token': 'tok-abc'},
        })
        ..on('reset', 200, {'success': true});
      bool? changed;
      await openScreen(tester, backend,
          initial: policy, onResult: (value) => changed = value);

      // Phone only - no email field, whatever the country's policy channel is.
      expect(find.text('Recover your account'), findsOneWidget);
      expect(field('Email address'), findsNothing);
      await sendCode(tester, phone);
      expect(backend.requests.single.path, '/api/v1/password/rider/send-otp');
      expect(backend.requests.single.body, {'country': dial, 'mobile': phone});

      expect(find.text('Enter verification code'), findsOneWidget);
      await verifyCode(tester, '123456');
      expect(backend.requests.last.path, '/api/v1/password/rider/verify-otp');
      expect(backend.requests.last.body,
          {'country': dial, 'mobile': phone, 'otp': '123456'});

      expect(find.text('Create a new password'), findsOneWidget);
      await tester.enterText(field('New password'), 'new-password-1');
      await tester.enterText(field('Confirm password'), 'new-password-1');
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();

      expect(backend.requests.last.path, '/api/v1/password/rider/reset');
      expect(backend.requests.last.body, {
        'country': dial,
        'mobile': phone,
        'reset_token': 'tok-abc',
        'password': 'new-password-1',
        'password_confirmation': 'new-password-1',
      });
      // Only the three rider recovery endpoints were ever called.
      expect(
        backend.requests.map((r) => r.path),
        [
          '/api/v1/password/rider/send-otp',
          '/api/v1/password/rider/verify-otp',
          '/api/v1/password/rider/reset',
        ],
      );
      // Back on the host (login) route: no session, just `true`.
      expect(find.byType(ModernForgotPassword), findsNothing);
      expect(changed, isTrue);
    });
  }

  testWidgets('an invalid phone is caught client-side without a request',
      (tester) async {
    final backend = _FakeBackend();
    await openScreen(tester, backend, initial: _egypt);

    await sendCode(tester, '123');

    expect(find.text('Check your phone number.'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('a wrong code stays on the code step and shows the error',
      (tester) async {
    final backend = _FakeBackend()
      ..on('send-otp', 200, {'success': true})
      ..on('verify-otp', 422, {
        'success': false,
        'errors': {
          'otp': ['The code is invalid.'],
        },
      });
    await openScreen(tester, backend, initial: _libya);
    await sendCode(tester, '912345678');

    await verifyCode(tester, '000000');

    expect(find.text('The code is invalid.'), findsOneWidget);
    expect(find.text('Enter verification code'), findsOneWidget);
  });

  testWidgets('password rules are checked before any reset request',
      (tester) async {
    final backend = _FakeBackend()
      ..on('send-otp', 200, {'success': true})
      ..on('verify-otp', 200, {
        'success': true,
        'data': {'reset_token': 'tok'},
      });
    await openScreen(tester, backend, initial: _libya);
    await sendCode(tester, '912345678');
    await verifyCode(tester, '123456');

    await tester.enterText(field('New password'), 'short');
    await tester.enterText(field('Confirm password'), 'short');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);

    await tester.enterText(field('New password'), 'long-enough-1');
    await tester.enterText(field('Confirm password'), 'different-1');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match.'), findsOneWidget);

    expect(backend.requests.map((r) => r.path.split('/').last),
        ['send-otp', 'verify-otp']);
  });

  testWidgets('an expired reset token sends the rider back for a new code',
      (tester) async {
    final backend = _FakeBackend()
      ..on('send-otp', 200, {'success': true})
      ..on('verify-otp', 200, {
        'success': true,
        'data': {'reset_token': 'tok'},
      })
      ..on('reset', 422, {
        'success': false,
        'errors': {
          'reset_token': ['expired'],
        },
      });
    await openScreen(tester, backend, initial: _libya);
    await sendCode(tester, '912345678');
    await verifyCode(tester, '123456');
    await tester.enterText(field('New password'), 'new-password-1');
    await tester.enterText(field('Confirm password'), 'new-password-1');

    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();

    expect(find.text('Recover your account'), findsOneWidget);
    expect(find.text('expired'), findsOneWidget);
  });

  testWidgets('going back from the password step discards the reset token',
      (tester) async {
    final backend = _FakeBackend()
      ..on('send-otp', 200, {'success': true})
      ..on('verify-otp', 200, {
        'success': true,
        'data': {'reset_token': 'tok'},
      });
    await openScreen(tester, backend, initial: _libya);
    await sendCode(tester, '912345678');
    await verifyCode(tester, '123456');
    expect(find.text('Create a new password'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Recover your account'), findsOneWidget);
    expect(find.byType(ModernForgotPassword), findsOneWidget);
  });
}
