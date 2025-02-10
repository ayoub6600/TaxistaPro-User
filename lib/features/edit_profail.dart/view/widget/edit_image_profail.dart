import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_cubit.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_state.dart';

class CustomButtonAppImage extends StatelessWidget {
  const CustomButtonAppImage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UdateProfailCubit, UpdateProfileState>(
      listener: (context, state) {},
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            context.read<UdateProfailCubit>().showImageSource(context);
          },
          child: Center(
            child: Stack(
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                Container(
                  height: 120.w,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(width: 1, color: Colors.black12),
                  ),
                  child: state.image.path.isEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            fit: BoxFit.fill,
                            placeholder: (context, url) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 34.0, horizontal: 10),
                              child: Image.asset(Assets.assetsImagesLogo,
                                  fit: BoxFit.fill),
                            ),
                            imageUrl: SharedPreferenceUtil.getString(
                                PrefKey.profileImage),
                            errorWidget: (context, url, error) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                Assets.assetsImagesLogo,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        )
                      : ClipOval(
                          child: CircleAvatar(
                            backgroundImage: FileImage(File(state.image.path)),
                            radius:
                                60.w, // Ensuring it fits within the container
                          ),
                        ),
                ),
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppColor.white,
                  child: CircleAvatar(
                    backgroundColor: AppColor.primary,
                    radius: 16.r,
                    child: Icon(
                      size: 18.sp, // Fixed incorrect property
                      Icons.edit,
                      color: AppColor.white,
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
