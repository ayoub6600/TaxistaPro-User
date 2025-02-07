class LoginResponce {
  String? tokenType;
  int? expiresIn;
  String? accessToken;

  LoginResponce({this.tokenType, this.expiresIn, this.accessToken});

  factory LoginResponce.fromJson(Map<String, dynamic> json) => LoginResponce(
        tokenType: json['token_type'] as String?,
        expiresIn: json['expires_in'] as int?,
        accessToken: json['access_token'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'token_type': tokenType,
        'expires_in': expiresIn,
        'access_token': accessToken,
      };
}
