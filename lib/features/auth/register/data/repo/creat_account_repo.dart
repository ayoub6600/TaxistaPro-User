import 'package:dartz/dartz.dart';
import 'package:taxista/features/auth/register/data/model/register_model.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class CreatAccountRepo {
  Future<Either<Failure, RegisterResponseModel>> creatAccountMethod({
    required String name,
    required String email,
    required String mobile,
    required String country,
    required String gender,
    required String password,
  });
}
