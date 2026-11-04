import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'calls/admin_call_controller.dart';
import 'functions.dart';
import 'pulse_api.dart';
import 'support_chat_link.dart';

// create an instance
FirebaseMessaging messaging = FirebaseMessaging.instance;
FlutterLocalNotificationsPlugin fltNotification =
    FlutterLocalNotificationsPlugin();
FlutterLocalNotificationsPlugin rideNotification =
    FlutterLocalNotificationsPlugin();
bool isGeneral = false;
String latestNotification = '';
int id = 0;
bool _messagingInitialized = false;
bool _permissionRequestInFlight = false;
bool _tokenSyncInFlight = false;
DateTime? _lastTokenSync;

/// Tells the backend which FCM token this device has right now.
///
/// The token used to be sent only at login. On iOS the APNs token usually does
/// not exist yet at that moment (the permission prompt comes later), so the
/// account was stored with no token and nothing ever filled it in - the rider
/// then showed as "no FCM" in the admin and received no push at all. This is
/// called whenever the rider reaches Home, when the OS grants permission, and
/// whenever Firebase rotates the token. A fresh app session re-confirms at most
/// every 6 hours; a rotation or a permission grant is sent immediately.
Future<void> syncDeviceToken({String? token, bool force = false}) async {
  if (bearerToken.isEmpty || _tokenSyncInFlight) return;
  final last = _lastTokenSync;
  if (!force &&
      token == null &&
      last != null &&
      DateTime.now().difference(last) < const Duration(hours: 6)) {
    return;
  }

  _tokenSyncInFlight = true;
  try {
    var fcm = token;
    if (fcm == null || fcm.isEmpty) {
      if (Platform.isIOS) {
        // getToken() throws on iOS until the APNs token exists; give it time.
        for (var i = 0; i < 5; i++) {
          String? apns;
          try {
            apns = await FirebaseMessaging.instance.getAPNSToken();
          } catch (_) {}
          if (apns != null) break;
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
      try {
        fcm = await FirebaseMessaging.instance.getToken();
      } catch (error) {
        debugPrint('FCM token not available yet: $error');
      }
    }
    if (fcm == null || fcm.isEmpty) return;

    final response = await http.post(
      Uri.parse('${url}api/v1/user/device-token'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_token': fcm,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    if (response.statusCode == 200) {
      _lastTokenSync = DateTime.now();
    }
  } catch (error) {
    debugPrint('Device token sync failed: $error');
  } finally {
    _tokenSyncInFlight = false;
  }
}

/// Every tap on a notification this app showed itself lands here (the plugin is one instance,
/// so each initialize() below passes it again): a message or a missed call from the
/// administration opens that conversation; anything else, as before.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final support = SupportChatLink.fromPayload(notificationResponse.payload);
  if (support != null) {
    SupportChatLink.open(support);
    return;
  }
  isGeneral = true;
  valueNotifierHome.incrementNotifier();
}

/// A message or a missed call from the administration while the app is on screen: the open chat
/// just reloads (and reads it); otherwise a notification whose tap opens the conversation.
Future<void> _supportPushInForeground(RemoteMessage message) async {
  final data = message.data;
  final isChat = data['push_type'] == SupportChatLink.chatPush;
  if (isChat && adminChatPagesOpen > 0) {
    await getadminCurrentMessages();
    return;
  }
  if (isChat) unawaited(getadminCurrentMessages(markRead: false)); // the badge
  await fltNotification.show(
    id++,
    message.notification?.title ?? data['title']?.toString() ?? 'إدارة تاكسيستا',
    message.notification?.body ?? data['message']?.toString() ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails('admin_chat_channel', 'Admin Chat',
          channelDescription: 'Messages and missed calls from the administration',
          importance: Importance.high, priority: Priority.high, playSound: true),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    ),
    payload: SupportChatLink.payload(data),
  );
}

/// This push is only ever a timely nudge, never trusted on its own -
/// findPresentedOfferForRider() on the backend is the actual source of
/// truth either way. Re-fetching it here is what makes the Home card
/// appear immediately instead of waiting for the next periodic poll,
/// including while the app is already open in the foreground.
void _handleRecoveryDriverReadyPush() {
  fetchPendingRecoveryOfferForRider(force: true).then((_) {
    valueNotifierHome.incrementNotifier();
  });
}

/// "A driver priced your scheduled ride": the push is only a nudge - the
/// upcoming-rides API is the truth. Refresh the Home banner now (past the poll
/// gate); a TAPPED push also opens the scheduled rides page once.
void _handleScheduledOfferPush({bool opened = false}) {
  if (opened) openScheduledOffersRequested = true;
  refreshScheduledOfferSummary(force: true).then((_) {
    valueNotifierHome.incrementNotifier();
  });
}

bool _isScheduledOfferPush(Map<String, dynamic>? data) =>
    data?['push_type']?.toString() == 'scheduled-ride-offer';

var androidDetails = const AndroidNotificationDetails(
  '54321',
  'normal_notification',
  enableVibration: true,
  enableLights: true,
  importance: Importance.high,
  playSound: true,
  priority: Priority.high,
  visibility: NotificationVisibility.private,
);

const iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true);

var generalNotificationDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

var androiInit =
    const AndroidInitializationSettings('@mipmap/ic_launcher'); //for logo
var iosInit = const DarwinInitializationSettings(
  defaultPresentAlert: true,
  defaultPresentBadge: true,
  defaultPresentSound: true,
);
var initSetting = InitializationSettings(android: androiInit, iOS: iosInit);

Future<void> initMessaging() async {
  await fltNotification.initialize(initSetting,
      onDidReceiveNotificationResponse: notificationTapBackground);
  _messagingInitialized = true;
  // the app was started by tapping one of its own notifications
  try {
    final launch = await fltNotification.getNotificationAppLaunchDetails();
    final support = SupportChatLink.fromPayload(launch?.notificationResponse?.payload);
    if (launch?.didNotificationLaunchApp == true && support != null) SupportChatLink.open(support);
  } catch (_) {}

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('FCM token refreshed');
    unawaited(syncDeviceToken(token: newToken, force: true));
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message?.data != null) {
      if (SupportChatLink.handles(message!.data)) {
        // closed app, tapped: the conversation opens once the home screen is up
        SupportChatLink.open(message.data);
        return;
      }
      if (message.data['push_type'] == 'admin_call') {
        AdminCallController.answerFromNotification(message.data);
      }
      if (message.data['push_type'] == 'general') {
        latestNotification = message.data['message'];
        isGeneral = true;
        valueNotifierHome.incrementNotifier();
      }
      if (message.data['push_type'] == 'recovery_driver_ready') {
        _handleRecoveryDriverReadyPush();
      }
      if (_isScheduledOfferPush(message.data)) {
        _handleScheduledOfferPush(opened: true);
      }
      if (message.data['push_type'] == 'pulse-reminder') {
        // the home map fills the usual destination; the rider confirms the booking himself
        PulseBookingIntent.fromPush(message.data);
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // calls: ring / stop ringing (data-only on Android)
    if (await handleCallPush(message.data, appOpen: true)) return;
    if (SupportChatLink.handles(message.data)) {
      await _supportPushInForeground(message);
      return;
    }
    RemoteNotification? notification = message.notification;
    if (message.data['push_type'].toString() == 'recovery_driver_ready') {
      _handleRecoveryDriverReadyPush();
    }
    if (_isScheduledOfferPush(message.data)) {
      _handleScheduledOfferPush();
    }
    if (message.data['push_type'].toString() == 'pickup-change' && userRequestData.isNotEmpty) {
      PickupChangeState.reload('${userRequestData['id']}');
    }
    if (notification != null) {
      if (message.data['push_type'].toString() == 'general') {
        latestNotification = message.data['message'];
        if (message.data['image'].isNotEmpty) {
          _showBigPictureNotificationURLGeneral(message.data);
        } else {
          _showGeneralNotification(message.data);
        }
      } else {
        showRideNotification(message.notification);
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (SupportChatLink.handles(message.data)) {
      // in the background, tapped: straight to the conversation (or the call log for a trip call)
      SupportChatLink.open(message.data);
      return;
    }
    if (message.data['push_type'].toString() == 'admin_call') {
      AdminCallController.answerFromNotification(message.data);
      return;
    }
    if (message.data['push_type'].toString() == 'general') {
      latestNotification = message.data['message'];
      isGeneral = true;
      valueNotifierHome.incrementNotifier();
    }
    if (message.data['push_type'].toString() == 'recovery_driver_ready') {
      _handleRecoveryDriverReadyPush();
    }
    if (_isScheduledOfferPush(message.data)) {
      _handleScheduledOfferPush(opened: true);
    }
    if (message.data['push_type'].toString() == 'pulse-reminder') {
      PulseBookingIntent.fromPush(message.data);
    }
    if (message.data['push_type'].toString() == 'pickup-change' && userRequestData.isNotEmpty) {
      PickupChangeState.reload('${userRequestData['id']}');
    }
  });
}

/// A call rings with the system call screen (and Taxista's own screen when the app is open); its
/// end dismisses it. True when the message was a call message (nothing else to show for it).
Future<bool> handleCallPush(Map<String, dynamic> data, {bool appOpen = false}) async {
  final type = data['push_type']?.toString();
  if (type == 'admin_call') {
    await AdminCallController.incomingPush(data,
        appOpen: appOpen && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
    return true;
  }
  if (type == 'admin_call_end') {
    await AdminCallController.dismissIncoming((data['call_id'] ?? '').toString());
    return true;
  }
  return false;
}

/// Requests the system prompt only after the rider reaches the home screen.
/// This avoids interrupting onboarding and also prevents duplicate prompts.
Future<void> requestNotificationPermissionIfNeeded() async {
  if (!_messagingInitialized || _permissionRequestInFlight) return;

  final current = await FirebaseMessaging.instance.getNotificationSettings();
  if (current.authorizationStatus != AuthorizationStatus.notDetermined) {
    // Permission was decided earlier: re-confirm the token for this account.
    if (current.authorizationStatus == AuthorizationStatus.authorized ||
        current.authorizationStatus == AuthorizationStatus.provisional) {
      unawaited(syncDeviceToken());
    }
    return;
  }

  _permissionRequestInFlight = true;
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await syncDeviceToken(force: true);
    }
  } catch (error) {
    debugPrint('Unable to request notification permission: $error');
  } finally {
    _permissionRequestInFlight = false;
  }
}

