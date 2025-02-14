import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/features/notification/manager/notifaication_state.dart';
import 'package:taxista/features/notification/manager/notification_cubit.dart';
import 'package:taxista/features/notification/view/widgets/notifaiction_items.dart';
import 'package:taxista/features/notification/view/widgets/notification_loding.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/error_state_widget.dart';

class NotificationViewBody extends StatefulWidget {
  const NotificationViewBody({super.key});

  @override
  State<NotificationViewBody> createState() => _NotificationViewBodyState();
}

class _NotificationViewBodyState extends State<NotificationViewBody> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      context.read<NotificationCubit>().getNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          CustomAppBar(
            appBarTitle: getTranslated(context, LangConst.textNotification),
            showBack: true,
          ),
          const SizedBox(height: 20),
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              // return const SizedBox.shrink();

              switch (state.status) {
                case NotificationStatus.initial:
                case NotificationStatus.loading:
                  return const NotifactionScima();
                case NotificationStatus.loaded:
                  if (state.newNotifications.isEmpty) {
                    return ErrorStateWidget(
                        image: Assets.assetsImagesNotification,
                        title:
                            getTranslated(context, LangConst.textNoDataFound),
                        subTitle: '');
                  }
                  return Expanded(
                      child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          separatorBuilder: (context, index) => SizedBox(
                                height: 10.h,
                              ),
                          itemCount: state.newNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = state.newNotifications[index];
                            return ItemsNotifaction(
                              time: notification.convertedCreatedAt,
                              title: notification.title,
                              subTitle: notification.body,
                              id: notification.id,
                            );
                          }));
                case NotificationStatus.error:
                  showCustomErrorToast(
                      state.errorMessage ?? 'An error occurred');
                  return ErrorStateWidget(
                      subTitle: state.errorMessage ?? 'An error occurred');
              }
            },
          ),
        ],
      ),
    );
  }
}
