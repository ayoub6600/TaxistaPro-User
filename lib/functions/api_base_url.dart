import 'package:flutter/foundation.dart';

/// The production API, and the local backend a developer runs on this Mac.
const productionApiBaseUrl = 'https://taxista.aljidartech.com/';
const localApiBaseUrl = 'http://127.0.0.1:8002/';

/// Where the app's API lives.
///
/// An explicit `--dart-define=API_BASE_URL=...` always wins. Without it a debug
/// run talks to the local backend, so a plain VS Code Run never signs in to
/// production by accident, and a release build talks to production: a release
/// APK left on 127.0.0.1 cannot even load the country list, so nobody can sign
/// in (rider APK 6.5.0+39, 2026-11-01). A compile-time constant, so a release
/// binary holds the production address only (tool/build_release_apk.sh checks).
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode ? productionApiBaseUrl : localApiBaseUrl,
);
