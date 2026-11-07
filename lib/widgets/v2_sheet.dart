import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../functions/functions.dart';
import '../styles/styles.dart';

/// Design v2: the frame every bottom sheet shares — handle, title and a short line, the content, and
/// one primary button. Light and dark follow the app's `page` / `textColor`.
class V2SheetFrame extends StatelessWidget {
  const V2SheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.primaryLabel,
    this.onPrimary,
    this.primaryBusy = false,
    this.maxHeightFactor = .82,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryBusy;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final rtl = languageDirection == 'rtl';
    final media = MediaQuery.of(context);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * maxHeightFactor),
        decoration: BoxDecoration(
          color: page,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(18, 10, 18, 14 + media.viewPadding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(width: 42, height: 5, decoration: BoxDecoration(color: textColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 14),
          Row(children: [
            if (icon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xff0873FF).withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: const Color(0xff0873FF), size: 23),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.cairo(color: textColor, fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .55), fontSize: 13, height: 1.4)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Flexible(child: SingleChildScrollView(child: child)),
          if (primaryLabel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: primaryBusy ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff0873FF),
                  disabledBackgroundColor: const Color(0xff0873FF).withValues(alpha: .4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: primaryBusy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(primaryLabel!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// One selectable line in a v2 sheet: icon tile, title and a short note, and a check when chosen.
class V2OptionRow extends StatelessWidget {
  const V2OptionRow({
    super.key,
    required this.title,
    this.note,
    this.icon,
    this.leading,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  final String title;
  final String? note;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xff0873FF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: Material(
          color: selected ? blue.withValues(alpha: .07) : (isDarkTheme ? const Color(0xff171B22) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? blue : textColor.withValues(alpha: .08), width: selected ? 1.6 : 1),
              ),
              child: Row(children: [
                leading ??
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: blue.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon ?? Icons.circle_outlined, color: blue, size: 23),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: GoogleFonts.cairo(color: textColor, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.3)),
                    if (note != null && note!.isNotEmpty)
                      Text(note!, style: GoogleFonts.cairo(color: textColor.withValues(alpha: .55), fontSize: 12.5, height: 1.35)),
                  ]),
                ),
                trailing ??
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? blue : Colors.transparent,
                        border: Border.all(color: selected ? blue : textColor.withValues(alpha: .25), width: 2),
                      ),
                      child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                    ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
