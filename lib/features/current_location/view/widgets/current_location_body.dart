import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/current_location/manager/current_location_cubit.dart';
import 'package:taxista/features/current_location/manager/current_location_state.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/widgets_new/button_auth.dart';

class CurrentLocationBody extends StatelessWidget {
  const CurrentLocationBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(Assets.assetsImagesAllowLocationPermission),
                  fit: BoxFit.cover),
            ),
          ),
          HeightSpace(20.h),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "ابدأ رحلتك معنا",
              style: AppStyle.style18W500Inter,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "حدد موقعك الحالي لنتمكن من خدمتك بشكل أفضل",
              style: AppStyle.style16W500Black.copyWith(
                color: AppColor.mainBlack,
              ),
            ),
          ),
          const Spacer(),
          BlocConsumer<CurrentLocationCubit, CurrentLocationState>(
            listener: (context, state) {
              if (state.currentLocationStatus == CurrentLocationStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error fetching location.")),
                );
              } else if (state.currentLocationStatus ==
                  CurrentLocationStatus.success) {
                GoRouter.of(context).pushReplacement(RoutesKeys.kHome);
              }
            },
            builder: (context, state) {
              return ButtonAuth(
                text: state.currentLocationStatus ==
                        CurrentLocationStatus.submitting
                    ? "جاري المعالجة..."
                    : "ابداء",
                onTap: state.currentLocationStatus ==
                        CurrentLocationStatus.submitting
                    ? null
                    : () => context
                        .read<CurrentLocationCubit>()
                        .getCurrentLocation(),
              );
            },
          ),
          HeightSpace(50.h),
        ],
      ),
    );
  }
}
