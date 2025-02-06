// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';

class AdvText extends StatelessWidget {
  final List<TextModel> texts;
  const AdvText(this.texts, {super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
            style: AppStyle.style24W500Black,
            children: texts.map(
              (e) {
                return TextSpan(
                    text: e.text,
                    style: AppStyle.style16W500Black
                        .copyWith(color: e.primary ? AppColor.primary : null)
                    // style: TextStyle(color: e.primary ? AppColor.primary : null),
                    );
              },
            ).toList()));
  }
}

class TextModel {
  final String text;
  final bool primary;

  TextModel(
    this.text, {
    this.primary = false,
  });
}
