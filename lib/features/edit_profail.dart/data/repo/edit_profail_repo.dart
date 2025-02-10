import 'package:dartz/dartz.dart';
import 'package:taxista/features/edit_profail.dart/data/model/edit_profile_response.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class UdateProfailRepo {
  Future<Either<Failure, UpdateProfile>> updateProfileMethod({
    required String name,
    required String email,
    required String gender,
    required String profileImageFile,
  });
}
