class ForgotResponse {
  final bool success;
  final String message;

  ForgotResponse({
    required this.success,
    required this.message,
  });

  // Factory method to create an instance from JSON
  factory ForgotResponse.fromJson(Map<String, dynamic> json) {
    return ForgotResponse(
      success: json['success'],
      message: json['message'],
    );
  }

  // Method to convert instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
