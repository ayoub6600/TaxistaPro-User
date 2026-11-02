import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'update_checker.dart';
import 'update_policy.dart';

/// Remembers, across restarts, that a ride was in progress: a mandatory update must not stop a
/// driver or a rider from finishing it, and the startup check runs before the ride is loaded.
class RideInProgress {
  static const _key = 'ride_in_progress_at';
  static bool? _last;

  /// Called by the home screen whenever it rebuilds; writes only when the answer changes.
  static void observe(bool active) {
    if (_last == active) return;
    _last = active;
    SharedPreferences.getInstance().then((p) => active
        ? p.setInt(_key, DateTime.now().millisecondsSinceEpoch)
        : p.remove(_key)).catchError((_) => false);
  }

  /// A ride was in progress when the app last ran (within the last 6 hours).
  static Future<bool> recently({Duration window = const Duration(hours: 6)}) async {
    try {
      final at = (await SharedPreferences.getInstance()).getInt(_key);
      return at != null && DateTime.now().millisecondsSinceEpoch - at < window.inMilliseconds;
    } catch (_) {
      return false;
    }
  }
}

/// The update found at startup that waits for the home screen: an optional one, or a mandatory
/// one held back while a ride was in progress. The home screen calls [maybeShow].
class UpdateOffer {
  static UpdateCheckResult? pending;
  static bool _showing = false;
  static const _snoozeKey = 'update_offer_snoozed';

  /// Android: was this copy installed by Google Play? (an APK from elsewhere cannot be updated
  /// by Play when it was signed differently - the user is told how to get out of that).
  static Future<bool> installedOutsideStore() async {
    if (!Platform.isAndroid) return false;
    try {
      final store = (await PackageInfo.fromPlatform()).installerStore;
      return store != 'com.android.vending';
    } catch (_) {
      return false;
    }
  }

  /// Shows the pending update once the home screen is up and no ride is in progress. An optional
  /// one comes back at most once a day per version; a mandatory one opens [mandatoryPage].
  static Future<void> maybeShow(
    BuildContext context, {
    required bool rideActive,
    required String languageCode,
    required Future<bool> Function(UpdatePolicy? policy) openStore,
    required Widget Function(UpdateCheckResult result) mandatoryPage,
  }) async {
    final result = pending;
    if (result == null || rideActive || _showing || !context.mounted) return;
    if (result.decision == UpdateDecision.mandatory) {
      pending = null;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => mandatoryPage(result)), (_) => false);
      return;
    }
    final isIos = Platform.isIOS;
    final live = result.policy?.platform(isIos: isIos);
    final stamp = '${live?.liveVersion ?? result.policy?.requiredVersion(isIos: isIos)}+${live?.liveBuild ?? 0}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozed = prefs.getString(_snoozeKey)?.split('|');
      if (snoozed != null &&
          snoozed.length == 2 &&
          snoozed[0] == stamp &&
          DateTime.now().millisecondsSinceEpoch - (int.tryParse(snoozed[1]) ?? 0) < const Duration(hours: 24).inMilliseconds) {
        pending = null;
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    _showing = true;
    pending = null;
    final outside = await installedOutsideStore();
    if (!context.mounted) {
      _showing = false;
      return;
    }
    final later = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateOfferSheet(
        languageCode: languageCode,
        message: result.policy?.message(isIos: isIos, languageCode: languageCode) ?? '',
        version: live?.liveVersion ?? '',
        installedOutsideStore: outside,
        isIos: isIos,
        onUpdate: () => openStore(result.policy),
      ),
    );
    _showing = false;
    if (later != false) {
      try {
        (await SharedPreferences.getInstance()).setString(_snoozeKey, '$stamp|${DateTime.now().millisecondsSinceEpoch}');
      } catch (_) {}
    }
  }
}

/// «تحديث جديد لتاكسيستا»: a light sheet over the home screen, never during a ride.
class UpdateOfferSheet extends StatefulWidget {
  const UpdateOfferSheet({
    super.key,
    required this.languageCode,
    required this.message,
    required this.version,
    required this.installedOutsideStore,
    required this.isIos,
    required this.onUpdate,
  });

  final String languageCode;
  final String message;
  final String version;
  final bool installedOutsideStore;
  final bool isIos;
  final Future<bool> Function() onUpdate;

  @override
  State<UpdateOfferSheet> createState() => _UpdateOfferSheetState();
}

class _UpdateOfferSheetState extends State<UpdateOfferSheet> {
  static const _accent = Color(0xFF0873FF);
  bool _failed = false;
  bool _opening = false;

  bool get _ar => widget.languageCode != 'en';
  String _t(String ar, String en) => _ar ? ar : en;

  Future<void> _update() async {
    if (_opening) return;
    setState(() => _opening = true);
    final opened = await widget.onUpdate();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _failed = !opened;
    });
    if (opened) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF111827) : Colors.white;
    final ink = dark ? Colors.white : const Color(0xFF0F172A);
    final sub = ink.withValues(alpha: 0.62);
    final message = widget.message.isNotEmpty
        ? widget.message
        : _t('حسّنّا المكالمات والخرائط وأداء التطبيق لتجربة أسرع وأسهل.',
            'We improved calls, maps and performance for a faster, easier ride.');
    return Directionality(
      textDirection: _ar ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: ink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_accent, Color.lerp(_accent, const Color(0xFF17C3E8), 0.6)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 14),
            Text(_t('تحديث جديد لتاكسيستا', 'A new Taxista update'),
                key: const ValueKey('update_offer_title'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink, height: 1.3)),
            if (widget.version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_t('الإصدار ${widget.version}', 'Version ${widget.version}'),
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: sub)),
              ),
            const SizedBox(height: 10),
            Text(message,
                key: const ValueKey('update_offer_message'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: sub, height: 1.55)),
            if (widget.installedOutsideStore) ...[
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('update_offer_sideload'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _t('هذه النسخة لم تُثبَّت من Google Play. إن لم يكتمل التحديث من المتجر، احذف التطبيق ثم ثبّته من Google Play، أو اطلب النسخة الجديدة من فريق تاكسيستا.',
                      'This copy was not installed from Google Play. If the store cannot update it, uninstall the app and install it from Google Play, or ask the Taxista team for the new version.'),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('update_offer_now'),
                style: FilledButton.styleFrom(backgroundColor: _accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _opening ? null : _update,
                child: _opening
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(_t('تحديث الآن', 'Update now'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    _t('تعذّر فتح ${widget.isIos ? 'App Store' : 'Google Play'}. افتح المتجر وابحث عن تاكسيستا.',
                        'Could not open ${widget.isIos ? 'the App Store' : 'Google Play'}. Open the store and search for Taxista.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB3261E))),
              ),
            TextButton(
              key: const ValueKey('update_offer_later'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_t('لاحقًا', 'Later'), style: TextStyle(fontSize: 14.5, color: sub)),
            ),
          ]),
        ),
      ),
    );
  }
}
