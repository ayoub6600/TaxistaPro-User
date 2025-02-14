import 'package:equatable/equatable.dart';
import 'package:taxista/features/notification/data/model/notifaication_model.dart';
import 'package:taxista/widgets_new/failures.dart';

// Enum to define different notification statuses
enum NotificationStatus { initial, loading, loaded, error }

enum RemoveNotifactionStatus { initial, loading, loaded, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final RemoveNotifactionStatus removeNotifactionStatus;
  final List<NotificationData> newNotifications;
  final Failure? failure;

  final String? errorMessage;

  const NotificationState({
    required this.status,
    this.removeNotifactionStatus = RemoveNotifactionStatus.initial,
    this.newNotifications = const [],
    this.errorMessage,
    this.failure,
  });

  // Initial state
  factory NotificationState.initial() {
    return const NotificationState(
      status: NotificationStatus.initial,
      removeNotifactionStatus: RemoveNotifactionStatus.initial,
      newNotifications: [],
      errorMessage: null,
      failure: null,
    );
  }

  NotificationState copyWith({
    NotificationStatus? status,
    RemoveNotifactionStatus? removeNotifactionStatus,
    List<NotificationData>? newNotifications,
    String? errorMessage,
    Failure? failure,
  }) {
    return NotificationState(
      status: status ?? this.status,
      newNotifications: newNotifications ?? this.newNotifications,
      removeNotifactionStatus:
          removeNotifactionStatus ?? this.removeNotifactionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      failure: failure,
    );
  }

  // Override the toString method for better logging/debugging
  @override
  String toString() {
    return 'NotificationState(status: $status, newNotifications: ${newNotifications.length},    errorMessage: $errorMessage, removeNotifactionStatus: $removeNotifactionStatus , failure: $failure)';
  }

  // Equatable props to allow comparison of states
  @override
  List<Object?> get props => [
        status,
        newNotifications,
        errorMessage,
        removeNotifactionStatus,
        failure
      ];
}
