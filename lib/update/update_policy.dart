import '../utils/version.dart';

/// What the app must do about the version policy the backend published.
enum UpdateDecision {
  /// Installed version meets the policy - open normally.
  none,

  /// A newer version is in the store; the user may update now or later.
  optional,

  /// Installed version is below the lowest version still allowed.
  mandatory,
}

/// Installed "6.4.2 (37)" against a required "6.4.10 (0)": -1 older, 0 same, 1 newer. Versions
/// compare numerically part by part; a required build of 0 means "any build".
int compareInstalled(String version, int build, String requiredVersion, int requiredBuild) {
  if (isVersionOutdated(version, requiredVersion)) return -1;
  if (isVersionOutdated(requiredVersion, version)) return 1;
  if (requiredBuild <= 0) return 0;
  return build.compareTo(requiredBuild).sign;
}

/// One platform of the app release page (Admin -> إصدارات التطبيقات), as AppUpdateSync publishes
/// it under `platforms/android` or `platforms/ios`:
///  - the version users can download now (nothing newer is ever announced);
///  - the lowest version still allowed, when the admin made it mandatory (never above the live one);
///  - from when the update window may offer the live version, and its message.
class PlatformRelease {
  const PlatformRelease({
    this.liveVersion = '',
    this.liveBuild = 0,
    this.mandatory = false,
    this.minVersion = '',
    this.minBuild = 0,
    this.notifyAt = 0,
    this.messageAr = '',
    this.messageEn = '',
    this.url = '',
  });

  final String liveVersion;
  final int liveBuild;
  final bool mandatory;
  final String minVersion;
  final int minBuild;

  /// Milliseconds since the epoch; 0 = at once.
  final int notifyAt;
  final String messageAr;
  final String messageEn;
  final String url;

  factory PlatformRelease.fromMap(Map<dynamic, dynamic> data) {
    String text(String key) => data[key]?.toString().trim() ?? '';
    int number(String key) => int.tryParse(data[key]?.toString().trim() ?? '') ?? 0;
    return PlatformRelease(
      liveVersion: text('live_version'),
      liveBuild: number('live_build'),
      mandatory: _truthy(data['mandatory']),
      minVersion: text('min_version'),
      minBuild: number('min_build'),
      notifyAt: number('notify_at'),
      messageAr: text('message_ar'),
      messageEn: text('message_en'),
      url: text('url'),
    );
  }

  Map<String, dynamic> toJson() => {
        'live_version': liveVersion,
        'live_build': liveBuild,
        'mandatory': mandatory,
        'min_version': minVersion,
        'min_build': minBuild,
        'notify_at': notifyAt,
        'message_ar': messageAr,
        'message_en': messageEn,
        'url': url,
      };

  UpdateDecision evaluate(String installedVersion, int installedBuild, int nowMs) {
    if (mandatory &&
        minVersion.isNotEmpty &&
        compareInstalled(installedVersion, installedBuild, minVersion, minBuild) < 0) {
      return UpdateDecision.mandatory;
    }
    if (liveVersion.isNotEmpty &&
        notifyAt <= nowMs &&
        compareInstalled(installedVersion, installedBuild, liveVersion, liveBuild) < 0) {
      return UpdateDecision.optional;
    }
    return UpdateDecision.none;
  }
}

bool _truthy(dynamic v) =>
    v == true || v == 1 || v?.toString().toLowerCase() == 'true' || v?.toString() == '1';

/// One app's update policy, as the backend syncs it to Firebase (`force_update_user` for the
/// Rider app, `force_update_driver` for the Driver app - never shared, see AppUpdateSync).
///
/// Since 6.7.2 / 6.8.2 the app reads its own platform under `platforms`. The flat fields are what
/// older versions read (one minimum per platform, one mandatory switch) and stay the fallback
/// when `platforms` is missing. Versions compare numerically ("6.4.2" is older than "6.4.10").
class UpdatePolicy {
  const UpdatePolicy({
    this.version = '',
    this.versionIos = '',
    this.versionAndroid = '',
    this.minBuildIos = 0,
    this.minBuildAndroid = 0,
    this.isMandatory = false,
    this.notes = '',
    this.urlAndroid = '',
    this.urlIos = '',
    this.android,
    this.ios,
  });

