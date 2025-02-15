import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/utils/lang_const.dart';

// ignore: must_be_immutable
class CustomTextFormFieldReview extends StatelessWidget {
  CustomTextFormFieldReview({
    super.key,
    required this.hint,
    required this.txtController,
    this.obscureText,
    this.readOnly,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.maxLength,
    this.onTap,
    this.style,
    this.onChanged,
    this.counterText,
    this.inputFormatters,
    this.maxLines,
  });

  FocusNode? focusNode;
  String hint;
  TextEditingController txtController;
  bool? obscureText;
  bool? readOnly;
  Widget? suffixIcon;
  Widget? prefixIcon;
  TextInputType? keyboardType;
  int? maxLength;
  Function()? onTap;
  TextStyle? style;
  Function(String)? onChanged;
  String? counterText;
  int? maxLines;
  List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // focusNode:focusNode,
      focusNode: FocusNode(),
      controller: txtController,
      obscureText: obscureText ?? false,
      readOnly: readOnly ?? false,
      onTap: onTap,
      style: style,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType ?? TextInputType.text,
      inputFormatters: inputFormatters ??
          ((keyboardType == TextInputType.phone ||
                  keyboardType == TextInputType.number)
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ]
              : keyboardType == TextInputType.emailAddress
                  ? [
                      FilteringTextInputFormatter.deny(RegExp(r"\s")),
                      // To prevent space
                      FilteringTextInputFormatter.allow(RegExp(
                          r"[a-zA-Z0-9@.!#$%&'*+/=?^_`{|}~-]+")), // To allow all valid email characters
                    ]
                  : []),
      validator: (value) {
        if (value!.isEmpty) {
          return 'requiredField';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        labelStyle: AppStyle.style12W500Black.copyWith(
          color: AppColor.mainBlack,
        ),
        hintStyle: AppStyle.style12W500Black.copyWith(
          color: AppColor.darkGrey,
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: counterText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          // تحديد نصف القطر هنا
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.10000000149011612),
            width: 2.0,
          ), // لجعل الحافة غير مرئية
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
              8.0), // تفعيل نفس نصف القطر عندما يكون غير مفعّل
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.10000000149011612),
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0), // نفس نصف القطر عند التركيز
          borderSide: BorderSide(
            color: Colors.black
                .withOpacity(0.10000000149011612), // لون الحافة عند التركيز
            width: 2.0, // سماكة الحافة عند التركيز
          ),
        ),
      ),
    );
  }
}
