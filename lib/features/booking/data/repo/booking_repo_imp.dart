import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/booking/data/model/booking_responce.dart';
import 'package:taxista/features/booking/data/repo/booking_repo.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class BookingRepoImp implements BookingRepo {
  final ApiService apiService;

  BookingRepoImp({required this.apiService});

  @override
  Future<Either<Failure, HistoryResponse>> getpendingBooking(int index) async {
    final queryParameters = <String, dynamic>{r'page': index};

    try {
      var response = await apiService.get(
        endPoint: 'api/v1/request/history?on_trip=0',
        // queryParameters: queryParameters,
      );

      if (200 <= response.code && response.code <= 300) {
        var model = HistoryResponse.fromJson(response.data);
        return right(model);
      } else {
        return left(Failure(response.errorMessage));
      }
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }
}
// url https://www.taxistapro.com/api/v1/request/history?is_completed=1
//url https://www.taxistapro.com/api/v1/request/history?is_later=1
//flutter: url https://www.taxistapro.com/api/v1/request/history?is_cancelled=1
