import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:taxista/features/edit_profail.dart/data/model/edit_profile_response.dart';

import 'package:taxista/features/edit_profail.dart/data/repo/edit_profail_repo.dart';

import 'package:taxista/widgets_new/api_service.dart';
import 'package:taxista/widgets_new/failures.dart';

class UdateProfailRepoImp implements UdateProfailRepo {
  final ApiService apiService;

  UdateProfailRepoImp({required this.apiService});

  @override
  Future<Either<Failure, UpdateProfile>> updateProfileMethod({
    required String name,
    required String email,
    String? profileImageFile,
    required String gender,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'name': name,
        'email': email,
        'gender': gender,
      });

      if (profileImageFile != null &&
          profileImageFile.isNotEmpty &&
          File(profileImageFile).existsSync()) {
        formData.files.add(MapEntry(
          'profile_picture',
          await MultipartFile.fromFile(profileImageFile),
        ));
      }
      // String jsonData = json.encode(formData);
      var response = await apiService.postMultipart(
          endPoint: "api/v1/user/profile", rawData: formData);
      if (200 <= response.code && response.code <= 300) {
        var model = UpdateProfile.fromJson(response.data);
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
