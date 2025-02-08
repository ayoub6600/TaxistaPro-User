// import 'package:carq_employee/Widget/failures.dart';
// import 'package:carq_employee/auth/verifaction/data/model/forgot_response.dart';
// import 'package:carq_employee/auth/verifaction/data/model/forgot_valid_response.dart';
// import 'package:carq_employee/auth/verifaction/data/model/verify_me_response.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';

// enum SendOtpStatus { initial, loading, success, error }

// enum SelectedCountryCodeStatus { selectedCountryCode }

// class SendOtpState extends Equatable {
//   final SendOtpStatus status;
//   final VerifyMeResponse? otpResponse;
//   final ForgotResponse? sendAgain;
//   final ForgotValidResponse? callForgotValid;
//   final TextEditingController phoneController; // Add this field
//   final Failure? failure;
//   final String? selectedCountryCode;

//   const SendOtpState({
//     required this.status,
//     this.otpResponse,
//     this.sendAgain,
//     this.failure,
//     this.selectedCountryCode,
//     this.callForgotValid,
//     required this.phoneController,
//   });

//   // Factory for initial state
//   factory SendOtpState.initial() {
//     return SendOtpState(
//       status: SendOtpStatus.initial,
//       selectedCountryCode: '966', // Set a default country code
//       phoneController: TextEditingController(), // Initialize controller
//     );
//   }

//   // Create a copy of the current state
//   SendOtpState copyWith({
//     SendOtpStatus? status,
//     VerifyMeResponse? otpResponse,
//     ForgotResponse? sendAgain,
//     ForgotValidResponse? callForgotValid,
//     Failure? failure,
//     String? selectedCountryCode,
//     TextEditingController? phoneController,
//   }) {
//     return SendOtpState(
//       status: status ?? this.status,
//       otpResponse: otpResponse ?? this.otpResponse,
//       sendAgain: sendAgain ?? this.sendAgain,
//       callForgotValid: callForgotValid ?? this.callForgotValid,
//       failure: failure ?? this.failure,
//       selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
//       phoneController: phoneController ?? this.phoneController,
//     );
//   }

//   @override
//   List<Object?> get props => [
//         status,
//         otpResponse,
//         sendAgain,
//         failure,
//         callForgotValid,
//         selectedCountryCode,
//         phoneController, // Include in props for equality checks
//       ];
// }

// // Add a dispose method to clean up the TextEditingController
// extension SendOtpStateExtension on SendOtpState {
//   void dispose() {
//     phoneController.dispose();
//   }
// }
