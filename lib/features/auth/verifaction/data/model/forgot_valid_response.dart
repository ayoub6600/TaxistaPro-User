class ForgotValidResponse {
  ForgotValidResponse({
    String? msg,
    Data? data,
    bool? success,
  }) {
    _msg = msg;
    _data = data;
    _success = success;
  }

  ForgotValidResponse.fromJson(dynamic json) {
    _msg = json['msg'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
    _success = json['success'];
  }

  String? _msg;
  Data? _data;
  bool? _success;

  ForgotValidResponse copyWith({
    String? msg,
    Data? data,
    bool? success,
  }) =>
      ForgotValidResponse(
        msg: msg ?? _msg,
        data: data ?? _data,
        success: success ?? _success,
      );

  String? get msg => _msg;

  Data? get data => _data;

  bool? get success => _success;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msg'] = _msg;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    map['success'] = _success;
    return map;
  }
}

class Data {
  Data({
    String? token,
  }) {
    _token = token;
  }

  Data.fromJson(dynamic json) {
    _token = json['token'];
  }

  String? _token;

  Data copyWith({
    String? token,
  }) =>
      Data(
        token: token ?? _token,
      );

  String? get token => _token;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    return map;
  }
}
