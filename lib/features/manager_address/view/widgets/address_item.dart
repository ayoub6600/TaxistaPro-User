import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/text_style.dart';
import 'package:taxista/features/manager_address/manager/manger_address_cubit.dart';
import 'package:taxista/features/manager_address/manager/manger_address_state.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';

import 'package:taxista/widgets_new/delete_account_modal.dart';

class AddressItem extends StatelessWidget {
  const AddressItem(
      {super.key,
      //  required this.addressData,
      required this.onTap,
      required this.addressData});

  final FavouriteLocation addressData;
  final Function() onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.w,
                  color: AppColor.grey,
                ),
              ),
              child: Icon(
                FontAwesomeIcons.locationDot,
                color: AppColor.primary,
                size: 25.w,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1.5,
              height: 58,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(addressData.addressName,
                            style: AppStyle.style14W500Black.copyWith(
                              color: AppColor.mainBlack,
                              height: 0,
                            )),
                        const SizedBox(height: 4),
                        Text(addressData.pickAddress,
                            maxLines: 3,
                            style: AppStyle.style12W500Black.copyWith(
                              color: AppColor.darkGrey,
                              height: 0,
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            BlocConsumer<MangerAddressCubit, ManagerAddressState>(
              listener: (context, state) {},
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context2) => CustmBootomModel(
                        buttonTextok: 'removeAddress',
                        title: "removeAddress",
                        subTitle: "areYouSureYouWantToCancelThisAddress",
                        onTapOk: () async {
                          Navigator.pop(context2); // Close the bottom sheet
                          context
                              .read<MangerAddressCubit>()
                              .removeAddress(addressId: addressData.id);
                        },
                      ),
                    );
                  },
                  child: Icon(
                    FontAwesomeIcons.trashAlt,
                    color: AppColor.error,
                    size: 20.sp,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
