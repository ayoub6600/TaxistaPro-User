import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/notification/manager/notifaication_state.dart';
import 'package:taxista/features/notification/manager/notification_cubit.dart';
import 'package:taxista/widgets_new/delete_account_modal.dart';

class ItemsNotifaction extends StatelessWidget {
  const ItemsNotifaction(
      {super.key,
      required this.title,
      required this.time,
      required this.subTitle,
      required this.id});
  final String title;
  final time;
  final String subTitle;
  final String id;

  @override
  Widget build(BuildContext context) {
    String formattedTime = '';
    if (time != null) {
      try {
        final dateTime = DateFormat("dd'th' MMM hh:mm a").parse(time!);
        formattedTime = DateFormat('hh:mm a').format(dateTime);
      } catch (e) {
        // Handle invalid date format gracefully
        formattedTime = time!;
      }
    }
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
          margin: EdgeInsets.only(top: 4.w, right: 4, left: 4),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.50,
                color: Colors.black.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xffF6F6F6),
                radius: 28,
                child: Icon(
                  Icons.notifications,
                  color: Color(0xff112533),
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1.5,
                height: 58,
                color: Colors.grey[300],
              ),
              const WidthSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: AppStyle.style16W500Black.copyWith(
                              color: AppColor.mainBlack,
                            )),
                        Text(formattedTime,
                            style: AppStyle.style12W500Black.copyWith(
                              color: AppColor.darkGrey,
                            )),
                      ],
                    ),
                    const HeightSpace(6),
                    Text(
                      subTitle,
                      maxLines: 3,
                      style: AppStyle.style12W500Black.copyWith(
                        color: AppColor.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BlocConsumer<NotificationCubit, NotificationState>(
          listener: (context, state) {
            print("---------> ${state.removeNotifactionStatus}");
          },
          builder: (context, state) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context2) => CustmBootomModel(
                    buttonTextok: 'removeNotification',
                    title: "removeNotification",
                    subTitle: "areYouSureYouWantToCancelThisNotification",
                    onTapOk: () async {
                      Navigator.pop(context2); // Close the bottom sheet
                      context
                          .read<NotificationCubit>()
                          .removeNotifaction(id: id);
                    },
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 10,
                child: Icon(
                  FontAwesomeIcons.xmark,
                  color: AppColor.white,
                  size: 10.sp,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
