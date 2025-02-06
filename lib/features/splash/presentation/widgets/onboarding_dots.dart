import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/features/splash/data/datasource/onboarding_pages.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            OnboardingPages.getPages(context).length,
            (index) {
              double radius = state.index == index ? 14 : 10;
              bool last = index == OnboardingPages.getPages(context).length - 1;
              bool active = index == state.index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: last ? 0 : 4),
                width: radius,
                height: radius,
                decoration: BoxDecoration(
                  color: active
                      ? AppColor.primary
                      : AppColor.primary.withOpacity(.2),
                  borderRadius: BorderRadius.circular(1000),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
