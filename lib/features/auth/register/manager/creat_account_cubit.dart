import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';

import 'package:taxista/features/auth/register/data/repo/creat_account_repo.dart';
import 'package:taxista/features/auth/register/manager/creat_account_state.dart';

class CreateAccountCubit extends Cubit<CreateAccountState> {
  final CreatAccountRepo repo;

  CreateAccountCubit(this.repo) : super(CreateAccountState.initial());
  void setGender(String gender) {
    emit(state.copyWith(gender: gender));
  }

  void createAccount() async {
    emit(state.copyWith(createAccountStatus: CreateAccountStatus.submitting));

    var result = await repo.creatAccountMethod(
      name: state.nameController.text,
      email: state.emailController.text,
      mobile: state.phoneController.text,
      country: "+218",
      gender: state.gender,
      password: state.passwordController.text,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          failure: failure,
          createAccountStatus: CreateAccountStatus.error,
        ));
        emit(state.copyWith(createAccountStatus: CreateAccountStatus.initial));
      },
      (model) {
        emit(state.copyWith(
            createAccountStatus: CreateAccountStatus.success,
            modelData: model));

        emit(state.copyWith(createAccountStatus: CreateAccountStatus.initial));
        setData(model);
      },
    );
  }

  setData(LoginResponce data) {
    SharedPreferenceUtil.putString(PrefKey.login, data.accessToken!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginType, data.tokenType!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginExpire, data.expiresIn!.toString());

    SharedPreferenceUtil.putBool(PrefKey.isLoggedIn, true);
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isObscureText: !state.isObscureText));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(isObscureConfirmText: !state.isObscureConfirmText));
  }
}
