import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../functions/functions.dart';

/// «مسابقات تاكسيستا» (api/v1/contests/*): the feed of contest posts, one post, its comments,
/// likes, shares, and the prediction sent as a comment. Reads return null when they could not be
/// done (the screens then show what they had); a comment returns the server's own words on failure.
class ContestsApi {
  /// The post shown on the home screen (newest open contest, else the newest result), or null.
  static final ValueNotifier<Map<String, dynamic>?> homePost = ValueNotifier<Map<String, dynamic>?>(null);

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${url}api/v1/contests$path').replace(queryParameters: query == null || query.isEmpty ? null : query);

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

  static Future<Map<String, dynamic>?> post(int id) => _get('/posts/$id');

  /// The top comments, each with its reply count and first reply («زي الفيسبوك»).
  static Future<Map<String, dynamic>?> comments(int id, {String side = 'all', String sort = 'new', int? before, int? offset, int? focus}) => _get('/posts/$id/comments', {
        'side': side,
        'sort': sort,
        'threads': '1',
        if (focus != null) 'focus': '$focus',
        if (before != null) 'before': '$before',
        if (offset != null) 'offset': '$offset',
      });

  /// [reaction]: like | love | haha | wow | sad | angry (a long press on «أعجبني»)
  static Future<Map<String, dynamic>?> like(int id, bool on, {String reaction = 'like'}) => _post('/posts/$id/like', {'on': on, 'reaction': reaction});

  static Future<Map<String, dynamic>?> likeComment(int post, int comment, bool on, {String reaction = 'like'}) =>
      _post('/posts/$post/comments/$comment/like', {'on': on, 'reaction': reaction});

  /// Every reply under a top comment («عرض المزيد»), oldest first.
  static Future<Map<String, dynamic>?> replies(int post, int comment, {int? after}) =>
      _get('/posts/$post/comments/$comment/replies', after == null ? null : {'after': '$after'});

  /// A shared link /c/<code>: the post id, or null (gone, another city, offline).
  static Future<Map<String, dynamic>?> postOfCode(String code, {int? comment}) => _get('/link/$code', comment == null ? null : {'m': '$comment'});

  /// Right after installing from a shared link: the post this phone came for (null when unsure).
  static Future<Map<String, dynamic>?> matchLink({required String platform, String? referrer, required int w, required int h}) async {
    final d = await _post('/link/match', {'platform': platform, 'app': 'rider', if (referrer != null) 'referrer': referrer, 'w': w, 'h': h});
    final link = d?['link'];
    return link is Map ? Map<String, dynamic>.from(link) : null;
  }

  /// [commentId]: the link points at that comment (a likes contest: «دير لايك لتعليقي»)
  static Future<Map<String, dynamic>?> share(int id, String channel, {int? commentId}) =>
      _post('/posts/$id/share', {'channel': channel, if (commentId != null) 'comment_id': commentId});

  static Future<Map<String, dynamic>?> consent(int id, bool showName) => _post('/posts/$id/consent', {'show_name': showName});

  /// Refreshes the home card. Called when the home screen opens and comes back.
  static Future<void> refreshHome() async {
    final d = await _get('/highlight');
    if (d == null) return; // offline: keep what was shown
    final p = d['post'];
    final post = p is Map ? Map<String, dynamic>.from(p) : null;
    if (post != null && (await _closed()).contains(homeKey(post))) {
      homePost.value = null;
      return;
    }
    homePost.value = post;
  }

  static const _closedKey = 'contests_home_closed';

  /// One announcement on the home card: the post and its state. A closed «النتيجة طلعت» stays closed;
  /// the same contest's next announcement (another post, or a result after the predictions) shows again.
  static String homeKey(Map<String, dynamic> post) {
    final c = post['contest'] is Map ? post['contest'] as Map : const {};
    return '${post['id']}:${post['kind'] ?? ''}:${c['status'] ?? ''}:${post['my_result']?['won'] == true ? 'won' : ''}';
  }

  static Future<List<String>> _closed() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_closedKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// The small × on the home card: this announcement only, on this phone (the server is not told).
  static Future<void> dismissHome() async {
    final post = homePost.value;
    homePost.value = null;
    if (post == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = [...(prefs.getStringList(_closedKey) ?? const <String>[]), homeKey(post)];
      await prefs.setStringList(_closedKey, list.length > 30 ? list.sublist(list.length - 30) : list);
    } catch (_) {}
  }

  /// A comment; with [answer] it is the person's prediction. Returns (data, null) or (null, message).
  static Future<(Map<String, dynamic>?, String?)> comment(int id, {String? body, Map<String, dynamic>? answer, int? replyTo}) async {
    if (bearerToken.isEmpty) return (null, 'سجّل الدخول أول.');
    String? device;
    try {
      // the install's push token: two accounts on one phone share it (the server keeps only a hash)
      device = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 4));
    } catch (_) {}
    try {
      final r = await http
          .post(_u('/posts/$id/comments'),
              headers: _headers,
              body: jsonEncode({
                if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
                if (answer != null) 'answer': answer,
                if (replyTo != null) 'reply_to': replyTo,
                if (device != null && device.isNotEmpty) 'device_id': device.length > 120 ? device.substring(0, 120) : device,
              }))
          .timeout(const Duration(seconds: 20));
      final data = _data(r);
      if (data != null) return (data, null);
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['errors'] is Map) {
        final first = (j['errors'] as Map).values.first;
        return (null, first is List && first.isNotEmpty ? '${first.first}' : '$first');
      }
      if (r.statusCode == 429) return (null, 'استنى شوية وجرّب مرة ثانية.');
      return (null, j is Map && j['message'] is String ? j['message'] as String : 'ما قدرناش ننشروا تعليقك. حاول مرة ثانية.');
    } catch (_) {
      return (null, 'ما فيش اتصال. حاول مرة ثانية.');
    }
  }
}
