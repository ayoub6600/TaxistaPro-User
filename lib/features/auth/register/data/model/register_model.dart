// To parse this JSON data, do
//
//     final registerResponseModel = registerResponseModelFromJson(jsonString);

import 'dart:convert';

RegisterResponseModel registerResponseModelFromJson(String str) => RegisterResponseModel.fromJson(json.decode(str));

String registerResponseModelToJson(RegisterResponseModel data) => json.encode(data.toJson());

class RegisterResponseModel {
  String? msg;
  RegisterResponseModelData? data;
  bool? success;
  String? flow;

  RegisterResponseModel({
    this.msg,
    this.data,
    this.success,
    this.flow,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) => RegisterResponseModel(
        msg: json["msg"],
        data: json["data"] == null ? null : RegisterResponseModelData.fromJson(json["data"]),
        success: json["success"],
        flow: json["flow"],
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
        "data": data?.toJson(),
        "success": success,
        "flow": flow,
      };
}

class RegisterResponseModelData {
  String? email;
  String? name;
  String? phoneNo;
  String? otp;
  int? id;
  dynamic imageUri;

  RegisterResponseModelData({
    this.email,
    this.name,
    this.phoneNo,
    this.otp,
    this.id,
    this.imageUri,
  });

  factory RegisterResponseModelData.fromJson(Map<String, dynamic> json) => RegisterResponseModelData(
        email: json["email"],
        name: json["name"],
        phoneNo: json["phone_no"],
        otp: json["otp"],
        id: json["id"],
        imageUri: json["imageUri"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "name": name,
        "phone_no": phoneNo,
        "otp": otp,
        "id": id,
        "imageUri": imageUri,
      };
}
