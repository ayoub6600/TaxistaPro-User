// Main response class
class ComplaintResponse {
  final bool success;
  final String message;
  final List<Complaint> data;

  ComplaintResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  // Factory method to create an instance from JSON
  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintResponse(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => Complaint.fromJson(item))
          .toList(),
    );
  }

  // Method to convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "data": data.map((item) => item.toJson()).toList(),
    };
  }
}

// Individual complaint item class
class Complaint {
  final String id;
  final String? companyKey;
  final String userType;
  final String complaintType;
  final String title;
  final int active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Complaint({
    required this.id,
    required this.companyKey,
    required this.userType,
    required this.complaintType,
    required this.title,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Factory method to create an instance from JSON
  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      companyKey: json['company_key'],
      userType: json['user_type'],
      complaintType: json['complaint_type'],
      title: json['title'],
      active: json['active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  // Method to convert the instance to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "company_key": companyKey,
      "user_type": userType,
      "complaint_type": complaintType,
      "title": title,
      "active": active,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "deleted_at": deletedAt?.toIso8601String(),
    };
  }
}
