import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/features/auth/login/view/widgets/logo.dart';
import 'package:taxista/features/auth/set_new_pass/manager/new_pass_cubit.dart';
import 'package:taxista/features/auth/set_new_pass/manager/new_pass_state.dart';
import 'package:taxista/features/auth/set_new_pass/view/widgets/password_fields_new_pass.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custem_header_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';

class SetNewPassViewBody extends StatefulWidget {
  final String phone;
  const SetNewPassViewBody({super.key, required this.phone});

  @override
  State<SetNewPassViewBody> createState() => _SetNewPassViewBodyState();
}

class _SetNewPassViewBodyState extends State<SetNewPassViewBody> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewPassWordCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const CustomAppBar(
              showBack: true,
              titleColor: Colors.black,
              appBarTitle: "",
            ),
            Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: BlocConsumer<NewPassWordCubit, NewPasswordState>(
                  listener: (context, state) {
                    switch (state.newPasswordStatus) {
                      case NewPasswordStatus.initial:
                        break;
                      case NewPasswordStatus.submitting:
                        customLoadingDialog(context);
                        break;
                      case NewPasswordStatus.error:
                        Navigator.pop(context);
                        showCustomErrorToast(state.failure?.errMessage ??
                            'Something went wrong');
                        break;
                      case NewPasswordStatus.success:
                        Navigator.pop(context);
                        Navigator.pop(context);
                        //    GoRouter.of(context).go(RoutesKeys.kHome);
                        //showCustomSuccessToast(state.modelData?.msg.toString() ?? "");

                        break;
                    }
                  },
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const LogoWidgets(),
                        HeightSpace(20.h),
                        Center(
                          child: CustmheaderAuth(
                            title: getTranslated(
                              context,
                              LangConst.setPassword,
                            ).toString(),
                            subtitle: '',
                          ),
                        ),
                        const HeightSpace(30),
                        PasswordFieldsNewPass(
                          passwordController: state.newPasswordController,
                          confirmPasswordController: confirmPasswordController,
                          isObscureText: state.isObscureText,
                          isObscureConfirmText: state.isObscureConfirmText,
                          toggleObscureText: cubit.togglePasswordVisibility,
                          toggleObscureConfirmText:
                              cubit.toggleConfirmPasswordVisibility,
                        ),
                        HeightSpace(50.h),
                        ButtonAuth(
                          text: getTranslated(
                            context,
                            LangConst.updatePassword,
                          ).toString(),
                          onTap: () {
                            if (state.newPasswordController.text ==
                                confirmPasswordController.text) {
                              cubit.updatePassword(phone: widget.phone);
                            } else {
                              showCustomErrorToast("Passwords don't match");
                            }
                          },
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
