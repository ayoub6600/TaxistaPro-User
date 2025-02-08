import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_cubit.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_state.dart';
import 'package:taxista/features/auth/forgot_password/view/widgets/for_got_password_phone.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custem_header_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';

class ForgotPasswordViewBody extends StatelessWidget {
  ForgotPasswordViewBody({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerifyUserCubit, VerifyUserState>(
      listener: (context, state) {
        switch (state.verifyUserStates) {
          case VerifyUserStates.initial:
            break;
          case VerifyUserStates.submitting:
            customLoadingDialog(context);
            break;
          case VerifyUserStates.error:
            Navigator.pop(context);

            showCustomErrorToast(state.failure.errMessage);
            break;
          case VerifyUserStates.success:
            {
              Navigator.pop(context);
              if (state.modelData?.success == true) {
                GoRouter.of(context).push(RoutesKeys.kOtpVerification,
                    extra: state.phoneController.text);
              }

              //  showCustomSuccessToast(state.modelData?.msg.toString() ?? "");
            }
            break;
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CustomAppBar(
                  showBack: true,
                  titleColor: Colors.black,
                  appBarTitle: "",
                ),
                Padding(
                  padding: EdgeInsets.all(24.0.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustmheaderAuth(
                        title: getTranslated(context, LangConst.forgotPassword),
                        subtitle: getTranslated(
                            context, LangConst.enterYourRegisteredPhoneNumber),
                      ),
                      const HeightSpace(70),
                      Text(
                        getTranslated(context, LangConst.textPhoneNumber)
                            .toString(),
                        style: AppStyle.style15W500Black,
                      ),
                      const HeightSpace(8),
                      PhoneFormLForgotpaassword(
                        phoneNumberController: state.phoneController,
                      ),
                      const HeightSpace(60),
                      ButtonAuth(
                        text: getTranslated(context, LangConst.textResendCode)
                            .toString(),
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<VerifyUserCubit>().verifyUser();
                          }
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
