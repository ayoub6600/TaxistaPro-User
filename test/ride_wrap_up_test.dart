import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/community/ride_wrap_up.dart';

/// "ختام الرحلة": the stars first, then only the cards this ride offers, one at a time; the
/// after-ride choices go before the rating, and nothing is sent before the last tap.
void main() {
  late List<String> sent;
  late Map<String, dynamic>? choices;
  late List<dynamic> ratingAnswers;
  late int finished;

  setUp(() {
    sent = [];
    choices = null;
    ratingAnswers = [true];
    finished = 0;
  });

  Map<String, dynamic> offers() => {
        'completed': true,
        'rated': false,
        'favorite': {'is': false, 'suggest': true, 'mutual': false},
        'badges': {
          'options': {'respectful': 'تعامل راقٍ', 'clean_car': 'سيارة نظيفة'},
          'sent': null,
        },
        'comment_allowed': true,
        'gift': {
          'coins': 10,
          'value_lyd': '1.00',
          'reasons': {'kind': 'لطيف'},
        },
      };

  Future<void> open(WidgetTester tester, {Map<String, dynamic>? after, bool canSkip = true}) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (_) => RideWrapUp(
          role: 'rider',
          requestId: 'ride-1',
          peerName: 'محمد علي',
          canSkipRating: canSkip,
          loadAfterRide: (_) async => after,
          sendRating: (stars, note) async {
            sent.add('rating:${stars.toInt()}:$note');
            return ratingAnswers.removeAt(0);
          },
          sendAfterRide: (c) async {
            sent.add('after');
            choices = c;
            return {
              'results': {'favorite': 'ok', 'appreciation': 'ok', 'gift': 'ok'},
            };
          },
          onFinished: () async => finished++,
          onLogout: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('wrapup-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('a ride with nothing extra: the stars, then "إرسال", then the thank-you and the map', (tester) async {
    await open(tester);
    expect(find.text('كيف كانت رحلتك؟'), findsOneWidget);
    // no star, no send
    await tester.tap(find.byKey(const ValueKey('wrapup-next')));
    await tester.pump();
    expect(sent, isEmpty);

    await tester.tap(find.byKey(const ValueKey('wrapup-star-5')));
    await tester.pumpAndSettle();
    expect(find.text('رائعة!'), findsOneWidget);
    expect(find.text('إرسال'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wrapup-add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('wrapup-note')), 'سائق محترم');
    await next(tester);

    expect(sent, ['rating:5:سائق محترم']);
    expect(find.byKey(const ValueKey('wrapup-thanks')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(finished, 1);
  });

  testWidgets('a good ride walks through heart, badges and gift, then sends the extras before the rating',
      (tester) async {
    await open(tester, after: offers());
    await tester.tap(find.byKey(const ValueKey('wrapup-star-5')));
    await tester.pumpAndSettle();
    expect(find.text('التالي'), findsOneWidget);
    await next(tester);

    expect(find.text('أضف محمد إلى «سواقيني»؟'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wrapup-heart')));
    await tester.pumpAndSettle();
    await next(tester);

    expect(find.text('ما الذي أعجبك؟'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wrapup-badge-clean_car')));
    await tester.enterText(find.byKey(const ValueKey('wrapup-praise')), 'شكرًا');
    await tester.pumpAndSettle();
    await next(tester);

    expect(find.text('أهدِ محمد 10 عملة ذهبية'), findsOneWidget);
    expect(sent, isEmpty, reason: 'nothing leaves before the last tap');
    await tester.tap(find.byKey(const ValueKey('wrapup-gift')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لطيف'));
    await tester.pumpAndSettle();
    await next(tester);

    expect(sent, ['after', 'rating:5:']);
    expect(choices, {
      'favorite': true,
      'badges': ['clean_car'],
      'comment': 'شكرًا',
      'gift': true,
      'gift_reason': 'kind',
    });
    expect(find.text('محمد في «سواقيني» الآن.'), findsOneWidget);
    expect(find.text('وصلت هديتك الذهبية إلى محمد.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(finished, 1);
  });

  testWidgets('a poor ride offers no heart, no badges and no gift', (tester) async {
    await open(tester, after: offers());
    await tester.tap(find.byKey(const ValueKey('wrapup-star-2')));
    await tester.pumpAndSettle();
    expect(find.text('إرسال'), findsOneWidget);
    await next(tester);
    expect(sent, ['rating:2:']);
    expect(choices, isNull);
    await tester.pump(const Duration(milliseconds: 1600));
  });

  testWidgets('back goes to the previous card; nothing chosen on a skipped card is sent', (tester) async {
    await open(tester, after: offers());
    await tester.tap(find.byKey(const ValueKey('wrapup-star-4')));
    await tester.pumpAndSettle();
    await next(tester);
    await tester.tap(find.byKey(const ValueKey('wrapup-heart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wrapup-back')));
    await tester.pumpAndSettle();
    expect(find.text('كيف كانت رحلتك؟'), findsOneWidget);

    // three stars now: the heart is no longer offered, so it is not sent
    await tester.tap(find.byKey(const ValueKey('wrapup-star-3')));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text('ما الذي أعجبك؟'), findsOneWidget);
    await next(tester);
    expect(sent, ['rating:3:']);
    expect(choices, isNull);
    await tester.pump(const Duration(milliseconds: 1600));
  });

  testWidgets('a rating that does not go through stays on the card with the reason, and is sent again', (tester) async {
    ratingAnswers = ['no internet', true];
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('wrapup-star-4')));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.byKey(const ValueKey('wrapup-problem')), findsOneWidget);
    expect(finished, 0);

    await next(tester);
    expect(sent, ['rating:4:', 'rating:4:']);
    expect(find.byKey(const ValueKey('wrapup-thanks')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(finished, 1);
  });

  testWidgets('a rider may skip; a driver may not', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('wrapup-skip')));
    await tester.pump();
    expect(finished, 1);
    expect(sent, isEmpty);

    await open(tester, canSkip: false);
    expect(find.byKey(const ValueKey('wrapup-skip')), findsNothing);
  });
}
