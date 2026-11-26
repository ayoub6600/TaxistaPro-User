import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/functions/service_kind.dart';
import 'package:taxista/pages/NavigatorPages/history_again.dart';
import 'package:taxista/pages/NavigatorPages/history_service.dart';

Map<String, Object?> _parcelRide() => {
      'service_kind': 'parcel',
      'pick_lat': 32.35,
      'pick_lng': 15.1,
      'pick_address': 'محلي',
      'drop_lat': '32.39',
      'drop_lng': '15.13',
      'drop_address': 'الزروق',
      'parcel': {
        'size': 'small',
        'size_label': 'صغير',
        'receiver_name': 'أحمد',
        'receiver_phone': '0912345678',
        'payer': 'sender',
        'needs_code': false,
        'pay': {'who': 'sender', 'how': 'wallet', 'amount': 8.5, 'sender': 'تنخصم 8.5 LYD من محفظتك'},
        'problem': {'kind': 'not_there', 'label': 'المستلم مش موجود', 'note': 'ما ردّش'},
      },
    };

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Directionality(textDirection: TextDirection.rtl, child: child)));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('each service its own icon and title; an older answer is told by its blocks', () {
    expect(ServiceKind.of(_parcelRide()).title(_parcelRide()), '📦 طرد لـأحمد');
    expect(ServiceKind.of({'service_kind': 'tow'}).title(const {}), '🚛 ساحبة');
    expect(ServiceKind.of({'service_kind': 'freight'}).title(const {}), '🚚 نقل');
    expect(ServiceKind.of({'service_kind': 'intercity'}).title(const {}), '🛣 سفر بين المدن');
    expect(ServiceKind.of(const {}).title(const {}), '🚕 رحلة');
    expect(ServiceKind.of({'tow': {}}).kind, 'tow');
    expect(ServiceKind.of({'is_out_station': 1}).kind, 'intercity');
    expect(ServiceKind.of({'service_kind': 'parcel'}).color, isNot(ServiceKind.of({'service_kind': 'tow'}).color));
  });

  test('wallet lines: the service label with its icon and the trip number', () {
    expect(ServiceKind.walletLine({'service_kind': 'parcel', 'service_label': 'طرد', 'request_number': 'REQ_1'}), '📦 طرد REQ_1');
    expect(ServiceKind.walletLine({'service_label': 'ونش', 'request_number': 'REQ_2'}), '🚛 ونش REQ_2');
    expect(ServiceKind.walletLine({'request_number': 'REQ_3'}), 'رحلة REQ_3', reason: 'an older line');
    expect(ServiceKind.walletLine({'remarks': 'top up'}), isNull);
  });

  test('«اطلبها مرة ثانية»: a parcel or a ride with both places; not a tow, a freight, a trip between cities or a rental', () {
    expect(HistoryAgain.can(_parcelRide()), isTrue);
    expect(HistoryAgain.drop(_parcelRide())!.lat, 32.39, reason: 'numbers that came as text');
    expect(HistoryAgain.can({..._parcelRide(), 'service_kind': 'ride'}), isTrue);
    for (final k in ['tow', 'freight', 'intercity']) {
      expect(HistoryAgain.can({..._parcelRide(), 'service_kind': k}), isFalse, reason: k);
    }
    expect(HistoryAgain.can({..._parcelRide(), 'service_kind': 'ride', 'is_rental': true}), isFalse);
    expect(HistoryAgain.can({..._parcelRide(), 'drop_lat': null}), isFalse, reason: 'a ride without a destination');
  });

  testWidgets('the history card: the kind and «اطلبها مرة ثانية» (only where it can be)', (t) async {
    var again = 0;
    await t.pumpWidget(_app(HistoryServiceHeader(ride: _parcelRide(), onAgain: () => again++)));
    expect(find.text('📦 طرد لـأحمد'), findsOneWidget);
    await t.tap(find.text('اطلبها مرة ثانية'));
    expect(again, 1);
    await t.pumpWidget(_app(HistoryServiceHeader(ride: {..._parcelRide(), 'service_kind': 'tow', 'parcel': null}, onAgain: () => again++)));
    expect(find.text('🚛 ساحبة'), findsOneWidget);
    expect(find.text('اطلبها مرة ثانية'), findsNothing);
  });

  testWidgets('the details page: the parcel\'s receiver, size, who paid how, no code and the problem', (t) async {
    await t.pumpWidget(_app(HistoryServiceDetails(ride: _parcelRide())));
    expect(find.text('أحمد · \u20660912345678\u2069'), findsOneWidget);
    expect(find.text('صغير'), findsOneWidget);
    expect(find.text('تنخصم 8.5 LYD من محفظتك'), findsOneWidget);
    expect(find.text('🔓 بدون كود'), findsOneWidget);
    expect(find.text('المستلم مش موجود · ما ردّش'), findsOneWidget);
  });

  test('tow and freight details; nothing for an ordinary ride', () {
    final tow = HistoryServiceDetails.lines({
      'tow': {
        'kind_label': 'سطحة',
        'condition_label': 'عطل',
        'car_label': 'سيدان',
        'workshop': {'name': 'ورشة النور'}
      },
    });
    expect(tow.map((e) => e.$2), ['سطحة', 'عطل', 'سيدان', 'ورشة النور']);
    final freight = HistoryServiceDetails.lines({
      'freight': {
        'class_label': 'نص نقل',
        'category_label': 'أثاث',
        'items': 'كنبة',
        'workers': 2,
        'pick_floor_label': 'أرضي',
        'drop_floor_label': 'الدور 2 · فيه مصعد'
      },
    });
    expect(freight.map((e) => e.$2), ['نص نقل', 'أثاث · كنبة', '2', 'أرضي', 'الدور 2 · فيه مصعد']);
    expect(HistoryServiceDetails.lines(const {'service_kind': 'ride'}), isEmpty);
  });
}
