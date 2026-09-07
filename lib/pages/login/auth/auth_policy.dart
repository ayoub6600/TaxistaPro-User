enum SignupOtpChannel { sms, email, whatsapp, firebase }

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
      flag: json['flag']?.toString(),
    );
  }

  static SignupOtpChannel _channelFrom(String value) {
    return SignupOtpChannel.values.firstWhere(
      (item) => item.name == value.toLowerCase(),
      orElse: () => SignupOtpChannel.sms,
    );
  }

  SignupOtpChannel channelFor({required bool hasEmail}) {
    if (channel == SignupOtpChannel.email && !hasEmail) {
      return SignupOtpChannel.sms;
    }
    return channel;
  }
}
