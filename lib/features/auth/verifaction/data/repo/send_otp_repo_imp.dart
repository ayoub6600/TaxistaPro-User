// import 'dart:convert';
// import 'package:carq_employee/Widget/api_service.dart';
// import 'package:carq_employee/Widget/failures.dart';
// import 'package:carq_employee/auth/verifaction/data/model/forgot_response.dart';
// import 'package:carq_employee/auth/verifaction/data/model/forgot_valid_response.dart';
// import 'package:carq_employee/auth/verifaction/data/model/verify_me_response.dart';
// import 'package:carq_employee/auth/verifaction/data/repo/send_otp_repo.dart';
// import 'package:dartz/dartz.dart';
// import 'package:dio/dio.dart';

// //forgot
// class SendOtpRepoImpl implements SendOtpRepo {
//   final ApiService apiService;

//   SendOtpRepoImpl({required this.apiService});

//   @override
//   Future<Either<Failure, VerifyMeResponse>> verifyMe({
//     required String otp,
//     required String phone,
//     required String type,
//   }) async {
//     try {
//       Map<String, dynamic> body = {
//         'phone_no': phone,
//         'OTP': otp,
//         'type': type,
//       };
//       String jsonData = json.encode(body);
//       // API Call
//       var response = await apiService.post(
//         endPoint: 'verifyMe',
//         rawData: jsonData,
//       );

//       if (response.code >= 200 && response.code < 300) {
//         var model = VerifyMeResponse.fromJson(response.data);
//         return right(model);
//       } else {
//         return left(Failure(response.errorMessage));
//       }
//     } catch (e) {
//       if (e is DioException) {
//         return left(ServerFailure.fromDioError(e));
//       }
//       return left(ServerFailure(e.toString()));
//     }
//   }

//   @override
//   Future<Either<Failure, ForgotValidResponse>> callForgotValid({
//     required String phone,
//     required String otp,
//     required String type,
//   }) async {
//     try {
//       Map<String, dynamic> body = {
//         'phone_no': phone,
//         'otp': otp,
//         'type': type,
//       };
//       String jsonData = json.encode(body);
//       // API Call
//       var response = await apiService.post(
//         endPoint: 'forgot/validate',
//         rawData: jsonData,
//       );

//       if (response.code >= 200 && response.code < 300) {
//         var model = ForgotValidResponse.fromJson(response.data);
//         return right(model);
//       } else {
//         return left(Failure(response.errorMessage));
//       }
//     } catch (e) {
//       if (e is DioException) {
//         return left(ServerFailure.fromDioError(e));
//       }
//       return left(ServerFailure(e.toString()));
//     }
//   }

//   @override
//   Future<Either<Failure, ForgotResponse>> callForgot(
//       {required String phone, required String type}) async {
//     try {
//       Map<String, dynamic> body = {
//         'phone_no': phone,
//         'type': type,
//       };
//       String jsonData = json.encode(body);
//       // API Call
//       var response = await apiService.post(
//         endPoint: 'forgot',
//         rawData: jsonData,
//       );

//       if (response.code >= 200 && response.code < 300) {
//         var model = ForgotResponse.fromJson(response.data);
//         return right(model);
//       } else {
//         return left(Failure(response.errorMessage));
//       }
//     } catch (e) {
//       if (e is DioException) {
//         return left(ServerFailure.fromDioError(e));
//       }
//       return left(ServerFailure(e.toString()));
//     }
//   }
// }
