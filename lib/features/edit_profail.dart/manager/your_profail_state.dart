import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/widgets_new/failures.dart';

enum UpdateProfileStatus { initial, submitting, success, error, updatingimage }

class UpdateProfileState extends Equatable {
  final Failure failure;
  final UpdateProfileStatus updateProfileStatus;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String gender; // New gender field
  final File image;

  const UpdateProfileState({
    required this.failure,
    required this.updateProfileStatus,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.gender, // Add gender to the constructor
    required this.image,
  });

  factory UpdateProfileState.initial() {
    return UpdateProfileState(
      failure: const Failure(""),
      updateProfileStatus: UpdateProfileStatus.initial,
      nameController: TextEditingController(
          text: SharedPreferenceUtil.getString(PrefKey.fullName)),
      emailController: TextEditingController(
          text: SharedPreferenceUtil.getString(PrefKey.email)),
      phoneController: TextEditingController(
          text: SharedPreferenceUtil.getString(PrefKey.mobile)),
      gender: "male",
      // Default gender value
      image: File(''),
    );
  }

  @override
  List<Object?> get props => [
        failure,
        updateProfileStatus,
        nameController,
        emailController,
        phoneController,
        gender, // Add gender to props
        image,
      ];

  UpdateProfileState copyWith({
    Failure? failure,
    UpdateProfileStatus? updateProfileStatus,
    TextEditingController? nameController,
    TextEditingController? emailController,
    TextEditingController? phoneController,
    String? gender, // Add gender to copyWith
    File? image,
  }) {
    return UpdateProfileState(
      failure: failure ?? this.failure,
      updateProfileStatus: updateProfileStatus ?? this.updateProfileStatus,
      nameController: nameController ?? this.nameController,
      emailController: emailController ?? this.emailController,
      phoneController: phoneController ?? this.phoneController,
      gender: gender ?? this.gender,
      image: image ?? this.image,
    );
  }
}
