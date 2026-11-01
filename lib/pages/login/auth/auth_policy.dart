/// The country's `signup_otp_channel` from the countries API. Registration no
/// longer branches on this: every country verifies its phone number with the
/// same Twilio Verify OTP. It only drives the sign-in method default (email vs
/// phone field); forgot-password is phone-only for every country.
enum SignupOtpChannel { sms, email, whatsapp, firebase }

enum SignupField { name, country, area, email, password, phone, otp, gender }

class SignupArea {
  const SignupArea({
    required this.id,
    required this.name,
    required this.serviceLocationId,
    required this.serviceLocationName,
  });

  final String id;
  final String name;
  final String serviceLocationId;
  final String serviceLocationName;
}

class CountryAuthPolicy {
  const CountryAuthPolicy({
    required this.index,
    required this.id,
    required this.name,
    required this.code,
    required this.dialCode,
    required this.minPhoneLength,
    required this.maxPhoneLength,
    required this.channel,
    required this.areas,
    this.flag,
    this.isDefault = false,
  });

  final int index;
  final int id;
  final String name;
  final String code;
  final String dialCode;
  final int minPhoneLength;
  final int maxPhoneLength;
  final SignupOtpChannel channel;
  final List<SignupArea> areas;
  final String? flag;

  /// The country the backend marks `default` (Libya).
  final bool isDefault;

  factory CountryAuthPolicy.fromApi(int index, Map<String, dynamic> json) {
    return CountryAuthPolicy(
      index: index,
      id: int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}'.toUpperCase(),
      dialCode: '${json['dial_code'] ?? ''}',
      minPhoneLength: int.tryParse('${json['dial_min_length']}') ?? 6,
      maxPhoneLength: int.tryParse('${json['dial_max_length']}') ?? 15,
      channel: _channelFrom('${json['signup_otp_channel'] ?? 'sms'}'),
      areas: _areasFrom(json['service_locations']),
      flag: json['flag']?.toString(),
      isDefault: json['default'] == true,
    );
  }

  static SignupOtpChannel _channelFrom(String value) {
    return SignupOtpChannel.values.firstWhere(
      (item) => item.name == value.toLowerCase(),
      orElse: () => SignupOtpChannel.sms,
    );
  }

  static List<SignupArea> _areasFrom(dynamic value) {
    if (value is! List) return const [];
    final areas = <SignupArea>[];
    for (final rawLocation in value) {
      if (rawLocation is! Map) continue;
      final location = Map<String, dynamic>.from(rawLocation);
      final zones = location['zones'];
      if (zones is! List) continue;
      for (final rawZone in zones) {
        if (rawZone is! Map) continue;
        final zone = Map<String, dynamic>.from(rawZone);
        areas.add(SignupArea(
          id: '${zone['id'] ?? ''}',
          name: '${zone['name'] ?? ''}',
          serviceLocationId: '${location['id'] ?? ''}',
          serviceLocationName: '${location['name'] ?? ''}',
        ));
      }
    }
    return areas;
  }
}

/// The country a sign-in screen starts on: where the phone is when that is
/// known, otherwise the backend's default country, never simply the first of
/// the list. The API sorts by name, so Egypt (+20, email sign-in) comes first:
/// a phone whose location could not be read started there and a Libyan number
/// could not sign in.
CountryAuthPolicy? initialSignInCountry(
  List<CountryAuthPolicy> policies, {
  CountryAuthPolicy? detected,
}) {
  if (detected != null) return detected;
  if (policies.isEmpty) return null;
  for (final policy in policies) {
    if (policy.isDefault) return policy;
  }
  for (final policy in policies) {
    if (policy.areas.isNotEmpty) return policy;
  }
  return policies.first;
}

/// The registration steps, identical for every country: the phone number is
/// collected and verified by an OTP sent to it. Email is an optional profile
/// field (skippable, never verified) and plays no part in registration.
List<SignupField> signupFlowFor({bool locationResolved = false}) {
  return [
    SignupField.name,
    if (!locationResolved) ...[
      SignupField.country,
      SignupField.area,
    ],
    SignupField.email,
    SignupField.password,
    SignupField.phone,
    SignupField.otp,
    SignupField.gender,
  ];
}

String? gmailSuggestionFor(String input) {
  final value = input.trim().toLowerCase();
  final at = value.indexOf('@');
  if (at <= 0 || value.indexOf('@', at + 1) != -1) return null;

  final localPart = value.substring(0, at);
  final domain = value.substring(at + 1);
  if (!'gmail.com'.startsWith(domain) || domain == 'gmail.com') return null;
  return '$localPart@gmail.com';
}
