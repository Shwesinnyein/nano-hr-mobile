import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/notification_provider.dart';
import 'auth_service.dart';
import 'notification_service.dart';

const bool kPushNotificationsEnabled = true;

class PushNotificationService {
  PushNotificationService(this._ref)
    : _notificationService = NotificationService();

  static const _kStoredTokenKey = 'fcm_device_token';
  static const _kStoredEmployeeKey = 'fcm_employee_id';

  final Ref _ref;
  final NotificationService _notificationService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _cachedToken;
  Future<String?>? _tokenFetchFuture;
  DateTime? _lastTokenErrorAt;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  Future<void>? _initializing;
  bool _localNotificationsInitialized = false;

  static const AndroidNotificationChannel _foregroundChannel =
      AndroidNotificationChannel(
    'nano_hr_foreground',
    'In-app notifications',
    description: 'Notifications displayed while the app is open',
    importance: Importance.high,
  );

  static const String _androidNotificationIcon = '@mipmap/ic_launcher';

  AuthService get _authService => _ref.read(authServiceProvider);

  Future<void> initialize() {
    if (!kPushNotificationsEnabled) {
      return Future.value();
    }

    if (_initialized) {
      return Future.value();
    }

    _initializing ??= _initializeInternal();
    return _initializing!;
  }

  Future<void> _initializeInternal() async {
    try {
      if (!kPushNotificationsEnabled) {
        _initialized = true;
        return;
      }

      if (kIsWeb) {
        // Web push is not currently supported in this app
        _initialized = true;
        return;
      }

      final permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        if (kDebugMode) {
          print('⚠️ PushNotificationService: Notification permission denied');
        }
        return;
      }

      await _syncTokenWithBackend();
      _listenForTokenRefresh();
      await _initializeLocalNotifications();
      _listenForForegroundMessages();

      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print(
        '🔔 PushNotificationService: Permission status ${settings.authorizationStatus}',
      );
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _syncTokenWithBackend() async {
    if (!kPushNotificationsEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken ??= prefs.getString(_kStoredTokenKey);

    if (kDebugMode) {
      final cached = prefs.getString(_kStoredTokenKey);
      final cachedEmployee = prefs.getString(_kStoredEmployeeKey);
      print(
        '📦 PushNotificationService: Stored token=$cached cachedEmployee=$cachedEmployee',
      );
    }

    final employeeId = _authService.currentEmployeeId;
    if (employeeId == null || employeeId.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ PushNotificationService: No employee ID, skipping token sync',
        );
      }
      return;
    }

    String? token = await _getMessagingTokenThrottled();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('⚠️ PushNotificationService: Unable to retrieve FCM token');
      }
      return;
    }
    if (kDebugMode) {
      print('🪪 PushNotificationService: Current FCM token $token');
    }

    final storedToken = prefs.getString(_kStoredTokenKey);
    final storedEmployeeId = prefs.getString(_kStoredEmployeeKey);

    if (storedToken == token && storedEmployeeId == employeeId) {
      if (kDebugMode) {
        print('ℹ️ PushNotificationService: Token already registered, skipping');
      }
      return;
    }

    final platform = _resolvePlatformLabel();

    try {
      final response = await _notificationService.registerDeviceToken(
        employeeId: employeeId,
        token: token,
        platform: platform,
      );

      if (response['success'] == true) {
        await prefs.setString(_kStoredTokenKey, token);
        await prefs.setString(_kStoredEmployeeKey, employeeId);
        if (kDebugMode) {
          print('✅ PushNotificationService: Device token registered');
        }
      } else {
        if (kDebugMode) {
          print(
            '❌ PushNotificationService: Failed to register token: ${response['message']}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PushNotificationService: Error registering token: $e');
      }
    }
  }

  void _listenForTokenRefresh() {
    if (!kPushNotificationsEnabled) {
      return;
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      String newToken,
    ) async {
      if (kDebugMode) {
        print('🔄 PushNotificationService: Token refreshed');
      }

      _cachedToken = newToken;
      _lastTokenErrorAt = null;

      final employeeId = _authService.currentEmployeeId;
      if (employeeId == null || employeeId.isEmpty) {
        return;
      }

      try {
        final response = await _notificationService.registerDeviceToken(
          employeeId: employeeId,
          token: newToken,
          platform: _resolvePlatformLabel(),
        );

        if (response['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kStoredTokenKey, newToken);
          await prefs.setString(_kStoredEmployeeKey, employeeId);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ PushNotificationService: Failed to refresh token: $e');
        }
      }
    });
  }
