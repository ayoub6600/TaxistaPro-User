import 'package:dartz/dartz.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/verifaction/data/model/verify_me_response.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class VerifyUserRepo {
  Future<Either<Failure, ForgotResponse>> verifyUser({
    required String mobile,
  });
}
