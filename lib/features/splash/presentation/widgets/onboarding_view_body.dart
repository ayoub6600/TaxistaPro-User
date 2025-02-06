import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/splash/data/datasource/onboarding_pages.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';
import 'package:taxista/features/splash/presentation/widgets/onboarding_dots.dart';
import 'package:taxista/features/splash/presentation/widgets/onboarding_next_page_button.dart';
import 'package:taxista/features/splash/presentation/widgets/onboarding_previous_page_button.dart';

class OnboardingViewBody extends StatelessWidget {
  const OnboardingViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    var cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 450.h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -550.sp,
                        right: -312.sp,
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          width: 1000.w,
                          height: 1000.h,
                          decoration: BoxDecoration(
                            color: const Color(0xffF6F6F6),
                            borderRadius: BorderRadius.circular(1000),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                bottom: -100.h,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 550.7.h,
                                  child: PageView(
                                    onPageChanged: (value) {
                                      cubit.changeIndex(value);
                                    },
                                    controller: cubit.pageController,
                                    children: [
                                      ...OnboardingPages.getPages(context).map(
                                        (e) => Image.asset(
                                          '${e.image}',
                                          width: double.infinity,
                                          fit: BoxFit
                                              .contain, // Ensures the image covers the area
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        HeightSpace(40.h),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              OnboardingPages.getPages(context)[state.index]
                                  .title,
                              style: AppStyle.style24W500Black,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        HeightSpace(12.h),
                        Expanded(
                            child: Text(
                          OnboardingPages.getPages(context)[state.index]
                              .subtitle,
                          style: AppStyle.style16W500Black.copyWith(height: 2),
                          textAlign: TextAlign.center,
                        )),
                        HeightSpace(12.h),
                        const Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              OnboardingDots(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  OnboardingNextPageButton(),
                                  OnboardingPreviousPageButton(),
                                ],
                              )
                            ],
                          ),
                        ),
                        HeightSpace(30.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
