import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/manager_address/data/model/remove_address_response.dart';
import 'package:taxista/features/notification/data/model/notifaication_model.dart';
import 'package:taxista/features/notification/data/repo/notification_repo.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class NotificationRepoImp implements NotificationRepo {
  final ApiService apiService;

  NotificationRepoImp({required this.apiService});

  @override
  Future<Either<Failure, NotificationResponse>> getNotification() async {
    try {
      var response = await apiService.get(
          endPoint: 'api/v1/notifications/get-notification');
      if (200 <= response.code && response.code <= 300) {
        var model = NotificationResponse.fromJson(response.data);
        // print(".....-----------------${model.data?.oldestNotifications?.length}");

        return right(model);
      } else {
        return left(Failure(response.errorMessage));
      }
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RemoveAddressResponse>> removeNotification(
      {required String id}) async {
    try {
      var response = await apiService.delete(
        endPoint: 'api/v1/notifications/delete-notification/$id',
      );
      if (200 <= response.code && response.code <= 300) {
        var model = RemoveAddressResponse.fromJson(response.data);
        return right(model);
      } else {
        return left(Failure(response.errorMessage));
      }
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioError(e));
      }
      return left(ServerFailure(e.toString()));
    }
  }
}
