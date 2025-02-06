import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';
import 'package:dio/dio.dart';

class LoginRepoImap implements LoginRepo {
  final ApiService apiService;

  LoginRepoImap({required this.apiService});

  @override
  Future<Either<Failure, LoginResponse>> loginMethod({
    required String phone,
    required String password,
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
        'password': password,
        'device_token': fcm,
      };

      if (phone.contains('@')) {
        body['email'] = phone;
      } else if (double.tryParse(phone) != null) {
        body['mobile'] = phone;
      } else {
        return left(Failure('Invalid phone format'));
      }

      String jsonData = json.encode(body);

      // Await the API response
      var response = await apiService.post(
          endPoint: 'api/v1/user/login', rawData: jsonData);

      if (response.code >= 200 && response.code < 300) {
        var model = LoginResponse.fromJson(response.data);
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
