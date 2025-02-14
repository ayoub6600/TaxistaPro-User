import 'package:dartz/dartz.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/features/notification/data/model/notifaication_model.dart';
import 'package:taxista/widgets_new/failures.dart';

abstract class NotificationRepo {
  Future<Either<Failure, NotificationResponse>> getNotification();
  Future<Either<Failure, RemoveAddressResponse>> removeNotification(
      {required String id});
}
