import 'package:flutter/material.dart';

class TaxistaPageTransitionsBuilder extends PageTransitionsBuilder {
  const TaxistaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final horizontalDirection = isRtl ? -1.0 : 1.0;
    final entrance = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final departure = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.82, end: 1).animate(entrance),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.055 * horizontalDirection, 0),
          end: Offset.zero,
        ).animate(entrance),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-0.018 * horizontalDirection, 0),
          ).animate(departure),
          child: child,
        ),
      ),
    );
  }
}

const taxistaPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: TaxistaPageTransitionsBuilder(),
    TargetPlatform.iOS: TaxistaPageTransitionsBuilder(),
    TargetPlatform.macOS: TaxistaPageTransitionsBuilder(),
    TargetPlatform.windows: TaxistaPageTransitionsBuilder(),
    TargetPlatform.linux: TaxistaPageTransitionsBuilder(),
    TargetPlatform.fuchsia: TaxistaPageTransitionsBuilder(),
  },
);
