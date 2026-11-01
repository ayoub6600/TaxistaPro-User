import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxista/firebase_options.dart';

import 'functions/app_lifecycle.dart';
import 'functions/calls/admin_call_controller.dart';
import 'functions/functions.dart';
import 'functions/live_queries.dart';
import 'functions/notifications.dart';
import 'local_firebase.dart';
import 'navigation/taxista_page_transitions.dart';
import 'pages/callPage/admin_call_page.dart';
import 'pages/loadingPage/loadingpage.dart';

/// Calls while the app is in the background or closed (Android: data-only messages): ring with
/// the full-screen incoming call, or stop ringing. Every other message is left to the system tray.
@pragma('vm:entry-point')
Future<void> riderBackgroundMessage(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {}
  await handleCallPush(message.data);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('geocoding_cache');
  await Hive.openBox('autocomplete_cache');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ تأكد من تهيئة Firebase لمرة واحدة فقط
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await configureLocalFirebase(url);

  // Local ride rehearsals use RTDB updates; FCM has no local emulator.
  if (!usesLocalFirebase) {
    await initMessaging();
    FirebaseMessaging.onBackgroundMessage(riderBackgroundMessage);
  }

  checkInternetConnection();

  // One owner for app-wide background/foreground work: shared Firebase
  // listeners and the ride listeners are closed while the app is away and
  // reopened once when it returns (see AppLifecycleCoordinator).
  AppLifecycleCoordinator.instance
    ..onBackground.addAll([
      LiveQueries.instance.pauseAll,
      detachRideStreams,
    ])
    ..onForeground.add(LiveQueries.instance.resumeAll)
    ..attach();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    platform = Theme.of(context).platform;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: valueNotifierBook.value,
          builder: (context, value, child) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Taxista',
              theme: ThemeData(
                pageTransitionsTheme: taxistaPageTransitionsTheme,
              ),
              locale: const Locale('ar'),
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('ar', ''),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const LoadingPage(),
              navigatorObservers: [BotToastNavigatorObserver()],
              builder: (context, widget) {
                final botToast = BotToastInit();
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  // a call going on behind another screen: the green "return to call" bar on top
                  child: Stack(children: [
                    botToast(context, widget),
                    const Positioned(top: 0, left: 0, right: 0, child: OngoingCallBar()),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
