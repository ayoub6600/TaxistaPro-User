import 'package:dartz/dartz.dart';
import 'package:taxista/features/auth/login/data/model/login_response_model.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class CreatAccountRepo {
  Future<Either<Failure, LoginResponce>> creatAccountMethod({
    required String name,
    required String email,
    required String mobile,
    required String country,
    required String gender,
    required String password,
  });

  Future<Either<Failure, List<dynamic>>> getCountryCode();
}
