import 'package:dartz/dartz.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class MangerAddressRepo {
  Future<Either<Failure, UserProfile>> getUserData();
  Future<Either<Failure, RemoveAddressResponse>> removeAddress(
      {required int id});
  Future<Either<Failure, dynamic>> addAddress({
    required String name,
    required String lat,
    required String lng,
    required String add,
  });
}
