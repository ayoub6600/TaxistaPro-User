import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/utils/lang_const.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget(
      {super.key,
      this.refresh,
      this.title,
      required this.subTitle,
      this.image});

  final void Function()? refresh;
  final String? title;
  final String subTitle;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (image != null)
            Image.asset(
              image ?? '',
              height: 200.h,
              width: 200.w,
            ),
          Text(
            '${title ?? getTranslated(context, LangConst.textNoDataFound)} !',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.style24W500Black.copyWith(
              color: AppColor.darkGrey,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            subTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.style14W500Black.copyWith(
              color: AppColor.darkGrey,
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
