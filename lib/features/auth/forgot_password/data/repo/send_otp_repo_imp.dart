import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/verifaction/data/model/verify_me_response.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class VerifyUserRepoImpl implements VerifyUserRepo {
  final ApiService apiService;

  VerifyUserRepoImpl({required this.apiService});

  @override
  Future<Either<Failure, ForgotResponse>> verifyUser({
    required String mobile,
  }) async {
    try {
      if (mobile.isEmpty) {
        return left(Failure("يجب إدخال رقم الجوال أو البريد الإلكتروني"));
      }

      Map<String, dynamic> body = {};
      if (mobile.contains('@')) {
        body['email'] = mobile;
      } else if (double.tryParse(mobile) != null) {
        body['mobile'] = mobile;
      } else {
        return left(Failure('Invalid phone format'));
      }

      String jsonData = json.encode(body);

      // API Call
      var response = await apiService.post(
        endPoint: 'api/v1/user/validate-mobile-for-login',
        rawData: jsonData,
      );

      if (response.code >= 200 && response.code < 300) {
        var model = ForgotResponse.fromJson(response.data);
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
