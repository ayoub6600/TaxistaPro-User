import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/features/booking/data/repo/booking_repo.dart';
import 'package:taxista/features/booking/manager/booking_state.dart';

class BookingCubit extends Cubit<MyBookingState> {
  final BookingRepo repo;

  BookingCubit(this.repo) : super(MyBookingState.initial());

  Future<void> getpendingBooking({bool reset = false}) async {
    if (reset) {
      // state.bookingList?.clear();
      emit(state.copyWith(
        status: BookingStatus.initial,
      ));

      emit(state.copyWith(
        //  bookingList: [],
        nextPage: 1,
      ));
    } else {
      emit(state.copyWith(isLoadingMore: true));
    }

    try {
      final response = await repo.getpendingBooking(state.nextPage ?? 1);
      response.fold(
        (failure) {
          print('---------__>${failure.errMessage}');
          emit(state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.errMessage,
            isLoadingMore: false,
          ));
        },
        (model) {
          if (model.data != null && model.data.isNotEmpty) {
            var pendingBNextPage = state.nextPage! + 1;
            emit(state.copyWith(
              status: BookingStatus.success,
              bookingList: [...state.bookingList!, ...model.data],
              nextPage: pendingBNextPage,
              isLoadingMore: false,
            ));
          } else {
            emit(state.copyWith(
              status: BookingStatus.success,
              bookingList: [...state.bookingList!],
              nextPage: state.nextPage,
              isLoadingMore: false,
            ));
          }
        },
      );
    } catch (error) {
      emit(state.copyWith(
        status: BookingStatus.error,
        errorMessage: error.toString(),
        isLoadingMore: false,
      ));
    }
  }

  // BookingDetailsResponseData? details;

  // Future<void> getDetailsBookings(int id) async {
  //   emit(state.copyWith(status: BookingStatus.loading));

  //   try {
  //     final response = await repo.getBookingDetails(id);
  //     response.fold(
  //       (failure) {
  //         emit(state.copyWith(
  //           status: BookingStatus.error,
  //           errorMessage: failure.errMessage,
  //         ));
  //       },
  //       (model) {
  //         details = model.data!;
  //         emit(state.copyWith(
  //           status: BookingStatus.success,
  //           details: details,
  //         ));
  //       },
  //     );
  //   } catch (error) {
  //     emit(state.copyWith(
  //       status: BookingStatus.error,
  //       errorMessage: error.toString(),
  //     ));
  //   }
  // }

  void reset() {
    emit(state.copyWith(
      //  bookingList: [],
      nextPage: 1,
    ));
  }
}
