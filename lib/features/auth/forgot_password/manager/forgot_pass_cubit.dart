import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_state.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/functions/functions.dart';
import 'package:taxista/pages/loadingPage/loadingpage.dart';

class VerifyUserCubit extends Cubit<VerifyUserState> {
  final VerifyUserRepo verifyUserRepo;

  VerifyUserCubit({required this.verifyUserRepo})
      : super(VerifyUserState.initial());

  /// ✅ تحقق من المستخدم وإرسال OTP عند نجاح التحقق
  Future<void> verifyUser() async {
    emit(state.copyWith(verifyUserStates: VerifyUserStates.submitting));

    final result = await verifyUserRepo.verifyUser(
      mobile: state.phoneController.text,
    );

    result.fold((failure) {
      emit(state.copyWith(
          failure: failure, verifyUserStates: VerifyUserStates.error));

      emit(state.copyWith(verifyUserStates: VerifyUserStates.initial));
    }, (response) async {
      emit(state.copyWith(
          modelData: response, verifyUserStates: VerifyUserStates.success));

      // ✅ تأكد من إتمام التحقق قبل إرسال OTP

      emit(state.copyWith(verifyUserStates: VerifyUserStates.initial));
    });
  }

  /// ✅ إرسال رمز OTP إلى رقم الهاتف
  Future<void> sendOTPtoMobile(
      {required String mobile, required String countryCode}) async {
    emit(
        state.copyWith(sendOTPtoMobileState: SendOTPtoMobileStates.submitting));

    final result = await verifyUserRepo.sendOTPtoMobile(
        mobile: mobile, countryCode: countryCode);

    result.fold((failure) {
      emit(state.copyWith(
          failure: failure, sendOTPtoMobileState: SendOTPtoMobileStates.error));
      emit(state.copyWith(sendOTPtoMobileState: SendOTPtoMobileStates.initial));
    }, (response) {
      emit(state.copyWith(
          modelData: response,
          sendOTPtoMobileState: SendOTPtoMobileStates.success));
      emit(state.copyWith(sendOTPtoMobileState: SendOTPtoMobileStates.initial));
    });
  }

  void callForgot({
    required String mobile,
    required String otp,
  }) async {
    emit(
        state.copyWith(sendOTPtoMobileState: SendOTPtoMobileStates.submitting));

    var result = await verifyUserRepo.callForgot(
      otp: otp,
      mobile: mobile,
    );
    result.fold(
      (failure) {
        emit(state.copyWith(
            failure: failure,
            sendOTPtoMobileState: SendOTPtoMobileStates.error));

        // emit(state.copyWith(
        //     sendOTPtoMobileState: SendOTPtoMobileStates.initial));
      },
      (model) async {
        if (model.accessToken != null) {
          if (model.accessToken != null && model.tokenType != null) {
            await setData(model);
          }
        }

        emit(state.copyWith(
            sendOTPtoMobileState: SendOTPtoMobileStates.success,
            loginResponce: model));
        // emit(state.copyWith(
        //     sendOTPtoMobileState: SendOTPtoMobileStates.initial));
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

  setData(LoginResponce data) {
    SharedPreferenceUtil.putString(PrefKey.login, data.accessToken!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginType, data.tokenType!.toString());
    SharedPreferenceUtil.putString(
        PrefKey.loginExpire, data.expiresIn!.toString());

    SharedPreferenceUtil.putBool(PrefKey.isLoggedIn, true);
  }

  @override
  Future<void> close() {
    state.phoneController.dispose();
    state.emailController.dispose();
    return super.close();
  }
}
