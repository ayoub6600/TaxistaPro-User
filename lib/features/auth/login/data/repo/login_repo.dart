import 'package:dartz/dartz.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class LoginRepo {
  Future<Either<Failure, LoginResponce>> loginMethod({
    required String phone,
    required String password,
  });
}
