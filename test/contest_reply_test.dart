import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/contests/contests_kit.dart';

/// «رد» on a contest comment: the button, and the quote of what a reply answers.
void main() {
  testWidgets('a reply shows the comment it answers, and «رد» hands the comment to the page', (tester) async {
    Map<String, dynamic>? picked;
    final reply = <String, dynamic>{'id': 2, 'name': 'محمد ب.', 'body': 'لا، تعادل', 'likes': 0, 'liked': false, 'created_at': '2026-11-12T12:00:00Z',
      'reply_to': {'id': 1, 'name': 'سالم و.', 'text': 'ليبيا بتكسب'}};
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ContestCommentTile(comment: reply, postId: 3, onReply: (c) => picked = c))));
    expect(find.text('↩ سالم و.'), findsOneWidget);
    expect(find.text('ليبيا بتكسب'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reply-2')));
    expect(picked?['id'], 2);
  });

  testWidgets('without onReply there is no «رد» (the feed previews)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ContestCommentTile(comment: {'id': 5, 'name': 'خالد', 'body': 'هلا', 'likes': 0, 'created_at': '2026-11-12T12:00:00Z'}, postId: 3))));
    expect(find.text('رد'), findsNothing);
  });
}
