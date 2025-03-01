import 'package:dartz/dartz.dart';
import 'package:taxista/features/auth/forgot_password/data/model/forgot_response.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class VerifyUserRepo {
  Future<Either<Failure, ForgotResponse>> verifyUser({
    required String mobile,
  });
  Future<Either<Failure, ForgotResponse>> sendOTPtoMobile({
    required String mobile,
    required String countryCode,
  });
  Future<Either<Failure, LoginResponce>> callForgot({
    required String mobile,
    required String otp,
  });
}
