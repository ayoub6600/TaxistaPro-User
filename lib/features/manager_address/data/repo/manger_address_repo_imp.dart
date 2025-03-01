import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/features/manager_address/data/repo/manger_address_view.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';
import 'package:taxista/features/profail/data/repo/get_user_data.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';
import 'package:dio/dio.dart';

class MangerAddressRepoImp implements MangerAddressRepo {
  final ApiService apiService;

  MangerAddressRepoImp({required this.apiService});

  @override
  Future<Either<Failure, UserProfile>> getUserData() {
    return GetUserData(apiService).getUserData();
  }

  @override
  Future<Either<Failure, RemoveAddressResponse>> removeAddress(
      {required int id}) async {
    try {
      var response = await apiService.get(
        endPoint: 'api/v1/user/delete-favourite-location/$id',
      );
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

  @override
  Future<Either<Failure, dynamic>> addAddress(
      {required String name,
      required String lat,
      required String lng,
      required String add}) async {
    try {
      var response = await apiService.post(
        endPoint: 'api/v1/user/add-favourite-location',
        rawData: jsonEncode({
          'pick_lat': lat,
          'pick_lng': lng,
          'pick_address': add,
          'address_name': name
        }),
      );
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
