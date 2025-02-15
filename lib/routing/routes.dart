import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/features/auth/forgot_password/data/repo/send_otp_repo.dart';
import 'package:taxista/features/auth/forgot_password/manager/forgot_pass_cubit.dart';
import 'package:taxista/features/auth/forgot_password/view/forgot_password_view.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/features/auth/login/manager/login_cubit.dart';
import 'package:taxista/features/auth/login/view/login_view.dart';
import 'package:taxista/features/auth/register/data/repo/creat_account_repo.dart';
import 'package:taxista/features/auth/register/manager/creat_account_cubit.dart';
import 'package:taxista/features/auth/register/view/creat_account_view.dart';
import 'package:taxista/features/auth/set_new_pass/data/repo/new_pass_repo.dart';
import 'package:taxista/features/auth/set_new_pass/manager/new_pass_cubit.dart';
import 'package:taxista/features/auth/set_new_pass/view/set_new_pass_view.dart';
import 'package:taxista/features/auth/verifaction/view/verifaction_view.dart';
import 'package:taxista/features/complaint/data/repo/complaint_repo.dart';
import 'package:taxista/features/complaint/manager/complaint_cubit.dart';
import 'package:taxista/features/complaint/view/complaint_view.dart';
import 'package:taxista/features/current_location/manager/current_location_cubit.dart';
import 'package:taxista/features/current_location/view/current_location_view.dart';
import 'package:taxista/features/edit_profail.dart/data/repo/edit_profail_repo.dart';
import 'package:taxista/features/edit_profail.dart/manager/your_profail_cubit.dart';
import 'package:taxista/features/edit_profail.dart/view/edit_profail_view.dart';
import 'package:taxista/features/home/view/home_view.dart';
import 'package:taxista/features/language/view/language_view.dart';
import 'package:taxista/features/manager_address/data/repo/manger_address_view.dart';
import 'package:taxista/features/manager_address/manager/manger_address_cubit.dart';
import 'package:taxista/features/manager_address/view/manger_address_view.dart';
import 'package:taxista/features/manager_address/view/add_address_view.dart';
import 'package:taxista/features/manager_address/view/widgets/add_address_view_body.dart';
import 'package:taxista/features/notification/data/repo/notification_repo.dart';
import 'package:taxista/features/notification/manager/notification_cubit.dart';
import 'package:taxista/features/notification/view/notifaication_view.dart';
import 'package:taxista/features/profail/view/profail_view.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';
import 'package:taxista/features/splash/presentation/onboarding_view.dart';
import 'package:taxista/features/splash/presentation/splash_view.dart';
import 'package:taxista/routing/routes_keys.dart';
import 'package:taxista/routing/runtime_variables.dart';
import 'package:taxista/widgets_new/service_locator.dart';

List<RouteBase> appRoutes = [
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kSplash,
    builder: (context, state) {
      return const SplashView();
    },
  ),
  //kCurrentLocation
//ChangeAddressLocation
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kChangeAddressLocation,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => MangerAddressCubit(
          getIt.get<MangerAddressRepo>(),
        ),
        child: const ChangeAddressLocation(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kNotifactionView,
    builder: (context, state) {
      return BlocProvider(
          create: (context) => NotificationCubit(getIt.get<NotificationRepo>()),
          child: NotifactionView());
    },
  ),
  //ComplaintView
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kComplaintView,
    builder: (context, state) {
      return BlocProvider(
          create: (context) => ComplaintCubit(getIt.get<ComplaintRepo>()),
          child: ComplaintView());
    },
  ),

  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kCurrentLocation,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => CurrentLocationCubit(),
        child: const CurrentLocationView(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kOnboarding,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => OnboardingCubit(),
        child: const OnboardingView(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kWelcome,
    builder: (context, state) {
      return const LanguageView();
    },
  ),
  //kManagerAddressView
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kManagerAddressView,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => MangerAddressCubit(
          getIt.get<MangerAddressRepo>(),
        ),
        child: const ManagerAddressView(),
      );
    },
  ),

  //kAddAddress
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kAddAddress,
    builder: (context, state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => MangerAddressCubit(
              getIt.get<MangerAddressRepo>(),
            ),
          ),
          //   BlocProvider(create: (context) => LayoutCubit()),
        ],
        child: const AddAddressView(),
      );
    },
  ),

  //login
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kLogin,
    builder: (context, state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => LoginCubit(
              getIt.get<LoginRepo>(),
            ),
          ),
        ],
        child: const LoginScreen(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kRegister,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => CreateAccountCubit(
          getIt.get<CreatAccountRepo>(),
        ),
        child: const CreatAccountView(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kForgot,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => VerifyUserCubit(
          verifyUserRepo: getIt.get<VerifyUserRepo>(),
        ),
        child: const ForgotPasswordView(),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kOtpVerification,
    builder: (context, state) {
      var arguments = state.extra as String;
      return BlocProvider(
        create: (context) => VerifyUserCubit(
          verifyUserRepo: getIt.get<VerifyUserRepo>(),
        ),
        child: VerifactionView(
          phone: arguments,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kNewPassword,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => NewPassWordCubit(
          getIt.get<NewPassRepo>(),
        ),
        child: SetNewPassView(
          phone: state.extra as String,
        ),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kProfail,
    builder: (context, state) {
      return const ProfailView();
    },
  ),
  //EditProfail
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.keditProfail,
    builder: (context, state) {
      return BlocProvider(
        create: (context) => UdateProfailCubit(
          getIt.get<UdateProfailRepo>(),
        ),
        child: const EditProfail(),
      );
    },
  ),

  // HomeView
  GoRoute(
    parentNavigatorKey: navigatorKey,
    path: RoutesKeys.kHome,
    builder: (context, state) {
      return const HomeView();
    },
  ),
];
