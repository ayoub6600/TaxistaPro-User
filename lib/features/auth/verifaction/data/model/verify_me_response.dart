class VerifyMeResponse {
  String? msg;
  Data? data;
  bool? success;

  VerifyMeResponse({this.msg, this.data, this.success});

  VerifyMeResponse.fromJson(Map<String, dynamic> json) {
    msg = json["msg"] ?? '';
    data = json["data"] == null ? null : Data.fromJson(json["data"]);
    success = json["success"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["msg"] = msg;
    if (data != null) {
      _data["data"] = data?.toJson();
    }
    _data["success"] = success;
    return _data;
  }
}

class Data {
  // num? id;
  // num? ownerId;
  // String? name;
  // String? email;
  // dynamic experience;
  // dynamic idNo;
  // String? image;
  // dynamic deviceToken;
  // String? fcmToken;
  // String? phoneNo;
  String? otp;
  // String? startTime;
  // String? endTime;
  num? status;
  num? noti;
  num? verified;
  num? ownerApproved;
  num? online;
  num? balance;
  // String? address;
  // String? longitude;
  // String? latitude;
  // String? imageUri;
  // ShopOwner? shopOwner;

  Data({
    this.otp,
    this.status,
    this.noti,
    this.verified,
    this.ownerApproved,
    this.online,
    this.balance,
  });

  Data.fromJson(Map<String, dynamic> json) {
    // id = json["id"]??0 ;
    // ownerId = json["owner_id"]??0;
    // name = json["name"]??'';
    // email = json["email"]??'';
    // experience = json["experience"];
    // idNo = json["id_no"];
    // image = json["image"]??'';
    // deviceToken = json["device_token"]??'';
    // fcmToken = json["fcm_token"]??'';
    // phoneNo = json["phone_no"]??'';
    otp = json["otp"] ?? '';
    // startTime = json["start_time"]??'';
    // endTime = json["end_time"]??'';
    status = json["status"] ?? 5;
    noti = json["noti"] ?? 5;
    verified = json["verified"] ?? 5;
    ownerApproved = json["owner_approved"] ?? 5;
    online = json["online"] ?? 5 ?? 0;
    balance = json["balance"] ?? 0;
    // address = json["address"]??'';
    // longitude = json["longitude"]??'';
    // latitude = json["latitude"]??'';
    // imageUri = json["imageUri"]??'';
    // shopOwner = json["shop_owner"] == ShopOwner() ? null : ShopOwner.fromJson(json["shop_owner"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    // _data["id"] = id;
    // _data["owner_id"] = ownerId;
    // _data["name"] = name;
    // _data["email"] = email;
    // _data["experience"] = experience;
    // _data["id_no"] = idNo;
    // _data["image"] = image;
    // _data["device_token"] = deviceToken;
    // _data["fcm_token"] = fcmToken;
    // _data["phone_no"] = phoneNo;
    _data["otp"] = otp;
    // _data["start_time"] = startTime;
    // _data["end_time"] = endTime;
    _data["status"] = status;
    _data["noti"] = noti;
    _data["verified"] = verified;
    _data["owner_approved"] = ownerApproved;
    _data["online"] = online;
    _data["balance"] = balance;
    // _data["address"] = address;
    // _data["longitude"] = longitude;
    // _data["latitude"] = latitude;
    // _data["imageUri"] = imageUri;
    // if(shopOwner != null) {
    //     _data["shop_owner"] = shopOwner?.toJson();
    // }
    return _data;
  }
}

class ShopOwner {
  num? id;
  String? name;
  String? email;
  String? phoneNo;
  String? image;
  num? verified;
  num? status;
  num? noti;
  num? autoAssign;
  num? empDeclineReq;
  dynamic deviceToken;
  String? fcmToken;
  String? imageUri;

  ShopOwner(
      {this.id,
      this.name,
      this.email,
      this.phoneNo,
      this.image,
      this.verified,
      this.status,
      this.noti,
      this.autoAssign,
      this.empDeclineReq,
      this.deviceToken,
      this.fcmToken,
      this.imageUri});

  ShopOwner.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? 0;
    name = json["name"] ?? '';
    email = json["email"] ?? '';
    phoneNo = json["phone_no"] ?? '';
    image = json["image"] ?? '';
    verified = json["verified"] ?? 5;
    status = json["status"] ?? 5;
    noti = json["noti"] ?? 5;
    autoAssign = json["auto_assign"] ?? 5;
    empDeclineReq = json["emp_decline_req"] ?? 5;
    deviceToken = json["device_token"] ?? '';
    fcmToken = json["fcm_token"] ?? '';
    imageUri = json["imageUri"] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["id"] = id;
    _data["name"] = name;
    _data["email"] = email;
    _data["phone_no"] = phoneNo;
    _data["image"] = image;
    _data["verified"] = verified;
    _data["status"] = status;
    _data["noti"] = noti;
    _data["auto_assign"] = autoAssign;
    _data["emp_decline_req"] = empDeclineReq;
    _data["device_token"] = deviceToken;
    _data["fcm_token"] = fcmToken;
    _data["imageUri"] = imageUri;
    return _data;
  }
}
