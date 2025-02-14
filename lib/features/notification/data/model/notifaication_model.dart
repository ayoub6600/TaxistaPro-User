class NotificationResponse {
  final bool success;
  final String message;
  final List<NotificationData> data;
  final Meta meta;

  NotificationResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => NotificationData.fromJson(item))
          .toList(),
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final String? image;
  final String convertedCreatedAt;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    required this.convertedCreatedAt,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      image: json['image'],
      convertedCreatedAt: json['converted_created_at'],
    );
  }
}

class Meta {
  final Pagination pagination;

  Meta({required this.pagination});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
    );
  }
}
