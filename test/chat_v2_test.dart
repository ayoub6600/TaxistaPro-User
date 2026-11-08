import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/widgets/chat/chat_actions.dart';
import 'package:taxista/widgets/chat/chat_kit.dart';

/// Chat 2.0: the reaction hangs on the bubble's own corner (own messages on the right, in Arabic
/// too), the quoted line shows inside the bubble, and a sideways swipe answers the message.
void main() {
  Widget host(Widget child, TextDirection dir) => MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: Scaffold(body: SizedBox(width: 400, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [child]))),
        ),
      );

  ChatBubble bubble({required bool mine, VoidCallback? onSwipe}) => ChatBubble(
        palette: ChatPalette.current(),
        mine: mine,
        tail: true,
        text: 'وين وصلت؟',
        time: '10:00',
        copiedLabel: 'copied',
        replyTo: const {'id': 1, 'name': 'أنت', 'text': 'أنا قدام المسجد'},
        reactions: const [
          {'emoji': '❤️', 'mine': false}
        ],
        onSwipeReply: onSwipe,
      );

  for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
    testWidgets('the reaction sits under its own bubble ($dir)', (t) async {
      await t.pumpWidget(host(bubble(mine: true), dir));
      final mineX = t.getCenter(find.byType(ChatReactionPill)).dx;
      expect(mineX, greaterThan(200), reason: 'own message on the right: its emoji on the right');

      await t.pumpWidget(host(bubble(mine: false), dir));
      final theirsX = t.getCenter(find.byType(ChatReactionPill)).dx;
      expect(theirsX, lessThan(200), reason: 'their message on the left: its emoji on the left');
    });
  }

  testWidgets('the quoted line is inside the bubble and a swipe answers it', (t) async {
    var replied = 0;
    await t.pumpWidget(host(bubble(mine: false, onSwipe: () => replied++), TextDirection.rtl));
    expect(find.text('أنا قدام المسجد'), findsOneWidget);
    expect(find.byType(ChatQuote), findsOneWidget);
    await t.drag(find.text('وين وصلت؟'), const Offset(90, 0));
    await t.pumpAndSettle();
    expect(replied, 1);
    await t.drag(find.text('وين وصلت؟'), const Offset(20, 0));
    await t.pumpAndSettle();
    expect(replied, 1, reason: 'a short drag does nothing');
  });
}
