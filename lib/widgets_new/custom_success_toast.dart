import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';

class CustomSuccessToastWidget extends StatelessWidget {
  const CustomSuccessToastWidget({super.key, required this.toastText});

  final String toastText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Container(
        height: 46,
        margin: EdgeInsets.only(left: 16.w),
        decoration: BoxDecoration(
          color: AppColor.success,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0.w),
            bottomLeft: Radius.circular(16.0.w),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, -2),
              color: const Color(0xFF000000).withOpacity(.12),
              spreadRadius: 0,
            ),
            BoxShadow(
              blurRadius: 5,
              offset: const Offset(0, -2),
              color: const Color(0xFF000000).withOpacity(.16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.done_outlined,
                size: 20.w,
                color: Colors.white,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: DefaultTextStyle(
                  style: AppStyle.style16W500Black.copyWith(
                    color: Colors.white,
                  ),
                  child: Text(
                    toastText,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis, // Truncate text
                    maxLines: 1, // Limit to one line
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

showCustomSuccessToast(String toastText) {
  showToastWidget(
    CustomSuccessToastWidget(toastText: toastText),
    dismissOtherToast: true,
    handleTouch: true,
    position: ToastPosition.top,
    duration: const Duration(seconds: 3),
  );
}
