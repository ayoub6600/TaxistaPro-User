import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxista/Localization/language_localization.dart';
import 'package:taxista/constants/keys_values.dart';

import 'package:taxista/constants/preference_utility.dart';

String getTranslated(BuildContext context, String key) {
  var value = LanguageLocalization.of(context)!.getTranslateValue(key);
  return value.toString();
}

const String english = "en";
const String arabic = "ar";

Future<Locale> setLocale(String languageCode) async {
  SharedPreferenceUtil.putString(PrefKey.currentLanguageCode, languageCode);
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  Locale temp;
  switch (languageCode) {
    case english:
      temp = Locale(languageCode, 'US');
      break;
    case arabic:
      temp = Locale(languageCode, 'AE');
      break;
    default:
      temp = const Locale(english, 'US');
  }
  return temp;
}

Future<Locale> getLocale() async {
  String languageCode =
      SharedPreferenceUtil.getString(PrefKey.currentLanguageCode);
  return _locale(languageCode);
}
