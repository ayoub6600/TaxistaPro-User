import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_cubit.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_state.dart';
import 'package:taxista/features/edit_profail.dart/view/widget/edit_image_profail.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_loading_dialog.dart';

import 'chooes_gender_edit_profail.dart';

class EditProfailViewBody extends StatelessWidget {
  const EditProfailViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          CustomAppBar(
            appBarTitle:
                "${getTranslated(context, LangConst.textEdit)} ${getTranslated(context, LangConst.textPersonalInfo)}",
            showBack: true,
          ),
          Expanded(
            child: BlocConsumer<UdateProfailCubit, UpdateProfileState>(
              listener: (context, state) {
                print("---------> ${state.updateProfileStatus}");
                switch (state.updateProfileStatus) {
                  case UpdateProfileStatus.initial:
                    break;
                  case UpdateProfileStatus.submitting:
                    customLoadingDialog(context);
                    break;
                  case UpdateProfileStatus.error:
                    Navigator.pop(context);
                    print(
                        "----------------------_> error ${state.failure.errMessage}");
                    showCustomErrorToast(state.failure.errMessage);
                    break;
                  case UpdateProfileStatus.success:
                    Navigator.pop(context);

                    GoRouter.of(context).go(RoutesKeys.kHome);
                    break;
                  case UpdateProfileStatus.updatingimage:
                    Navigator.pop(context);
                    break;
                }
              },
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeightSpace(20.h),
                        const CustomButtonAppImage(),
                        HeightSpace(20.h),
                        Text(
                          getTranslated(context, LangConst.textName).toString(),
                          style: AppStyle.style15W500Black,
                        ),
                        HeightSpace(5.h),
                        NewCustomTextFormField(
                          hint:
                              SharedPreferenceUtil.getString(PrefKey.fullName),
                          enabled: true,
                          txtController: state.nameController,
                        ),
                        HeightSpace(20.h),
                        Text(
                          getTranslated(context, LangConst.textEmail)
                              .toString(),
                          style: AppStyle.style18W500Inter,
                        ),
                        HeightSpace(5.h),
                        NewCustomTextFormField(
                          hint: SharedPreferenceUtil.getString(PrefKey.email),
                          enabled: true,
                          txtController: state.emailController,
                        ),

                        //gender
                        HeightSpace(20.h),
                        Text(
                          getTranslated(context, LangConst.textGender)
                              .toString(),
                          style: AppStyle.style18W500Inter,
                        ),
                        HeightSpace(5.h),
                        GenderSelection(
                          onGenderSelected: (String value) {
                            context
                                .read<UdateProfailCubit>()
                                .updateGender(value);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ButtonAuth(
            text: getTranslated(context, LangConst.textEdit),
            onTap: () {
              context.read<UdateProfailCubit>().updateProfile();
            },
          ),
          HeightSpace(20.h)
        ],
      ),
    );
  }
}
