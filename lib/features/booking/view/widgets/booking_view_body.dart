import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/features/booking/manager/booking_cubit.dart';
import 'package:taxista/features/booking/view/widgets/cancel_bookings_list.dart';
import 'package:taxista/features/booking/view/widgets/complete_bookings_list.dart';
import 'package:taxista/features/booking/view/widgets/pending_view.dart';
import 'package:taxista/features/booking/view/widgets/section_item.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/custom_app_bar.dart';

class BooKingViewBody extends StatefulWidget {
  const BooKingViewBody({super.key});

  @override
  State<BooKingViewBody> createState() => _BooKingViewBodyState();
}

class _BooKingViewBodyState extends State<BooKingViewBody> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch active bookings initially when the widget is loaded
    context.read<BookingCubit>().getpendingBooking(reset: true);
  }

  void _onButtonPressed(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Switch between active, complete, and cancelled bookings
    switch (index) {
      case 0:
        context.read<BookingCubit>().getpendingBooking(reset: true);
        break;

      case 1:
        context.read<BookingCubit>().getpendingBooking(reset: true);
        break;
      case 2:
        context.read<BookingCubit>().getpendingBooking(reset: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const CustomAppBar(
            appBarTitle: "حجوزاتي",
            showBack: true,
          ),
          SizedBox(height: 20.h),
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SectionItem(
                      sectionTitle: 'معلقة',
                      isSelected: _currentIndex == 0,
                      onTap: () => _onButtonPressed(0),
                    ),
                    SectionItem(
                      sectionTitle: 'مفعلة',
                      isSelected: _currentIndex == 2,
                      onTap: () => _onButtonPressed(2),
                    ),
                    SectionItem(
                      sectionTitle: 'ملغية',
                      isSelected: _currentIndex == 3,
                      onTap: () => _onButtonPressed(3),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black12,
                height: 1,
                width: double.infinity,
              ),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const <Widget>[
                PendingBookingViewBody(),
                CompleteBookingsList(),
                CancelBookingsList(),
              ],
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
