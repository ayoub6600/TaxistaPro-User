import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/spaces.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      body: SafeArea(
          child: Column(
        children: [
          HeightSpace(20.h),
          Image.asset(Assets.assetsImagesAuto,
              height: 430.h, width: double.infinity, fit: BoxFit.fill),
          HeightSpace(6.h),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 24),
          //   child: Column(
          //     children: [
          //       AdvText([
          //         TextModel(getTranslated(context, LangConst.yourJourneyToA)
          //             .toString()),
          //         TextModel(
          //             getTranslated(context, LangConst.gleamingCarBeginsHere)
          //                 .toString(),
          //             primary: true),
          //       ]),
          //       HeightSpace(20.h),
          //       Text(
          //           getTranslated(
          //                   context,
          //                   LangConst
          //                       .everyJourneyBeginsWithASingleStepLeadingToDiscoveriesBeyondImagination)
          //               .toString(),
          //           overflow: TextOverflow.visible,
          //           textAlign: TextAlign.center,
          //           style: AppStyle.style14W500Black),
          //       HeightSpace(24.h),
          //       AppButton(
          //         getTranslated(context, LangConst.letSGetStartedSplach)
          //             .toString(),
          //         onTap: () {
          //           GoRouter.of(context)
          //               .pushReplacement(RoutesKeys.kOnboarding);
          //         },
          //       ),
          //       HeightSpace(20.h),
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Text(
          //               getTranslated(context, LangConst.alreadyHaveAnAccount)
          //                   .toString(),
          //               style: AppStyle.style16W500Black.copyWith(
          //                 color: AppColor.mainBlack,
          //               )),
          //           GestureDetector(
          //             onTap: () {
          //               GoRouter.of(context).pushReplacement(RoutesKeys.kLogin);
          //             },
          //             child: Text(
          //                 getTranslated(context, LangConst.login).toString(),
          //                 style: AppStyle.style16W500Black.copyWith(
          //                   color: AppColor.primary,
          //                 )),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
        ],
      )),
    );
  }
}
