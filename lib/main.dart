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

import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';

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

  // 🔔 طلب صلاحيات الإشعارات
  await _initFirebaseMessaging();

  checkInternetConnection();
  await initMessaging();

  runApp(const MyApp());
}

/// 🔧 إعداد إشعارات FCM
Future<void> _initFirebaseMessaging() async {
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔥 FCM Token after refresh: $newToken");
    });

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('🔥 Current FCM Token: $token');
      }
    } catch (e) {
      print('❗ Error getting FCM token: $e');
    }
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('⚠️ User granted provisional permission');
  } else {
    print('❌ User declined or has not accepted permission');
  }
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
              debugShowCheckedModeBanner: false,
              title: 'Taxista',
              theme: ThemeData(),
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
                  child: botToast(context, widget),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
