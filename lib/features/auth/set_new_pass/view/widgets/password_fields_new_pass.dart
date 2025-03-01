import 'package:flutter/material.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';

class PasswordFieldsNewPass extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isObscureText;
  final bool isObscureConfirmText;
  final VoidCallback toggleObscureText;
  final VoidCallback toggleObscureConfirmText;

  const PasswordFieldsNewPass({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isObscureText,
    required this.isObscureConfirmText,
    required this.toggleObscureText,
    required this.toggleObscureConfirmText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, LangConst.newPassword).toString(),
          style: AppStyle.style16W500Black,
        ),
        const HeightSpace(6),
        NewCustomTextFormField(
          txtController: passwordController,
          hint: "**********",
          obscureText: isObscureText,
          suffixIcon: InkWell(
            onTap: toggleObscureText,
            child: Icon(
              isObscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
        const HeightSpace(20),
        Text(
          getTranslated(context, LangConst.confirmPassword).toString(),
          style: AppStyle.style16W500Black,
        ),
        const HeightSpace(6),
        NewCustomTextFormField(
          txtController: confirmPasswordController,
          hint: "**********",
          obscureText: isObscureConfirmText,
          suffixIcon: InkWell(
            onTap: toggleObscureConfirmText,
            child: Icon(
              isObscureConfirmText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
      ],
    );
  }
}
