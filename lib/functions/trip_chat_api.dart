import 'dart:convert';

import 'package:http/http.dart' as http;

import 'functions.dart';

/// The chat with the driver of one ride, by its id: the ride under way or one from the trip
/// history (the server lets only that ride's rider and driver read and write it).
class TripChatApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
      };

  static Uri _u(String path) => Uri.parse('${url}api/v1/request/$path');

  /// Oldest first; null when it could not be loaded.
  static Future<List<Map<String, dynamic>>?> history(String requestId) async {
    try {
      final response = await http.get(_u('chat-history/$requestId'), headers: _headers);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map || body['data'] is! List) return null;
      return [for (final m in body['data'] as List) if (m is Map) Map<String, dynamic>.from(m)];
    } catch (_) {
      return null;
    }
  }

  /// The whole conversation after the message went out, or null when it did not.
  static Future<List<Map<String, dynamic>>?> send(String requestId, String message, {String? replyTo}) async {
    try {
      final response = await http.post(_u('send'),
          headers: _headers, body: jsonEncode({'request_id': requestId, 'message': message, if (replyTo != null) 'reply_to': replyTo}));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['success'] == false) return null;
      return await history(requestId) ?? const [];
    } catch (_) {
      return null;
    }
  }

  /// What the driver sent is read.
  static Future<void> seen(String requestId) async {
    try {
      await http.post(_u('seen'), headers: _headers, body: jsonEncode({'request_id': requestId}));
    } catch (_) {}
  }
}
