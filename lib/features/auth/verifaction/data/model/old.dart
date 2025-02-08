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
