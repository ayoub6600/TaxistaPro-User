import 'dart:convert';
import 'growth/growth_api.dart';
import 'growth/my_gifts_page.dart';
import 'dart:io';
import 'functions/pulse_api.dart';
import 'functions/recurring_push.dart';
import 'functions/ride_offer_push.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
import 'contests/contests_pages.dart';

/// Calls while the app is in the background or closed (Android: data-only messages): ring with
/// the full-screen incoming call, or stop ringing. Every other message is left to the system tray.
@pragma('vm:entry-point')
Future<void> riderBackgroundMessage(RemoteMessage message) async {
  // a call rings first, before Firebase is initialised: on a phone woken by the push every second counts
  if (await handleCallPush(message.data)) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {}
  // Android, the evening reminder of a recurring ride sent data-only to this version: shown here
  // with its two buttons (✅ تأكيد / ⏭ تخطي), which answer without opening the app
  if (Platform.isAndroid && message.notification == null && RideOfferPush.handles(message.data)) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveBackgroundNotificationResponse: recurringNotificationAction);
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(RideOfferPush.channel);
    await RideOfferPush.show(plugin, message.data);
    return;
  }
  if (Platform.isAndroid && message.notification == null && RecurringPush.handles(message.data)) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveBackgroundNotificationResponse: recurringNotificationAction);
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(RecurringPush.channel);
    await RecurringPush.show(plugin, message.data);
  }
}

const _rigRecurringPush = String.fromEnvironment('RIG_RECURRING_PUSH');

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
  // the iPhone answers the reminder's buttons natively: it needs this build's API address
  await RecurringPush.rememberApiBase();

  // Local ride rehearsals use RTDB updates; FCM has no local emulator, but the notifications the
  // app shows itself (and `simctl push` on the Simulator) still need their handlers there.
  await initMessaging();
  if (!usesLocalFirebase) {
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
    // routine reminders: the open app tells where it is (only if the rider switched them on)
    ..onForeground.add(PulsePresence.report)
    ..attach();

  runApp(const MyApp());
  // rig only (a debug build given --dart-define=RIG_RECURRING_PUSH=<json>): the evening reminder as
  // the server sends it, shown 6 s after start, to press its buttons on an emulator without FCM
  if (kDebugMode && _rigRecurringPush.isNotEmpty) {
    Future<void>.delayed(const Duration(seconds: 6), () => RecurringPush.show(fltNotification, Map<String, dynamic>.from(jsonDecode(_rigRecurringPush) as Map)));
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
              // https://taxista.aljidartech.com/offers/<ref> (App Links / Universal Links): «هداياي»
              // when signed in, otherwise kept until the home screen; any other route is ignored
              onGenerateRoute: (settings) {
                // https://taxista.aljidartech.com/c/<code>: a shared contest opens «مسابقات تاكسيستا»
                if (ContestLink.isLink(settings.name)) {
                  if (bearerToken.isEmpty) {
                    ContestLink.openLink(); // kept until the home screen is up
                    return null;
                  }
                  return MaterialPageRoute(builder: (_) => const ContestsFeedPage());
                }
                final ref = GrowthLinks.refFrom(settings.name);
                if (ref == null) return null;
                if (bearerToken.isEmpty) {
                  GrowthLinks.pendingRef = ref;
                  return null;
                }
                return MaterialPageRoute(builder: (_) => MyGiftsPage(highlightRef: ref));
              },
              // a link that came while signed out (kept for later) or any unknown route: nothing opens
              onUnknownRoute: (settings) => PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, _, __) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  });
                  return const SizedBox.shrink();
                },
              ),
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
