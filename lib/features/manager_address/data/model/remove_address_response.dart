class RemoveAddressResponse {
  final bool success;
  final String message;

  RemoveAddressResponse({required this.success, required this.message});

  factory RemoveAddressResponse.fromJson(Map<String, dynamic> json) {
    return RemoveAddressResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
