import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../functions/functions.dart';

/// «منشورات تاكسيستا» (api/v1/posts/*): the feed, the home card, one post, likes, comments and
/// what was seen / played / closed. Reads return null when they could not be done (the screens
/// keep what they had); a comment returns the server's own words on failure.
class PostsApi {
  /// The post on the home screen (the newest one of its days that he did not close), or null.
  static final ValueNotifier<Map<String, dynamic>?> homePost = ValueNotifier<Map<String, dynamic>?>(null);

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${url}api/v1/posts$path').replace(queryParameters: query == null || query.isEmpty ? null : query);

  static Map<String, dynamic>? _data(http.Response r) {
    if (r.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    if (body is! Map || body['success'] == false) return null;
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> _get(String path, [Map<String, String>? query]) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http.get(_u(path, query), headers: _headers).timeout(const Duration(seconds: 15)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    if (bearerToken.isEmpty) return null;
    try {
      return _data(await http.post(_u(path), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15)));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> feed({int? before}) => _get('', before == null ? null : {'before': '$before'});

  static Future<Map<String, dynamic>?> post(int id) => _get('/$id');

  static Future<Map<String, dynamic>?> comments(int id, {int? before}) => _get('/$id/comments', before == null ? null : {'before': '$before'});

  static Future<Map<String, dynamic>?> like(int id, bool on) => _post('/$id/like', {'on': on});

  /// view | play | dismiss | share — the server counts each once per person
  static void event(int id, String kind) => unawaited(_post('/$id/event', {'kind': kind}));

  static Future<void> refreshHome() async {
    final d = await _get('/home');
    if (d == null) return; // offline: keep what was shown
    final p = d['post'];
    homePost.value = p is Map ? Map<String, dynamic>.from(p) : null;
  }

  /// a swipe on the home card: it does not come back (the server remembers)
  static void dismissHome() {
    final post = homePost.value;
    homePost.value = null;
    if (post != null) event((post['id'] as num).toInt(), 'dismiss');
  }

  /// Returns (comment, null) or (null, message).
  static Future<(Map<String, dynamic>?, String?)> comment(int id, String body) async {
    if (bearerToken.isEmpty) return (null, 'سجّل الدخول أول.');
    try {
      final r = await http.post(_u('/$id/comments'), headers: _headers, body: jsonEncode({'body': body})).timeout(const Duration(seconds: 15));
      final d = _data(r);
      if (d != null) return (d, null);
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['errors'] is Map && (j['errors'] as Map).isNotEmpty) {
        final first = (j['errors'] as Map).values.first;
        return (null, first is List && first.isNotEmpty ? '${first.first}' : '$first');
      }
      return (null, j is Map && j['message'] != null ? '${j['message']}' : 'ما وصلش التعليق. حاول مرة ثانية.');
    } catch (_) {
      return (null, 'الشبكة ضعيفة. حاول مرة ثانية.');
    }
  }
}
