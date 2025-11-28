import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_badger/app_badger.dart';

import '../providers/notification_provider.dart';
import '../providers/otp_provider.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  bool _initialized = false;
  Future<void>? _initializing;
  bool _localNotificationsInitialized = false;
  final Set<String> _processedMessageIds = <String>{}; // Track processed messages to prevent duplicates

  static const AndroidNotificationChannel _foregroundChannel =
      AndroidNotificationChannel(
    'nano_hr_foreground',
    'In-app notifications',
    description: 'Notifications displayed while the app is open',
    importance: Importance.high,
  );

  static const String _androidNotificationIcon = '@drawable/nano_notification';

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
        _initialized = true;
        return;
      }

      final permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        return;
      }

      // Enable Firebase's automatic foreground presentation on iOS
      // On Android, we use local notifications manually
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS) {
        if (kDebugMode) {
          debugPrint('🔔 [INIT] Enabling Firebase automatic foreground presentation for iOS');
        }
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,  // Show banner automatically on iOS
          badge: true,  // Update badge
          sound: true,  // Play sound
        );
        if (kDebugMode) {
          debugPrint('🔔 [INIT] Firebase automatic presentation enabled for iOS');
        }
      }

      await _syncTokenWithBackend(forceReRegister: true);
      _listenForTokenRefresh();
      
      try {
        if (kDebugMode) {
          debugPrint('🔔 [INIT] Initializing local notifications...');
        }
        await _initializeLocalNotifications();
        if (kDebugMode) {
          debugPrint('🔔 [INIT] Local notifications initialized: $_localNotificationsInitialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [INIT] Failed to initialize local notifications: $e');
        }
      }
      
      if (kDebugMode) {
        debugPrint('🔔 [INIT] Setting up foreground message listener...');
      }
      _listenForForegroundMessages();
      if (kDebugMode) {
        debugPrint('✅ [INIT] PushNotificationService initialized successfully');
      }

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

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _syncTokenWithBackend({bool forceReRegister = false}) async {
    if (!kPushNotificationsEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final employeeId = _authService.currentEmployeeId;
    if (employeeId == null || employeeId.isEmpty) {
      return;
    }

    String? token;
    if (forceReRegister) {
      _cachedToken = null;
      _tokenFetchFuture = null;
      _lastTokenErrorAt = null;
      
      try {
        token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          await prefs.setString(_kStoredTokenKey, token);
        }
      } catch (e) {
        token = await _getMessagingTokenThrottled();
      }
    } else {
      token = await _getMessagingTokenThrottled();
    }

    if (token == null || token.isEmpty) {
      return;
    }

    final storedToken = prefs.getString(_kStoredTokenKey);
    final storedEmployeeId = prefs.getString(_kStoredEmployeeKey);

    if (!forceReRegister && storedToken == token && storedEmployeeId == employeeId) {
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
      }
    } catch (e) {
    }
  }

  void _listenForTokenRefresh() {
    if (!kPushNotificationsEnabled) {
      return;
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      String newToken,
    ) async {
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
      }
    });
  }
