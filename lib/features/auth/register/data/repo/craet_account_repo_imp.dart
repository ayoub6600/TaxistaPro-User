import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/auth/register/data/model/register_model.dart';
import 'package:taxista/features/auth/register/data/repo/creat_account_repo.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class CreatAccountImap implements CreatAccountRepo {
  final ApiService apiService;

  CreatAccountImap({required this.apiService});

  @override
  Future<Either<Failure, RegisterResponseModel>> creatAccountMethod({
    required String name,
    required String email,
    required String mobile,
    required String country,
    required String gender,
    required String password,
  }) async {
    try {
      final body = {
        'name': name,
        'mobile': mobile,
        'country': '+218',
        'email': email,
        'gender': gender,
        'password': password
      };
      String jsonData = json.encode(body);

      // Await the API response
      var response = await apiService.post(
        endPoint: 'api/v1/user/register',
        rawData: jsonData,
      );

      // Check response code and return appropriate result
      if (response.code >= 200 && response.code < 300) {
        var model = RegisterResponseModel.fromJson(response.data);
        return right(model);
      } else {
        return left(Failure(response.errorMessage));
      }
    } catch (e) {
      // Catch any exception and return it as a Failure
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }
}
