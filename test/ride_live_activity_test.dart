import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The ride on the iPhone lock screen + Dynamic Island (Live Activity): the contract the server
/// builds its pushes against, and what must stay true in the native code.
void main() {
  final shared = File('ios/RecurringLive/TaxistaRideShared.swift').readAsStringSync();
  final widget = File('ios/RecurringLive/TaxistaRideWidget.swift').readAsStringSync();
  final bundle = File('ios/RecurringLive/RecurringLiveWidget.swift').readAsStringSync();
  final live = File('ios/Runner/RideLiveActivities.swift').readAsStringSync();
  final app = File('ios/Runner/AppDelegate.swift').readAsStringSync();
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  test('the attributes type and JSON keys the server pushes (push-to-start uses the type name)', () {
    expect(shared.contains('struct TaxistaRideAttributes: ActivityAttributes'), isTrue);
    for (final k in ['"request_id"', '"rating_token"', '"driver_name"']) {
      expect(shared.contains(k), isTrue, reason: k);
    }
    expect(shared.contains('case plate, car'), isTrue);
    for (final k in ['"eta_minutes"', '"pay_amount"', '"pay_line"']) {
      expect(shared.contains(k), isTrue, reason: k);
    }
    expect(shared.contains('case stage, title, subtitle, progress, note, rated'), isTrue);
    // lenient: a number as text, a missing key or null never stops the card
    expect(shared.contains('func looseString(') && shared.contains('func looseDouble('), isTrue);
  });

  test('both tokens reach the server natively with the saved login (works on a background launch)', () {
    expect(live.contains('Activity<TaxistaRideAttributes>.pushToStartTokenUpdates'), isTrue);
    expect(live.contains('"api/v1/user/live-activity/ride-start-token", ["token": hex]'), isTrue);
    expect(live.contains('a.pushTokenUpdates'), isTrue);
    expect(live.contains('"api/v1/request/live-activity/update-token", ["request_id": requestId, "token": hex]'), isTrue);
    expect(live.contains('"flutter.Bearer"') && live.contains('"Bearer \\(jwt)"'), isTrue);
    expect(live.contains('beginBackgroundTask'), isTrue);
    expect(live.contains('didBecomeActiveNotification'), isTrue, reason: 'a token that could not go is sent again');
    expect(app.contains('RideLiveActivities.start()'), isTrue);
    expect(app.contains('RideLiveActivities.open(url)'), isTrue);
  });

  test('five stars on the card, each one the rating itself, no login, never «thank you» before the server', () {
    expect(shared.contains('struct RateRideIntent: LiveActivityIntent'), isTrue);
    expect(shared.contains('"api/v1/request/live-rate"'), isTrue);
    expect(shared.contains('["request_id": requestId, "t": token, "rating": stars]'), isTrue);
    expect(shared.contains('forHTTPHeaderField: "Authorization"'), isFalse, reason: 'the card\'s own rating token, no bearer');
    expect(widget.contains('ForEach(1...5'), isTrue);
    expect(widget.contains('Button(intent: RateRideIntent('), isTrue);
    final postAt = shared.indexOf('let ok = await post(');
    final thanksAt = shared.indexOf('"شكرًا على تقييمك"');
    expect(postAt, greaterThan(0));
    expect(thanksAt, greaterThan(postAt));
    expect(shared.contains('"ما وصلش التقييم، افتح التطبيق"'), isTrue);
    expect(shared.contains('dismissalPolicy: .after('), isTrue, reason: 'ends a few seconds after the thanks');
  });

  test('the approved look: Taxista blue, the yellow plate, every stage, no emoji', () {
    expect(widget.contains('#1677FF') && widget.contains('#FFD43B'), isTrue);
    for (final s in ['"coming"', '"arrived"', '"on_trip"', '"rate"']) {
      expect(widget.contains('case $s'), isTrue, reason: s);
    }
    for (final w in ['يوصلك خلال', 'ينتظر فيك', 'توصل ', 'تدفع للكابتن نقدًا', 'كيف كانت رحلتك مع', 'قيّم']) {
      expect(widget.contains(w), isTrue, reason: w);
    }
    expect(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true).hasMatch(widget), isFalse);
    expect(widget.contains('.environment(\\.layoutDirection, .rightToLeft)'), isTrue);
    expect(widget.contains('.widgetURL(context.attributes.openURL)'), isTrue);
  });

  test('beside the recurring card in the same extension; the rig never reaches a phone', () {
    expect(bundle.contains('RecurringDayLiveActivity()') && bundle.contains('TaxistaRideLiveActivity()'), isTrue);
    int built(String f) => '$f in Sources */ = {isa = PBXBuildFile'.allMatches(pbx).length;
    expect(built('TaxistaRideShared.swift'), 2, reason: 'app (the stars\' intent) + extension (the card)');
    expect(built('TaxistaRideWidget.swift'), 1);
    expect(built('RideLiveActivities.swift'), 1);
    final rig = live.indexOf('rig_ride_card');
    expect(rig, greaterThan(0));
    expect(live.lastIndexOf('#if targetEnvironment(simulator)', rig), greaterThan(0));
  });

  test('rated inside the app: its card leaves the lock screen', () {
    final dart = File('lib/functions/live_activity.dart').readAsStringSync();
    final rating = File('lib/functions/parts/ride_requests.dart').readAsStringSync();
    expect(dart.contains("MethodChannel('taxista/ride_live_activity')"), isTrue);
    expect(live.contains('"taxista/ride_live_activity"') && live.contains('case "endRide"'), isTrue);
    expect(rating.contains('LiveActivity.endRide(ratedId)'), isTrue);
  });
}
