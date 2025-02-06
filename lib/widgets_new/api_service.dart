import 'dart:convert';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../Constants/keys_values.dart';
import '../Constants/preference_utility.dart';

class ApiService {
  final Dio _dio;

  ApiService(
    this._dio,
    /*this.sharedPreferences*/
  ) {
    // _dio.options.headers["Accept"] =
    //     "application/json"; // Config your dio headers globally
    // dio.options.headers["Authorization"] = "Bearer YOUR_TOKEN";
    // _dio.options.headers["Authorization"] =
    // "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}";
    // _dio.options.headers["accept-tokenapi"] =
    //     "k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA";
    // _dio.options.headers["accept-language"] =
    //     SharedPreferenceUtil.getString(PrefKey.currentLanguageCode);
    _dio.options.followRedirects = false;
    _dio.options.connectTimeout = const Duration(milliseconds: 75000); //5ss
    _dio.options.receiveTimeout = const Duration(milliseconds: 75000);
    if (SharedPreferenceUtil.getBool(PrefKey.chucker) == true) {
      _dio.interceptors.add(
        ChuckerDioInterceptor(),
      );
    }
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
    ));
  }

  Future<ApiData> postWithFormData(
      {required String endPoint, FormData? rawData}) async {
    var response = await _dio.post(
      '${getUrl()}$endPoint',
      data: rawData,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
        validateStatus: (status) {
          return status! < 500;
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      // navigatorKey?.currentState?.pushNamed("/loginView");
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  // Future<ApiData> postUploadFile(
  //     {required String endPoint, FormData? rawData}) async {
  //   var response = await _dio.post('${getUrl()}$endPoint',
  //       data: rawData,
  //       options: Options(
  //         headers: {
  //           "Content-Type": "application/json",
  //           'Accept': 'application/json',
  //           "Authorization":
  //           "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
  //         },
  //         followRedirects: false,
  //         validateStatus: (status) {
  //           return status! < 500;
  //         },
  //         contentType: Headers.formUrlEncodedContentType,
  //       ), onSendProgress: (int sent, int total) {
  //     var progress = sent / total;
  //     rootNavigatorKey.currentContext
  //         ?.read<FooterCubit>()
  //         .changeProgress(progress);
  //   });
  //
  //   if (200 <= response.statusCode! &&
  //       response.statusCode! <= 300 &&
  //       jsonEncode(response.data['status']) == "true") {
  //     return ApiData(
  //         data: response.data,
  //         code: response.statusCode ?? 0,
  //         errorMessage: "",
  //         success: true);
  //   } else if (response.statusCode == 401) {
  //     // navigatorKey?.currentState?.pushNamed("/loginView");
  //     logoutAndClearCach();
  //     return ApiData(
  //         data: response.data,
  //         code: response.statusCode ?? 0,
  //         errorMessage: "",
  //         success: false);
  //   } else {
  //     return ApiData(
  //         data: response.data,
  //         code: response.statusCode ?? 0,
  //         errorMessage: getError(response),
  //         success: false);
  //   }
  // }

  Future<ApiData> get(
      {required String endPoint,
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? data}) async {
    var response = await _dio.get(
      '${getUrl()}$endPoint',
      queryParameters: queryParameters,
      data: data,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      logoutAndClearCach();

      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  Future<ApiData> getCancelAble(
      {required String endPoint,
      Map<String, dynamic>? queryParameters,
      CancelToken? cancelToken}) async {
    var response = await _dio.get('${getUrl()}$endPoint',
        cancelToken: cancelToken, queryParameters: queryParameters);

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  void logoutAndClearCach() {
    // clearShardData();
    // GoRouter.of(rootNavigatorKey.currentContext!).go(AppRouter.kLoginView);
  }

  Future<int> logOut({required String endPoint}) async {
    var response = await _dio.delete(
      '${getUrl()}$endPoint',
    );
    return response.statusCode!;
  }

  // void clearShardData() {
  //   var environment = sharedPreferences.getString(SharedConstants.environment);
  //   var baseUrl = sharedPreferences.getString(SharedConstants.baseUrl);
  //   var chatCollection =
  //       sharedPreferences.getString(SharedConstants.chatCollection);
  //   var firstTime = sharedPreferences.getBool(SharedConstants.firstTime);
  //   var Chucker = sharedPreferences.getBool(SharedConstants.Chucker);
  //   sharedPreferences.clear();
  //   sharedPreferences.setString(SharedConstants.environment, environment ?? "");
  //   sharedPreferences.setString(SharedConstants.baseUrl, baseUrl ?? "");
  //   sharedPreferences.setString(
  //       SharedConstants.chatCollection, chatCollection ?? "");
  //   sharedPreferences.setBool(SharedConstants.firstTime, firstTime ?? true);
  //   sharedPreferences.setBool(SharedConstants.Chucker, Chucker ?? false);
  // }

  Future<ApiData> delete({required String endPoint, String? rawData}) async {
    var response = await _dio.delete(
      '${getUrl()}$endPoint',
      data: rawData,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
        validateStatus: (status) {
          return status! < 500;
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      // navigatorKey?.currentState?.pushNamed("/loginView");
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  Future<ApiData> post(
      {required String endPoint,
      String? rawData,
      Map<String, dynamic>? queryParameters}) async {
    //  print('----------TOKEN>${SharedPreferenceUtil.getString(PrefKey.login)}');
    var response = await _dio.post(
      '${getUrl()}$endPoint',
      queryParameters: queryParameters ?? jsonDecode(rawData ?? "{}"),
      data: rawData,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
        validateStatus: (status) {
          return status! < 500;
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      // navigatorKey?.currentState?.pushNamed("/loginView");
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  Future<ApiData> postMultipart(
      {required String endPoint, FormData? rawData}) async {
    var response = await _dio.post(
      '${getUrl()}$endPoint',
      data: rawData,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
        validateStatus: (status) {
          return status! < 500;
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      // navigatorKey?.currentState?.pushNamed("/loginView");
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  Future<ApiData> put({required String endPoint, String? rawData}) async {
    var response = await _dio.put(
      '${getUrl()}$endPoint',
      queryParameters: jsonDecode(rawData ?? "{}"),
      data: rawData,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json',
          'accept-tokenapi': 'k*RQ=z*2K4@WnA6d2h_&z39?bE9kDszkwh4XTePpU_vA',
          "accept-language":
              SharedPreferenceUtil.getString(PrefKey.currentLanguageCode),
          "Authorization":
              "Bearer ${SharedPreferenceUtil.getString(PrefKey.login)}",
        },
        validateStatus: (status) {
          return status! < 500;
        },
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (200 <= response.statusCode! &&
        response.statusCode! <= 300 &&
        jsonEncode(response.data['status']) == "true") {
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: true);
    } else if (response.statusCode == 401) {
      // navigatorKey?.currentState?.pushNamed("/loginView");
      logoutAndClearCach();
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: "",
          success: false);
    } else {
      String jsonUser = jsonEncode(response.data['message']);
      return ApiData(
          data: response.data,
          code: response.statusCode ?? 0,
          errorMessage: getError(response),
          success: false);
    }
  }

  String getError(Response json) {
    final jsonString = jsonEncode(json.data);

    if (jsonString.contains("errors")) {
      String error = "";

      try {
        Map<String, dynamic> jsonData = jsonDecode(jsonString);
        Map<String, dynamic> errors = jsonData['msg'];
        // Get the first error message
        error = errors.values.first.first;
        error = error.replaceAll('"', '');
      } catch (e) {
        error = 'something want wrong try again later';
      }

      return error;
    } else {
      String error = "";
      try {
        error = jsonEncode(json.data['msg']);
        error = error.replaceAll('"', '');
      } catch (e) {
        error = 'something want wrong try again later';
      }
      return error;
    }
  }

  String getUrl() {
    String url = "https://www.taxistapro.com/";
    return url;
  }
}

class ApiData {
  final Map<String, dynamic> data;
  final int code;
  final String errorMessage;
  final bool success;

  const ApiData(
      {required this.data,
      required this.code,
      required this.errorMessage,
      required this.success});

  ApiData copyWith({
    Map<String, dynamic>? data,
    int? code,
    String? errorMessage,
    bool? success,
  }) {
    return ApiData(
      data: data ?? this.data,
      code: code ?? this.code,
      errorMessage: errorMessage ?? this.errorMessage,
      success: success ?? this.success,
    );
  }
}
