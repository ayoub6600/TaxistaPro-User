import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const localFirebaseHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
const usesLocalFirebase = localFirebaseHost != '';

/// Configure before any database reference is created, including on restart.
Future<void> configureLocalFirebase(String apiBaseUrl) async {
  final apiHost = Uri.parse(apiBaseUrl).host;
  const loopbackHosts = ['localhost', '127.0.0.1', '10.0.2.2'];
  if (!usesLocalFirebase) {
    // A local API with cloud Firebase splits the app across two databases:
    // rides go to the local MySQL while driver presence, offers and
    // request-meta go to production, so each app sees a different world.
    if (kDebugMode && loopbackHosts.contains(apiHost)) {
      throw StateError(
        'API_BASE_URL points at $apiHost but FIREBASE_EMULATOR_HOST is empty, '
        'so this build would use production Firebase with the local backend. '
        'Launch with --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1.',
      );
    }
    return;
  }
  if (!kDebugMode ||
      !loopbackHosts.contains(localFirebaseHost) ||
      !loopbackHosts.contains(apiHost)) {
    throw StateError('Local Firebase requires a debug build and a local API.');
  }

  // Keep native app registration intact while isolating every existing
  // FirebaseDatabase.instance call in the same demonstration namespace.
  final database = FirebaseDatabase.instance;
  database.databaseURL =
      'https://demo-taxista-local-default-rtdb.firebaseio.com';
  database.useDatabaseEmulator(localFirebaseHost, 9000);
  await FirebaseAuth.instance.useAuthEmulator(localFirebaseHost, 9099);
  await FirebaseMessaging.instance.setAutoInitEnabled(false);
}
