import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

enum LoginStatus { initial, submitting, success, error }

class LoginState extends Equatable {
  final Failure failure;
  final LoginStatus loginStatus;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final String? selectedCountryCode; // Add selectedCountryCode field
  final LoginResponse? modelData; // Add modelData field
  final bool isObscureText; // Add isObscureText field

  const LoginState({
    required this.failure,
    required this.loginStatus,
    required this.phoneController,
    required this.passwordController,
    this.selectedCountryCode,
    this.modelData, // Initialize modelData in the constructor
    this.isObscureText = true,
  });

  factory LoginState.initial() {
    return LoginState(
      failure: const Failure(""),
      loginStatus: LoginStatus.initial,
      phoneController: TextEditingController(),
      passwordController: TextEditingController(),
      selectedCountryCode: '966', // Set a default country code
      modelData: null, // Initialize modelData to null
      isObscureText: true,
    );
  }

  @override
  List<Object?> get props => [
        failure,
        loginStatus,
        phoneController,
        passwordController,
        selectedCountryCode,
        modelData, // Add modelData to the props list
        isObscureText,
      ];

  LoginState copyWith({
    Failure? failure,
    LoginStatus? loginStatus,
    TextEditingController? phoneController,
    TextEditingController? passwordController,
    String? selectedCountryCode,
    LoginResponse? modelData, // Include modelData in copyWith
    bool? isObscureText,
  }) {
    return LoginState(
      failure: failure ?? this.failure,
      loginStatus: loginStatus ?? this.loginStatus,
      phoneController: phoneController ?? this.phoneController,
      passwordController: passwordController ?? this.passwordController,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      modelData: modelData ?? this.modelData, // Handle copying of modelData
      isObscureText: isObscureText ?? this.isObscureText,
    );
  }
}
