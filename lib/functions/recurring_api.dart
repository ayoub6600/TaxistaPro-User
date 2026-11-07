import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'functions.dart';

/// «رحلاتي المتكررة» (recurring rides set up with the administration): the rider's schedules, their
/// days, and his answer for one day (✅ confirm / ⏭ skip). The server is the truth for every state.
class RecurringApi {
  static Map<String, String> get _headers => {
        'Authorization': 'Bearer ${bearerToken.isEmpty ? '' : bearerToken[0].token}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Uri _u(String path) => Uri.parse('${url}api/v1/request/$path');

  static Future<RecurringResult> list() => _send(http.get(_u('recurring-rides'), headers: _headers));

  static Future<RecurringResult> show(String uuid) => _send(http.get(_u('recurring-rides/$uuid'), headers: _headers));

  /// attend | skip, for one date (Y-m-d)
  static Future<RecurringResult> answer(String uuid, String date, String answer) =>
      _send(http.post(_u('recurring-rides/$uuid/$answer'), headers: _headers, body: jsonEncode({'date': date})));

  /// the whole schedule ends (every coming day of it is skipped)
  static Future<RecurringResult> cancel(String uuid) =>
      _send(http.post(_u('recurring-rides/$uuid/cancel'), headers: _headers, body: jsonEncode({})));

  static Future<RecurringResult> _send(Future<http.Response> request) async {
    try {
      final r = await request.timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
      } catch (_) {}
      return RecurringResult(r.statusCode, body);
    } on TimeoutException {
      return const RecurringResult(0, {'message': 'الاتصال ضعيف وما وصلناش رد. ما تسجلش شي؛ جرب مرة ثانية.'});
    } catch (_) {
      return const RecurringResult(0, {'message': 'ما فيش اتصال بالإنترنت. ما تسجلش شي؛ جرب مرة ثانية.'});
    }
  }

  /// the next day that still needs his answer (the home card): tomorrow's, not answered, answerable
  static Map<String, dynamic>? pendingTomorrow(List<Map<String, dynamic>> rides) {
    for (final r in rides) {
      final n = r['next'];
      if (r['status'] == 'active' && n is Map && n['answerable'] == true && n['day_word'] == 'بكرة' && n['state'] != 'skipped') {
        return {'ride': r, 'next': Map<String, dynamic>.from(n)};
      }
    }
    return null;
  }

  /// shared with the home card: refreshed on open, after an answer, and when the app comes back
  static final ValueNotifier<List<Map<String, dynamic>>> rides = ValueNotifier(const []);
  static DateTime? _loadedAt;

  static Future<void> refresh({bool force = false}) async {
    if (bearerToken.isEmpty) return;
    final last = _loadedAt;
    if (!force && last != null && DateTime.now().difference(last) < const Duration(minutes: 2)) return;
    final r = await list();
    if (r.status == 200) {
      _loadedAt = DateTime.now();
      rides.value = r.list;
    } else if (r.status == 404 || r.status == 403) {
      _loadedAt = DateTime.now();
      rides.value = const []; // not in the pilot: nothing to show
    }
  }
}

class RecurringResult {
  final int status;
  final Map<String, dynamic> body;

  const RecurringResult(this.status, this.body);

  bool get ok => status == 200 && body['success'] == true;
  Map<String, dynamic> get data => body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : <String, dynamic>{};
  List<Map<String, dynamic>> get list =>
      body['data'] is List ? (body['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
  String get message => (body['message']?.toString().isNotEmpty ?? false) ? body['message'].toString() : 'ما تمش. جرب مرة ثانية.';
}
