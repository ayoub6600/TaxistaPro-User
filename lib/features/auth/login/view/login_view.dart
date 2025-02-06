import 'package:flutter/material.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/auth/login/view/widgets/login_screen_view_body.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: const LoginScreenViewBody(),
    );
  }
}
