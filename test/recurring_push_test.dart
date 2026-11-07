import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/recurring_push.dart';

http.Response _json(String body, int status) => http.Response.bytes(utf8.encode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  final day = {'category': 'RECURRING_TOMORROW', 'occurrence_id': '208', 'day_token': 't0k', 'seen_at': '2026-11-08 19:37'};

  test('the server\'s own answer is shown, and the token and the time it showed are sent', () async {
    Map? sent;
    final c = MockClient((r) async {
      expect(r.url.path, '/api/v1/recurring-day/208/attend');
      sent = jsonDecode(r.body) as Map;
      return _json(jsonEncode({'success': true, 'state': 'coming', 'title': '✅ أكدنا', 'message': 'تمام'}), 200);
    });
    final a = await RecurringPush.answer(day, 'attend', client: c);
    expect([a.ok, a.state, a.title, a.retry], [true, 'coming', '✅ أكدنا', false]);
    expect(sent, containsPair('t', 't0k'));
    expect(sent, containsPair('seen_at', '2026-11-08 19:37'));
  });

  test('an invalid or changed day is a refusal with its reason, not a retry', () async {
    final c = MockClient((r) async => _json(jsonEncode({'success': false, 'state': 'changed', 'title': 'تغيّر موعد بكرة', 'message': 'صار 8:00'}), 200));
    final a = await RecurringPush.answer(day, 'skip', client: c);
    expect([a.ok, a.state, a.retry], [false, 'changed', false]);
  });

  test('no connection twice: honest failure, the buttons stay', () async {
    var calls = 0;
    final c = MockClient((r) async {
      calls++;
      throw http.ClientException('Connection closed before full header was received');
    });
    final a = await RecurringPush.answer(day, 'attend', client: c);
    expect(calls, 2);
    expect([a.ok, a.retry], [false, true]);
    expect(a.message, contains('ما تسجلش'));
  });

  test('a server error is tried once more', () async {
    var calls = 0;
    final c = MockClient((r) async => ++calls == 1
        ? http.Response('oops', 502)
        : _json(jsonEncode({'success': true, 'state': 'skipped', 'title': '⏭', 'message': 'تمام'}), 200));
    final a = await RecurringPush.answer(day, 'skip', client: c);
    expect([calls, a.ok, a.state], [2, true, 'skipped']);
  });

  test('only the reminder of a recurring day is handled, by its occurrence', () {
    expect(RecurringPush.handles(day), isTrue);
    expect(RecurringPush.handles({'category': 'SCHEDULED_READY', 'occurrence_id': '1'}), isFalse);
    expect(RecurringPush.fromPayload(RecurringPush.payload(day))!['day_token'], 't0k');
    expect(RecurringPush.payload(day), isNot(contains('address')));
  });
}
