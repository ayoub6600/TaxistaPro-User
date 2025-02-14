import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/features/notification/data/repo/notification_repo.dart';
import 'package:taxista/features/notification/manager/notifaication_state.dart';
import 'package:taxista/widgets_new/custom_error_toast.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo repo;

  NotificationCubit(this.repo) : super(NotificationState.initial());

  Future<void> getNotification() async {
    emit(state.copyWith(status: NotificationStatus.loading));

    try {
      // Fetch notifications from the repository
      final response = await repo.getNotification();

      // Handle the result using fold to manage success or failure
      response.fold(
        (failure) {
          // Emit error state if the request fails
          emit(state.copyWith(
            status: NotificationStatus.error,
            errorMessage: failure.errMessage,
          ));
        },
        (model) {
          // print("--------------------...>${model.code}");
          // Check if data is available and successful
          if (model.success == true) {
            // Access the notification lists from NotificationData
            final newNotifications = model.data;

            // Emit a success state with the fetched notification lists
            emit(state.copyWith(
              status: NotificationStatus.loaded,
              newNotifications: newNotifications,
            ));
          } else {
            // Emit an error state if no data is returned
            emit(state.copyWith(
              status: NotificationStatus.error,
              errorMessage: 'No notifications available',
            ));
          }
        },
      );
    } catch (error) {
      // Catch any other errors and emit error state
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: error.toString(),
      ));
    }
  }

  void removeNotifaction({required String id}) async {
    emit(state.copyWith(
        removeNotifactionStatus: RemoveNotifactionStatus.initial));

    var result = await repo.removeNotification(
      id: id,
    );
    result.fold((failure) {
      emit(state.copyWith(
        failure: failure,
        removeNotifactionStatus: RemoveNotifactionStatus.error,
      ));
      showCustomErrorToast(state.failure?.errMessage ?? "");
    }, (model) {
      emit(state.copyWith(
        removeNotifactionStatus: RemoveNotifactionStatus.loaded,
      ));
      showCustomSuccessToast(model.message);
      getNotification();
    });
  }
}
