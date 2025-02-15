import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo_imp.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo_imp.dart';
import 'package:taxista/features/auth/register/data/repo/craet_account_repo_imp.dart';
import 'package:taxista/features/auth/register/data/repo/creat_account_repo.dart';
import 'package:taxista/features/auth/set_new_pass/data/repo/new_pass_repo.dart';
import 'package:taxista/features/auth/set_new_pass/data/repo/new_pass_repo_imp.dart';
import 'package:taxista/features/complaint/data/repo/complaint_repo.dart';
import 'package:taxista/features/complaint/data/repo/complaint_repo_imp.dart';
import 'package:taxista/features/edit_profail.dart/data/repo/edit_profail_repo.dart';
import 'package:taxista/features/edit_profail.dart/data/repo/edit_profail_repo_imp.dart';
import 'package:taxista/features/manager_address/data/repo/manger_address_repo_imp.dart';
import 'package:taxista/features/manager_address/data/repo/manger_address_view.dart';
import 'package:taxista/features/notification/data/repo/notication_repo_imp.dart';
import 'package:taxista/features/notification/data/repo/notification_repo.dart';

import 'api_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  await _initSharedPref();
  // await _initDirectory();

  getIt.registerSingleton<ApiService>(ApiService(Dio()));
//NotificationRepo
  getIt.registerSingleton<NotificationRepo>(NotificationRepoImp(
    apiService: getIt.get<ApiService>(),
  ));
  //ComplaintRepo
  getIt.registerSingleton<ComplaintRepo>(ComplaintRepoImp(
    apiService: getIt.get<ApiService>(),
  ));
  //login repo
  getIt.registerSingleton<LoginRepo>(LoginRepoImap(
    apiService: getIt.get<ApiService>(),
  ));
  getIt.registerSingleton<CreatAccountRepo>(CreatAccountImap(
    apiService: getIt.get<ApiService>(),
  ));
  //VerifyUserRepo
  getIt.registerSingleton<VerifyUserRepo>(VerifyUserRepoImpl(
    apiService: getIt.get<ApiService>(),
  ));
  //NewPassRepo
  getIt.registerSingleton<NewPassRepo>(NewPassrepoImp(
    apiService: getIt.get<ApiService>(),
  ));
  getIt.registerSingleton<UdateProfailRepo>(UdateProfailRepoImp(
    apiService: getIt.get<ApiService>(),
  ));
  //MangerAddressRepo
  getIt.registerSingleton<MangerAddressRepo>(MangerAddressRepoImp(
    apiService: getIt.get<ApiService>(),
  ));
}

Future<void> _initSharedPref() async {
  final SharedPreferences sharedPref = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPref);
}

// Future<void> _initDirectory() async {
//   Directory dir = await getApplicationCacheDirectory();
//   getIt.registerSingleton<Directory>(dir);
// }
