import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_state.dart';

class VerifyUserCubit extends Cubit<VerifyUserState> {
  final VerifyUserRepo verifyUserRepo;

  VerifyUserCubit({required this.verifyUserRepo})
      : super(VerifyUserState.initial());

  Future<void> verifyUser() async {
    emit(state.copyWith(VerifyUserStates: VerifyUserStates.submitting));
    final result = await verifyUserRepo.verifyUser(
      mobile: state.phoneController.text,
    );

    result.fold((failure) {
      emit(state.copyWith(
          failure: failure, VerifyUserStates: VerifyUserStates.error));

      emit(state.copyWith(VerifyUserStates: VerifyUserStates.initial));
    }, (response) {
      emit(state.copyWith(
          modelData: response, VerifyUserStates: VerifyUserStates.success));
      emit(state.copyWith(VerifyUserStates: VerifyUserStates.initial));
    });
  }

  @override
  Future<void> close() {
    state.phoneController.dispose();
    state.emailController.dispose();
    return super.close();
  }
}
