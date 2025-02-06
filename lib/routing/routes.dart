import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/features/auth/login/data/repo/login_repo.dart';
import 'package:taxista/features/auth/login/manager/login_cubit.dart';
import 'package:taxista/features/auth/login/view/login_view.dart';
import 'package:taxista/features/auth/register/data/repo/creat_account_repo.dart';
import 'package:taxista/features/auth/register/manager/creat_account_cubit.dart';
import 'package:taxista/features/auth/register/view/creat_account_view.dart';
import 'package:taxista/features/language/view/language_view.dart';
import 'package:taxista/features/splash/manager/onboarding_cubit.dart';
import 'package:taxista/features/splash/presentation/onboarding_view.dart';
import 'package:taxista/features/splash/presentation/splash_view.dart';
import 'package:taxista/features/splash/presentation/widgets/welcome_view.dart';
import 'package:taxista/pages/language/languages.dart';
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
];
