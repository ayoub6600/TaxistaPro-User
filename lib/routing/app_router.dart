import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taxista/routing/routes.dart';
import 'package:taxista/routing/runtime_variables.dart';

final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

extension GoRouterExtension on GoRouter {
  // Navigate back to a specific route
  void popUntilPath(BuildContext context, String ancestorPath) {
    while (routerDelegate.currentConfiguration.matches.last.matchedLocation !=
        ancestorPath) {
      if (!context.canPop()) {
        return;
      }
      context.pop();
    }
  }

  static dynamic back([dynamic popValue]) {
    return navigatorKey.currentState?.pop(popValue);
  }
}

abstract class AppRouter {
  static final router = GoRouter(
    navigatorKey: navigatorKey,
    routes: appRoutes,
    observers: [ChuckerFlutter.navigatorObserver],
    // initialLocation: RoutesKeys.kRequestNotificationsView,
  );
}
