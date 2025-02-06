// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/routing/routes_keys.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    Future.delayed(Duration(seconds: 1)).then(
      (value) {
        var result = SharedPreferenceUtil.getString(PrefKey.login);
        if (result.isEmpty) {
          GoRouter.of(context).pushReplacement(RoutesKeys.kWelcome);
        } else if (result == '1') {
          GoRouter.of(context).pushReplacement(RoutesKeys.kLogin);
        } else {
          GoRouter.of(context).pushReplacement(RoutesKeys.kHome);
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          Assets.assetsImagesSplch,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
