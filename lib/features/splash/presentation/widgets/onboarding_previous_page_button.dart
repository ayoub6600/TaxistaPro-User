import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/widgets_new/button_wrapper.dart';

class OnboardingPreviousPageButton extends StatelessWidget {
  const OnboardingPreviousPageButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return ButtonWrapper(
          onTap: () {
            bool done = cubit.increment(context);
            if (!done) {
              // AppRouter.pushReplacement(context, LoginScreen());
              GoRouter.of(context).pushReplacement(RoutesKeys.kLogin);
            }
          },
          width: 48.w,
          height: 48.h,
          borderRadius: 1000,
          backgroundColor: AppColor.primary,
          child: const Icon(
            Icons.arrow_forward,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
