import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _local.initialize(initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      print('🔔 Notification permission: ${settings.authorizationStatus}');
    }

    // Register token
    await _registerToken();

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _registerToken(tokenOverride: token);
    });

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        final androidDetails = AndroidNotificationDetails(
          'default_channel',
          'General',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        const iosDetails = DarwinNotificationDetails();
        await _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(android: androidDetails, iOS: iosDetails),
          payload: message.data['route'],
        );
      }
    });
  }

  static Future<void> _registerToken({String? tokenOverride}) async {
    try {
      final token = tokenOverride ?? await _messaging.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_id');
      if (employeeId == null) return;
      final api = ApiService();
      await api.registerDevice(
        employeeId: employeeId,
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      await prefs.setString('fcm_token', token);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Register token failed: $e');
      }
    }
  }

  static Future<void> onLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        await ApiService().unregisterDevice(token: token);
        await prefs.remove('fcm_token');
      }
    } catch (_) {}
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    // No-op here; your router can read initial link/route from message data
  }
}


