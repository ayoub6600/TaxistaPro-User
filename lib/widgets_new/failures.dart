import 'package:dio/dio.dart';

 class Failure {
  final String errMessage;

  const Failure(this.errMessage);
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage);

  factory ServerFailure.fromDioError(DioException dioError) {
    switch (dioError.type) {


      case DioExceptionType.sendTimeout:
        return ServerFailure('Send timeout with ApiServer');
        // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

      case DioExceptionType.receiveTimeout:
        return ServerFailure('Receive timeout with ApiServer');
        // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());


      case DioExceptionType.cancel:
        return ServerFailure('Request to ApiServer was canceld');
        // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

      case DioExceptionType.connectionTimeout:
      return ServerFailure('Request to ApiServer was canceld');
        // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());


      default:
        return ServerFailure('Opps There was an Error, Please try again');
        // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      return ServerFailure('Your request not found, Please try later!');
      // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());
    } else if (statusCode == 404) {
      return ServerFailure('Your request not found, Please try later!');
      // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

    } else if (statusCode == 500) {
      return ServerFailure('Internal Server error, Please try later');
      // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

    } else {
      return ServerFailure('Opps There was an Error, Please try again');
      // return ServerFailure(LocaleKeys.opps_There_was_an_Error_Please_try_again.tr());

    }
  }
}
