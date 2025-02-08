import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomCircularIcon extends StatelessWidget {
  const CustomCircularIcon({super.key, this.icon, this.onTap, this.padding});

  final Widget? icon;
  final Function()? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.pop(context),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  width: 1.01,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              child: Center(child: icon ?? const Icon(Icons.arrow_back)),
            ),
          ],
        ),
      ),
    );
  }
}
