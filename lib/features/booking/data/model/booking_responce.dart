class HistoryResponse {
  bool success;
  String message;
  List<RequestData> data;
  Meta meta;

  HistoryResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      success: json['success'],
      message: json['message'],
      data: List<RequestData>.from(
          json['data'].map((x) => RequestData.fromJson(x))),
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class RequestData {
  String id;
  String requestNumber;
  int rideOtp;
  int isLater; // Changed from bool to int
  int userId;
  String serviceLocationId;
  String? tripStartTime;
  String? arrivedAt;
  String? acceptedAt;
  String? completedAt;
  int isDriverStarted; // Changed from bool to int
  int isDriverArrived; // Changed from bool to int
  String updatedAt;
  int isTripStart; // Changed from bool to int
  String totalDistance;
  int totalTime;
  int isCompleted; // Changed from bool to int
  int isCancelled; // Changed from bool to int
  String cancelMethod;
  String paymentOpt;
  int isPaid; // Changed from bool to int
  int userRated; // Changed from bool to int
  int driverRated; // Changed from bool to int
  String unit;
  String zoneTypeId;
  String vehicleTypeId;
  String vehicleTypeName;
  String vehicleTypeImage;
  String carMakeName;
  String carModelName;
  String carColor;
  String carNumber;
  double pickLat;
  double pickLng;
  double dropLat;
  double dropLng;
  String pickAddress;
  String dropAddress;
  String requestedCurrencyCode;
  String requestedCurrencySymbol;
  int userCancellationFee;
  int isRental; // Changed from bool to int
  dynamic rentalPackageId;
  int isOutStation; // Changed from bool to int
  dynamic returnTime;
  dynamic isRoundTrip;
  String rentalPackageName;
  bool showDropLocation;
  int requestEtaAmount;
  bool showRequestEtaAmount;
  int offeredRideFare;
  int acceptedRideFare;
  int isBidRide; // Changed from bool to int
  int rideUserRating; // Changed from bool to int
  int rideDriverRating; // Changed from bool to int
  bool ifDispatch; // Changed from int to bool
  String goodsType;
  dynamic goodsTypeQuantity;
  String convertedCancelledAt;
  String convertedCreatedAt;
  String paymentType;
  String polyLine;
  int isPetAvailable; // Changed from bool to int
  int isLuggageAvailable; // Changed from bool to int
  int instantRide; // Changed from bool to int
  bool showOtpFeature; // Changed from int to bool
  bool completedRide; // Changed from int to bool
  bool laterRide; // Changed from int to bool
  bool cancelledRide; // Changed from int to bool
  bool ongoingRide; // Changed from int to bool
  String cancelledAtWithDate;
  String creatededAtWithDate;
  String paymentTypeString;
  String transportType;

  RequestData({
    required this.id,
    required this.requestNumber,
    required this.rideOtp,
    required this.isLater,
    required this.userId,
    required this.serviceLocationId,
    this.tripStartTime,
    this.arrivedAt,
    this.acceptedAt,
    this.completedAt,
    required this.isDriverStarted,
    required this.isDriverArrived,
    required this.updatedAt,
    required this.isTripStart,
    required this.totalDistance,
    required this.totalTime,
    required this.isCompleted,
    required this.isCancelled,
    required this.cancelMethod,
    required this.paymentOpt,
    required this.isPaid,
    required this.userRated,
    required this.driverRated,
    required this.unit,
    required this.zoneTypeId,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.vehicleTypeImage,
    required this.carMakeName,
    required this.carModelName,
    required this.carColor,
    required this.carNumber,
    required this.pickLat,
    required this.pickLng,
    required this.dropLat,
    required this.dropLng,
    required this.pickAddress,
    required this.dropAddress,
    required this.requestedCurrencyCode,
    required this.requestedCurrencySymbol,
    required this.userCancellationFee,
    required this.isRental,
    this.rentalPackageId,
    required this.isOutStation,
    this.returnTime,
    this.isRoundTrip,
    required this.rentalPackageName,
    required this.showDropLocation,
    required this.requestEtaAmount,
    required this.showRequestEtaAmount,
    required this.offeredRideFare,
    required this.acceptedRideFare,
    required this.isBidRide,
    required this.rideUserRating,
    required this.rideDriverRating,
    required this.ifDispatch,
    required this.goodsType,
    this.goodsTypeQuantity,
    required this.convertedCancelledAt,
    required this.convertedCreatedAt,
    required this.paymentType,
    required this.polyLine,
    required this.isPetAvailable,
    required this.isLuggageAvailable,
    required this.instantRide,
    required this.showOtpFeature,
    required this.completedRide,
    required this.laterRide,
    required this.cancelledRide,
    required this.ongoingRide,
    required this.cancelledAtWithDate,
    required this.creatededAtWithDate,
    required this.paymentTypeString,
    required this.transportType,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      id: json['id'],
      requestNumber: json['request_number'],
      rideOtp: json['ride_otp'],
      isLater: json['is_later'], // Parse as int
      userId: json['user_id'],
      serviceLocationId: json['service_location_id'],
      tripStartTime: json['trip_start_time'],
      arrivedAt: json['arrived_at'],
      acceptedAt: json['accepted_at'],
      completedAt: json['completed_at'],
      isDriverStarted: json['is_driver_started'], // Parse as int
      isDriverArrived: json['is_driver_arrived'], // Parse as int
      updatedAt: json['updated_at'],
      isTripStart: json['is_trip_start'], // Parse as int
      totalDistance: json['total_distance'],
      totalTime: json['total_time'],
      isCompleted: json['is_completed'], // Parse as int
      isCancelled: json['is_cancelled'], // Parse as int
      cancelMethod: json['cancel_method'],
      paymentOpt: json['payment_opt'],
      isPaid: json['is_paid'], // Parse as int
      userRated: json['user_rated'], // Parse as int
      driverRated: json['driver_rated'], // Parse as int
      unit: json['unit'],
      zoneTypeId: json['zone_type_id'],
      vehicleTypeId: json['vehicle_type_id'],
      vehicleTypeName: json['vehicle_type_name'],
      vehicleTypeImage: json['vehicle_type_image'],
      carMakeName: json['car_make_name'] ?? '-',
      carModelName: json['car_model_name'] ?? '-',
      carColor: json['car_color'] ?? '-',
      carNumber: json['car_number'] ?? '-',
      pickLat: double.parse(json['pick_lat'].toString()),
      pickLng: double.parse(json['pick_lng'].toString()),
      dropLat: double.parse(json['drop_lat'].toString()),
      dropLng: double.parse(json['drop_lng'].toString()),
      pickAddress: json['pick_address'],
      dropAddress: json['drop_address'],
      requestedCurrencyCode: json['requested_currency_code'],
      requestedCurrencySymbol: json['requested_currency_symbol'],
      userCancellationFee: json['user_cancellation_fee'],
      isRental: json['is_rental'] == true ? 1 : 0, // Convert bool to int
      rentalPackageId: json['rental_package_id'],
      isOutStation: json['is_out_station'], // Parse as int
      returnTime: json['return_time'],
      isRoundTrip: json['is_round_trip'],
      rentalPackageName: json['rental_package_name'] ?? '-',
      showDropLocation: json['show_drop_location'],
      requestEtaAmount: json['request_eta_amount'],
      showRequestEtaAmount: json['show_request_eta_amount'],
      offeredRideFare: json['offerred_ride_fare'],
      acceptedRideFare: json['accepted_ride_fare'],
      isBidRide: json['is_bid_ride'], // Parse as int
      rideUserRating: json['ride_user_rating'], // Parse as int
      rideDriverRating: json['ride_driver_rating'], // Parse as int
      ifDispatch: json['if_dispatch'], // Parse as bool
      goodsType: json['goods_type'] ?? '-',
      goodsTypeQuantity: json['goods_type_quantity'],
      convertedCancelledAt: json['converted_cancelled_at'],
      convertedCreatedAt: json['converted_created_at'],
      paymentType: json['payment_type'],
      polyLine: json['poly_line'] ?? '',
      isPetAvailable: json['is_pet_available'], // Parse as int
      isLuggageAvailable: json['is_luggage_available'], // Parse as int
      instantRide: json['instant_ride'], // Parse as int
      showOtpFeature: json['show_otp_feature'], // Parse as bool
      completedRide: json['completed_ride'], // Parse as bool
      laterRide: json['later_ride'], // Parse as bool
      cancelledRide: json['cancelled_ride'], // Parse as bool
      ongoingRide: json['ongoing_ride'], // Parse as bool
      cancelledAtWithDate: json['cancelled_at_with_date'],
      creatededAtWithDate: json['createded_at_with_date'],
      paymentTypeString: json['payment_type_string'],
      transportType: json['transport_type'],
    );
  }
}

class Meta {
  Pagination pagination;

  Meta({required this.pagination});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  int total;
  int count;
  int perPage;
  int currentPage;
  int totalPages;
  Map<String, dynamic> links;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    required this.links,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      links: json['links'],
    );
  }
}
