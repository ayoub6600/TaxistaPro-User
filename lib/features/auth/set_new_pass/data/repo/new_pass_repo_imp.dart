// import 'dart:convert';
// import 'package:carq_employee/Widget/api_service.dart';
// import 'package:carq_employee/Widget/failures.dart';
// import 'package:carq_employee/auth/login/data/model/login_model.dart';
// import 'package:carq_employee/auth/set_new_pass/data/repo/new_pass_repo.dart';

// import 'package:dartz/dartz.dart';
// import 'package:dio/dio.dart';

// class NewPassrepoImp implements NewPassRepo {
//   final ApiService apiService;

//   NewPassrepoImp({required this.apiService});

//   @override
//   Future<Either<Failure, LoginResponse>> updatePasswordRepo({
//     required String newPassword,
//     required String phone,
//     required String type,
//   }) async {
//     // Validate inputs
//     if (!isValidPhoneNumber(phone)) {
//       return left(const Failure("Invalid phone number."));
//     }
//     if (!isValidPassword(newPassword)) {
//       return left(
//           const Failure("Password must be at least 6 characters long."));
//     }

//     try {
//       // Prepare the request payload
//       Map<String, dynamic> body = {
//         'password': newPassword,
//         'type': type, // Use the provided type parameter
//         'phone_no': phone,
//       };
//       String jsonData = json.encode(body);

//       // Make the API call
//       var response = await apiService.post(
//         endPoint: 'newpassword',
//         rawData: jsonData,
//       );

//       // Handle the response
//       if (response.code >= 200 && response.code < 300) {
//         var model = LoginResponse.fromJson(response.data);
//         return right(model);
//       } else {
//         return left(Failure(response.errorMessage));
//       }
//     } catch (e) {
//       if (e is DioException) {
//         return left(ServerFailure.fromDioError(e));
//       }
//       // Handle any other errors
//       return left(ServerFailure(e.toString()));
//     }
//   }

//   // Validation functions
//   bool isValidPhoneNumber(String phone) {
//     // Basic validation for phone number format
//     final RegExp phoneRegex = RegExp(r'^\+\d{1,3}\d{9,}$');
//     return phoneRegex.hasMatch(phone);
//   }

//   bool isValidPassword(String password) {
//     // Check for minimum length
//     return password.length >= 6;
//   }
// }



// updatePassword(email, password, loginby) async {
//   dynamic result;

//   try {
//     var response =
//         await http.post(Uri.parse('${url}api/v1/user/update-password'), body: {
//       if (loginby == true) 'email': email,
//       if (loginby == false) 'mobile': email,
//       'password': password
//     });
//     if (response.statusCode == 200) {
//       if (jsonDecode(response.body)['success'] == true) {
//         result = true;
//       } else {
//         result = jsonDecode(response.body)['message'];
//       }
//     } else if (response.statusCode == 401) {
//       result = 'logout';
//     } else {
//       debugPrint(response.body);
//       result = false;
//     }
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//       result = 'no internet';
//     }
//   }
//   return result;
// }