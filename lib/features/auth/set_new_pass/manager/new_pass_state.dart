// import 'package:carq_employee/Widget/failures.dart';
// import 'package:carq_employee/auth/login/data/model/login_model.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';

// enum NewPasswordStatus { initial, submitting, success, error }

// class NewPasswordState extends Equatable {
//   final bool isObscureConfirmText;
//   final bool isObscureText;
//   final NewPasswordStatus newPasswordStatus;
//   final Failure? failure;
//   final TextEditingController newPasswordController;
//   final TextEditingController phoneController;
//   final LoginResponse? modelData;

//   const NewPasswordState({
//     required this.newPasswordStatus,
//     required this.newPasswordController,
//     required this.phoneController,
//     this.isObscureText = true,
//     this.isObscureConfirmText = true,
//     this.modelData,

//     // Default to true (password hidden)
//     this.failure,
//   });

//   factory NewPasswordState.initial() {
//     return NewPasswordState(
//       newPasswordStatus: NewPasswordStatus.initial,
//       newPasswordController: TextEditingController(),
//       phoneController: TextEditingController(),
//       isObscureText: true,
//       isObscureConfirmText: true,
//       modelData: null,
//     );
//   }

//   NewPasswordState copyWith({
//     bool? isObscureText,
//     bool? isObscureConfirmText,
//     NewPasswordStatus? newPasswordStatus,
//     Failure? failure,
//     TextEditingController? newPasswordController,
//     TextEditingController? phoneController,
//     LoginResponse? modelData,
//   }) {
//     return NewPasswordState(
//       newPasswordStatus: newPasswordStatus ?? this.newPasswordStatus,
//       failure: failure ?? this.failure,
//       newPasswordController:
//           newPasswordController ?? this.newPasswordController,
//       phoneController: phoneController ?? this.phoneController,
//       isObscureText: isObscureText ?? this.isObscureText,
//       isObscureConfirmText: isObscureConfirmText ?? this.isObscureConfirmText,
//       modelData: modelData ?? this.modelData,
//     );
//   }

//   @override
//   List<Object?> get props => [
//         newPasswordStatus,
//         failure,
//         newPasswordController,
//         phoneController,
//         isObscureText,
//         isObscureConfirmText,
//         modelData,
//       ];
// }
