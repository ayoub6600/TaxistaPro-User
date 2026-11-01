// The sign-in screen must start on Libya (+218) and send +218 with a Libyan
// number. Two ways it failed on 2026-11-01:
//  - rider APK 6.5.0+39 was built without API_BASE_URL and pointed at
//    127.0.0.1, so the country list never loaded and nobody could sign in;
//  - whenever the phone's location could not be read the screen fell back to
//    the first country of the API (Egypt, +20, email sign-in) instead of the
//    backend's default (Libya).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/api_base_url.dart';
import 'package:taxista/functions/functions.dart' as app;
import 'package:taxista/pages/login/auth/auth_policy.dart';
import 'package:taxista/pages/login/auth/modern_login.dart';

/// `api/v1/countries-new` as production answered on 2026-11-01: sorted by
/// name, so Egypt (no active service location since 2026-10-29) comes first
/// and Libya carries `default: true`.
Map<String, dynamic> _productionCountries() => {
      'success': true,
      'data': {
        'countries': {
          'data': [
            {
              'id': 231,
              'name': 'Egypt',
              'code': 'EG',
              'dial_code': '+20',
              'default': false,
              'dial_min_length': 7,
              'dial_max_length': 14,
              'signup_otp_channel': 'email',
              'service_locations': [],
            },
            {
              'id': 124,
              'name': 'Libya',
              'code': 'LY',
              'dial_code': '+218',
              'default': true,
              'dial_min_length': 7,
              'dial_max_length': 14,
              'signup_otp_channel': 'whatsapp',
              'service_locations': [
                {
                  'id': '8073ae30-faba-4943-bccc-9dddf5e9a6bb',
                  'name': 'ليبيا',
                  'zones': [
                    {'id': 'f9aafc1e-d83f-4269-b5f9-7ebdf3006f60', 'name': 'طرابلس'},
                    {'id': '4466d222-d0c8-4c95-a5ce-37da2d63f2e7', 'name': 'مصراتة'},
                  ],
                },
              ],
            },
          ],
        },
        'onboarding': {'data': []},
      },
    };

List<CountryAuthPolicy> _policies(Map<String, dynamic> body) {
  final list = body['data']['countries']['data'] as List;
  return [
    for (var i = 0; i < list.length; i++)
      CountryAuthPolicy.fromApi(i, Map<String, dynamic>.from(list[i] as Map)),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('initial sign-in country', () {
    test('location unknown: the backend default (Libya), not the first (Egypt)',
        () {
      final policies = _policies(_productionCountries());
      expect(policies.first.code, 'EG');

      final selected = initialSignInCountry(policies);

      expect(selected?.code, 'LY');
      expect(selected?.dialCode, '+218');
      expect(selected?.channel, SignupOtpChannel.whatsapp);
    });

    test('a detected location wins over the default', () {
      final policies = _policies(_productionCountries());

      expect(initialSignInCountry(policies, detected: policies.first)?.code,
          'EG');
    });

    test('no default flag: a country that has service areas', () {
      final body = _productionCountries();
      for (final c in body['data']['countries']['data'] as List) {
        (c as Map)['default'] = false;
      }

      expect(initialSignInCountry(_policies(body))?.code, 'LY');
    });

    test('nothing loaded: no country', () {
      expect(initialSignInCountry(const []), isNull);
    });
  });

  test('tests and debug runs use the local backend; release uses production',
      () {
    // A release build cannot be exercised from a test; the release APK script
    // (tool/build_release_apk.sh) reads the address compiled into the APK.
    expect(apiBaseUrl, localApiBaseUrl);
    expect(productionApiBaseUrl, 'https://taxista.aljidartech.com/');
  });

  group('sign-in screen', () {
    late List<http.Request> requests;

    setUp(() {
      requests = [];
      app.countries = [];
      // The phone's location cannot be read (location services off).
      for (final name in const [
        'flutter.baseflow.com/geolocator',
        'flutter.baseflow.com/geolocator_android',
        'flutter.baseflow.com/geolocator_apple',
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(name), (call) async {
          return call.method == 'isLocationServiceEnabled' ? false : null;
        });
      }
    });

    Future<void> openLogin(
        WidgetTester tester, Future<http.Response> Function(http.Request) server) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(home: ModernLogin()));
        // the country list, the location attempt, the modules call
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => MockClient((request) async {
            requests.add(request);
            return server(request);
          }));
    }

    http.Response json(Object body, [int status = 200]) => http.Response.bytes(
        utf8.encode(jsonEncode(body)), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

    testWidgets(
        'starts on Libya +218 and signs in a Libyan number with +218, '
        'even when the FCM token cannot be read', (tester) async {
      await openLogin(tester, (request) async {
        final path = request.url.path;
        if (path.endsWith('countries-new')) return json(_productionCountries());
        if (path.endsWith('user/login')) {
          return json({'success': false, 'message': 'wrong password'}, 401);
        }
        return json({});
      });

      expect(find.text('Libya  +218'), findsOneWidget);
      expect(find.text('Egypt  +20'), findsNothing);
      expect(find.text('Phone number'), findsOneWidget);

      await http.runWithClient(() async {
        await tester.enterText(find.byType(TextField).at(0), '0912345678');
        await tester.enterText(find.byType(TextField).at(1), 'not-a-real-pass');
        await tester.tap(find.text('Sign in'));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => MockClient((request) async {
            requests.add(request);
            return json({'success': false}, 401);
          }));

      // No Firebase in tests: getToken() throws, and the sign-in still goes.
      final login =
          requests.where((r) => r.url.path.endsWith('user/login')).toList();
      expect(login, hasLength(1));
      final body = jsonDecode(login.single.body) as Map<String, dynamic>;
      expect(body['country'], '+218');
      expect(body['mobile'], '0912345678');
      expect(find.textContaining('login details are incorrect'), findsOneWidget);
    });

    testWidgets(
        'server unreachable: says so and offers a reload, which then starts on Libya',
        (tester) async {
      var reachable = false;
      await openLogin(tester, (request) async {
        if (!reachable) throw const SocketException('Connection refused');
        if (request.url.path.endsWith('countries-new')) {
          return json(_productionCountries());
        }
        return json({});
      });

      expect(find.textContaining("Couldn't reach the server"), findsOneWidget);
      expect(find.text('Reload countries'), findsOneWidget);

      reachable = true;
      await http.runWithClient(() async {
        await tester.tap(find.text('Reload countries'));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => MockClient((request) async {
            if (request.url.path.endsWith('countries-new')) {
              return json(_productionCountries());
            }
            return json({});
          }));

      expect(find.text('Libya  +218'), findsOneWidget);
      expect(find.textContaining("Couldn't reach the server"), findsNothing);
    });
  });
}
