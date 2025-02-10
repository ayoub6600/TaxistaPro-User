import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/utils/text_form_faild.dart';
import 'package:taxista/widgets_new/button_auth.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';

class ProfailViewBody extends StatelessWidget {
  const ProfailViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          CustomAppBar(
            appBarTitle: getTranslated(context, LangConst.textPersonalInfo),
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeightSpace(20.h),
                    Center(
                      child: CircleAvatar(
                        radius: 50.r,
                        backgroundImage: CachedNetworkImageProvider(
                            SharedPreferenceUtil.getString(
                                PrefKey.profileImage)),
                      ),
                    ),
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.textName).toString(),
                      style: AppStyle.style15W500Black,
                    ),
                    HeightSpace(5.h),
                    NewCustomTextFormField(
                      hint: SharedPreferenceUtil.getString(PrefKey.fullName),
                      enabled: false,
                      txtController: TextEditingController(),
                    ),
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.textEmail).toString(),
                      style: AppStyle.style18W500Inter,
                    ),
                    HeightSpace(5.h),
                    NewCustomTextFormField(
                      hint: SharedPreferenceUtil.getString(PrefKey.email),
                      enabled: false,
                      txtController: TextEditingController(),
                    ),
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.phone).toString(),
                      style: AppStyle.style18W500Inter,
                    ),
                    HeightSpace(5.h),
                    NewCustomTextFormField(
                      hint: SharedPreferenceUtil.getString(PrefKey.mobile)
                          .replaceFirst('+218', ''),
                      enabled: false,
                      txtController: TextEditingController(),
                    ),
                    HeightSpace(20.h),
                    Text(
                      getTranslated(context, LangConst.textGender).toString(),
                      style: AppStyle.style18W500Inter,
                    ),
                    HeightSpace(5.h),
                    NewCustomTextFormField(
                      hint: getTranslated(context,
                          SharedPreferenceUtil.getString(PrefKey.gender)),
                      enabled: false,
                      txtController: TextEditingController(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ButtonAuth(
            text:
                "${getTranslated(context, LangConst.textEdit)} ${getTranslated(context, LangConst.textPersonalInfo)}",
            onTap: () {
              GoRouter.of(context).push(RoutesKeys.keditProfail);
            },
          ),
          HeightSpace(20.h)
        ],
      ),
    );
  }
}
