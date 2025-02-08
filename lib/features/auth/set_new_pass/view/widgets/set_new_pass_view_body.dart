import 'package:flutter/material.dart';

import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/features/auth/set_new_pass/view/widgets/password_fields_new_pass.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custem_header_auth.dart';

class SetNewPassViewBody extends StatelessWidget {
  SetNewPassViewBody({
    super.key,
  });
  // final Map<String, dynamic>? data;
  final formKey = GlobalKey<FormState>();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // const CustomAppBar(
            //   showBack: true,
            //   titleColor: Colors.black,
            //   appBarTitle: "",
            // ),
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CustmheaderAuth(
                      title: getTranslated(context, LangConst.setPassword)
                          .toString(),
                      subtitle: getTranslated(
                              context, LangConst.enterTheVerificationCodeBelow)
                          .toString(),
                    ),
                    const HeightSpace(30),
                    PasswordFieldsNewPass(
                      passwordController: TextEditingController(),
                      confirmPasswordController: confirmPasswordController,
                      isObscureText: true,
                      isObscureConfirmText: true,
                      toggleObscureText: () {
                        // context
                        //     .read<NewPassWordCubit>()
                        //     .togglePasswordVisibility();
                      },
                      toggleObscureConfirmText: () {
                        // context
                        //     .read<NewPassWordCubit>()
                        //     .toggleConfirmPasswordVisibility();
                      },
                    ),
                    const HeightSpace(30),
                    ButtonAuth(
                      text: getTranslated(context, LangConst.updatePassword)
                          .toString(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
