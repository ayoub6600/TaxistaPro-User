import 'package:flutter/cupertino.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';

class CustmheaderAuth extends StatelessWidget {
  const CustmheaderAuth({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppStyle.style24W500Black,
        ),
        const HeightSpace(5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 3,
          style: AppStyle.style16W500Black.copyWith(
            color: AppColor.mainBlack,
          ),
        ),
      ],
    );
  }
}
