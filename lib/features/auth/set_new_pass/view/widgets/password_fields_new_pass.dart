import 'package:flutter/material.dart';
import 'package:taxista/constants/spaces.dart';
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
        // LadelText(
        //   ladelText: getTranslated(context, LangConst.password).toString(),
        // ),
        // const HeightBox(6),
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
        const HeightSpace(18),
        // LadelText(
        //   ladelText:
        //       getTranslated(context, LangConst.confirmPassword).toString(),
        // ),
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
