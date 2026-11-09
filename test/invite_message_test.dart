import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/invite_link.dart';
import 'package:taxista/functions/invite_message.dart';
import 'package:taxista/functions/share_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the invite carries the code and the real store links', () {
    final m = inviteMessage('ABC123');
    expect(m, contains('ABC123'));
    expect(m, contains('https://taxista.aljidartech.com/i/ABC123'));
    expect(inviteMessage('ABC123', friendReward: '2 دينار'), contains('2 دينار بعد أول مشوار'));
  });

  test('an answer without a code is nobody', () {
    expect(InviteMatch.fromJson({'code': null}), isNull);
    expect(InviteMatch.fromJson(null), isNull);
    expect(InviteMatch.fromJson({'code': 'ABC', 'name': 'محمد', 'reward': '2 دينار'})!.reward, '2 دينار');
  });

  testWidgets('the share sheet is told where it comes from', (tester) async {
    MethodCall? call;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (c) async {
      call = c;
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) { ctx = c; return const SizedBox.expand(); })));
    expect(await shareText(ctx, 'hello'), isTrue);
    final args = Map<String, dynamic>.from(call!.arguments as Map);
    expect(args['text'], 'hello');
    expect(args['originWidth'], greaterThan(0));
    expect(args['originHeight'], greaterThan(0));
  });

  testWidgets('if sharing fails the message is copied, so the button is never dead', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), (c) async => throw PlatformException(code: 'error'));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String;
      return null;
    });
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) { ctx = c; return const SizedBox.expand(); })));
    expect(await shareText(ctx, 'hello'), isFalse);
    expect(copied, 'hello');
  });
}
