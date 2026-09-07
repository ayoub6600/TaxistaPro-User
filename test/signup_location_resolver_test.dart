import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/pages/login/auth/auth_policy.dart';
import 'package:taxista/pages/login/auth/signup_location_resolver.dart';

void main() {
  final egypt = CountryAuthPolicy.fromApi(0, {
    'id': 231,
    'code': 'EG',
    'name': 'مصر',
    'service_locations': [
      {
        'id': 'egypt-service',
        'name': 'مصر',
        'zones': [
          {'id': 'qena-zone', 'name': 'قنا'},
        ],
      },
    ],
  });

  test('maps a resolved backend zone to the loaded signup policy', () {
    final resolved = resolvedSignupLocationFromJson([
      egypt
    ], {
      'success': true,
      'data': {
        'country_id': 231,
        'country_code': 'EG',
        'zone_id': 'qena-zone',
      },
    });

    expect(resolved?.country.name, 'مصر');
    expect(resolved?.area.name, 'قنا');
    expect(resolved?.area.serviceLocationId, 'egypt-service');
  });

  test('returns null for a location outside configured areas', () {
    expect(
      resolvedSignupLocationFromJson([
        egypt
      ], {
        'success': false,
        'data': null,
      }),
      isNull,
    );
  });
}
