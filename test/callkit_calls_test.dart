import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxista/functions/calls/admin_call_controller.dart';

/// Real-iPhone failures traced on 2026-11-02: a call the app had just started was hung up after 2 s
/// because CallKit reported the end of an older, stuck call. These pin how an event is matched to
/// the call the app holds, and that stuck calls are cleared before a new one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const server = '4e13a503-ed8f-4885-87e8-eaa11be22598';
  const older = 'dfcfd715-6aac-47af-a3da-b128559c0a96';

  test('the rider app gives CallKit the server id, lower case', () {
    expect(AdminCallController.callKitId(server.toUpperCase()), server);
  });

  test('an event is about the current call by its server id or by its bare CallKit id', () {
    expect(AdminCallController.isSameCall(const CallKitParams(id: server, extra: {'call_id': server}), server), isTrue);
    // an untracked call's end only carries the CallKit id, and CallKit hands UUIDs back in upper case
    expect(AdminCallController.isSameCall(CallKitParams(id: server.toUpperCase()), server), isTrue);
  });

  test('the end of an older, stuck call never hangs up the call just started', () {
    expect(AdminCallController.isSameCall(CallKitParams(id: older.toUpperCase()), server), isFalse);
    expect(AdminCallController.isSameCall(const CallKitParams(id: older, extra: {'call_id': older}), server), isFalse);
    expect(AdminCallController.isSameCall(const CallKitParams(id: server), null), isFalse);
  });

  test('every call but the current one is cleared from CallKit first', () {
    final active = [
      const CallKitParams(id: server, extra: {'call_id': server}),
      CallKitParams(id: older.toUpperCase()), // a ring the caller cancelled, still in CallKit
      const CallKitParams(id: ''),
    ];
    expect(AdminCallController.staleCallKitIds(active, server), [older]);
  });

  test('a call that stopped ringing is ended in CallKit under the id CallKit knows', () async {
    final sent = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_callkit_incoming'), (call) async {
      sent.add(call);
      return true;
    });
    await AdminCallController.dismissIncoming(server.toUpperCase());
    expect(sent.single.method, 'endCall');
    expect((sent.single.arguments as Map)['id'], server);
  });
}
