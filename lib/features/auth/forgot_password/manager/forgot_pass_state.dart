import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

enum VerifyUserStates { initial, submitting, success, error }

enum SendOTPtoMobileStates { initial, submitting, success, error }

enum CallForgotValidStates { initial, submitting, success, error }

class VerifyUserState extends Equatable {
  final Failure failure;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final VerifyUserStates verifyUserStates;
  final CallForgotValidStates callForgotValidStates;
  final LoginResponce? loginResponce; // Add modelData field

  final SendOTPtoMobileStates sendOTPtoMobileState;
  final ForgotResponse? modelData;

  const VerifyUserState({
    required this.failure,
    required this.phoneController,
    required this.emailController,
    required this.callForgotValidStates,
    required this.loginResponce,
    required this.verifyUserStates,
    required this.sendOTPtoMobileState,
    this.modelData,
  });

  // ✅ Factory constructor لإنشاء الحالة الأولية
  factory VerifyUserState.initial() {
    return VerifyUserState(
      failure: const Failure(""),
      verifyUserStates: VerifyUserStates.initial,
      callForgotValidStates: CallForgotValidStates.initial,
      loginResponce: null,
      phoneController: TextEditingController(),
      emailController: TextEditingController(),
      sendOTPtoMobileState: SendOTPtoMobileStates.initial,
      modelData: null,
    );
  }

  @override
  List<Object?> get props => [
        failure,
        phoneController
            .text, // ✅ استخدام `text` لضمان إعادة بناء الواجهة عند التغيير
        emailController.text,
        callForgotValidStates,
        loginResponce,
        modelData,
        verifyUserStates,
        sendOTPtoMobileState,
      ];

  // ✅ تحديث الحالة باستخدام `copyWith`
  VerifyUserState copyWith({
    Failure? failure,
    TextEditingController? phoneController,
    TextEditingController? emailController,
    CallForgotValidStates? callForgotValidStates,
    LoginResponce? loginResponce,
    ForgotResponse? modelData,
    VerifyUserStates? verifyUserStates,
    SendOTPtoMobileStates? sendOTPtoMobileState,
  }) {
    return VerifyUserState(
      failure: failure ?? this.failure,
      phoneController: phoneController ?? this.phoneController,
      loginResponce: loginResponce ?? this.loginResponce,
      callForgotValidStates:
          callForgotValidStates ?? this.callForgotValidStates,
      emailController: emailController ?? this.emailController,
      sendOTPtoMobileState: sendOTPtoMobileState ?? this.sendOTPtoMobileState,
      modelData: modelData ?? this.modelData,
      verifyUserStates: verifyUserStates ?? this.verifyUserStates,
    );
  }

  // ✅ تنظيف موارد الإدخال لتجنب تسريب الذاكرة
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
  }
}
