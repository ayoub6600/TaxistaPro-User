import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/verifaction/data/model/verify_me_response.dart';
import 'package:taxista/widgets_new/failures.dart';

enum VerifyUserStates { initial, submitting, success, error }

class VerifyUserState extends Equatable {
  final Failure failure;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final VerifyUserStates verifyUserStates;
  final ForgotResponse? modelData;

  const VerifyUserState({
    required this.failure,
    required this.phoneController,
    required this.emailController,
    required this.verifyUserStates,
    this.modelData,
  });

  // Factory constructor for initial state
  factory VerifyUserState.initial() {
    return VerifyUserState(
      failure: const Failure(""),
      verifyUserStates: VerifyUserStates.initial,
      phoneController: TextEditingController(),
      emailController: TextEditingController(),
      modelData: null,
    );
  }

  @override
  List<Object?> get props => [
        failure,
        phoneController
            .text, // Use text instead of controller to avoid redundancy
        emailController.text,
        modelData,
        verifyUserStates,
      ];

  // Copy with method for state updates
  VerifyUserState copyWith({
    Failure? failure,
    TextEditingController? phoneController,
    TextEditingController? emailController,
    ForgotResponse? modelData,
    VerifyUserStates? VerifyUserStates,
    bool? isSubmitting,
  }) {
    return VerifyUserState(
      failure: failure ?? this.failure,
      phoneController: phoneController ?? this.phoneController,
      emailController: emailController ?? this.emailController,
      modelData: modelData ?? this.modelData,
      verifyUserStates: VerifyUserStates ?? this.verifyUserStates,
    );
  }

  // Dispose controllers to avoid memory leaks
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
  }
}
