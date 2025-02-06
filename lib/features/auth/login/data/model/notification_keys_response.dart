// To parse this JSON data, do
//
//     final notificationKeysResponse = notificationKeysResponseFromJson(jsonString);

import 'dart:convert';

NotificationKeysResponse notificationKeysResponseFromJson(String str) => NotificationKeysResponse.fromJson(json.decode(str));

String notificationKeysResponseToJson(NotificationKeysResponse data) => json.encode(data.toJson());

class NotificationKeysResponse {
  dynamic msg;
  Data? data;
  bool? success;

  NotificationKeysResponse({
    this.msg,
    this.data,
    this.success,
  });

  factory NotificationKeysResponse.fromJson(Map<String, dynamic> json) => NotificationKeysResponse(
        msg: json["msg"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
        "data": data?.toJson(),
        "success": success,
      };
}

class Data {
  String? appId;
  String? restApiKey;
  String? userAuthKey;
  String? projectNumber;

  Data({
    this.appId,
    this.restApiKey,
    this.userAuthKey,
    this.projectNumber,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        appId: json["APP_ID"],
        restApiKey: json["REST_API_KEY"],
        userAuthKey: json["USER_AUTH_KEY"],
        projectNumber: json["PROJECT_NUMBER"],
      );

  Map<String, dynamic> toJson() => {
        "APP_ID": appId,
        "REST_API_KEY": restApiKey,
        "USER_AUTH_KEY": userAuthKey,
        "PROJECT_NUMBER": projectNumber,
      };
}
