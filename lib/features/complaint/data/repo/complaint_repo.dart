import 'package:dartz/dartz.dart';
import 'package:taxista/features/complaint/data/model/complaint_response.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class ComplaintRepo {
  Future<Either<Failure, ComplaintResponse>> getcomplaint();
  Future<Either<Failure, RemoveAddressResponse>> sendComplaint(
      String id, String description);
}
