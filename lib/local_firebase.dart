import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const localFirebaseHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
const usesLocalFirebase = localFirebaseHost != '';

/// Configure before any database reference is created, including on restart.
Future<void> configureLocalFirebase(String apiBaseUrl) async {
  if (!usesLocalFirebase) return;
  final apiHost = Uri.parse(apiBaseUrl).host;
  const loopbackHosts = ['localhost', '127.0.0.1', '10.0.2.2'];
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
