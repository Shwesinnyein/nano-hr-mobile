import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'app/app.dart';

const AndroidNotificationChannel _backgroundNotificationChannel =
    AndroidNotificationChannel(
  'nano_hr_foreground',
  'In-app notifications',
  description: 'Notifications displayed while the app is open',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _backgroundNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _backgroundNotificationsInitialized = false;

Future<void> _ensureBackgroundNotificationsInitialized() async {
  if (_backgroundNotificationsInitialized) return;

  const androidInit = AndroidInitializationSettings('@drawable/nano_notification');
  // ✅ Request iOS permissions for local notifications (needed for foreground notifications)
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  await _backgroundNotificationsPlugin.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ),
  );

  final androidPlugin =
      _backgroundNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    _backgroundNotificationChannel,
  );

  _backgroundNotificationsInitialized = true;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title']?.toString();
  final body = notification?.body ?? data['body']?.toString();

  if (title == null && body == null) {
    return;
  }

  await _ensureBackgroundNotificationsInitialized();

  const androidDetails = AndroidNotificationDetails(
    'nano_hr_foreground',
    'In-app notifications',
    channelDescription: 'Notifications displayed while the app is open',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@drawable/nano_notification',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await _backgroundNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title ?? 'NANO Work',
    body ?? '',
    const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    ),
    payload: data.isNotEmpty ? jsonEncode(data) : null,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // ✅ Note: Foreground message handling is done by PushNotificationService
    // No need to set up listener here to avoid duplicate notifications
  } catch (e) {
    // In release mode, we need to handle errors gracefully
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const ProviderScope(child: App()));
}
