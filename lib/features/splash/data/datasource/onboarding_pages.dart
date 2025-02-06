// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/features/splash/data/models/onboarding_model.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/adv_text.dart';

class OnboardingPages {
  static List<OnboardingModel> getPages(BuildContext context) {
    return [
      OnboardingModel(
        image: Assets.assetsImagesOnboarding1,
        imageIndex: 0,
        title: getTranslated(context, LangConst.textInsurance),
        subtitle: getTranslated(context, LangConst.textInsuranceDesc),
      ),
      OnboardingModel(
        image: Assets.assetsImagesOnboarding2,
        imageIndex: 1,
        title: getTranslated(context, LangConst.textSupport24h),
        subtitle: getTranslated(context, LangConst.textSupport24hDesc),
      ),
      OnboardingModel(
        image: Assets.assetsImagesOnboarding3,
        imageIndex: 2,
        title: getTranslated(context, LangConst.textClear2),
        subtitle: getTranslated(context, LangConst.textClearDesc),
      ),
      OnboardingModel(
        image: Assets.assetsImagesOnboarding4,
        imageIndex: 2,
        title: getTranslated(context, LangConst.textFastAndEasy),
        subtitle: getTranslated(context, LangConst.textFastAndEasyDesc),
      ),
    ];
  }
}
