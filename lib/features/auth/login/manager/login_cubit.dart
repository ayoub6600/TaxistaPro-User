import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/features/auth/login/manager/login_state.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/loadingPage/loadingpage.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepo repo;

  LoginCubit(this.repo) : super(LoginState.initial());
  String? fcmToken;
  void loginMethod() async {
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
        if (model.success == true) {
          if (model.data != null && model.data!.token != null) {
            await setData(model.data!);
          }
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

  void togglePasswordVisibility() {
    emit(state.copyWith(isObscureText: !state.isObscureText));
  }

  setData(LoginResponseData data) {
    SharedPreferenceUtil.putString(PrefKey.login, data.token!.toString());
    SharedPreferenceUtil.putString(PrefKey.fullName, data.name!);
    SharedPreferenceUtil.putString(PrefKey.mobile, data.phoneNo!);
    SharedPreferenceUtil.putString(PrefKey.email, data.email!);
    SharedPreferenceUtil.putString(PrefKey.profileImage, data.imageUri!);
    // if (SharedPreferenceUtil.getString(PrefKey.currentLanguageCode) == '') {
    //   SharedPreferenceUtil.putString(PrefKey.currentLanguageCode, 'ar');
    // }
    SharedPreferenceUtil.putInt(PrefKey.userId, data.id!);
    SharedPreferenceUtil.putString(PrefKey.fcmToken, data.fcmToken ?? '');
    SharedPreferenceUtil.putString(PrefKey.gender, data.gender!);
    SharedPreferenceUtil.putBool(PrefKey.isLoggedIn, true);
  }
}
