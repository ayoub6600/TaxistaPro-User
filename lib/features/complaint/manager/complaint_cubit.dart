import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/features/complaint/data/repo/complaint_repo.dart';
import 'package:taxista/features/complaint/manager/complaint_state.dart';
import 'package:taxista/widgets_new/custom_success_toast.dart';

class ComplaintCubit extends Cubit<ComplaintState> {
  final ComplaintRepo repo;

  ComplaintCubit(this.repo) : super(ComplaintState.initial());

  Future<void> getcomplaint() async {
    emit(state.copyWith(status: ComplaintStatus.loading));

    try {
      final response = await repo.getcomplaint();

      response.fold(
        (failure) {
          emit(state.copyWith(
            status: ComplaintStatus.error,
            errorMessage: failure.errMessage,
          ));
        },
        (model) {
          if (model.success == true) {
            final newComplaints = model.data;

            emit(state.copyWith(
              status: ComplaintStatus.loaded,
              newComplaints: newComplaints,
            ));
          } else {
            emit(state.copyWith(
              status: ComplaintStatus.error,
              errorMessage: 'No Complaints available',
            ));
          }
        },
      );
    } catch (error) {
      // Catch any other errors and emit error state
      emit(state.copyWith(
        //status: NotificationStatus.error,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> sendComplaint(
      {required String id, required String description}) async {
    emit(state.copyWith(sendcomplaintStatus: SendcomplaintStatus.loading));

    try {
      final response = await repo.sendComplaint(id, description);

      response.fold(
        (failure) {
          emit(state.copyWith(
            sendcomplaintStatus: SendcomplaintStatus.error,
            errorMessage: failure.errMessage,
          ));
        },
        (success) {
          showCustomSuccessToast(success.message);
          emit(state.copyWith(
            sendcomplaintStatus: SendcomplaintStatus.loaded,
          ));
        },
      );
    } catch (error) {
      emit(state.copyWith(
        sendcomplaintStatus: SendcomplaintStatus.error,
        errorMessage: error.toString(),
      ));
    }
  }
}