Future<String> _downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

Future<void> _showBigPictureNotificationURLGeneral(message) async {
  latestNotification = message['message'];
  if (platform == TargetPlatform.android) {
    final ByteArrayAndroidBitmap bigPicture =
        ByteArrayAndroidBitmap(await _getByteArrayFromUrl(message['image']));
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(bigPicture);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'notification_1',
      'general image notification',
      channelDescription: 'general notification with image',
      styleInformation: bigPictureStyleInformation,
      enableVibration: true,
      enableLights: true,
      importance: Importance.high,
      playSound: true,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    fltNotification.initialize(initSetting,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    await fltNotification.show(
        id++, message['title'], message['message'], notificationDetails);
  } else {
    final String bigPicturePath = await _downloadAndSaveFile(
        Uri.parse(message['image']).toString(), 'bigPicture.jpg');
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: <DarwinNotificationAttachment>[
          DarwinNotificationAttachment(
            bigPicturePath,
          )
        ]);

    final NotificationDetails notificationDetails =
        NotificationDetails(iOS: iosDetails);
    fltNotification.initialize(initSetting,
        onDidReceiveNotificationResponse: notificationTapBackground,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    await fltNotification.show(
        id++, message['title'], message['message'], notificationDetails);
  }
  id = id++;
}

Future<void> _showGeneralNotification(message) async {
  latestNotification = message['message'];
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'notification_1',
    'general notification',
    channelDescription: 'general notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true);
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: iosDetails);
  fltNotification.initialize(initSetting,
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
  await fltNotification.show(
      id++, message['title'], message['message'], notificationDetails);
  id = id++;
}

Future<void> showOtpNotification(message) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'notification_1',
    'ride notification',
    channelDescription: 'ride notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: iosDetails);
  rideNotification.initialize(initSetting,
      onDidReceiveNotificationResponse: notificationTapBackground);
  await rideNotification.show(id++, message.title.toString(),
      message.body.toString(), notificationDetails);
  id = id++;
}

Future<void> showRideNotification(message) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'notification_1',
    'ride notification',
    channelDescription: 'ride notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: iosDetails);
  rideNotification.initialize(initSetting,
      onDidReceiveNotificationResponse: notificationTapBackground);
  await rideNotification.show(id++, message.title.toString(),
      message.body.toString(), notificationDetails);
  id = id++;
}
