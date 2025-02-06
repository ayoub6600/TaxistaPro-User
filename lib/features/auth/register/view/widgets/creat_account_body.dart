import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/auth/register/manager/creat_account_cubit.dart';
import 'package:taxista/features/auth/register/manager/creat_account_state.dart';
import 'package:taxista/features/auth/register/view/widgets/chooes_gender.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';

class CreatAccountViewBody extends StatelessWidget {
  CreatAccountViewBody({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateAccountCubit, CreateAccountState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return SafeArea(
          child: Form(
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
                          'انشاء حساب',
                          // getTranslated(context, LangConst.textCreateAccount)
                          //     .toString(),
                          style: AppStyle.style24W500Black,
                        ),
                      ),
                      HeightSpace(20.h),

                      //name
                      Text(
                        getTranslated(context, LangConst.textName).toString(),
                        style: AppStyle.style16W500Black,
                      ),
                      HeightSpace(5.h),
                      NewCustomTextFormField(
                        txtController: state.nameController,
                        hint: getTranslated(context, LangConst.textName),
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        enabled: true,
                        readOnly: false,
                        onTap: () {},
                      ),
                      HeightSpace(20.h),
                      //mobile
                      Text(
                        "رقم الجوال",
                        style: AppStyle.style16W500Black,
                      ),
                      HeightSpace(5.h),
                      NewCustomTextFormField(
                        txtController: state.phoneController,
                        hint: "ادخل رقم الجوال",
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        enabled: true,
                        readOnly: false,
                        onTap: () {},
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
                        hint: getTranslated(context, LangConst.password)
                            .toString(),
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
                        "اختر النوع",
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
                        text: "انشاء حساب",
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
          ),
        );
      },
    );
  }
}
