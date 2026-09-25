import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The single, dedicated screen shown when the installed app is below the
/// backend's minimum version. A normal full-screen page (not a dialog over a
/// barrier), so it always renders immediately, is fully visible, and cannot
/// leave an invisible touch-blocking layer behind. Its text is built in and
/// independent of the app's language tables, which are not loaded yet at
/// startup (that ordering was what used to break the old dialog).
///
/// [mandatory]: there is no "later" and Back is blocked. Optional updates get
/// a "Later" button that calls [onLater].
class ForcedUpdatePage extends StatelessWidget {
  const ForcedUpdatePage({
    super.key,
    required this.appName,
    required this.languageCode,
    required this.mandatory,
    required this.onUpdate,
    this.notes = '',
    this.onLater,
    this.updateFailed = false,
    this.accent = const Color(0xFF1A73E8),
  });

  /// e.g. "تاكسيستا" / "تاكسيستامان".
  final String appName;
  final String languageCode;
  final bool mandatory;
  final String notes;

  /// Opens the store listing. The page never decides the URL itself.
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  /// Show the "could not open the store" hint under the button.
  final bool updateFailed;
  final Color accent;

  bool get _arabic => languageCode != 'en';

  String get _title => _arabic
      ? 'يتوفر تحديث جديد لـ$appName'
      : 'A new update is available for $appName';
  String get _body => _arabic
      ? 'يجب تحديث التطبيق للاستمرار والاستفادة من آخر التحسينات.'
      : 'Please update the app to continue and get the latest improvements.';
  String get _optionalBody => _arabic
      ? 'يتوفر إصدار أحدث من التطبيق مع آخر التحسينات.'
      : 'A newer version of the app with the latest improvements is available.';
  String get _updateNow => _arabic ? 'تحديث الآن' : 'Update now';
  String get _later => _arabic ? 'لاحقًا' : 'Later';
  String get _openFailed => _arabic
      ? 'تعذّر فتح المتجر. افتح متجر التطبيقات وابحث عن التطبيق لتحديثه.'
      : 'Could not open the store. Open the App Store and search for the app to update it.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !mandatory,
      child: Directionality(
        textDirection: _arabic ? TextDirection.rtl : TextDirection.ltr,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.system_update_rounded,
                              size: 46, color: accent),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          _title,
                          key: const ValueKey('update_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mandatory ? _body : _optionalBody,
                          key: const ValueKey('update_body'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5F6368),
                            height: 1.55,
                          ),
                        ),
                        if (notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            notes.trim(),
                            key: const ValueKey('update_notes'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF80868B),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            key: const ValueKey('update_now'),
                            onPressed: onUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _updateNow,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (!mandatory && onLater != null) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            key: const ValueKey('update_later'),
                            onPressed: onLater,
                            child: Text(_later,
                                style: TextStyle(
                                    fontSize: 15, color: scheme.onSurfaceVariant)),
                          ),
                        ],
                        if (updateFailed) ...[
                          const SizedBox(height: 14),
                          Text(
                            _openFailed,
                            key: const ValueKey('update_failed'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFB3261E), height: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
