import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';

class ButtonAuth extends StatelessWidget {
  const ButtonAuth({super.key, this.onTap, required this.text});
  final Function()? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50.h,
          width: 300.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(50.r)),
          child: Text(
            text,
            style: AppStyle.style16W500hepo.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
