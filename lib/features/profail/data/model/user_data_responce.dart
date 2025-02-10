class UserProfile {
  final bool success;
  final UserData data;

  UserProfile({required this.success, required this.data});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      success: json['success'],
      data: UserData.fromJson(json['data']),
    );
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
  final DateTime lastLoginAt;
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
  final int? maximumTimeForFindDriversForBittingRide;
  final String? enableDriverPreferenceForUser;
  final String enablePetPreferenceForUser;
  final String enableLuggagePreferenceForUser;
  final String? biddingAmountIncreaseOrDecrease;
  final String showRideWithoutDestination;
  final String enableCountryRestrictOnMap;
  final String chatId;
  final String mapType;
  final bool hasOngoingRide;
  final Sos sos;
  final BannerImage bannerImage;
  final Wallet wallet;
  final List<FavouriteLocation> favouriteLocations;

  UserData({
    required this.id,
    required this.name,
    required this.gender,
    this.lastName,
    this.username,
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
    this.authorizationCode,
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
    this.maximumTimeForFindDriversForBittingRide,
    this.enableDriverPreferenceForUser,
    required this.enablePetPreferenceForUser,
    required this.enableLuggagePreferenceForUser,
    this.biddingAmountIncreaseOrDecrease,
    required this.showRideWithoutDestination,
    required this.enableCountryRestrictOnMap,
    required this.chatId,
    required this.mapType,
    required this.hasOngoingRide,
    required this.sos,
    required this.bannerImage,
    required this.wallet,
    required this.favouriteLocations,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    var favouriteLocationsJson = json['favouriteLocations']['data'] as List;
    List<FavouriteLocation> favouriteLocationsList = favouriteLocationsJson
        .map((location) => FavouriteLocation.fromJson(location))
        .toList();

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
      lastLoginAt: DateTime.parse(json['last_login_at']),
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
      maximumTimeForFindDriversForBittingRide:
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
      sos: Sos.fromJson(json['sos']),
      bannerImage: BannerImage.fromJson(json['bannerImage']),
      wallet: Wallet.fromJson(json['wallet']),
      favouriteLocations: favouriteLocationsList,
    );
  }
}

class Sos {
  final List<dynamic> data;

  Sos({required this.data});

  factory Sos.fromJson(Map<String, dynamic> json) {
    return Sos(
      data: json['data'],
    );
  }
}

class BannerImage {
  final List<dynamic> data;

  BannerImage({required this.data});

  factory BannerImage.fromJson(Map<String, dynamic> json) {
    return BannerImage(
      data: json['data'],
    );
  }
}

class Wallet {
  final WalletData data;

  Wallet({required this.data});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      data: WalletData.fromJson(json['data']),
    );
  }
}

class WalletData {
  final String id;
  final int userId;
  final int amountAdded;
  final int amountBalance;
  final int amountSpent;
  final String currencySymbol;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;

  WalletData({
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

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
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
}

class FavouriteLocation {
  final int id;
  final double pickLat;
  final double pickLng;
  final double? dropLat;
  final double? dropLng;
  final String pickAddress;
  final String? dropAddress;
  final String addressName;
  final String? landmark;

  FavouriteLocation({
    required this.id,
    required this.pickLat,
    required this.pickLng,
    this.dropLat,
    this.dropLng,
    required this.pickAddress,
    this.dropAddress,
    required this.addressName,
    this.landmark,
  });

  factory FavouriteLocation.fromJson(Map<String, dynamic> json) {
    return FavouriteLocation(
      id: json['id'],
      pickLat: json['pick_lat'].toDouble(),
      pickLng: json['pick_lng'].toDouble(),
      dropLat: json['drop_lat'] != null ? json['drop_lat'].toDouble() : null,
      dropLng: json['drop_lng'] != null ? json['drop_lng'].toDouble() : null,
      pickAddress: json['pick_address'],
      dropAddress: json['drop_address'],
      addressName: json['address_name'],
      landmark: json['landmark'],
    );
  }
}
