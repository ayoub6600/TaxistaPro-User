import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';

class SectionItem extends StatelessWidget {
  const SectionItem(
      {super.key,
      required this.sectionTitle,
      required this.isSelected,
      required this.onTap});

  final String sectionTitle;
  final Function() onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(
              sectionTitle,
              style: AppStyle.style14W500Black.copyWith(
                color: isSelected ? AppColor.primary : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 80.w,
            height: 4.h,
            decoration: isSelected
                ? ShapeDecoration(
                    color: AppColor.primary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  )
                : null,
          )
        ],
      ),
    );
  }
}
