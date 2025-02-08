import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/otp_pin_field_widget.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/resend_otp_widget.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custem_header_auth.dart';

// ignore: must_be_immutable
class VerifactionViewBody extends StatefulWidget {
  VerifactionViewBody({
    super.key,
    required this.phone,
  });
  final String phone;
  //final Map<String, dynamic> data;
  bool? isForgetPass;

  @override
  State<VerifactionViewBody> createState() => _VerifactionViewBodyState();
}

class _VerifactionViewBodyState extends State<VerifactionViewBody> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController otpController = TextEditingController();

  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();

  @override
  void dispose() {
    otpController.dispose();
    _otpPinFieldController.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              HeightSpace(30.h),
              CustmheaderAuth(
                title:
                    getTranslated(context, LangConst.verification).toString(),
                subtitle: getTranslated(
                        context, LangConst.enterTheVerificationCodeBelow)
                    .toString(),
              ),
              Padding(
                padding: EdgeInsets.all(20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        widget.phone,
                        style: AppStyle.style18W500Black,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const HeightSpace(36),
                    OtpPinFieldWidget(
                      otpPinFieldController: _otpPinFieldController,
                      onChange: (p0) => otpController.text = p0,
                      onSubmit: (p0) => otpController.text = p0,
                    ),
                    const HeightSpace(36),
                    ButtonAuth(
                      text: getTranslated(context, LangConst.textverify)
                          .toString(),
                      onTap: () {
                        GoRouter.of(context).push(RoutesKeys.kNewPassword);
                      },
                    ),
                    const HeightSpace(36),

                    ResendOtpWidget(
                        //data: widget.data,
                        ),
                    const HeightSpace(30),

                    // CustemButtomAuth(
                    //   title: getTranslated(context, LangConst.verify)
                    //       .toString(),
                    //   onTap: () {
                    //     if (_formKey.currentState!.validate()) {
                    //       _formKey.currentState!.save();
                    //       Map<String, dynamic> body = {
                    //         "phone_no": widget.data['phone_no'],
                    //         "otp": otpController.text,
                    //         "type": widget.data['type'],
                    //         // "type": 2,
                    //       };

                    //       bool isForgetPass =
                    //           widget.data['isForgetPass'] == true;

                    //       if (isForgetPass) {
                    //         // context
                    //         //     .read<SendOtpCubit>()
                    //         //     .callForgotValid(body);
                    //       } else {
                    //        // context.read<SendOtpCubit>().verifyMe(body);
                    //       }
                    //     }
                    //   },
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
