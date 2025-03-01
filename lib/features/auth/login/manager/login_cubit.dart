import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/features/auth/login/manager/login_state.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/loadingPage/loadingpage.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepo repo;

  LoginCubit(this.repo) : super(LoginState.initial());
  String? fcmToken;
  void loginMethod() async {
    print(
        "--------->${SharedPreferenceUtil.getString(PrefKey.currentLanguageCode)}");
    emit(state.copyWith(loginStatus: LoginStatus.submitting));

    var result = await repo.loginMethod(
      phone: state.phoneController.text,
      password: state.passwordController.text,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(failure: failure, loginStatus: LoginStatus.error));

        emit(state.copyWith(loginStatus: LoginStatus.initial));
      },
      (model) async {
        if (model.accessToken != null) {
          if (model.accessToken != null && model.tokenType != null) {
            await setData(model);
          }
          print("token ${model.accessToken}");
          print("token ${SharedPreferenceUtil.getString(PrefKey.login)}");
          getUserData();
        }

        emit(
            state.copyWith(loginStatus: LoginStatus.success, modelData: model));
        emit(state.copyWith(loginStatus: LoginStatus.initial));
        package = await PackageInfo.fromPlatform();
        if (platform == TargetPlatform.android && package != null) {
          await FirebaseDatabase.instance.ref().update({
            'user_package_name': package.packageName.toString()
          }); // تحديث قاعدة البيانات
        } else if (package != null) {
          await FirebaseDatabase.instance
              .ref()
              .update({'user_bundle_id': package.packageName.toString()});
        }
      },
    );
  }

  void getUserData() async {
    var result = await repo.getUserData();
    result.fold(
      (failure) {
        emit(state.copyWith(failure: failure));
      },
      (model) {
        saveData(model);
        emit(state.copyWith());
      },
    );
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(isObscureText: !state.isObscureText));
  }

  setData(LoginResponce data) {
    SharedPreferenceUtil.putString(PrefKey.login, data.accessToken!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginType, data.tokenType!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginExpire, data.expiresIn!.toString());

    SharedPreferenceUtil.putBool(PrefKey.isLoggedIn, true);
  }

  saveData(UserProfile data) {
    SharedPreferenceUtil.putInt(PrefKey.userId, data.data.id);
    SharedPreferenceUtil.putString(PrefKey.email, data.data.email);
    SharedPreferenceUtil.putString(PrefKey.fullName, data.data.name);
    SharedPreferenceUtil.putString(PrefKey.mobile, data.data.mobile);
    SharedPreferenceUtil.putString(PrefKey.gender, data.data.gender);
    SharedPreferenceUtil.putString(
        PrefKey.profileImage, data.data.profilePicture);
  }
}
