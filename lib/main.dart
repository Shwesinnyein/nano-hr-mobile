import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  if (androidPlugin != null) {
    // Create high importance channel (required by Firebase/Google Play)
    const highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for essential notifications.',
      importance: Importance.max,
      showBadge: true,
      enableVibration: true,
      playSound: true,
    );
    await androidPlugin.createNotificationChannel(highImportanceChannel);
    // Create foreground channel for background notifications
    await androidPlugin.createNotificationChannel(_backgroundNotificationChannel);
  }

  _backgroundNotificationsInitialized = true;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // STEP 4: Background handler - must be top-level function
  debugPrint('🔔 [BACKGROUND] Background handler called');
  debugPrint('🔔 [BACKGROUND] MessageId: ${message.messageId}');
  debugPrint('🔔 [BACKGROUND] Has notification: ${message.notification != null}');
  debugPrint('🔔 [BACKGROUND] Data: ${message.data}');
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notification = message.notification;
  final data = message.data;

  // Extract title and body from notification or data payload
  String? title;
  String? body;
  
  if (notification != null) {
    title = notification.title;
    body = notification.body;
  } else if (data.isNotEmpty) {
    // Try multiple possible keys for title and body in data payload
    title = data['title']?.toString() ?? 
            data['notification']?['title']?.toString() ?? 
            data['notification_title']?.toString();
    
    body = data['body']?.toString() ?? 
           data['message']?.toString() ?? 
           data['notification']?['body']?.toString() ?? 
           data['notification_body']?.toString() ??
           data['text']?.toString();
    
    // Check for leave-related notification types
    final notificationType = data['type']?.toString() ?? 
                            data['notification_type']?.toString() ??
                            data['action']?.toString();
    
    // For leave notifications, construct meaningful messages if title/body are missing
    if ((title == null || title.isEmpty) && notificationType != null) {
      if (notificationType.contains('leave_request')) {
        title = 'Leave Request';
        body = body ?? data['message']?.toString() ?? 'New leave request received';
      } else if (notificationType.contains('leave_approved') || notificationType.contains('approved')) {
        title = 'Leave Approved';
        body = body ?? data['message']?.toString() ?? 'Your leave request has been approved';
      } else if (notificationType.contains('leave_rejected') || notificationType.contains('rejected')) {
        title = 'Leave Rejected';
        body = body ?? data['message']?.toString() ?? 'Your leave request has been rejected';
      }
    }
  }

  // Default fallback
  title = title ?? 'NANO Work';
  body = body ?? 'New notification';

  if (title == 'NANO Work' && body == 'New notification' && data.isEmpty) {
    return;
  }

  await _ensureBackgroundNotificationsInitialized();

  // Use high_importance_channel for background notifications (required by Firebase/Google Play)
  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // Use the channel defined in AndroidManifest
    'High Importance Notifications',
    channelDescription: 'Used for essential notifications.',
    importance: Importance.max, // Max importance for immediate display
    priority: Priority.max, // Max priority for immediate display
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@drawable/nano_notification',
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.message,
    autoCancel: true,
    ongoing: false,
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // STEP 1: Initialize Firebase FIRST
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // STEP 4: Register background handler - CRITICAL for Android background notifications
    // Must be registered before runApp() - Android needs this isolate ready
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      debugPrint('✅ [MAIN] Background message handler registered');
    }
    
    // Enable iOS foreground presentation to show banners
    // NOTE: This is also set in PushNotificationService, but we set it here too for safety
    // On Android, this setting has no effect - we use local notifications manually
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,  // Show banner/alert
            badge: true,  // Update badge
            sound: true,  // Play sound
          );
      if (kDebugMode) {
        debugPrint('✅ [MAIN] iOS foreground presentation enabled');
      }
    }

  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ [MAIN] Firebase initialization error: $e');
    }
    // Continue even if Firebase init fails - app should still work
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    // Flutter error handled silently
  };

  runApp(const ProviderScope(child: App()));
}
