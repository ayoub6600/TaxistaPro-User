import 'package:flutter/material.dart';
import 'package:taxista/constants/app_color.dart';

import 'widgets/language_screen_view_body.dart';

class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: const LanguageScreenViewBody(),
    );
  }
}