  final String version;
  final String versionIos;
  final String versionAndroid;
  final int minBuildIos;
  final int minBuildAndroid;
  final bool isMandatory;
  final String notes;
  final String urlAndroid;
  final String urlIos;
  final PlatformRelease? android;
  final PlatformRelease? ios;

  /// Tolerant of the loosely typed values Firebase hands back.
  factory UpdatePolicy.fromMap(Map<dynamic, dynamic> data) {
    String text(String key) => data[key]?.toString().trim() ?? '';
    int number(String key) => int.tryParse(data[key]?.toString().trim() ?? '') ?? 0;
    final platforms = data['platforms'];
    PlatformRelease? platform(String key) =>
        platforms is Map && platforms[key] is Map ? PlatformRelease.fromMap(platforms[key] as Map) : null;
    return UpdatePolicy(
      version: text('version'),
      versionIos: text('version_ios'),
      versionAndroid: text('version_android'),
      minBuildIos: number('min_build_ios'),
      minBuildAndroid: number('min_build_android'),
      isMandatory: _truthy(data['is_mandatory']),
      notes: text('release_notes'),
      urlAndroid: text('url'),
      urlIos: text('url_ios'),
      android: platform('android'),
      ios: platform('ios'),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'version_ios': versionIos,
        'version_android': versionAndroid,
        'min_build_ios': minBuildIos,
        'min_build_android': minBuildAndroid,
        'is_mandatory': isMandatory,
        'release_notes': notes,
        'url': urlAndroid,
        'url_ios': urlIos,
        if (android != null || ios != null)
          'platforms': {
            if (android != null) 'android': android!.toJson(),
            if (ios != null) 'ios': ios!.toJson(),
          },
      };

  PlatformRelease? platform({required bool isIos}) => isIos ? ios : android;

  /// The version this platform must at least be running ('' = no requirement) - the flat fields.
  String requiredVersion({required bool isIos}) {
    final own = isIos ? versionIos : versionAndroid;
    return own.isNotEmpty ? own : version;
  }

  UpdateDecision evaluate({
    required String installedVersion,
    required int installedBuild,
    required bool isIos,
    int? nowMs,
  }) {
    final own = platform(isIos: isIos);
    if (own != null) {
      return own.evaluate(installedVersion, installedBuild, nowMs ?? DateTime.now().millisecondsSinceEpoch);
    }
    final required = requiredVersion(isIos: isIos);
    final minBuild = isIos ? minBuildIos : minBuildAndroid;
    final versionTooOld =
        required.isNotEmpty && isVersionOutdated(installedVersion, required);
    final buildTooOld = minBuild > 0 && installedBuild < minBuild;
    if (!versionTooOld && !buildTooOld) return UpdateDecision.none;
    return isMandatory ? UpdateDecision.mandatory : UpdateDecision.optional;
  }

  /// The admin's message for this platform in [languageCode] ('' when there is none).
  String message({required bool isIos, required String languageCode}) {
    final own = platform(isIos: isIos);
    if (own != null) {
      final text = languageCode == 'en' ? own.messageEn : own.messageAr;
      if (text.isNotEmpty) return text;
    }
    return notes;
  }

  static const _storeHosts = {true: 'apps.apple.com', false: 'play.google.com'};

  /// The store link to open: the admin's link when it is a real https link to THIS platform's
  /// store (an Android phone never goes to the App Store), otherwise the listing baked into the app.
  String storeUrl({
    required bool isIos,
    required String fallbackIos,
    required String fallbackAndroid,
  }) {
    for (final candidate in [platform(isIos: isIos)?.url ?? '', isIos ? urlIos : urlAndroid]) {
      final uri = Uri.tryParse(candidate);
      if (uri != null && uri.scheme == 'https' && uri.host == _storeHosts[isIos]) return candidate;
    }
    return isIos ? fallbackIos : fallbackAndroid;
  }
}
