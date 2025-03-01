import 'package:equatable/equatable.dart';
import 'package:taxista/features/booking/data/model/booking_responce.dart';

enum BookingStatus { initial, loading, success, error }

enum CheckOutState {
  initial,
  loading,
  success,
  error,
}

class MyBookingState extends Equatable {
  final BookingStatus status;
  // final BookingDetailsResponseData? details;
  // final StoreResponseData? storeResponseData;
  final List<RequestData>? bookingList;
  final String? errorMessage;
  final int? nextPage;
  final bool isLoadingMore;
  final CheckOutState checkOutState; // حالة عملية الدفع أو الإغلاق

  const MyBookingState({
    required this.status,
    // this.details,
    this.bookingList,
    this.errorMessage,
    this.nextPage,
    this.isLoadingMore = false,
    this.checkOutState = CheckOutState.initial,
    // this.storeResponseData,
  });

  factory MyBookingState.initial() {
    return MyBookingState(
        status: BookingStatus.initial,
        bookingList: const [],
        // details: BookingDetailsResponseData(),
        errorMessage: null,
        nextPage: 0,
        isLoadingMore: false,
        //storeResponseData: StoreResponseData(),
        checkOutState: CheckOutState.initial);
  }

  MyBookingState copyWith(
      {BookingStatus? status,
      // BookingDetailsResponseData? details,
      List<RequestData>? bookingList,
      String? errorMessage,
      int? nextPage,
      bool? isLoadingMore,
      //  StoreResponseData? storeResponseData,
      CheckOutState? checkOutState}) {
    return MyBookingState(
        //details: details ?? this.details,
        status: status ?? this.status,
        bookingList: bookingList ?? this.bookingList,
        errorMessage: errorMessage ?? this.errorMessage,
        nextPage: nextPage ?? this.nextPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        //storeResponseData: storeResponseData ?? this.storeResponseData,
        checkOutState: checkOutState ?? this.checkOutState);
  }

  @override
  List<Object?> get props => [
        status,
        bookingList,
        // details,
        errorMessage,
        nextPage,
        isLoadingMore,
        checkOutState
      ];
}
