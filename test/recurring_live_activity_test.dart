import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// «🚕 مشوارك غدًا» on the iPhone lock screen (Live Activity): what must stay true in the native code.
void main() {
  final widget = File('ios/RecurringLive/RecurringLiveWidget.swift').readAsStringSync();
  final shared = File('ios/RecurringLive/RecurringDayShared.swift').readAsStringSync();
  final live = File('ios/Runner/RecurringLiveActivities.swift').readAsStringSync();
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  test('the card shows both buttons; ✅ runs in place, ⏭ opens the app (Face ID / code when locked)', () {
    expect('Button(intent: RecurringConfirmIntent('.allMatches(widget).length, 1);
    expect(widget.contains('Link(destination: attributes.skipURL)'), isTrue);
    expect(widget.contains('RecurringSkip'), isFalse, reason: 'skip is never an in-place intent');
    // short words beside Apple's own symbols (no emoji inside the coloured buttons)
    expect(widget.contains('title: "تأكيد"') && widget.contains('title: "تخطي"'), isTrue);
    expect(widget.contains('HStack(spacing: 10)'), isTrue, reason: 'the two buttons side by side, never stacked');
    expect(shared.contains('"platform": "ios_live"'), isTrue);
    expect(shared.contains('api/v1/recurring-day/'), isTrue);
  });

  test('no buttons once stale; a lost connection keeps them with a short line (never past Apple\'s height)', () {
    expect(widget.contains('!context.isStale'), isTrue);
    expect(shared.contains('phase: "retry"'), isTrue);
    expect(widget.contains('if s.phase == "retry" && !s.note.isEmpty && asks(context)'), isTrue);
  });

  test('a tap shows «جاري…» at once, never a success before the server; a stuck send gives the buttons back', () {
    expect(shared.contains('phase: "sending"'), isTrue);
    expect(shared.contains('staleDate: Date().addingTimeInterval(25)'), isTrue);
    expect(widget.contains('func sendingStuck('), isTrue);
    final sendingAt = shared.indexOf('phase: "sending"');
    final postAt = shared.indexOf('let reply = await post(');
    expect(sendingAt, lessThan(postAt), reason: '«جاري…» before the request, «done» only after the reply');
  });

  test('the real Taxista Rider icon, never an emoji, small enough for every presentation', () {
    expect(widget.contains('Image("TaxistaIcon")'), isTrue);
    expect(widget.contains('Text("🚕")'), isFalse);
    for (final f in ['TaxistaIcon@2x.png', 'TaxistaIcon@3x.png']) {
      expect(File('ios/RecurringLive/LiveAssets.xcassets/TaxistaIcon.imageset/$f').existsSync(), isTrue);
    }
    expect(pbx.contains('LiveAssets.xcassets in Resources'), isTrue);
    expect(widget.contains('.widgetURL(context.attributes.openURL)'), isTrue, reason: 'a tap on the card opens that day');
    expect(live.contains('url.path == "/open"') && live.contains('"takeOpen"'), isTrue);
  });

  test('the TestFlight tryout and the rig hook never reach an App Store build', () {
    expect(live.contains('appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"'), isTrue);
    final rig = live.indexOf('rig_live_card');
    expect(rig, greaterThan(0));
    expect(live.lastIndexOf('#if targetEnvironment(simulator)', rig), greaterThan(0));
    expect(shared.contains('occurrenceId == "demo"'), isTrue, reason: 'a tryout card never posts to the server');
  });

  test('the app can show Live Activities, opens taxistarider:// and embeds the extension', () {
    expect(plist.contains('NSSupportsLiveActivities'), isTrue);
    expect(plist.contains('<string>taxistarider</string>'), isTrue);
    expect(pbx.contains('com.taxistapro.user.RecurringLive'), isTrue);
    expect(pbx.contains('RecurringLive.appex'), isTrue);
    expect(pbx.contains('Embed Foundation Extensions'), isTrue);
  });

  test('short words on the Android buttons too', () {
    final dart = File('lib/functions/recurring_push.dart').readAsStringSync();
    expect(dart.contains("'✅ تأكيد'") && dart.contains("'⏭ تخطي'"), isTrue);
    expect(dart.contains('تأكيد مشوار الغد'), isFalse);
  });
}
