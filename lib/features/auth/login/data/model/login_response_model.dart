import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  String? msg;
  LoginResponseData? data;
  bool? success;
  bool? verification;
  Map<String, dynamic>? errors; // Added errors field

  LoginResponse({
    this.msg,
    this.data,
    this.success,
    this.verification,
    this.errors, // Initialize errors
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        msg: json["msg"],
        data: json["data"] == null
            ? null
            : LoginResponseData.fromJson(json["data"]),
        success: json["success"],
        verification: json["verification"],
        errors: json["errors"], // Parse errors if present
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
        "data": data?.toJson(),
        "success": success,
        "verification": verification,
        "errors": errors, // Include errors in JSON
      };
}

class LoginResponseData {
  int? id;
  String? name;
  String? email;
  String? phoneNo;
  String? image;
  dynamic address;
  dynamic deviceToken;
  int? status;
  dynamic otp;
  int? noti;
  int? verified;
  String? token;
  String? fcmToken;
  String? imageUri;
  String? gender;

  LoginResponseData({
    this.id,
    this.name,
    this.email,
    this.phoneNo,
    this.image,
    this.address,
    this.deviceToken,
    this.status,
    this.otp,
    this.noti,
    this.verified,
    this.token,
    this.imageUri,
    this.fcmToken,
    this.gender,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) =>
      LoginResponseData(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phoneNo: json["phone_no"],
        image: json["image"],
        address: json["address"],
        deviceToken: json["device_token"],
        status: json["status"],
        otp: json["otp"],
        noti: json["noti"],
        verified: json["verified"],
        token: json["token"],
        imageUri: json["imageUri"],
        fcmToken: json["fcm_token"],
        gender: json["gender"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "phone_no": phoneNo,
        "image": image,
        "address": address,
        "device_token": deviceToken,
        "status": status,
        "otp": otp,
        "noti": noti,
        "verified": verified,
        "token": token,
        "imageUri": imageUri,
        "fcm_token": fcmToken,
        "gender": gender,
      };
}
