import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';

class ChooseGender extends StatefulWidget {
  final ValueChanged<String> onGenderSelected;

  const ChooseGender({super.key, required this.onGenderSelected});

  @override
  _ChooseGenderState createState() => _ChooseGenderState();
}

class _ChooseGenderState extends State<ChooseGender> {
  String selectedGender = 'male'; // Default gender selection

  void _selectGender(String value) {
    setState(() {
      selectedGender = value;
    });
    widget.onGenderSelected(value);
  }

  Widget _buildGenderOption(String key, String value) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectGender(value),
        child: Row(
          children: [
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 1.2, color: Colors.black),
              ),
              alignment: Alignment.center,
              child: (selectedGender == value)
                  ? Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.primary,
                      ),
                    )
                  : null,
            ),
            WidthSpace(10.w),
            GestureDetector(
              onTap: () => _selectGender(value),
              child: Text(
                getTranslated(context, key), // Localized text
                style: AppStyle.style16W500hepo,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildGenderOption('male', 'male'),
        _buildGenderOption('female', 'female'),
      ],
    );
  }
}
