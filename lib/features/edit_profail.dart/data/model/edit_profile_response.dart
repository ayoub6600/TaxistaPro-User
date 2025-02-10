class UpdateProfile {
  final bool success;
  final String message;
  final UserData data;

  UpdateProfile({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UpdateProfile.fromJson(Map<String, dynamic> json) {
    return UpdateProfile(
      success: json['success'],
      message: json['message'],
      data: UserData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "data": data.toJson(),
    };
  }
}

class UserData {
  final int id;
  final String name;
  final String gender;
  final String? lastName;
  final String? username;
  final String email;
  final String mobile;
  final String profilePicture;
  final int active;
  final int emailConfirmed;
  final int mobileConfirmed;
  final String lastKnownIp;
  final String lastLoginAt;
  final double rating;
  final int noOfRatings;
  final String referralCode;
  final String currencyCode;
  final String currencySymbol;
  final String countryCode;
  final bool showRentalRide;
  final bool isDeliveryApp;
  final bool showRideLaterFeature;
  final String? authorizationCode;
  final String enableMapLocationIconDragAndDropFeature;
  final String enableModulesForApplications;
  final String contactUsMobile1;
  final String contactUsMobile2;
  final String contactUsLink;
  final String showWalletMoneyTransferFeatureOnMobileApp;
  final String showBankInfoFeatureOnMobileApp;
  final String showWalletFeatureOnMobileApp;
  final int notificationsCount;
  final String referralCommissionString;
  final String userCanMakeARideAfterXMinutes;
  final int maximumTimeForFindDriversForRegularRide;
  final int? maximumTimeForFindDriversForBiddingRide;
  final String? enableDriverPreferenceForUser;
  final String enablePetPreferenceForUser;
  final String enableLuggagePreferenceForUser;
  final String? biddingAmountIncreaseOrDecrease;
  final String showRideWithoutDestination;
  final String enableCountryRestrictOnMap;
  final String chatId;
  final String mapType;
  final bool hasOngoingRide;
  final Wallet wallet;

  UserData({
    required this.id,
    required this.name,
    required this.gender,
    required this.lastName,
    required this.username,
    required this.email,
    required this.mobile,
    required this.profilePicture,
    required this.active,
    required this.emailConfirmed,
    required this.mobileConfirmed,
    required this.lastKnownIp,
    required this.lastLoginAt,
    required this.rating,
    required this.noOfRatings,
    required this.referralCode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.countryCode,
    required this.showRentalRide,
    required this.isDeliveryApp,
    required this.showRideLaterFeature,
    required this.authorizationCode,
    required this.enableMapLocationIconDragAndDropFeature,
    required this.enableModulesForApplications,
    required this.contactUsMobile1,
    required this.contactUsMobile2,
    required this.contactUsLink,
    required this.showWalletMoneyTransferFeatureOnMobileApp,
    required this.showBankInfoFeatureOnMobileApp,
    required this.showWalletFeatureOnMobileApp,
    required this.notificationsCount,
    required this.referralCommissionString,
    required this.userCanMakeARideAfterXMinutes,
    required this.maximumTimeForFindDriversForRegularRide,
    required this.maximumTimeForFindDriversForBiddingRide,
    required this.enableDriverPreferenceForUser,
    required this.enablePetPreferenceForUser,
    required this.enableLuggagePreferenceForUser,
    required this.biddingAmountIncreaseOrDecrease,
    required this.showRideWithoutDestination,
    required this.enableCountryRestrictOnMap,
    required this.chatId,
    required this.mapType,
    required this.hasOngoingRide,
    required this.wallet,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      lastName: json['last_name'],
      username: json['username'],
      email: json['email'],
      mobile: json['mobile'],
      profilePicture: json['profile_picture'],
      active: json['active'],
      emailConfirmed: json['email_confirmed'],
      mobileConfirmed: json['mobile_confirmed'],
      lastKnownIp: json['last_known_ip'],
      lastLoginAt: json['last_login_at'],
      rating: json['rating'].toDouble(),
      noOfRatings: json['no_of_ratings'],
      referralCode: json['refferal_code'],
      currencyCode: json['currency_code'],
      currencySymbol: json['currency_symbol'],
      countryCode: json['country_code'],
      showRentalRide: json['show_rental_ride'],
      isDeliveryApp: json['is_delivery_app'],
      showRideLaterFeature: json['show_ride_later_feature'],
      authorizationCode: json['authorization_code'],
      enableMapLocationIconDragAndDropFeature:
          json['enable_map_location_icon_drag_and_drop_feature'],
      enableModulesForApplications: json['enable_modules_for_applications'],
      contactUsMobile1: json['contact_us_mobile1'],
      contactUsMobile2: json['contact_us_mobile2'],
      contactUsLink: json['contact_us_link'],
      showWalletMoneyTransferFeatureOnMobileApp:
          json['show_wallet_money_transfer_feature_on_mobile_app'],
      showBankInfoFeatureOnMobileApp:
          json['show_bank_info_feature_on_mobile_app'],
      showWalletFeatureOnMobileApp: json['show_wallet_feature_on_mobile_app'],
      notificationsCount: json['notifications_count'],
      referralCommissionString: json['referral_comission_string'],
      userCanMakeARideAfterXMinutes:
          json['user_can_make_a_ride_after_x_miniutes'],
      maximumTimeForFindDriversForRegularRide:
          json['maximum_time_for_find_drivers_for_regular_ride'],
      maximumTimeForFindDriversForBiddingRide:
          json['maximum_time_for_find_drivers_for_bitting_ride'],
      enableDriverPreferenceForUser: json['enable_driver_preference_for_user'],
      enablePetPreferenceForUser: json['enable_pet_preference_for_user'],
      enableLuggagePreferenceForUser:
          json['enable_luggage_preference_for_user'],
      biddingAmountIncreaseOrDecrease:
          json['bidding_amount_increase_or_decrease'],
      showRideWithoutDestination: json['show_ride_without_destination'],
      enableCountryRestrictOnMap: json['enable_country_restrict_on_map'],
      chatId: json['chat_id'],
      mapType: json['map_type'],
      hasOngoingRide: json['has_ongoing_ride'],
      wallet: Wallet.fromJson(json['wallet']['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "gender": gender,
      "last_name": lastName,
      "username": username,
      "email": email,
      "mobile": mobile,
      "profile_picture": profilePicture,
      "active": active,
      "email_confirmed": emailConfirmed,
      "mobile_confirmed": mobileConfirmed,
      "last_known_ip": lastKnownIp,
      "last_login_at": lastLoginAt,
      "rating": rating,
      "no_of_ratings": noOfRatings,
      "refferal_code": referralCode,
      "currency_code": currencyCode,
      "currency_symbol": currencySymbol,
      "country_code": countryCode,
      "show_rental_ride": showRentalRide,
      "is_delivery_app": isDeliveryApp,
      "show_ride_later_feature": showRideLaterFeature,
      "authorization_code": authorizationCode,
      "wallet": wallet.toJson(),
    };
  }
}

class Wallet {
  final String id;
  final int userId;
  final int amountAdded;
  final int amountBalance;
  final int amountSpent;
  final String currencySymbol;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.amountAdded,
    required this.amountBalance,
    required this.amountSpent,
    required this.currencySymbol,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      userId: json['user_id'],
      amountAdded: json['amount_added'],
      amountBalance: json['amount_balance'],
      amountSpent: json['amount_spent'],
      currencySymbol: json['currency_symbol'],
      currencyCode: json['currency_code'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "amount_added": amountAdded,
      "amount_balance": amountBalance,
      "amount_spent": amountSpent,
      "currency_symbol": currencySymbol,
      "currency_code": currencyCode,
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }
}
