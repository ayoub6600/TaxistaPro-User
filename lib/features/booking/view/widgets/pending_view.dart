import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/app_color.dart';
import 'package:taxista/constants/assets.dart';
import 'package:taxista/constants/spaces.dart';
import 'package:taxista/features/booking/data/model/booking_responce.dart';
import 'package:taxista/features/booking/manager/booking_cubit.dart';
import 'package:taxista/features/booking/manager/booking_state.dart';
import 'package:taxista/features/booking/view/widgets/custmin_formationmy_booking.dart';
import 'package:taxista/utils/lang_const.dart';
import 'package:taxista/widgets_new/error_state_widget.dart';

class PendingBookingViewBody extends StatefulWidget {
  const PendingBookingViewBody({
    super.key,
  });

  @override
  State<PendingBookingViewBody> createState() => _PendingBookingViewBodyState();
}

class _PendingBookingViewBodyState extends State<PendingBookingViewBody> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_scrollListener);

    // Fetch pending bookings on initialization
    // context.read<BookingCubit>().getActiveBookings();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);

    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      final cubit = context.read<BookingCubit>();
      if (cubit.state.nextPage != null) {
        debugPrint('Fetching more pending bookings');
        cubit.getpendingBooking();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, MyBookingState>(
      builder: (context, state) {
        switch (state.status) {
          case BookingStatus.initial:
          case BookingStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case BookingStatus.error:
            return Center(
              child: Text(state.errorMessage ?? 'Error'),
            );
          case BookingStatus.success:
            final bookingList = state.bookingList ?? [];
            return Stack(
              children: [
                if (bookingList.isEmpty)
                  const Center(
                    child: ErrorStateWidget(
                      title: "No Bookings",
                      subTitle: "Looks like you don't have any bookings yet",
                      image: Assets.assetsImagesHistory,
                    ),
                  ),
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<BookingCubit>().getpendingBooking(reset: true);
                  },
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: bookingList.length,
                    separatorBuilder: (context, index) => HeightSpace(10.h),
                    padding: EdgeInsets.only(
                      bottom: 100.h,
                      right: 20.h,
                      left: 20.h,
                      top: 20.h,
                    ),
                    itemBuilder: (context, index) {
                      return BookingItemeList(
                        booking: bookingList[index],
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore)
                  const Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
        }
      },
    );
  }
}

class BookingItemeList extends StatelessWidget {
  const BookingItemeList({super.key, required this.booking});
  final RequestData booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.07),
            offset: Offset(0, 11),
            blurRadius: 194,
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColor.stroke,
        ),
        color: const Color(0xFFFFFFFF),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                width: 101,
                height: 110,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: booking.vehicleTypeImage != null
                          ? CachedNetworkImageProvider(booking.vehicleTypeImage)
                              as ImageProvider<Object>
                          : AssetImage(Assets.assetsImagesAboutImage)
                              as ImageProvider<Object>, // Explicit casting
                      fit: BoxFit.cover,
                    )),
              ),
              const WidthSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.stroke.withAlpha(100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.vehicleTypeName,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColor.primary,
                            ),
                      ),
                    ),
                    const HeightSpace(12),

                    // if (booking.address != null)
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.mapMarkerAlt,
                          color: AppColor.primary,
                          size: 12,
                        ),
                        const WidthSpace(5),
                        Flexible(
                          child: Text(
                            booking.pickAddress,
                            style: GoogleFonts.cairo(
                              textStyle: const TextStyle(
                                color:
                                    Color(0xFF797979), // secondary black color
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w400, // font weight 400 (normal)
                                height: 1.0, // equivalent to normal line-height
                                fontStyle: FontStyle.normal,
                                decoration:
                                    TextDecoration.none, // no text decoration
                              ),
                            ),
                            // textAlign: TextAlign.end,
                            overflow: TextOverflow
                                .ellipsis, // Handle overflow with ellipsis
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),

                    const HeightSpace(10),

                    const HeightSpace(10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustminformationMyBooking(
                              title: 'Order ID',
                              subtitle: "#${booking.requestNumber}",
                            ),
                            const SizedBox(width: 12),
                            CustminformationMyBooking(
                              title: 'Total',
                              subtitle: (booking.paymentOpt == '1')
                                  ? 'text_cash'
                                  : (booking.paymentOpt == '2')
                                      ? 'text_wallet'
                                      : (booking.paymentOpt == '0')
                                          ? 'text_card'
                                          : (booking.isBidRide == 1)
                                              ? '${booking.requestedCurrencySymbol ?? ''} ${booking.acceptedRideFare ?? '0'}'
                                              : (booking.isCompleted == 1)
                                                  ? '${booking.requestedCurrencySymbol ?? ''} '
                                                  : '${booking.requestedCurrencySymbol ?? ''} ${booking.requestEtaAmount ?? '0'}',
                              // "${booking.requestedCurrencySymbol ?? 0} ${booking.requestedCurrencyCode ?? ""}",
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CustminformationMyBooking(
                          title: "orderDate",
                          //   converted_completed_at
                          subtitle: (booking.laterRide == true)
                              ? booking.tripStartTime ?? "Default Value"
                              : (booking.cancelledRide == true)
                                  ? booking.convertedCancelledAt
                                  : (booking.completedRide == true)
                                      ? booking.convertedCreatedAt
                                      : booking.convertedCreatedAt,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
