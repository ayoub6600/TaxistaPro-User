import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/features/profail/data/model/user_data_responce.dart';
import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class GetUserData {
  final ApiService apiService;

  GetUserData(this.apiService);

  Future<Either<Failure, UserProfile>> getUserData() async {
    try {
      var response = await apiService.get(
        endPoint: 'api/v1/user',
      );

      if (200 <= response.code && response.code <= 300) {
        UserProfile userData = UserProfile.fromJson(response.data);

        return right(userData);
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