Future<String?> _getMessagingTokenThrottled() async {
  // ✅ 1. Use in-memory cache first
  if (_cachedToken != null && _cachedToken!.isNotEmpty) {
    if (kDebugMode) {
      print('ℹ️ PushNotificationService: Using cached FCM token (memory)');
    }
    return _cachedToken;
  }

  // ✅ 2. Load from SharedPreferences before hitting Firebase servers
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString(_kStoredTokenKey);
  if (savedToken != null && savedToken.isNotEmpty) {
    _cachedToken = savedToken;
    if (kDebugMode) {
      print('ℹ️ PushNotificationService: Loaded FCM token from local storage');
    }
    return _cachedToken;
  }

  // ✅ 3. Avoid overlapping token requests
  if (_tokenFetchFuture != null) {
    if (kDebugMode) {
      print('ℹ️ PushNotificationService: Token request already in progress');
    }
    return _tokenFetchFuture!;
  }

  // ✅ 4. Throttle repeated errors (5-minute cooldown)
  const cooldownDuration = Duration(minutes: 5);
  if (_lastTokenErrorAt != null &&
      DateTime.now().difference(_lastTokenErrorAt!) < cooldownDuration) {
    if (kDebugMode) {
      print(
        '⏱️ PushNotificationService: Cooling down for '
        '${cooldownDuration.inMinutes} min after recent error',
      );
    }
    return null;
  }

  // ✅ 5. Now request from Firebase only once
  _tokenFetchFuture = _messaging.getToken().then((token) async {
    _cachedToken = token;
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_kStoredTokenKey, token);
      if (kDebugMode) {
        print('✅ PushNotificationService: New FCM token fetched and saved');
      }
    }
    return token;
  }).catchError((Object error) {
    _lastTokenErrorAt = DateTime.now();
    if (kDebugMode) {
      print('❌ PushNotificationService: Failed to get FCM token: $error');
    }
    return null;
  }).whenComplete(() {
    _tokenFetchFuture = null;
  });

  return _tokenFetchFuture;
}

  // Future<String?> _getMessagingTokenThrottled() async {
  //   if (_cachedToken != null && _cachedToken!.isNotEmpty) {
  //     if (kDebugMode) {
  //       print('ℹ️ PushNotificationService: Using cached FCM token');
  //     }
  //     return _cachedToken;
  //   }

  //   if (_tokenFetchFuture != null) {
  //     if (kDebugMode) {
  //       print('ℹ️ PushNotificationService: Token request already in flight');
  //     }
  //     return _tokenFetchFuture!;
  //   }

  //   const cooldownDuration = Duration(minutes: 5);

  //   if (_lastTokenErrorAt != null &&
  //       DateTime.now().difference(_lastTokenErrorAt!) < cooldownDuration) {
  //     if (kDebugMode) {
  //       print(
  //         '⏱️ PushNotificationService: Throttling token request for '
  //         '${cooldownDuration.inMinutes} minutes after recent error',
  //       );
  //     }
  //     return null;
  //   }

  //   _tokenFetchFuture = _messaging.getToken().then((token) {
  //     _cachedToken = token;
  //     return token;
  //   }).catchError((Object error) {
  //     _lastTokenErrorAt = DateTime.now();
  //     if (kDebugMode) {
  //       print('❌ PushNotificationService: Failed to get FCM token: $error');
  //     }
  //     return null;
  //   }).whenComplete(() {
  //     _tokenFetchFuture = null;
  //   });

  //   return _tokenFetchFuture;
  // }

  // void _listenForForegroundMessages() {
  //   if (!kPushNotificationsEnabled) {
  //     return;
  //   }

  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //     if (kDebugMode) {
  //       print(
  //         '📩 PushNotificationService: Foreground message received: ${message.messageId}',
  //       );
  //     }

  //     final notification = message.notification;
  //     if (notification != null) {
  //       await _showForegroundNotification(notification, message.data);
  //     }

  //     _ref.read(notificationProvider.notifier).refreshUnreadCount();
  //   });

  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     if (kDebugMode) {
  //       print('📬 PushNotificationService: Notification opened');
  //     }
  //     _ref.read(notificationProvider.notifier).refreshUnreadCount();
  //   });
  // }
  void _listenForForegroundMessages() {
    if (!kPushNotificationsEnabled) {
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print(
          '📩 PushNotificationService: Foreground message received: ${message.messageId}',
        );
      }

      final notification = message.notification;
      if (notification != null) {
        await _showForegroundNotification(notification, message.data);
      }

      _ref.read(notificationProvider.notifier).refreshUnreadCount();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📬 PushNotificationService: Notification opened');
      }
      _ref.read(notificationProvider.notifier).refreshUnreadCount();
    });
  }

  Future<void> unregisterDeviceToken() async {
    if (!kPushNotificationsEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken ??= prefs.getString(_kStoredTokenKey);
    final token = _cachedToken ?? await _getMessagingTokenThrottled();
    final employeeId =
        _authService.currentEmployeeId ?? prefs.getString(_kStoredEmployeeKey);

    if (token == null ||
        token.isEmpty ||
        employeeId == null ||
        employeeId.isEmpty) {
      await prefs.remove(_kStoredTokenKey);
      await prefs.remove(_kStoredEmployeeKey);
      return;
    }

    try {
      await _notificationService.unregisterDeviceToken(
        employeeId: employeeId,
        token: token,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ PushNotificationService: Failed to unregister token: $e');
      }
    } finally {
      await prefs.remove(_kStoredTokenKey);
      await prefs.remove(_kStoredEmployeeKey);
      _cachedToken = null;
    }
  }

  Future<void> refreshTokenRegistration() async {
    if (!kPushNotificationsEnabled) {
      return;
    }

    await _syncTokenWithBackend();
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _initializing = null;
    _initialized = false;
  }

  String _resolvePlatformLabel() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const androidInit = AndroidInitializationSettings(_androidNotificationIcon);
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print(
            '🔔 PushNotificationService: Notification tapped with payload ${response.payload}',
          );
        }
        _ref.read(notificationProvider.notifier).refreshUnreadCount();
      },
    );

    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_foregroundChannel);

    _localNotificationsInitialized = true;
  }

  Future<void> _showForegroundNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    if (!_localNotificationsInitialized) {
      await _initializeLocalNotifications();
    }

    final androidDetails = AndroidNotificationDetails(
      _foregroundChannel.id,
      _foregroundChannel.name,
      channelDescription: _foregroundChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidNotificationIcon,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      notification.title ?? 'NANO Work',
      notification.body ?? '',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: data.isNotEmpty ? jsonEncode(data) : null,
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