Future<String?> _getMessagingTokenThrottled() async {
  if (_cachedToken != null && _cachedToken!.isNotEmpty) {
    return _cachedToken;
  }

  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString(_kStoredTokenKey);
  if (savedToken != null && savedToken.isNotEmpty) {
    _cachedToken = savedToken;
    return _cachedToken;
  }

  if (_tokenFetchFuture != null) {
    return _tokenFetchFuture!;
  }

  const cooldownDuration = Duration(minutes: 5);
  if (_lastTokenErrorAt != null &&
      DateTime.now().difference(_lastTokenErrorAt!) < cooldownDuration) {
    return null;
  }

  _tokenFetchFuture = _messaging.getToken().then((token) async {
    _cachedToken = token;
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_kStoredTokenKey, token);
    }
    return token;
  }).catchError((Object error) {
    _lastTokenErrorAt = DateTime.now();
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

  // Prevent duplicate listeners - cancel existing ones first
  _foregroundMessageSubscription?.cancel();
  _messageOpenedSubscription?.cancel();
  
  // Set to null to ensure we don't have stale references
  _foregroundMessageSubscription = null;
  _messageOpenedSubscription = null;

  
  _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Prevent duplicate processing of the same message
    final messageId = message.messageId ?? '${DateTime.now().millisecondsSinceEpoch}';
    if (_processedMessageIds.contains(messageId)) {
      if (kDebugMode) {
        debugPrint('⚠️ [FOREGROUND] Message already processed, skipping: $messageId');
      }
      return;
    }
    _processedMessageIds.add(messageId);
    
    // Clean up old message IDs (keep only last 100)
    if (_processedMessageIds.length > 100) {
      _processedMessageIds.remove(_processedMessageIds.first);
    }
    
    if (kDebugMode) {
      debugPrint('📨 [FOREGROUND] Message received: $messageId');
      debugPrint('📨 [FOREGROUND] Has notification: ${message.notification != null}');
      debugPrint('📨 [FOREGROUND] Data: ${message.data}');
      debugPrint('📨 [FOREGROUND] Notification title: ${message.notification?.title}');
      debugPrint('📨 [FOREGROUND] Notification body: ${message.notification?.body}');
    }
    
    final settings = await _messaging.getNotificationSettings();
    if (kDebugMode) {
      debugPrint('📨 [FOREGROUND] Notification settings: ${settings.authorizationStatus}');
    }

    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    RemoteNotification? notification = message.notification;
    
    // On iOS foreground, FCM might strip the notification block, so check data as fallback
    if (notification != null) {
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Notification block present');
        debugPrint('📨 [FOREGROUND] Title: ${notification.title}, Body: ${notification.body}');
      }
      
      _extractAndStoreOTP(notification.body ?? '', message.data);
      
      // On iOS: Firebase shows automatically (we set alert: true)
      // On Android: We show local notification manually
      if (!isIOS) {
        // Only show local notification on Android
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] Showing local notification on Android');
        }
        try {
          await _showForegroundNotification(notification, message.data);
          if (kDebugMode) {
            debugPrint('📨 [FOREGROUND] Local notification shown successfully');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [FOREGROUND] Error showing notification: $e');
            debugPrint('❌ [FOREGROUND] Stack trace: $stackTrace');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] iOS - Firebase will show banner automatically');
        }
      }
    } 
    // Fallback: If notification block is missing (common on iOS foreground), extract from data
    else if (message.data.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Processing data-only message');
      }
     
      // Try multiple possible keys for title and body in data payload
      final title = message.data['title']?.toString() ?? 
                   message.data['notification']?['title']?.toString() ?? 
                   message.data['aps']?['alert']?['title']?.toString() ??
                   message.data['notification']?['title']?.toString() ??
                   message.data['notification_title']?.toString() ??
                   'NANO Work';
      final body = message.data['body']?.toString() ?? 
                  message.data['message']?.toString() ?? 
                  message.data['notification']?['body']?.toString() ?? 
                  message.data['aps']?['alert']?['body']?.toString() ??
                  message.data['notification_body']?.toString() ??
                  'New notification';
      
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Extracted title: $title');
        debugPrint('📨 [FOREGROUND] Extracted body: $body');
      }
     
      _extractAndStoreOTP(body, message.data);
      
     
      if (title != 'NANO Work' || body != 'New notification') {
        final dataNotification = RemoteNotification(
          title: title,
          body: body,
          android: null,
          apple: null,
        );
        
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] Showing data-only notification');
        }
        
        // Show notification on both iOS and Android
        try {
          await _showForegroundNotification(dataNotification, message.data);
          if (kDebugMode) {
            debugPrint('📨 [FOREGROUND] Data-only notification shown successfully');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [FOREGROUND] Error showing data-only notification: $e');
            debugPrint('❌ [FOREGROUND] Stack trace: $stackTrace');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [FOREGROUND] Skipping notification - default title/body');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ [FOREGROUND] Message has no notification and no data');
      }
    }

    try {
      _ref.read(notificationProvider.notifier).refreshUnreadCount();
    } catch (e) {
      
    }
  }, onError: (error) {
   
  });

  _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    
    final notification = message.notification;
    if (notification != null) {
      _extractAndStoreOTP(notification.body ?? '', message.data);
    } else if (message.data.isNotEmpty) {
      final body = message.data['body']?.toString() ?? 
                  message.data['message']?.toString() ?? 
                  message.data['notification']?['body']?.toString() ?? 
                  '';
      _extractAndStoreOTP(body, message.data);
    }
    
    _ref.read(notificationProvider.notifier).refreshUnreadCount();
  }, onError: (error) {
   
  });

}

  
  void _extractAndStoreOTP(String body, Map<String, dynamic> data) {
    try {
     
      final isPasswordReset = body.toLowerCase().contains('otp') ||
          body.toLowerCase().contains('password') ||
          data['type']?.toString().toLowerCase() == 'password_reset' ||
          data['type']?.toString().toLowerCase() == 'forgot_password';

      if (isPasswordReset) {
       
        final otpRegex = RegExp(r'\b\d{6}\b');
        final match = otpRegex.firstMatch(body);
        
        if (match != null) {
          final otp = match.group(0);
          if (otp != null && otp.length == 6) {
           
            _ref.read(otpProvider.notifier).setOTP(otp);
          }
        } else {
        
          final otpFromData = data['otp']?.toString();
          if (otpFromData != null && otpFromData.length == 6) {
            
            _ref.read(otpProvider.notifier).setOTP(otpFromData);
          }
        }
      }
    } catch (e) {
      
    }
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

 
  Future<void> updateBadgeCount(int count) async {
    if (!kPushNotificationsEnabled) {
      return;
    }

    if (kIsWeb) {
      return; 
    }

    try {
     
      final isSupported = await AppBadger.isBadgeSupported();
      if (isSupported) {
        if (count > 0) {
          await AppBadger.updateBadgeCount(count);
         
        } else {
          await AppBadger.removeBadge();
        
        }
      } else {
      }
    } catch (e) {
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription = null;
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

    try {
      const androidInit = AndroidInitializationSettings(_androidNotificationIcon);
     
      final iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      final initialized = await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _ref.read(notificationProvider.notifier).refreshUnreadCount();
        },
      );

      if (initialized != true) {
       
        return;
      }

      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_foregroundChannel);

      _localNotificationsInitialized = true;
      
    } catch (e) {
      
      _localNotificationsInitialized = false;
      rethrow;
    }
  }

  Future<void> _showForegroundNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    if (kDebugMode) {
      debugPrint('🔔 [SHOW] Starting to show notification: ${notification.title} - ${notification.body}');
    }

    if (!_localNotificationsInitialized) {
      if (kDebugMode) {
        debugPrint('🔔 [SHOW] Local notifications not initialized, initializing...');
      }
      try {
        await _initializeLocalNotifications();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [SHOW] Failed to initialize local notifications: $e');
        }
        return;
      }
    }

    if (!_localNotificationsInitialized) {
      if (kDebugMode) {
        debugPrint('❌ [SHOW] Local notifications still not initialized');
      }
      return;
    }

    try {
      // Request iOS permissions if needed
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS) {
        if (kDebugMode) {
          debugPrint('🔔 [SHOW] Requesting iOS permissions...');
        }
        final iosPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final permissionGranted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          if (kDebugMode) {
            debugPrint('🔔 [SHOW] iOS permission granted: $permissionGranted');
          }
          if (permissionGranted != true) {
            if (kDebugMode) {
              debugPrint('❌ [SHOW] iOS permissions not granted');
            }
            return;
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [SHOW] iOS plugin not available');
          }
        }
      }

      // Ensure Android channel exists
      final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        if (kDebugMode) {
          debugPrint('🔔 [SHOW] Creating Android notification channel...');
        }
        await androidPlugin.createNotificationChannel(_foregroundChannel);
      }

      final androidDetails = AndroidNotificationDetails(
        _foregroundChannel.id,
        _foregroundChannel.name,
        channelDescription: _foregroundChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: _androidNotificationIcon,
        largeIcon: const DrawableResourceAndroidBitmap('nano_notification'),
      );

      // iOS notification details with banner presentation
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Force banner presentation even in foreground
        interruptionLevel: InterruptionLevel.active,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      final title = notification.title ?? 'NANO Work';
      final body = notification.body ?? '';

      if (kDebugMode) {
        debugPrint('🔔 [SHOW] Showing notification - ID: $notificationId, Title: $title, Body: $body');
      }

      // For iOS, we need to ensure the notification is shown as a banner
      if (isIOS) {
        final iosPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          // Request permissions again to ensure banner presentation
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      }

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: data.isNotEmpty ? jsonEncode(data) : null,
      );

      if (kDebugMode) {
        debugPrint('✅ [SHOW] Notification shown successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [SHOW] Error showing notification: $e');
        debugPrint('❌ [SHOW] Stack trace: $stackTrace');
      }
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
