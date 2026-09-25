import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'forced_update_page.dart';
import 'update_checker.dart';
import 'update_policy.dart';

/// Rider app identity for the update gate. These are the ONLY places this
/// app touches update configuration: its own Firebase node and its own store
/// listings. The Driver app has its own, so a change to one never affects the
/// other.
const String riderUpdateNode = 'force_update_user';
const String riderAppName = 'تاكسيستا';
// Verified with the App Store: com.taxistapro.user -> id6739538467.
const String riderAppStoreFallback = 'https://apps.apple.com/app/id6739538467';
const String riderPlayStoreFallback =
    'https://play.google.com/store/apps/details?id=com.ayoub.usertaxista';
const String _cacheKey = 'update_policy_user';

UpdateChecker buildRiderUpdateChecker() => UpdateChecker(
      fetch: () async {
        final snapshot =
            await FirebaseDatabase.instance.ref().child(riderUpdateNode).get();
        final value = snapshot.value;
        return snapshot.exists && value is Map ? value : null;
      },
      readCache: () async =>
          (await SharedPreferences.getInstance()).getString(_cacheKey),
      writeCache: (json) async =>
          (await SharedPreferences.getInstance()).setString(_cacheKey, json),
    );

/// Runs the check and returns the decision plus the policy. Never throws.
Future<UpdateCheckResult> checkRiderUpdate({UpdateChecker? checker}) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return await (checker ?? buildRiderUpdateChecker()).check(
      installedVersion: info.version,
      installedBuild: int.tryParse(info.buildNumber) ?? 0,
      isIos: Platform.isIOS,
    );
  } catch (_) {
    return const UpdateCheckResult(UpdateDecision.none, null, UpdateSource.none);
  }
}

String updateLanguage(String chosenLanguage) {
  if (chosenLanguage == 'ar' || chosenLanguage == 'en') return chosenLanguage;
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'en'
      ? 'en'
      : 'ar';
}

/// Opens the store listing; false when it could not be opened.
Future<bool> openRiderStore(UpdatePolicy? policy) async {
  final target = (policy ?? const UpdatePolicy()).storeUrl(
    isIos: Platform.isIOS,
    fallbackIos: riderAppStoreFallback,
    fallbackAndroid: riderPlayStoreFallback,
  );
  try {
    return await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The update screen with its "open the store" wiring. Shown once, as a
/// replacement for the whole stack (mandatory) or on top of the loading page
/// (optional).
class RiderUpdateScreen extends StatefulWidget {
  const RiderUpdateScreen({
    super.key,
    required this.result,
    required this.chosenLanguage,
    this.onLater,
  });

  final UpdateCheckResult result;
  final String chosenLanguage;
  final VoidCallback? onLater;

  @override
  State<RiderUpdateScreen> createState() => _RiderUpdateScreenState();
}

class _RiderUpdateScreenState extends State<RiderUpdateScreen> {
  bool _failed = false;
  bool _opening = false;

  Future<void> _update() async {
    if (_opening) return; // one tap, one attempt
    _opening = true;
    final opened = await openRiderStore(widget.result.policy);
    _opening = false;
    if (mounted) setState(() => _failed = !opened);
  }

  @override
  Widget build(BuildContext context) => ForcedUpdatePage(
        appName: riderAppName,
        languageCode: updateLanguage(widget.chosenLanguage),
        mandatory: widget.result.decision == UpdateDecision.mandatory,
        notes: widget.result.policy?.notes ?? '',
        onUpdate: _update,
        onLater: widget.onLater,
        updateFailed: _failed,
      );
}
