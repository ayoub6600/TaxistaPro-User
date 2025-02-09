import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/register/manager/creat_account_cubit.dart';
import 'package:taxista/features/auth/register/manager/creat_account_state.dart';
import 'package:taxista/features/auth/register/view/widgets/chooes_gender.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class CreatAccountViewBody extends StatelessWidget {
  CreatAccountViewBody({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateAccountCubit, CreateAccountState>(
      listener: (context, state) {
        switch (state.createAccountStatus) {
          case CreateAccountStatus.initial:
            break;
          case CreateAccountStatus.submitting:
            customLoadingDialog(context);
            break;
          case CreateAccountStatus.error:
            Navigator.pop(context);

            showCustomErrorToast(state.failure.errMessage);
            break;
          case CreateAccountStatus.success:
            Navigator.pop(context);
            showCustomSuccessToast(
              getTranslated(context, LangConst.textHello),
            );
            GoRouter.of(context).go(RoutesKeys.kHome);

            break;
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0.h),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeightSpace(20.h),
                    Center(
                      child: Text(
                        getTranslated(context, LangConst.textCreateAccount)
                            .toString(),
                        style: AppStyle.style24W500Black,
                      ),
                    ),
                    HeightSpace(20.h),

                    Text(
                      getTranslated(context, LangConst.textName).toString(),
                      style: AppStyle.style16W500Black,
                    ),
                    HeightSpace(5.h),
                    NewCustomTextFormField(
                      txtController: state.nameController,
                      hint: getTranslated(context, LangConst.textName),
                      keyboardType: TextInputType.text,
                      obscureText: false,
                      enabled: true,
                      readOnly: false,
                      onTap: () {},
                    ),
                    HeightSpace(20.h),
                    //mobile
                    Text(
                      getTranslated(context, LangConst.textPhoneNumber)
                          .toString(),
                      style: AppStyle.style16W500Black,
                    ),
                    HeightSpace(5.h),
                    Row(
                      children: [
                        // InkWell(
                        //   onTap: () {},
                        //   child: Container(
                        //     height: 50.h,
                        //     padding: EdgeInsets.symmetric(horizontal: 10.w),
                        //     //width: 80.w,
                        //     decoration: BoxDecoration(
                        //         color: const Color(0xffF6F6F6),
                        //         borderRadius: BorderRadius.circular(5),
                        //         border: Border.all(
                        //             color: const Color(0xffF6F6F6))),
                        //     child: Center(
                        //         child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         // const Icon(Icons.arrow_drop_down),
                        //         Text(
                        //           "+218",
                        //           style: AppStyle.style16W500Black,
                        //           textDirection: TextDirection.ltr,
                        //           //  '+${context.read<LoginCubit>().selectedCountry}',
                        //         ),
                        //       ],
                        //     )),
                        //   ),
                        // ),
                        // WidthSpace(10.w),
                        Expanded(
                          child: NewCustomTextFormField(
                            txtController: state.phoneController,
                            hint: getTranslated(
                                context, LangConst.textPhoneNumber),
                            keyboardType: TextInputType.emailAddress,
                            obscureText: false,
                            enabled: true,
                            readOnly: false,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    //email
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.textEmail).toString(),
                      style: AppStyle.style16W500Black,
                    ),
                    HeightSpace(5.h),

                    NewCustomTextFormField(
                      txtController: state.emailController,
                      hint: getTranslated(context, LangConst.textEmail),
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      enabled: true,
                      readOnly: false,
                      onTap: () {},
                    ),
                    HeightSpace(20.h),
                    //password

                    Text(
                      getTranslated(context, LangConst.password).toString(),
                      style: AppStyle.style16W500Black,
                    ),
                    HeightSpace(5.h),

                    NewCustomTextFormField(
                      hint:
                          getTranslated(context, LangConst.password).toString(),
                      txtController: state.passwordController,
                      obscureText: state.isObscureText,
                      suffixIcon: InkWell(
                        onTap: () {
                          context
                              .read<CreateAccountCubit>()
                              .togglePasswordVisibility();
                        },
                        child: Icon(
                          state.isObscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),

                    HeightSpace(20.h),
                    //gender
                    Text(
                      getTranslated(context, LangConst.textGender).toString(),
                      style: AppStyle.style16W500Black,
                    ),
                    HeightSpace(10.h),
                    ChooseGender(
                      onGenderSelected: (value) {
                        print(value);
                        context.read<CreateAccountCubit>().setGender(value);
                      },
                    ),
                    HeightSpace(50.h),
                    ButtonAuth(
                      text: getTranslated(context, LangConst.textSignUp),
                      onTap: () {
                        if (formKey.currentState!.validate()) {
                          context.read<CreateAccountCubit>().createAccount();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
