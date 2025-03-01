import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/features/auth/set_new_pass/data/repo/new_pass_repo.dart';
import 'package:taxista/features/auth/set_new_pass/manager/new_pass_state.dart';

class NewPassWordCubit extends Cubit<NewPasswordState> {
  final NewPassRepo repo;

  NewPassWordCubit(this.repo) : super(NewPasswordState.initial());

  void updatePassword({
    required String phone,
  }) async {
    // Check if the required fields are empty

    // Emit a submitting state to reflect loading
    emit(state.copyWith(newPasswordStatus: NewPasswordStatus.submitting));

    try {
      // Call the repository to update the password
      var result = await repo.updatePassword(
        password: state.newPasswordController.text,
        mobile: phone,
      );

      result.fold(
        (failure) {
          emit(state.copyWith(
            failure: failure,
            newPasswordStatus: NewPasswordStatus.error,
          ));
          emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
        },
        (model) async {
          setData(model);

          emit(state.copyWith(newPasswordStatus: NewPasswordStatus.success));
          emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
        },
      );
    } catch (e) {
      emit(state.copyWith(newPasswordStatus: NewPasswordStatus.error));
      emit(state.copyWith(newPasswordStatus: NewPasswordStatus.initial));
    }
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isObscureText: !state.isObscureText));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(isObscureConfirmText: !state.isObscureConfirmText));
  }

  setData(LoginResponce data) {
    SharedPreferenceUtil.putString(PrefKey.login, data.accessToken!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginType, data.tokenType!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginExpire, data.expiresIn!.toString());

    SharedPreferenceUtil.putBool(PrefKey.isLoggedIn, true);
  }
}
