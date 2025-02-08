import 'package:flutter/material.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';

class PhoneFormLForgotpaassword extends StatelessWidget {
  const PhoneFormLForgotpaassword(
      {super.key, required this.phoneNumberController});
  final TextEditingController phoneNumberController;
  @override
  Widget build(BuildContext context) {
    //   final sendOtpCubit = context.read<SendOtpCubit>();
    return Row(
      children: [
        Expanded(
          child: NewCustomTextFormField(
            hint: getTranslated(context, LangConst.textPhoneNumber),
            txtController: phoneNumberController,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}
