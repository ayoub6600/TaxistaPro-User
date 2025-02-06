import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/login/manager/login_cubit.dart';
import 'package:taxista/features/auth/login/manager/login_state.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';

class LoginScreenViewBody extends StatefulWidget {
  const LoginScreenViewBody({super.key});

  @override
  State<LoginScreenViewBody> createState() => _LoginScreenViewBodyState();
}

class _LoginScreenViewBodyState extends State<LoginScreenViewBody> {
  @override
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        switch (state.loginStatus) {
          case LoginStatus.initial:
            break;
          case LoginStatus.submitting:
            customLoadingDialog(context);
            break;
          case LoginStatus.error:
            Navigator.pop(context);

            showCustomErrorToast(state.failure.errMessage);
            break;
          case LoginStatus.success:
            {
              Navigator.pop(context);
              GoRouter.of(context).go(RoutesKeys.kHome);
              //  showCustomSuccessToast(state.modelData?.msg.toString() ?? "");
            }
            break;
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeightSpace(50.h),
                    Center(
                      child: Text(
                        getTranslated(context, LangConst.textLogin),
                        style: AppStyle.style24W500Black,
                      ),
                    ),
                    HeightSpace(20.h),
                    Center(
                      child: Text(
                        getTranslated(context, LangConst.textHello),
                        style: AppStyle.style15W500Black
                            .copyWith(color: AppColor.darkGrey),
                      ),
                    ),
                    HeightSpace(50.h),
                    Text(
                      getTranslated(context, LangConst.textEmailMobile),
                      style: AppStyle.style15W500Black,
                    ),
                    HeightSpace(10.h),
                    NewCustomTextFormField(
                      txtController: state.phoneController,
                      hint: getTranslated(context, LangConst.textEmailMobile),
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      enabled: true,
                      readOnly: false,
                      onTap: () {},
                    ),
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.password),
                      style: AppStyle.style15W500Black,
                    ),
                    HeightSpace(10.h),
                    NewCustomTextFormField(
                      txtController: state.passwordController,
                      hint: getTranslated(context, LangConst.textEnterPassword),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: state.isObscureText,
                      enabled: true,
                      readOnly: false,
                      onTap: () {},
                      suffixIcon: InkWell(
                        onTap: () {
                          context.read<LoginCubit>().togglePasswordVisibility();
                        },
                        child: Icon(
                          state.isObscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    HeightSpace(10.h),
                    Row(children: [
                      Text(
                        getTranslated(context, LangConst.textForgoPassword),
                        style: AppStyle.style15W500Black.copyWith(
                          color: AppColor.primary,
                        ),
                      ),
                    ]),
                    HeightSpace(50.h),
                    ButtonAuth(
                      onTap: () {
                        if (state.phoneController.text.isEmpty) {
                          showCustomErrorToast(getTranslated(
                              context, LangConst.textEmailMobile));
                        } else if (state.passwordController.text.isEmpty) {
                          showCustomErrorToast(getTranslated(
                              context, LangConst.textEnterPassword));
                        } else {
                          context.read<LoginCubit>().loginMethod();
                        }
                      },
                      text: getTranslated(context, LangConst.textLogin),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RichText(
                    text: TextSpan(
                      text: getTranslated(context, LangConst.dontHaveAccount)
                          .toString(),
                      style: AppStyle.style16W500Black,
                      children: [
                        TextSpan(
                          text: getTranslated(context, LangConst.textSignUp)
                              .toString(),
                          style: AppStyle.style16W500Black
                              .copyWith(color: AppColor.primary),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              GoRouter.of(context).push(RoutesKeys.kRegister);
                            },
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
