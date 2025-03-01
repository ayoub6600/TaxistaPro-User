import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/login/manager/login_cubit.dart';
import 'package:taxista/features/auth/login/manager/login_state.dart';
import 'package:taxista/features/auth/login/view/widgets/logo.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class LoginScreenViewBody extends StatefulWidget {
  const LoginScreenViewBody({super.key});

  @override
  State<LoginScreenViewBody> createState() => _LoginScreenViewBodyState();
}

class _LoginScreenViewBodyState extends State<LoginScreenViewBody> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeightSpace(40.h),
                    const LogoWidgets(),
                    _buildHeader(context),
                    _buildLoginForm(context, state),
                    HeightSpace(2.h),
                    _buildForgotPassword(context),
                    HeightSpace(50.h),
                    _buildLoginButton(context, state),
                  ],
                ),
                _buildSignUpText(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, LoginState state) {
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
        Navigator.pop(context);
        showCustomSuccessToast(getTranslated(context, LangConst.textHello));
        GoRouter.of(context).go(RoutesKeys.kCurrentLocation);
        break;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        HeightSpace(50.h),
        Center(
          child: Text(
            getTranslated(context, LangConst.textLogin),
            style: AppStyle.style24W500Black,
          ),
        ),
        HeightSpace(8.h),
        Center(
          child: Text(
            getTranslated(context, LangConst.textHello),
            style: AppStyle.style15W500Black.copyWith(color: AppColor.darkGrey),
          ),
        ),
        HeightSpace(50.h),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          context,
          label: LangConst.textPhoneNumber,
          controller: state.phoneController,
          hint: LangConst.textPhoneNumber,
          keyboardType: TextInputType.phone,
        ),
        HeightSpace(20.h),
        _buildTextField(
          context,
          label: LangConst.password,
          controller: state.passwordController,
          hint: LangConst.textEnterPassword,
          keyboardType: TextInputType.visiblePassword,
          obscureText: state.isObscureText,
          suffixIcon: _buildPasswordVisibilityToggle(context, state),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, label),
          style: AppStyle.style15W500Black,
        ),
        HeightSpace(10.h),
        NewCustomTextFormField(
          txtController: controller,
          hint: getTranslated(context, hint),
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: true,
          readOnly: false,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }

  Widget _buildPasswordVisibilityToggle(
      BuildContext context, LoginState state) {
    return InkWell(
      onTap: () => context.read<LoginCubit>().togglePasswordVisibility(),
      child: Icon(
        state.isObscureText
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => GoRouter.of(context).push(RoutesKeys.kForgot),
        child: Text(
          getTranslated(context, LangConst.textForgoPassword),
          style: AppStyle.style15W500Black.copyWith(color: AppColor.primary),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginState state) {
    return ButtonAuth(
      onTap: () {
        if (state.phoneController.text.isEmpty) {
          showCustomErrorToast(
              getTranslated(context, LangConst.textPhoneNumber));
        } else if (state.passwordController.text.isEmpty) {
          showCustomErrorToast(
              getTranslated(context, LangConst.textEnterPassword));
        } else {
          context.read<LoginCubit>().loginMethod();
        }
      },
      text: getTranslated(context, LangConst.textLogin),
    );
  }

  Widget _buildSignUpText(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: RichText(
        text: TextSpan(
          text: getTranslated(context, LangConst.dontHaveAccount),
          style: AppStyle.style16W500Black,
          children: [
            TextSpan(
              text: getTranslated(context, LangConst.textSignUp),
              style:
                  AppStyle.style16W500Black.copyWith(color: AppColor.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () => GoRouter.of(context).push(RoutesKeys.kRegister),
            ),
          ],
        ),
      ),
    );
  }
}
