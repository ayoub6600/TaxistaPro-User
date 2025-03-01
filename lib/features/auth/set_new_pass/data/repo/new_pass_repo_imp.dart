import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/features/auth/set_new_pass/data/repo/new_pass_repo.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class NewPassrepoImp implements NewPassRepo {
  final ApiService apiService;

  NewPassrepoImp({required this.apiService});

  @override
  Future<Either<Failure, LoginResponce>> updatePassword({
    required String mobile,
    required String password,
  }) async {
    // Validate inputs

    if (!isValidPassword(password)) {
      return left(
          const Failure("Password must be at least 6 characters long."));
    }

    try {
      // Prepare the request payload
      Map<String, dynamic> body = {
        'password': password,
        'mobile': mobile,
      };
      String jsonData = json.encode(body);
      print("body $body");

      // Make the API call
      var response = await apiService.post(
        endPoint: 'api/v1/user/update-password',
        rawData: jsonData,
      );

      // Handle the response
      if (response.code >= 200 && response.code < 300) {
        var model = LoginResponce.fromJson(response.data);
        return right(model);
      } else {
        return left(Failure(response.errorMessage));
      }
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      // Handle any other errors
      return left(ServerFailure(e.toString()));
    }
  }

  // Validation functions

  bool isValidPassword(String password) {
    // Check for minimum length
    return password.length >= 6;
  }
}
