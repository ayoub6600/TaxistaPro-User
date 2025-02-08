import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/text_style.dart';
import 'custom_circular_icon.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
    required this.appBarTitle,
    this.endIcon,
    this.onEndIconTap,
    this.padding,
    this.showBack = true,
    this.titleColor,
  });

  final String appBarTitle;
  final Widget? endIcon;
  final Function()? onEndIconTap;
  final EdgeInsets? padding;
  final bool showBack;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
      child: Stack(
        children: [
          if (showBack) const CustomCircularIcon(),
          SizedBox(
            height: 50.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(appBarTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.style16W500Black.copyWith(
                      color: titleColor ?? const Color(0xFF242424),
                    )),
              ],
            ),
          ),
          if (endIcon != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomCircularIcon(
                  icon: endIcon,
                  onTap: onEndIconTap,
                )
              ],
            ),
        ],
      ),
    );
  }
}
