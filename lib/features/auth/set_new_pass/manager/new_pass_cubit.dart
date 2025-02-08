// import 'package:carq_employee/Utils/preferences_names.dart';
// import 'package:carq_employee/Utils/shared_preferences.dart';
// import 'package:carq_employee/auth/login/data/model/login_model.dart';
// import 'package:carq_employee/auth/set_new_pass/data/repo/new_pass_repo.dart';
// import 'package:carq_employee/auth/set_new_pass/manager/new_pass_state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class NewPassWordCubit extends Cubit<NewPasswordState> {
//   final NewPassRepo repo;

//   NewPassWordCubit(this.repo) : super(NewPasswordState.initial());

//   void updatePassword({
//     required String phone,
//   }) async {
//     // Check if the required fields are empty

//     // Emit a submitting state to reflect loading
//     emit(state.copyWith(newPasswordStatus: NewPasswordStatus.submitting));

//     try {
//       // Call the repository to update the password
//       var result = await repo.updatePasswordRepo(
//         newPassword: state.newPasswordController.text,
//         phone: phone,
//         type: '2',
//       );

//       result.fold(
//         (failure) {
//           emit(state.copyWith(
//             failure: failure,
//             newPasswordStatus: NewPasswordStatus.error,
//           ));
//           emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
//         },
//         (model) async {
//           if (model.success == true) {
//             if (model.data != null && model.data!.token != null) {
//               await setData(model.data!);
//             }
//           }

//           emit(state.copyWith(newPasswordStatus: NewPasswordStatus.success));
//           emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
//         },
//       );
//     } catch (e) {
//       emit(state.copyWith(newPasswordStatus: NewPasswordStatus.error));
//       emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
//     }
//   }

//   void togglePasswordVisibility() {
//     emit(state.copyWith(isObscureText: !state.isObscureText));
//   }

//   void toggleConfirmPasswordVisibility() {
//     emit(state.copyWith(isObscureConfirmText: !state.isObscureConfirmText));
//   }

//   setData(LoginData data) {
//     SharedPreferenceHelper.setBoolean(PreferencesNames.isLogin, true);
//     SharedPreferenceHelper.setString(
//         PreferencesNames.authToken, data.token ?? "");
//     SharedPreferenceHelper.setString(PreferencesNames.imageUrl, data.imageUri!);
//     SharedPreferenceHelper.setString(PreferencesNames.phoneNo, data.phoneNo!);
//     SharedPreferenceHelper.setString(PreferencesNames.userName, data.name!);
//     SharedPreferenceHelper.setString(PreferencesNames.email, data.email!);
//     // if (context.mounted)
//     //   Navigator.of(context).pushReplacement(
//     //       MaterialPageRoute(builder: (context) => const HomeScreen()));
//     // if (response.msg != null) {
//     //   DeviceUtils.toastMessage(response.msg!);
//     // }
//   }
// }
