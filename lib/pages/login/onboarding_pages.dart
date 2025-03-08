// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/login/onboarding_model.dart';
import 'package:taxista/translations/translation.dart';

class OnboardingPages {
  static List<OnboardingModel> getPages(BuildContext context) {
    return [
      OnboardingModel(
        image: "assets/images/onboarding_1.jpg",
        imageIndex: 0,
        title: languages[choosenLanguage]['text_insurance'],
        subtitle: languages[choosenLanguage]['text_insurance_desc'],
      ),
      OnboardingModel(
        image: "assets/images/onboarding_2.jpg",
        imageIndex: 0,
        title: languages[choosenLanguage]['text_support_24h'],
        subtitle: languages[choosenLanguage]['text_support_24h_desc'],
      ),
      OnboardingModel(
        image: "assets/images/onboarding_3.jpg",
        imageIndex: 0,
        title: languages[choosenLanguage]['text_clear2'],
        subtitle: languages[choosenLanguage]['text_clear_desc'],
      ),
      OnboardingModel(
        image: "assets/images/onboarding_4.jpg",
        imageIndex: 0,
        title: languages[choosenLanguage]['text_fast_and_easy'],
        subtitle: languages[choosenLanguage]['text_fast_and_easy_desc'],
      ),
    ];
  }
}
