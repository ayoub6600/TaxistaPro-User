import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:taxista/contests/contests_kit.dart';
import 'package:taxista/contests/contests_pages.dart';

/// The contest post, its comments and the prediction sheet draw from the server's own words.
Map<String, dynamic> _post({String status = 'open', bool mine = false, bool won = false, bool hidden = false}) => {
      'id': 7,
      'kind': 'contest',
      'caption': '🏆 مسابقة الأسبوع: كم تنتهي مباراة السويحلي والاتحاد؟\nاكتب توقّعك في التعليقات 👇',
      'image_url': null,
      'published_at': DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
      'counts': {'likes': 1240, 'comments': 846, 'shares': 213},
      'liked': false,
      'share_url': 'https://taxista.aljidartech.com/c/ABCDEF',
      'contest': {
        'kind': 'match',
        'label': 'توقّع النتيجة',
        'question': 'كم تنتهي مباراة السويحلي والاتحاد؟',
        'teams': {
          'home': {'name': 'السويحلي', 'color': '#0E8A5F'},
          'away': {'name': 'الاتحاد', 'color': '#C62828'},
        },
        'status': status,
        'seconds_left': status == 'open' ? 8076 : 0,
        'prizes': {
          'riders': {'text': '5 × 20.00 د.ل رصيد مشاوير'},
          'drivers': null
        },
        'hide_answers': hidden,
        'correct_text': status == 'paid' ? 'السويحلي 2 – 1 الاتحاد' : null,
      },
      'my_entry': mine ? {'text': 'السويحلي 2 – 1 الاتحاد'} : null,
      'my_result': won ? {'won': true, 'amount_lyd': '20.00', 'credited': true, 'show_name': false} : null,
      'can_predict': status == 'open' && !mine,
      'can_comment': !(status == 'open' && !mine),
      'preview_comments': [
        {
          'id': 1,
          'name': 'محمد ع.',
          'party': 'rider',
          'is_captain': false,
          'is_mine': false,
          'body': 'السويحلي اليوم واخذها',
          'prediction': {'text': 'السويحلي 2 – 1 الاتحاد', 'hidden': false, 'correct': status == 'paid' ? true : null},
          'likes': 48,
          'liked': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'id': 2,
          'name': 'الكابتن خالد م.',
          'party': 'driver',
          'is_captain': true,
          'is_mine': false,
          'body': null,
          'prediction': {'text': null, 'hidden': true, 'correct': null},
          'likes': 0,
          'liked': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    };

Widget _app(Widget child) => MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: SingleChildScrollView(child: child))));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a contest post looks like a social post: counts, actions, comments that are predictions', (t) async {
    await t.pumpWidget(_app(ContestPostCard(post: _post(), onOpen: () {})));
    await t.pump();
    expect(find.text('تاكسيستا'), findsOneWidget);
    expect(find.text('1.2 ألف'), findsOneWidget);
    expect(find.text('846 توقّع · 213 مشاركة'), findsOneWidget);
    expect(find.text('أعجبني'), findsWidgets);
    expect(find.text('توقّع'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
    expect(find.text('التوقعات تقفل بعد'), findsOneWidget);
    expect(find.text('السويحلي 2 – 1 الاتحاد'), findsOneWidget);
    expect(find.text('كابتن'), findsOneWidget);
    expect(find.text('الإجابة مخفية لين تقفل'), findsOneWidget);
    expect(find.text('عرض كل التوقعات'), findsOneWidget);
  });

  testWidgets('after the result the strip turns green and right predictions say so', (t) async {
    await t.pumpWidget(_app(ContestPostCard(post: _post(status: 'paid', mine: true), onOpen: () {})));
    await t.pump();
    expect(find.textContaining('النتيجة طلعت'), findsOneWidget);
    expect(find.text('السويحلي 2 – 1 الاتحاد · صح'), findsOneWidget);
    expect(find.text('توقّعك'), findsOneWidget);
  });

  testWidgets('the prediction sheet sends a score with optional words and warns it is final', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: PredictionSheet(post: _post())))));
    await t.pump();
    expect(find.text('انشر توقّعي'), findsOneWidget);
    expect(find.textContaining('توقّع واحد لكل حساب'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    await t.tap(find.widgetWithText(TextButton, '+').first);
    await t.pump();
    await t.tap(find.widgetWithText(TextButton, '+').first);
    await t.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the home card invites to predict and shows the count', (t) async {
    await t.pumpWidget(_app(ContestHomeCard(post: _post())));
    await t.pump();
    expect(find.text('توقّع: السويحلي × الاتحاد'), findsOneWidget);
    expect(find.text('846 توقّع · 5 × 20.00 د.ل رصيد مشاوير'), findsOneWidget);
    expect(find.text('توقّع'), findsOneWidget);
  });
}
