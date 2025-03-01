import 'package:dartz/dartz.dart';
import 'package:taxista/features/booking/data/model/booking_responce.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class BookingRepo {
  Future<Either<Failure, HistoryResponse>> getpendingBooking(
    int index,
  );
}
// url https://www.taxistapro.com/api/v1/request/history?is_completed=1
//url https://www.taxistapro.com/api/v1/request/history?is_later=1
//flutter: url https://www.taxistapro.com/api/v1/request/history?is_cancelled=1
