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
    required this.emailOptional,
    required this.areas,
    this.flag,
  });

  final int index;
  final int id;
  final String name;
  final String code;
  final String dialCode;
  final int minPhoneLength;
  final int maxPhoneLength;
  final SignupOtpChannel channel;
  final bool emailOptional;
  final List<SignupArea> areas;
  final String? flag;

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
      emailOptional:
          json['email_optional'] != false && json['email_optional'] != 0,
      areas: _areasFrom(json['service_locations']),
      flag: json['flag']?.toString(),
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

  SignupOtpChannel channelFor({required bool hasEmail}) {
    if (channel == SignupOtpChannel.email && !hasEmail) {
      return SignupOtpChannel.sms;
    }
    return channel;
  }
}

List<SignupField> signupFlowFor(
  CountryAuthPolicy policy, {
  required bool hasEmail,
}) {
  final channel = policy.channelFor(hasEmail: hasEmail);
  return [
    SignupField.name,
    SignupField.country,
    SignupField.area,
    SignupField.email,
    SignupField.password,
    if (channel == SignupOtpChannel.email) ...[
      SignupField.otp,
      SignupField.phone,
    ] else ...[
      SignupField.phone,
      SignupField.otp,
    ],
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
