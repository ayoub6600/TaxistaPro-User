import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/forgot_password/view/widgets/forget_password_view_body.dart';

import 'package:taxista/utils/lang_const.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ForgotPasswordViewBody(),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.center,
          child: RichText(
              text: TextSpan(
                  text: getTranslated(context, LangConst.rememberYourPassword),
                  style: AppStyle.style16W500Black,
                  children: [
                TextSpan(
                  text: getTranslated(context, LangConst.textLogin).toString(),
                  style: AppStyle.style16W500Black.copyWith(
                    color: AppColor.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.of(context).pop();
                    },
                )
              ])),
        ),
        const HeightSpace(15),
      ]),
    );
  }
}
