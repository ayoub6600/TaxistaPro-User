import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/main.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/utils/lang_const.dart';

class LanguageScreenViewBody extends StatefulWidget {
  const LanguageScreenViewBody({super.key});

  @override
  State<LanguageScreenViewBody> createState() => _LanguageScreenViewBodyState();
}

class _LanguageScreenViewBodyState extends State<LanguageScreenViewBody> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeightSpace(20.h),
          Center(
            child: Text(
              getTranslated(context, LangConst.textChangeLanguage).toString(),
              style: AppStyle.style18W500Inter,
            ),
          ),
          HeightSpace(20.h),
          Image.asset(
            Assets.assetsImagesSelectLanguage,
            height: 300.h,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
          ListView.builder(
            itemCount: Language.languageList().length,
            shrinkWrap: true,
            padding: EdgeInsets.only(
              top: 30.h,
              left: 20.w,
              right: 20.w,
            ),
            itemBuilder: (context, index) {
              String currentLanguageCode =
                  SharedPreferenceUtil.getString(PrefKey.currentLanguageCode);
              bool isSelected = (currentLanguageCode == 'N/A' && index == 0) ||
                  currentLanguageCode ==
                      Language.languageList()[index].languageCode;

              return ListTile(
                onTap: () async {
                  Locale local = await setLocale(
                      Language.languageList()[index].languageCode);
                  setState(() {
                    MyApp.setLocale(context, local);
                    SharedPreferenceUtil.putString(
                      PrefKey.currentLanguageCode,
                      Language.languageList()[index].languageCode,
                    );
                  });
                },
                contentPadding: EdgeInsets.zero,
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        Language.languageList()[index].name,
                        style: AppStyle.style16W500Black.copyWith(
                          color: AppColor.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) async {
                    if (value == true) {
                      Locale local = await setLocale(
                          Language.languageList()[index].languageCode);
                      setState(() {
                        MyApp.setLocale(context, local);
                        SharedPreferenceUtil.putString(
                          PrefKey.currentLanguageCode,
                          Language.languageList()[index].languageCode,
                        );
                      });
                    }
                  },
                  activeColor: AppColor.primary,
                ),
              );
            },
          ),
          Spacer(),
          Center(
            child: GestureDetector(
              onTap: () {
                GoRouter.of(context).pushReplacement(RoutesKeys.kOnboarding);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 20.h),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                height: 50.h,
                width: 300.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(50.r)),
                child: Text(
                  getTranslated(context, LangConst.textConfirm).toString(),
                  style: AppStyle.style16W500hepo.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Language {
  final int id;
  final String name;
  final String flag;
  final String languageCode;

  Language(
    this.id,
    this.name,
    this.flag,
    this.languageCode,
  );

  static List<Language> languageList() {
    return <Language>[
      Language(1, 'English', '🇺🇸', 'en'),
      Language(2, 'عربى', 'AE', 'ar'),
    ];
  }
}
