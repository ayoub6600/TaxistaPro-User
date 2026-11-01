import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/functions/functions.dart' as app;
import 'package:taxista/pages/chatPage/trip_chat_page.dart';
import 'package:taxista/widgets/chat/chat_kit.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('chat kit', () {
    test('day labels: today, yesterday, weekday, then the date', () {
      final now = DateTime.now();
      expect(ChatTime.dayLabel(now, true), 'اليوم');
      expect(ChatTime.dayLabel(now.subtract(const Duration(days: 1)), true), 'أمس');
      expect(ChatTime.dayLabel(now.subtract(const Duration(days: 1)), false), 'Yesterday');
      final old = DateTime(now.year - 1, 3, 9);
      expect(ChatTime.dayLabel(old, true), '9 مارس ${now.year - 1}');
    });

    test('times are 12-hour with ص / م', () {
      expect(ChatTime.clock(DateTime(2026, 11, 2, 0, 5), true), '12:05 ص');
      expect(ChatTime.clock(DateTime(2026, 11, 2, 21, 24), true), '9:24 م');
      expect(ChatTime.clock(DateTime(2026, 11, 2, 13, 0), false), '1:00 PM');
    });

    test('the server UTC time is shown in the phone time', () {
      final t = ChatTime.parse('2026-11-01T22:19:42.000000Z')!;
      expect(t.isUtc, isFalse);
      expect(t.toUtc(), DateTime.utc(2026, 11, 1, 22, 19, 42));
    });

    test('Arabic text right to left, Latin left to right', () {
      expect(chatTextDirection('مرحبا'), ui.TextDirection.rtl);
      expect(chatTextDirection('  Hello driver'), ui.TextDirection.ltr);
      expect(chatTextDirection('123 ...'), isNull);
    });

    testWidgets('a message that failed says so and retries on tap', (tester) async {
      var retried = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChatBubble(
            palette: ChatPalette.current(),
            mine: true,
            tail: true,
            text: 'hello',
            time: '9:24 م',
            status: ChatDelivery.failed,
            failedLabel: 'لم تُرسل · اضغط لإعادة المحاولة',
            onRetry: () => retried++,
            copiedLabel: 'copied',
          ),
        ),
      ));
      await tester.tap(find.text('لم تُرسل · اضغط لإعادة المحاولة'));
      expect(retried, 1);
    });
  });

  group('chat with the driver of a past ride', () {
    late List<http.Request> requests;
    late bool callable;

    setUp(() {
      requests = [];
      callable = true;
      app.languageDirection = 'rtl';
    });

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final history = [
        {'id': 'a', 'message': 'السلام عليكم، أنا عند الباب', 'from_type': 2, 'seen': 1, 'created_at': '2026-11-01T19:23:00.000000Z'},
        {'id': 'b', 'message': 'تمام، نازل', 'from_type': 1, 'seen': 1, 'created_at': '2026-11-01T19:24:00.000000Z'},
      ];
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(
          home: TripChatPage(requestId: 'ride-1', driverName: 'محمد علي', details: 'Hyundai · 5-12345'),
        ));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.enterText(find.byType(TextField), 'نسيت حقيبتي في السيارة');
        await tester.pump(); // the mic turns into the send button
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byIcon(Icons.send_rounded));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }, () => MockClient((request) async {
            requests.add(request);
            final path = request.url.path;
            if (path.endsWith('calls/availability')) {
              return _json({'success': true, 'data': {'can_call_driver': callable, 'request_id': callable ? 'ride-1' : null}});
            }
            if (path.endsWith('request/send')) {
              history.add({'id': 'c', 'message': jsonDecode(request.body)['message'], 'from_type': 1, 'seen': 0,
                  'created_at': DateTime.now().toUtc().toIso8601String()});
              return _json({'success': true, 'data': history});
            }
            if (path.contains('chat-history/ride-1')) return _json({'success': true, 'data': history});
            return _json({'success': true});
          }));
    }

    testWidgets('reads the ride chat, sends with that ride id, and shows the free call', (tester) async {
      await open(tester);

      expect(find.text('السلام عليكم، أنا عند الباب'), findsOneWidget);
      expect(find.text('نسيت حقيبتي في السيارة'), findsWidgets);
      expect(find.text('يمكنك الاتصال به مجانًا الآن'), findsOneWidget);
      final availability = requests.firstWhere((r) => r.url.path.endsWith('calls/availability'));
      expect(availability.url.queryParameters['request_id'], 'ride-1');
      final send = requests.firstWhere((r) => r.url.path.endsWith('request/send'));
      expect(jsonDecode(send.body), {'request_id': 'ride-1', 'message': 'نسيت حقيبتي في السيارة'});

      await tester.pumpWidget(const SizedBox()); // stops the refresh timer
    });

    testWidgets('after the 24 hours: no "call now", the car instead', (tester) async {
      callable = false;
      await open(tester);

      expect(find.text('يمكنك الاتصال به مجانًا الآن'), findsNothing);
      expect(find.text('Hyundai · 5-12345'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
