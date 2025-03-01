import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_cubit.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_state.dart';
import 'package:taxista/features/auth/login/view/widgets/logo.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/otp_pin_field_widget.dart';
import 'package:taxista/features/auth/verifaction/view/widgets/resend_otp_widget.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custem_header_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';

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
      child: BlocConsumer<VerifyUserCubit, VerifyUserState>(
        listener: (context, state) {
          switch (state.callForgotValidStates) {
            case CallForgotValidStates.initial:
              break;
            case CallForgotValidStates.submitting:
              customLoadingDialog(context);
              break;
            case CallForgotValidStates.error:
              Navigator.pop(context);

              showCustomErrorToast(state.failure.errMessage);
              break;
            case CallForgotValidStates.success:
              {
                Navigator.pop(context);
                GoRouter.of(context).push(
                  RoutesKeys.kNewPassword,
                  extra: widget.phone,
                );
              }
              break;
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const CustomAppBar(
                    showBack: true,
                    titleColor: Colors.black,
                    appBarTitle: "",
                  ),
                  HeightSpace(30.h),
                  const LogoWidgets(),
                  const HeightSpace(20),
                  CustmheaderAuth(
                    title: getTranslated(context, LangConst.verification)
                        .toString(),
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
                            if (_formKey.currentState!.validate()) {
                              GoRouter.of(context).push(RoutesKeys.kNewPassword,
                                  extra: widget.phone);
                              // context.read<VerifyUserCubit>().callForgot(
                              //       mobile: widget.phone,
                              //       otp: otpController.text,
                              //     );
                            }
                          },
                        ),
                        const HeightSpace(36),
                        ResendOtpWidget(
                          phone: widget.phone,
                        ),
                        const HeightSpace(30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
