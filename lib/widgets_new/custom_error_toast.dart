import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:taxista/constants/text_style.dart';

class CustomErrorToastWidget extends StatelessWidget {
  const CustomErrorToastWidget({super.key, required this.toastText});

  final String toastText;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Container(
      margin: EdgeInsets.only(left: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFD72F5A),
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
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20.w,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 4.w,
                ),
                SizedBox(
                  width: 300.w,
                  child: DefaultTextStyle(
                    style:
                        AppStyle.style16W500Black.copyWith(color: Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        toastText,
                        textDirection: TextDirection.rtl,
                        // textDirection: currentLocale == 'ar'
                        //     ? ui.TextDirection.rtl
                        //     : ui.TextDirection.ltr,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

showCustomErrorToast(String toastText) {
  showToastWidget(
    CustomErrorToastWidget(toastText: toastText),
    dismissOtherToast: true,
    handleTouch: true,
    position: ToastPosition.top,
    duration: const Duration(seconds: 3),
  );
}
