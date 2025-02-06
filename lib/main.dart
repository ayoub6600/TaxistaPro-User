import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:taxista/Localization/localization_constant.dart';
import 'package:taxista/constants/keys_values.dart';
import 'package:taxista/constants/preference_utility.dart';
import 'package:taxista/firebase_options.dart';
import 'package:taxista/pages/loadingPage/loadingpage.dart';
import 'package:taxista/routing/app_router.dart';
import 'package:taxista/widgets_new/service_locator.dart';
import 'Localization/language_localization.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceUtil.getInstance();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (SharedPreferenceUtil.getString(PrefKey.currentLanguageCode) == '') {
    SharedPreferenceUtil.putString(PrefKey.currentLanguageCode, 'ar');
  }
  checkInternetConnection();
  await setupServiceLocator();

  initMessaging();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void didChangeDependencies() {
    getLocale().then((local) => {
          setState(() {
            _locale = local;
          })
        });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    platform = Theme.of(context).platform;
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: GestureDetector(
          onTap: () {
            //remove keyboard on touching anywhere on the screen.
            FocusScopeNode currentFocus = FocusScope.of(context);

            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: ValueListenableBuilder(
              valueListenable: valueNotifierBook.value,
              builder: (context, value, child) {
                return OKToast(
                  child: Builder(
                    builder: (BuildContext context) {
                      return MaterialApp.router(
                        routerConfig: AppRouter.router,
                        debugShowCheckedModeBanner: false,
                        title: 'Taxista',
                        locale: _locale,

                        supportedLocales: const [
                          Locale(english, 'US'),
                          Locale(arabic, 'AE'),
                        ],
                        localeResolutionCallback:
                            (deviceLocal, supportedLocales) {
                          for (var local in supportedLocales) {
                            if (local.languageCode ==
                                    deviceLocal!.languageCode &&
                                local.countryCode == deviceLocal.countryCode) {
                              return deviceLocal;
                            }
                          }
                          return supportedLocales.first;
                        },
                        localizationsDelegates: const [
                          LanguageLocalization.delegate,
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        theme: ThemeData(),
                        // home: const LoadingPage(),
                        // navigatorObservers: [BotToastNavigatorObserver()],
                        builder: (context, widget) {
                          Function botToast = BotToastInit();
                          Widget mWidget = botToast(context, widget);
                          return MediaQuery(
                            //Setting font does not change with system font size
                            data: MediaQuery.of(context).copyWith(
                                textScaler: const TextScaler.linear(1.0)),
                            child: mWidget,
                          );
                        },
                      );
                    },
                  ),
                );
              })),
    );
  }
}
