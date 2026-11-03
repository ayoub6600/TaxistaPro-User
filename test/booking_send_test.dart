import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:taxista/functions/booking_send.dart';
import 'package:taxista/pages/loadingPage/loading.dart';

void main() {
  group('a booking on a weak connection', () {
    test('every send of one booking carries the same id', () {
      final body = jsonEncode({'pick_lat': 32.35, 'vehicle_type': 'abc'});
      final first = jsonDecode(BookingSend.withBookingId(body, 'b-1'));
      final again = jsonDecode(BookingSend.withBookingId(body, 'b-1'));
      expect(first['client_request_id'], 'b-1');
      expect(again, first);
      expect(first['pick_lat'], 32.35, reason: 'the booking itself is untouched');
      expect(BookingSend.withBookingId('not json', 'b-1'), 'not json');
    });

    test('a lost answer is sent again until one arrives', () async {
      var sends = 0;
      final attempts = <int>[];
      BookingSend.attempt.addListener(() => attempts.add(BookingSend.attempt.value));
      final response = await BookingSend.send(() async {
        sends++;
        if (sends == 1) throw TimeoutException('no answer');
        if (sends == 2) throw const SocketException('connection reset');
        return http.Response('{"success":true}', 200);
      }, pause: (_) => Duration.zero);

      expect(response?.statusCode, 200);
      expect(sends, 3);
      expect(attempts, [1, 2, 3, 0], reason: 'the waiting screen can say which try it is, then idle');
    });

    test('no answer at all after every try gives null, never an exception', () async {
      var sends = 0;
      final response = await BookingSend.send(() async {
        sends++;
        throw http.ClientException('Connection closed before full header was received');
      }, pause: (_) => Duration.zero);
      expect(response, isNull);
      expect(sends, BookingSend.attempts);
    });

    test('a slow answer counts as lost after the time limit', () async {
      var sends = 0;
      final response = await BookingSend.send(() {
        sends++;
        return Completer<http.Response>().future; // never answers
      }, tries: 2, perTry: const Duration(milliseconds: 20), pause: (_) => Duration.zero);
      expect(response, isNull);
      expect(sends, 2);
    });

    test('an answer from the server is never re-sent, whatever it says', () async {
      var sends = 0;
      final response = await BookingSend.send(() async {
        sends++;
        return http.Response('{"message":"no drivers available"}', 400);
      }, pause: (_) => Duration.zero);
      expect(response?.statusCode, 400);
      expect(sends, 1);
    });

    test('a bug in the app is not mistaken for a weak connection', () async {
      expect(
        () => BookingSend.send(() async => throw const FormatException('bad body'), pause: (_) => Duration.zero),
        throwsFormatException,
      );
    });
  });

  group('the waiting card explains a slow connection', () {
    test('quiet first, then slow, then very weak', () {
      expect(connectionNotice(const Duration(seconds: 3), true), isNull);
      expect(connectionNotice(const Duration(seconds: 7), true)?.title, 'الاتصال بطيء…');
      expect(connectionNotice(const Duration(seconds: 20), true)?.title, 'الإنترنت ضعيف جدًا');
      expect(connectionNotice(const Duration(seconds: 20), false)?.title, 'Very weak internet');
    });
  });
}
