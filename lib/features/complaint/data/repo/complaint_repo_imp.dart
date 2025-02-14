import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/complaint/data/model/complaint_response.dart';
import 'package:taxista/features/complaint/data/repo/complaint_repo.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class ComplaintRepoImp implements ComplaintRepo {
  final ApiService apiService;

  ComplaintRepoImp({required this.apiService});

  @override
  Future<Either<Failure, ComplaintResponse>> getcomplaint() async {
    try {
      var response = await apiService.get(
          endPoint: 'api/v1/common/complaint-titles?complaint_type=general');
      if (200 <= response.code && response.code <= 300) {
        var model = ComplaintResponse.fromJson(response.data);
        // print(".....-----------------${model.data?.oldestNotifications?.length}");

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

  @override
  Future<Either<Failure, RemoveAddressResponse>> sendComplaint(
      String id, String description) async {
    try {
      Map<String, dynamic> body = {
        "complaint_title_id": id,
        "description": description,
      };
      String result = json.encode(body);
      var response = await apiService.post(
          endPoint: 'api/v1/common/make-complaint', rawData: result);
      if (200 <= response.code && response.code <= 300) {
        var model = RemoveAddressResponse.fromJson(response.data);
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
