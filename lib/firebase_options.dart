// File generated manually to match GoogleService-Info.plist and Firebase Console
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCFL4Gk3U2IfCqTpGLH_IiAXwxOcCIQcTc',
    appId: '1:1066498192256:web:3373d1a08b0afc8f1f8765',
    messagingSenderId: '1066498192256',
    projectId: 'taxista-ee27d',
    authDomain: 'taxista-ee27d.firebaseapp.com',
    storageBucket: 'taxista-ee27d.firebasestorage.app',
    measurementId: 'G-5ZXJYJM3E7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvXGdmQyi4cLNF6cTn-zu-8qJcDStIf2E',
    appId: '1:1066498192256:android:612d08f233ca51051f8765',
    messagingSenderId: '1066498192256',
    projectId: 'taxista-ee27d',
    storageBucket: 'taxista-ee27d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCFL4Gk3U2IfCqTpGLH_IiAXwxOcCIQcTc',
    appId: '1:1066498192256:ios:717df0b6737598561f8765',
    messagingSenderId: '1066498192256',
    projectId: 'taxista-ee27d',
    storageBucket: 'taxista-ee27d.firebasestorage.app',
    androidClientId:
        '1066498192256-0s8qle9uqvprpad59c2gnis4f4dvb8um.apps.googleusercontent.com',
    iosBundleId: 'com.taxistapro.user',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = web;
}
