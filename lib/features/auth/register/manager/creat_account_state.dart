import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

enum CreateAccountStatus { initial, submitting, success, error }

class CreateAccountState extends Equatable {
  final bool isObscureConfirmText;
  final bool isObscureText;
  final Failure failure;
  final CreateAccountStatus createAccountStatus;
  final String? selectedCountryCode;
  final LoginResponce modelData;
  final String gender; // Added gender field

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;

  const CreateAccountState({
    required this.failure,
    required this.createAccountStatus,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    this.selectedCountryCode,
    required this.modelData,
    this.isObscureText = true,
    this.isObscureConfirmText = true,
    this.gender = 'male',
  });

  factory CreateAccountState.initial() {
    return CreateAccountState(
      isObscureText: true,
      isObscureConfirmText: true,
      failure: const Failure(""),
      createAccountStatus: CreateAccountStatus.initial,
      nameController: TextEditingController(),
      emailController: TextEditingController(),
      phoneController: TextEditingController(),
      passwordController: TextEditingController(),
      selectedCountryCode: '966',
      gender: 'male',
      modelData: LoginResponce(), // Make sure this is initialized correctly
    );
  }

  @override
  List<Object?> get props => [
        failure,
        createAccountStatus,
        selectedCountryCode,
        modelData,
        isObscureText,
        isObscureConfirmText,
        gender
      ];

  CreateAccountState copyWith({
    bool? isObscureText,
    bool? isObscureConfirmText,
    Failure? failure,
    CreateAccountStatus? createAccountStatus,
    String? selectedCountryCode,
    LoginResponce? modelData,
    String? gender, // Added gender field

    // You might consider returning TextEditingController values instead of instances
  }) {
    return CreateAccountState(
      isObscureText: isObscureText ?? this.isObscureText,
      isObscureConfirmText: isObscureConfirmText ?? this.isObscureConfirmText,
      failure: failure ?? this.failure,
      createAccountStatus: createAccountStatus ?? this.createAccountStatus,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      modelData: modelData ?? this.modelData,
      nameController: nameController,
      emailController: emailController,
      phoneController: phoneController,
      passwordController: passwordController,
      gender: gender ?? this.gender, // Use new gender value
    );
  }
}
