import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
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

  @override
  Future<Either<Failure, ForgotResponse>> sendOTPtoMobile({
    required String mobile,
    required String countryCode,
  }) async {
    try {
      if (mobile.isEmpty || countryCode.isEmpty) {
        return left(Failure("يجب إدخال رقم الجوال ورمز الدولة"));
      }

      Map<String, dynamic> body = {
        'mobile': mobile,
        'country_code': countryCode,
      };

      String jsonData = json.encode(body);

      // API Call
      var response = await apiService.post(
        endPoint: 'api/v1/mobile-otp',
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

  @override
  Future<Either<Failure, LoginResponce>> callForgot({
    required String mobile,
    required String otp,
  }) async {
    String? token;
    if (Platform.isIOS) {
      // إذا كان النظام هو iOS
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        token = await FirebaseMessaging.instance.getToken();
      } else {
        await Future<void>.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          token = await FirebaseMessaging.instance.getToken();
        }
      }
    } else {
      // إذا كان النظام هو Android
      token = await FirebaseMessaging.instance.getToken();
    }
    var fcm = token.toString();
    try {
      Map<String, dynamic> body = {
        'otp': otp,
        'device_token': fcm,
      };

      if (mobile.contains('@')) {
        body['email'] = mobile;
      } else if (double.tryParse(mobile) != null) {
        body['mobile'] = mobile;
      } else {
        return left(Failure('Invalid phone format'));
      }

      String jsonData = json.encode(body);

      // Await the API response
      var response = await apiService.post(
          endPoint: 'api/v1/user/login', rawData: jsonData);
      print('---->${response.code}');
      if (response.code >= 200 && response.code < 300) {
        var model = LoginResponce.fromJson(response.data);
        return right(model);
      } else {
        if (response.code == 422) {
          print(
            "response.errorMessage ${response}",
          );
          return left(Failure(response.errorMessage));
        }
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
