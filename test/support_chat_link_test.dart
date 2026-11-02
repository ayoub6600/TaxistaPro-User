import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/support_chat_link.dart';

void main() {
  group('opening the chat with the administration from a notification', () {
    test('a message or a missed call from the administration is routed; other pushes are not', () {
      expect(SupportChatLink.handles({'push_type': 'admin_chat_message', 'chat_id': 'c1', 'message_id': '7'}), isTrue);
      expect(SupportChatLink.handles({'push_type': 'admin_call_missed', 'call_kind': 'admin_driver'}), isTrue);
      expect(SupportChatLink.handles({'push_type': 'admin_call'}), isFalse, reason: 'a ringing call stays CallKit\'s');
      expect(SupportChatLink.handles({'push_type': 'change_return', 'request_id': 'r1'}), isTrue, reason: 'opens the wallet');
      expect(SupportChatLink.handles({'push_type': 'wallet_topup', 'transaction_ref': 'TU-1'}), isTrue, reason: 'a top-up through a driver opens the wallet');
      expect(SupportChatLink.handles({'push_type': 'general'}), isFalse);
      expect(SupportChatLink.handles({}), isFalse);
    });

    test('a local notification carries the conversation and the message, and comes back the same', () {
      final payload = SupportChatLink.payload({'push_type': 'admin_chat_message', 'chat_id': 'c1', 'message_id': '7', 'title': 'x', 'message': 'secret text'});
      expect(payload.contains('secret text'), isFalse, reason: 'only ids, never the message text');
      final back = SupportChatLink.fromPayload(payload)!;
      expect(back['push_type'], 'admin_chat_message');
      expect(back['chat_id'], 'c1');
      expect(back['message_id'], '7');
    });

    test('any other payload is left to the existing handlers', () {
      expect(SupportChatLink.fromPayload(null), isNull);
      expect(SupportChatLink.fromPayload('order_details'), isNull);
      expect(SupportChatLink.fromPayload('{"push_type":"general"}'), isNull);
      expect(SupportChatLink.fromPayload('{broken'), isNull);
    });
  });
}
