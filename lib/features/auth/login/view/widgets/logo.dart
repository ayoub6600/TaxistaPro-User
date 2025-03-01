import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/assets.dart';

class LogoWidgets extends StatelessWidget {
  const LogoWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 50.w,
        height: 50.h,
        decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage(Assets.assetsImagesLogo))),
      ),
    );
  }
}
