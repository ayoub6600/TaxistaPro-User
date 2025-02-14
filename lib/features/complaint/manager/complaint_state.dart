import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taxista/features/complaint/data/model/complaint_response.dart';

enum ComplaintStatus {
  initial,
  loading,
  loaded,
  error,
}

enum SendcomplaintStatus {
  initial,
  loading,
  loaded,
  error,
}

class ComplaintState extends Equatable {
  final ComplaintStatus status;
  final SendcomplaintStatus sendcomplaintStatus;
  final TextEditingController descriptionController;
  final List<Complaint>
      complaints; // Replace `Complaint` with the actual complaint model type
  final String errorMessage;

  // Constructor
  const ComplaintState({
    required this.status,
    this.complaints = const [],
    required this.descriptionController,
    this.errorMessage = '',
    required this.sendcomplaintStatus,
  });

  // Initial state
  factory ComplaintState.initial() {
    return ComplaintState(
      status: ComplaintStatus.initial,
      descriptionController: TextEditingController(),
      complaints: const [],
      errorMessage: '',
      sendcomplaintStatus: SendcomplaintStatus.initial,
    );
  }

  // Copy method to update state
  ComplaintState copyWith({
    ComplaintStatus? status,
    List<Complaint>? newComplaints,
    String? errorMessage,
    TextEditingController? descriptionController,
    SendcomplaintStatus? sendcomplaintStatus,
  }) {
    return ComplaintState(
      status: status ?? this.status,
      complaints: newComplaints ?? this.complaints,
      descriptionController:
          descriptionController ?? this.descriptionController,
      errorMessage: errorMessage ?? this.errorMessage,
      sendcomplaintStatus: sendcomplaintStatus ?? this.sendcomplaintStatus,
    );
  }

  @override
  List<Object> get props => [
        status,
        complaints,
        errorMessage,
        sendcomplaintStatus,
        descriptionController
      ];
}
