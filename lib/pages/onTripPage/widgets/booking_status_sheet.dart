import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

/// A single, responsive presentation for recoverable booking states.
class BookingStatusSheet extends StatelessWidget {
  const BookingStatusSheet({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.info_outline_rounded,
    this.assetName,
    this.accentColor = const Color(0xffEF4444),
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String actionLabel;
  final Future<void> Function() onAction;
  final IconData icon;
  final String? assetName;
  final Color accentColor;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 18.h),
            decoration: BoxDecoration(
              color: page,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: 68.w,
                  height: 68.w,
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.10),
                  ),
                  child: assetName == null
                      ? Icon(icon, color: accentColor, size: 34.w)
                      : Image.asset(assetName!, fit: BoxFit.contain),
                ),
                SizedBox(height: 16.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.82),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 17.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                if (secondaryActionLabel == null)
                  Button(
                    onTap: onAction,
                    text: actionLabel,
                    width: double.infinity,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondaryAction,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(48.h),
                          ),
                          child: Text(secondaryActionLabel!),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Button(
                          onTap: onAction,
                          text: actionLabel,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
