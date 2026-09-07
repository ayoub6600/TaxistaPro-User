import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'auth_policy.dart';

class ResolvedSignupLocation {
  const ResolvedSignupLocation({required this.country, required this.area});

  final CountryAuthPolicy country;
  final SignupArea area;
}

ResolvedSignupLocation? resolvedSignupLocationFromJson(
  List<CountryAuthPolicy> policies,
  Map<String, dynamic> json,
) {
  final data = json['data'];
  if (json['success'] != true || data is! Map) return null;

  final values = Map<String, dynamic>.from(data);
  final countryId = int.tryParse('${values['country_id']}');
  final countryCode = '${values['country_code'] ?? ''}'.toUpperCase();
  final zoneId = '${values['zone_id'] ?? ''}';

  for (final policy in policies) {
    if (policy.id != countryId && policy.code != countryCode) continue;
    for (final area in policy.areas) {
      if (area.id == zoneId) {
        return ResolvedSignupLocation(country: policy, area: area);
      }
    }
  }
  return null;
}

Future<ResolvedSignupLocation?> detectSignupLocation({
  required String baseUrl,
  required List<CountryAuthPolicy> policies,
}) async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 12),
    ),
  );
  final uri = Uri.parse(baseUrl).resolve('api/v1/signup-location').replace(
    queryParameters: {
      'lat': position.latitude.toString(),
      'lng': position.longitude.toString(),
    },
  );
  final response = await http.get(uri).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) return null;

  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return null;
  return resolvedSignupLocationFromJson(
    policies,
    Map<String, dynamic>.from(decoded),
  );
}
