// import 'package:carq_employee/auth/verifaction/data/repo/send_otp_repo.dart';
// import 'package:carq_employee/auth/verifaction/manager/send_otp_state.dart';
// import 'package:carq_employee/constant/show_tost/custom_error_toast.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class SendOtpCubit extends Cubit<SendOtpState> {
//   final SendOtpRepo sendOtpRepo;

//   SendOtpCubit(this.sendOtpRepo) : super(SendOtpState.initial());

//   Future<void> callForgot(
//     Map<String, dynamic> body,
//   ) async {
//     print("---------->1");
//     emit(state.copyWith(status: SendOtpStatus.loading));

//     try {
//       print("---------->2");

//       final result = await sendOtpRepo.callForgot(
//         phone: body['phone_no'],
//         type: body['type'],
//       );
//       print("---------->2$result");
//       result.fold(
//         (failure) {
//           print("---------->3");
//           emit(state.copyWith(status: SendOtpStatus.error, failure: failure));
//           emit(state.copyWith(status: SendOtpStatus.initial));
//         },
//         (responseModel) {
//           print("---------->4");
//           emit(state.copyWith(
//               status: SendOtpStatus.success, sendAgain: responseModel));
//           emit(state.copyWith(status: SendOtpStatus.initial));
//         },
//       );
//     } catch (error) {
//       print("---------->5");
//       emit(state.copyWith(status: SendOtpStatus.error));
//       emit(state.copyWith(status: SendOtpStatus.initial));
//       // Fluttertoast.showToast(msg: error.toString()  );
//     }
//   }
// }
