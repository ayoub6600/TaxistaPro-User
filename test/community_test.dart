import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taxista/community/after_ride_page.dart';
import 'package:taxista/community/community_api.dart';
import 'package:taxista/community/favorite_driver_choice.dart';
import 'package:taxista/community/favorites_page.dart';
import 'package:taxista/community/rewards_page.dart';
import 'package:taxista/functions/functions.dart' as app;

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// TAXISTA 2.0 rider screens against a mocked server: what they show, what they send.
void main() {
  late List<http.Request> requests;

  setUp(() {
    requests = [];
    app.bearerToken = [app.BearerClass(type: 'Bearer', token: 'test-token')];
    app.languageDirection = 'rtl';
    chosenFavoriteDriverId = null;
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final afterState = {
    'request_id': 'ride-9',
    'role': 'rider',
    'completed': true,
    'peer': {'driver_id': 7, 'name': 'محمد', 'photo': null, 'car': 'Hyundai Accent · أبيض'},
    'rated': true,
    'favorite': {'is': false, 'suggest': true, 'mutual': false},
    'badges': {'options': {'respectful': 'تعامل راقٍ', 'clean_car': 'سيارة نظيفة'}, 'sent': null},
    'comment_allowed': true,
    'gift': {'coins': 10, 'value_lyd': '0.50', 'reasons': {'clean_car': 'سيارة نظيفة'}, 'expires_at': '2026-11-03T10:00:00Z'},
    'gift_sent': false,
    'mutual_appreciation': false,
  };

  testWidgets('after the ride: heart, a badge, a word and the gold gift go in one request', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: AfterRidePage(requestId: 'ride-9', state: Map<String, dynamic>.from(afterState))));
      await settle(tester);
      expect(find.text('أضف محمد إلى «سواقيني»'), findsOneWidget);
      expect(find.text('أهدِ محمد 10 عملة ذهبية'), findsOneWidget);
      expect(find.textContaining('تدفعها تاكسيستا بالكامل'), findsOneWidget);

      await tester.tap(find.text('أضف محمد إلى «سواقيني»'));
      await tester.tap(find.text('سيارة نظيفة'));
      await tester.enterText(find.byType(TextField), 'شكرًا على الرحلة');
      await tester.tap(find.byType(Switch));
      await settle(tester);
      await tester.tap(find.text('سيارة نظيفة').last);
      await tester.tap(find.text('إرسال'));
      await settle(tester);
    }, () => MockClient((request) async {
          requests.add(request);
          return _json({'success': true, 'data': {...afterState, 'results': {'favorite': 'ok', 'appreciation': 'ok', 'gift': 'ok'}}});
        }));

    final sent = requests.singleWhere((r) => r.method == 'POST');
    expect(sent.url.path, endsWith('community/rides/ride-9/after'));
    expect(jsonDecode(sent.body), {
      'favorite': true,
      'badges': ['clean_car'],
      'comment': 'شكرًا على الرحلة',
      'gift': true,
      'gift_reason': 'clean_car',
    });
    expect(find.text('أضفنا محمد إلى «سواقيني».'), findsOneWidget);
    expect(find.text('وصلت هديتك الذهبية إلى محمد، شكرًا لك.'), findsOneWidget);
  });

  testWidgets('rewards: balances apart, gold progress and a campaign with its terms', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: RewardsPage()));
      await settle(tester);
    }, () => MockClient((request) async {
          if (request.url.path.endsWith('rewards/summary')) {
            return _json({
              'success': true,
              'data': {
                'party': 'rider',
                'balances': {'wallet_lyd': '15.00', 'ride_credit_lyd': '10.00', 'own_money_lyd': '5.00', 'campaign_rewards_on_the_way_lyd': '7.50'},
                'gold': {'enabled': true, 'coins': 40, 'pending_coins': 10, 'value_lyd': '2.00', 'conversion_threshold': 100, 'can_convert': false, 'expiring_in_30_days': 0},
                'history': [
                  {'what': 'مكافأة حملة', 'kind': 'إضافة', 'unit': 'lyd', 'amount': '10.00', 'at': '2026-11-01T10:00:00Z'}
                ],
                'marketing_opt_out': false,
                'achievements': [
                  {'key': 'first_favorite', 'title': 'أول سائق في «سواقيني»', 'reached': true}
                ],
                'how_it_works': 'بعد بعض الرحلات المؤهلة تقدر تهدي سائقك.',
              }
            });
          }
          if (request.url.path.endsWith('request/promotions')) {
            return _json({
              'success': true,
              'data': {
                'campaigns': [
                  {'id': 'c1', 'name': '100 رحلة = 100 دينار', 'type': 'completed_rides', 'reward_amount': 100, 'currency_symbol': 'د.ل',
                    'required_rides': 100, 'completed_rides': 55, 'can_earn_more': true, 'reward_label': 'رصيد مشاوير',
                    'count_period': 'campaign', 'period_ends_at': '2026-12-31T22:00:00Z', 'pending_amount': '0.00',
                    'terms': 'أكمل 100 رحلة خلال مدة الحملة واحصل على 100.00 د.ل.'}
                ]
              }
            });
          }
          return _json({'success': true, 'data': {}});
        }));

    expect(find.text('10.00 د.ل'), findsWidgets);
    expect(find.text('5.00 د.ل'), findsOneWidget);
    expect(find.text('7.50 د.ل'), findsOneWidget);
    expect(find.text('40 عملة ذهبية'), findsOneWidget);
    expect(find.text('باقي 60 عملة للتحويل إلى رصيد مشاوير.'), findsOneWidget);
    expect(find.text('أول سائق في «سواقيني»'), findsOneWidget);
    // design v2: the ride campaign leads on its own card, and its page holds the count and the terms
    expect(find.text('باقي 45 رحلة مكتملة'), findsOneWidget);
    await tester.tap(find.text('100 رحلة = 100 دينار'));
    await settle(tester);
    expect(find.text('55'), findsWidgets);
    expect(find.text('من 100 رحلة'), findsOneWidget);
    expect(find.text('باقي 45 رحلة على مكافأتك'), findsOneWidget);
    expect(find.text('أكمل 100 رحلة خلال مدة الحملة واحصل على 100.00 د.ل.'), findsOneWidget);
  });

  testWidgets('booking: a free favourite is offered and chosen; the request names him', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FavoriteDriverChoice(pickLat: 32.8872, pickLng: 13.1913, zoneTypeId: 'zone-type-1')),
      ));
      await settle(tester);
      await tester.tap(find.text('محمد · 5 د'));
      await settle(tester);
    }, () => MockClient((request) async {
          requests.add(request);
          return _json({
            'success': true,
            'data': {
              'drivers': [
                {'driver_id': 7, 'name': 'محمد علي', 'photo': null, 'distance_km': 2.0, 'eta_minutes': 5, 'rides_together': 3}
              ]
            }
          });
        }));

    expect(requests.single.url.queryParameters, {'pick_lat': '32.8872', 'pick_lng': '13.1913', 'vehicle_type': 'zone-type-1'});
    expect(find.text('سائقك المفضل متاح الآن'), findsOneWidget);
    expect(chosenFavoriteDriverId, 7);
    expect(find.textContaining('نعرض طلبك عليه أولًا'), findsOneWidget);
    expect(jsonDecode(withChosenFavorite(jsonEncode({'pick_lat': 1}))), {'pick_lat': 1, 'preferred_driver_id': 7});
  });

  testWidgets('booking: nobody free, nothing shown', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FavoriteDriverChoice(pickLat: 32.8, pickLng: 13.1, zoneTypeId: 'zone-type-1')),
      ));
      await settle(tester);
    }, () => MockClient((request) async => _json({'success': true, 'data': {'drivers': []}})));

    expect(find.textContaining('متاح'), findsNothing);
    expect(withChosenFavorite('{"pick_lat":1}'), '{"pick_lat":1}');
  });

  testWidgets('"سواقيني": the list, and the heart removes a driver', (tester) async {
    bigScreen(tester);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: FavoritesPage()));
      await settle(tester);
      expect(find.text('محمد علي'), findsOneWidget);
      expect(find.text('3 رحلة معًا'), findsOneWidget);
      expect(find.text('يفضّلك أيضًا'), findsOneWidget);
      await tester.tap(find.byTooltip('إزالة من سواقيني'));
      await settle(tester);
    }, () => MockClient((request) async {
          requests.add(request);
          if (request.method == 'DELETE') return _json({'success': true, 'data': {'favorite': false}});
          return _json({
            'success': true,
            'data': [
              {'driver_id': 7, 'name': 'محمد علي', 'car': 'Hyundai Accent', 'rating': 4.9, 'verified': true, 'rides_together': 3, 'mutual': true}
            ]
          });
        }));

    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, endsWith('community/favorites/7'));
    expect(find.text('محمد علي'), findsNothing);
  });
}
