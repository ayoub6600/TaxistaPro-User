import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';
import 'package:taxista/widgets_new/button_wrapper.dart';

class OnboardingNextPageButton extends StatelessWidget {
  const OnboardingNextPageButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        if (state.index == 0) return const SizedBox();
        return ButtonWrapper(
          onTap: () {
            cubit.decrement();
          },

          width: 48.w,
          height: 48.h,
          border: Border.all(
            width: 1.dg,
            color: AppColor.primary,
          ),
          borderRadius: 1000,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.arrow_back,
            color: AppColor.primary,
          ),
          //
        );
      },
    );
  }
}
