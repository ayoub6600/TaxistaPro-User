import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../styles/styles.dart';
import '../../../widgets/widgets.dart';

class CancellationSheet extends StatelessWidget {
  const CancellationSheet({
    super.key,
    required this.reasons,
    required this.selectedReason,
    required this.otherValue,
    required this.copy,
    required this.errorText,
    required this.onReasonSelected,
    required this.onCustomReasonChanged,
    required this.onKeepRide,
    required this.onConfirmCancellation,
  });

  final List<String> reasons;
  final String selectedReason;
  final String otherValue;
  final Map<String, dynamic> copy;
  final String errorText;
  final ValueChanged<String> onReasonSelected;
  final ValueChanged<String> onCustomReasonChanged;
  final VoidCallback onKeepRide;
  final Future<void> Function() onConfirmCancellation;

  String _text(String key) => copy[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 460.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: page,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xffEF4444).withValues(alpha: 0.10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xffEF4444),
                          size: 34,
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ...reasons.map(
                      (reason) => _ReasonTile(
                        label: reason,
                        selected: selectedReason == reason,
                        onTap: () => onReasonSelected(reason),
                      ),
                    ),
                    _ReasonTile(
                      label: _text('text_others'),
                      selected: selectedReason == otherValue,
                      onTap: () => onReasonSelected(otherValue),
                    ),
                    if (selectedReason == otherValue) ...[
                      SizedBox(height: 8.h),
                      TextField(
                        minLines: 2,
                        maxLines: 4,
                        onChanged: onCustomReasonChanged,
                        decoration: InputDecoration(
                          hintText: _text('text_cancelRideReason'),
                          filled: true,
                          fillColor: textColor.withValues(alpha: 0.035),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(color: borderLines),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(color: borderLines),
                          ),
                        ),
                      ),
                    ],
                    if (errorText.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        errorText,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: const Color(0xffDC2626),
                        ),
                      ),
                    ],
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: Button(
                            onTap: onKeepRide,
                            text: _text('tex_dontcancel'),
                            backgroundcolor: textColor.withValues(alpha: 0.08),
                            textcolor: textColor,
                            width: double.infinity,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Button(
                            onTap: onConfirmCancellation,
                            text: _text('text_cancel'),
                            backgroundcolor: const Color(0xffEF4444),
                            textcolor: Colors.white,
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
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? buttonColor : hintColor,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
