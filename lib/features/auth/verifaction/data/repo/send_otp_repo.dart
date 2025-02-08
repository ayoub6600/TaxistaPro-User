// import 'package:dartz/dartz.dart';

// abstract class SendOtpRepo {
//   Future<Either<Failure, VerifyMeResponse>> verifyMe({
//     required String otp,
//     required String phone,
//     required String type,
//   });
//   Future<Either<Failure, ForgotValidResponse>> callForgotValid({
//     required String otp,
//     required String phone,
//     required String type,
//   });
//   Future<Either<Failure, ForgotResponse>> callForgot({
//     required String phone,
//     required String type,
//   });
// }
// phoneAuth(String phone) async {
//   try {
//     credentials = null;
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phone,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         credentials = credential;
//         valueNotifierHome.incrementNotifier();
//       },
//       forceResendingToken: resendTokenId,
//       verificationFailed: (FirebaseAuthException e) {
//         if (e.code == 'invalid-phone-number') {
//           debugPrint('The provided phone number is not valid.');
//         }
//       },
//       codeSent: (String verificationId, int? resendToken) async {
//         verId = verificationId;
//         resendTokenId = resendToken;
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//     }
//   }
// }
// emailVerify(String email, otpNumber) async {
//   dynamic val;
//   try {
//     var response = await http.post(Uri.parse('${url}api/v1/validate-email-otp'),
//         body: {"email": email, "otp": otpNumber});
//     if (response.statusCode == 200) {
//       if (jsonDecode(response.body)['success'] == true) {
//         val = 'success';
//       } else {
//         debugPrint(response.body);
//         val = 'failed';
//       }
//     } else if (response.statusCode == 422) {
//       debugPrint(response.body);
//       var error = jsonDecode(response.body)['errors'];
//       val = error[error.keys.toList()[0]]
//           .toString()
//           .replaceAll('[', '')
//           .replaceAll(']', '')
//           .toString();
//     } else {
//       val = 'Something went wrong';
//     }
//     return val;
//   } catch (e) {
//     if (e is SocketException) {
//       internet = false;
//     }
//   }
// }

// verifyUser(String number, int login, String password, String email, isOtp,
//     forgot) async {
//   dynamic val;
//   print('drops1 ${url}api/v1/user/validate-mobile-for-login');
//   try {
//     var response = await http.post(
//         Uri.parse('${url}api/v1/user/validate-mobile-for-login'),
//         body: (number != '' && email != '')
//             ? {"mobile": number, "email": email}
//             : (login == 0)
//                 ? {
//                     "mobile": number,
//                   }
//                 : {
//                     "email": number,
//                   });

//     if (response.statusCode == 200) {
//       print('drops2 ');
//       val = jsonDecode(response.body)['success'];
//       if (val == true) {
//         if ((number != '' && email != '') || forgot == true) {
//           print('drops33 ');

//           if (forgot == true) {
//             val = true;
//           } else if (jsonDecode(response.body)['message'] == 'email_exists') {
//             val = 'Email Already Exists';
//           } else if (jsonDecode(response.body)['message'] == 'mobile_exists') {
//             val = 'Mobile Already Exists';
//           } else {
//             val = 'Email and Mobile Already Exists';
//           }
//         } else {
//           print('drops4 ');
//           var check = await userLogin(number, login, password, isOtp);
//           if (check == true) {
//             var uCheck = await getUserDetails();
//             val = uCheck;
//           } else {
//             val = check;
//           }
//         }
//       } else {
//         print('drops5 ');
//         val = false;
//       }
//     } else if (response.statusCode == 422) {
//       print('drops ${response.body}');
//       var error = jsonDecode(response.body)['errors'];
//       val = error[error.keys.toList()[0]]
//           .toString()
//           .replaceAll('[', '')
//           .replaceAll(']', '')
//           .toString();
//     } else {
//       print('drops ${response.body}');
//       val = jsonDecode(response.body)['message'];
//     }
//   } catch (e) {
//     print('drops $e');
//     if (e is SocketException) {
//       val = 'no internet';
//       internet = false;
//     }
//   }
//   return val;
// }
