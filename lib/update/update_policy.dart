import '../utils/version.dart';

/// What the app must do about the version policy the backend published.
enum UpdateDecision {
  /// Installed version meets the policy - open normally.
  none,

  /// A newer version exists but the admin did not make it mandatory.
  optional,

  /// Installed version is below the minimum and the update is mandatory.
  mandatory,
}

/// One app's force-update policy, as the backend syncs it to Firebase
/// (`force_update_user` for the Rider app, `force_update_driver` for the
/// Driver app - never shared, see AppUpdateSync on the backend).
///
/// Versions are compared numerically part by part ("6.4.2" is older than
/// "6.4.10"), never as strings. `versionIos` / `versionAndroid` are optional
/// per-platform minimums; blank falls back to [version]. Build numbers are an
/// additional optional minimum (0 = no build check).
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

  /// Tolerant of the loosely typed values Firebase hands back.
  factory UpdatePolicy.fromMap(Map<dynamic, dynamic> data) {
    String text(String key) => data[key]?.toString().trim() ?? '';
    int number(String key) => int.tryParse(data[key]?.toString().trim() ?? '') ?? 0;
    final mandatory = data['is_mandatory'];
    return UpdatePolicy(
      version: text('version'),
      versionIos: text('version_ios'),
      versionAndroid: text('version_android'),
      minBuildIos: number('min_build_ios'),
      minBuildAndroid: number('min_build_android'),
      isMandatory: mandatory == true ||
          mandatory == 1 ||
          mandatory?.toString().toLowerCase() == 'true' ||
          mandatory?.toString() == '1',
      notes: text('release_notes'),
      urlAndroid: text('url'),
      urlIos: text('url_ios'),
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
      };

  /// The version this platform must at least be running ('' = no requirement).
  String requiredVersion({required bool isIos}) {
    final own = isIos ? versionIos : versionAndroid;
    return own.isNotEmpty ? own : version;
  }

  UpdateDecision evaluate({
    required String installedVersion,
    required int installedBuild,
    required bool isIos,
  }) {
    final required = requiredVersion(isIos: isIos);
    final minBuild = isIos ? minBuildIos : minBuildAndroid;
    final versionTooOld =
        required.isNotEmpty && isVersionOutdated(installedVersion, required);
    final buildTooOld = minBuild > 0 && installedBuild < minBuild;
    if (!versionTooOld && !buildTooOld) return UpdateDecision.none;
    return isMandatory ? UpdateDecision.mandatory : UpdateDecision.optional;
  }

  /// The store link to open: the admin's link when it is a real https URL,
  /// otherwise the verified listing baked into this app.
  String storeUrl({
    required bool isIos,
    required String fallbackIos,
    required String fallbackAndroid,
  }) {
    final own = isIos ? urlIos : urlAndroid;
    final uri = Uri.tryParse(own);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) return own;
    return isIos ? fallbackIos : fallbackAndroid;
  }
}
