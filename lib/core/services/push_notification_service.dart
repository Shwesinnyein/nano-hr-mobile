import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_badger/app_badger.dart';
import 'package:permission_handler/permission_handler.dart';

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
  int _notificationCounter = 0; // Counter to ensure unique IDs for rapid notifications

  static const AndroidNotificationChannel _foregroundChannel =
      AndroidNotificationChannel(
    'nano_hr_foreground',
    'In-app notifications',
    description: 'Notifications displayed while the app is open',
    importance: Importance.max, // Max importance for immediate display
    showBadge: true,
    enableVibration: true,
    playSound: true,
  );

  // High importance channel required by Firebase/Google Play
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for essential notifications.',
    importance: Importance.max,
    showBadge: true,
    enableVibration: true,
    playSound: true,
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
    // For Android 13+ (API 33+), we need to request POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('🔔 [PERM] Checking Android notification permission...');
      }
      
      try {
        final status = await Permission.notification.status;
        if (kDebugMode) {
          debugPrint('🔔 [PERM] Android notification permission status: $status');
        }
        
        if (status.isDenied) {
          if (kDebugMode) {
            debugPrint('🔔 [PERM] Requesting Android notification permission...');
          }
          final result = await Permission.notification.request();
          if (kDebugMode) {
            debugPrint('🔔 [PERM] Android notification permission request result: $result');
          }
          if (result.isDenied || result.isPermanentlyDenied) {
            if (kDebugMode) {
              debugPrint('❌ [PERM] Android notification permission denied');
            }
            return false;
          }
        } else if (status.isPermanentlyDenied) {
          if (kDebugMode) {
            debugPrint('❌ [PERM] Android notification permission permanently denied');
          }
          return false;
        }
        
        if (kDebugMode) {
          debugPrint('✅ [PERM] Android notification permission granted');
        }
        return true;
      } catch (e) {
        // On Android 12 and below, Permission.notification might not be available
        // In that case, notifications work without runtime permission
        if (kDebugMode) {
          debugPrint('⚠️ [PERM] Could not check Android notification permission (likely Android < 13): $e');
          debugPrint('✅ [PERM] Assuming permission granted for Android < 13');
        }
        return true;
      }
    }
    
    // For iOS, use Firebase's permission request
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    
    if (kDebugMode) {
      debugPrint('🔔 [PERM] iOS notification permission: $granted');
    }
    
    return granted;
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
    // Extract notification type and content FIRST to create a proper unique ID
    // This is critical for data-only messages (like leave_rejected/leave_approved)
    final notificationType = message.data['type']?.toString() ?? 
                             message.data['notification_type']?.toString() ??
                             message.data['action']?.toString() ?? '';
    
    // Get title and body from notification block or data payload
    // Priority: notification block > data['title']/data['body'] > data['notification_title']/data['notification_body'] > data['message']
    String notificationTitle = message.notification?.title ?? 
                               message.data['title']?.toString() ??
                               message.data['notification_title']?.toString() ?? '';
    String notificationBody = message.notification?.body ?? 
                              message.data['body']?.toString() ?? 
                              message.data['notification_body']?.toString() ??
                              message.data['message']?.toString() ?? '';
    
    // For leave notifications, construct meaningful titles if missing
    if ((notificationTitle.isEmpty) && notificationType.isNotEmpty) {
      if (notificationType.contains('leave_request')) {
        notificationTitle = 'Leave Request';
        notificationBody = notificationBody.isEmpty ? (message.data['message']?.toString() ?? 'New leave request received') : notificationBody;
      } else if (notificationType.contains('leave_approved') || notificationType.contains('approved')) {
        notificationTitle = 'Leave Approved';
        notificationBody = notificationBody.isEmpty ? (message.data['message']?.toString() ?? 'Your leave request has been approved') : notificationBody;
      } else if (notificationType.contains('leave_rejected') || notificationType.contains('rejected')) {
        notificationTitle = 'Leave Rejected';
        notificationBody = notificationBody.isEmpty ? (message.data['message']?.toString() ?? 'Your leave request has been rejected') : notificationBody;
      }
    }
    
    // Create a unique identifier that includes messageId + notification type + content
    // CRITICAL: For Android, ensure each notification gets a truly unique ID
    // For iOS, use messageId (Firebase ensures uniqueness)
    final baseMessageId = message.messageId ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    
    // Increment counter for each notification to ensure uniqueness (especially for rapid notifications on Android)
    _notificationCounter++;
    
    // For Android: Use counter + timestamp + type + messageId to ensure each notification is unique
    // This ensures that even if two notifications arrive quickly with same type, they're treated as different
    // For iOS: Use messageId + type (Firebase ensures unique messageIds, so this is sufficient)
    final uniqueId = isAndroid
        ? '${baseMessageId}_${notificationType}_${timestamp}_${_notificationCounter}_${notificationTitle.hashCode}_${notificationBody.hashCode}'
        : (baseMessageId.isNotEmpty 
            ? '${baseMessageId}_${notificationType}'
            : '${timestamp}_${notificationType}');
    
    if (_processedMessageIds.contains(uniqueId)) {
      if (kDebugMode) {
        debugPrint('⚠️ [FOREGROUND] Message already processed, skipping: $uniqueId');
        debugPrint('⚠️ [FOREGROUND] Original messageId: ${message.messageId}');
        debugPrint('⚠️ [FOREGROUND] Type: $notificationType, Title: $notificationTitle, Body: $notificationBody');
        debugPrint('⚠️ [FOREGROUND] Counter: $_notificationCounter, Timestamp: $timestamp');
      }
      return;
    }
    
    _processedMessageIds.add(uniqueId);
    
    // Clean up old message IDs (keep only last 200 to handle rapid notifications)
    if (_processedMessageIds.length > 200) {
      final idsToRemove = _processedMessageIds.take(50).toList();
      for (final id in idsToRemove) {
        _processedMessageIds.remove(id);
      }
    }
    
    if (kDebugMode) {
      debugPrint('📨 [FOREGROUND] Message received - uniqueId: $uniqueId');
      debugPrint('📨 [FOREGROUND] Original messageId: ${message.messageId}');
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
    // On Android, we ALWAYS show local notification manually (Firebase doesn't show foreground notifications automatically)
    if (notification != null) {
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Notification block present');
        debugPrint('📨 [FOREGROUND] Title: ${notification.title}, Body: ${notification.body}');
        debugPrint('📨 [FOREGROUND] Platform: ${isIOS ? "iOS" : "Android"}');
        debugPrint('📨 [FOREGROUND] Has data: ${message.data.isNotEmpty}');
        debugPrint('📨 [FOREGROUND] Notification type from data: $notificationType');
      }
      
      _extractAndStoreOTP(notification.body ?? '', message.data);
      
      // On iOS: Firebase shows automatically (we set alert: true in main.dart)
      // On Android: We MUST show local notification manually - Firebase doesn't show foreground notifications
      if (!isIOS) {
        // Android: ALWAYS show local notification manually - use await to ensure it's displayed
        // Check if we need to enhance the notification with data payload info (for approve/reject)
        RemoteNotification notificationToShow = notification;
        
        // If notification type is in data, always use the enhanced title/body from data payload
        // This ensures approve/reject notifications show properly even if notification block has generic content
        if (notificationType.isNotEmpty) {
          // Use enhanced title/body from data payload (already extracted at the top)
          String enhancedTitle = notificationTitle.isNotEmpty ? notificationTitle : (notification.title ?? 'NANO Work');
          String enhancedBody = notificationBody.isNotEmpty ? notificationBody : (notification.body ?? '');
          
          if (kDebugMode) {
            debugPrint('📨 [FOREGROUND] Android - Notification type detected: $notificationType');
            debugPrint('📨 [FOREGROUND] Android - Enhancing notification with data payload');
            debugPrint('📨 [FOREGROUND] Android - Original title: ${notification.title}');
            debugPrint('📨 [FOREGROUND] Android - Enhanced title: $enhancedTitle');
            debugPrint('📨 [FOREGROUND] Android - Original body: ${notification.body}');
            debugPrint('📨 [FOREGROUND] Android - Enhanced body: $enhancedBody');
          }
          
          notificationToShow = RemoteNotification(
            title: enhancedTitle,
            body: enhancedBody,
            android: notification.android,
            apple: notification.apple,
          );
        }
        
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] Android - Calling _showForegroundNotification()');
          debugPrint('📨 [FOREGROUND] Android - Final title: ${notificationToShow.title}');
          debugPrint('📨 [FOREGROUND] Android - Final body: ${notificationToShow.body}');
        }
        // Generate unique notification ID using counter to prevent collisions
        final notificationId = (_notificationCounter * 1000 + timestamp.remainder(1000)).remainder(1 << 31);
        
        try {
          await _showForegroundNotification(notificationToShow, message.data, notificationId: notificationId);
          if (kDebugMode) {
            debugPrint('✅ [FOREGROUND] Android - Local notification shown successfully');
            debugPrint('✅ [FOREGROUND] Android - Notification ID: $notificationId');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [FOREGROUND] Android - Error showing notification: $e');
            debugPrint('❌ [FOREGROUND] Android - Stack trace: $stackTrace');
          }
        }
      } else {
        // iOS: Firebase shows automatically (we set alert: true in main.dart)
        // Don't show local notification to avoid duplicates
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] iOS - Firebase will show banner automatically (no local notification to avoid duplicates)');
        }
      }
    } 
    // Fallback: If notification block is missing (common on iOS foreground), extract from data
    // This is important for Android when backend sends data-only payloads (e.g., leave_rejected, leave_approved)
    else if (message.data.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Processing data-only message');
        debugPrint('📨 [FOREGROUND] Data keys: ${message.data.keys.toList()}');
      }
     
      // Try multiple possible keys for title and body in data payload
      String? title;
      String? body;
      
      // Check for leave-related notification types
      final notificationType = message.data['type']?.toString() ?? 
                              message.data['notification_type']?.toString() ??
                              message.data['action']?.toString();
      
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Notification type: $notificationType');
      }
      
      // Extract title and body from various possible keys
      title = message.data['title']?.toString() ?? 
                   message.data['notification']?['title']?.toString() ?? 
                   message.data['aps']?['alert']?['title']?.toString() ??
              message.data['notification_title']?.toString();
      
      body = message.data['body']?.toString() ?? 
                  message.data['message']?.toString() ?? 
                  message.data['notification']?['body']?.toString() ?? 
                  message.data['aps']?['alert']?['body']?.toString() ??
             message.data['notification_body']?.toString() ??
             message.data['text']?.toString();
      
      // For leave notifications, construct meaningful messages if title/body are missing
      if ((title == null || title.isEmpty) && notificationType != null) {
        if (notificationType.contains('leave_request')) {
          title = 'Leave Request';
          body = body ?? message.data['message']?.toString() ?? 'New leave request received';
        } else if (notificationType.contains('leave_approved') || notificationType.contains('approved')) {
          title = 'Leave Approved';
          body = body ?? message.data['message']?.toString() ?? 'Your leave request has been approved';
        } else if (notificationType.contains('leave_rejected') || notificationType.contains('rejected')) {
          title = 'Leave Rejected';
          body = body ?? message.data['message']?.toString() ?? 'Your leave request has been rejected';
        }
      }
      
      // Default fallback
      title = title ?? 'NANO Work';
      body = body ?? 'New notification';
      
      if (kDebugMode) {
        debugPrint('📨 [FOREGROUND] Extracted title: $title');
        debugPrint('📨 [FOREGROUND] Extracted body: $body');
      }
     
      _extractAndStoreOTP(body, message.data);
      
      // Always show notification if we have meaningful content (not default values)
      // This ensures leave_rejected and leave_approved are shown on Android
      if (title != 'NANO Work' || body != 'New notification' || notificationType != null) {
        final dataNotification = RemoteNotification(
          title: title,
          body: body,
          android: null,
          apple: null,
        );
        
        if (kDebugMode) {
          debugPrint('📨 [FOREGROUND] Showing data-only notification');
          debugPrint('📨 [FOREGROUND] Title: $title, Body: $body, Type: $notificationType');
        }
        
             // On Android: Always show data-only notifications
             // On iOS: Firebase shows automatically, don't show local to avoid duplicates
             if (!isIOS) {
               // Android: Always show local notification for data-only messages
               // Generate unique notification ID using counter to prevent collisions
               final notificationId = (_notificationCounter * 1000 + timestamp.remainder(1000)).remainder(1 << 31);
               
               if (kDebugMode) {
                 debugPrint('📨 [FOREGROUND] Android - Calling _showForegroundNotification() for data-only');
                 debugPrint('📨 [FOREGROUND] Android - Notification ID: $notificationId');
               }
               try {
                 await _showForegroundNotification(dataNotification, message.data, notificationId: notificationId);
                 if (kDebugMode) {
                   debugPrint('✅ [FOREGROUND] Android - Data-only notification shown successfully');
                 }
               } catch (e, stackTrace) {
                 if (kDebugMode) {
                   debugPrint('❌ [FOREGROUND] Android - Error showing data-only notification: $e');
                   debugPrint('❌ [FOREGROUND] Android - Stack trace: $stackTrace');
                 }
               }
             } else {
          // iOS: Firebase shows automatically (we set alert: true in main.dart)
          // NEVER show local notification for iOS to avoid duplicates
          // Firebase handles all iOS foreground notifications automatically
          if (kDebugMode) {
            debugPrint('📨 [FOREGROUND] iOS - Firebase will show banner automatically');
            debugPrint('📨 [FOREGROUND] iOS - NOT showing local notification to prevent duplicates');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [FOREGROUND] Skipping notification - default title/body and no notification type');
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
      if (androidPlugin != null) {
        // Create high importance channel (required by Firebase/Google Play)
        await androidPlugin.createNotificationChannel(_highImportanceChannel);
        // Create foreground channel for in-app notifications
        await androidPlugin.createNotificationChannel(_foregroundChannel);
        if (kDebugMode) {
          debugPrint('🔔 [INIT] Created Android notification channels: high_importance_channel, nano_hr_foreground');
        }
      }

      _localNotificationsInitialized = true;
      
    } catch (e) {
      
      _localNotificationsInitialized = false;
      rethrow;
    }
  }

  Future<void> _showForegroundNotification(
    RemoteNotification notification,
    Map<String, dynamic> data, {
    int? notificationId,
  }) async {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      debugPrint('🔔 [SHOW] ===== STARTING _showForegroundNotification() =====');
      debugPrint('🔔 [SHOW] Platform: ${isAndroid ? "Android" : "iOS"}');
      debugPrint('🔔 [SHOW] Title: ${notification.title}');
      debugPrint('🔔 [SHOW] Body: ${notification.body}');
      debugPrint('🔔 [SHOW] Data: $data');
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

      // For Android: Check permissions and ensure channel is ready
      if (!isIOS) {
        // Check Android notification permission (Android 13+)
        bool permissionGranted = true;
        try {
          final permissionStatus = await Permission.notification.status;
          if (kDebugMode) {
            debugPrint('🔔 [SHOW] Android notification permission status: $permissionStatus');
          }
          
          if (permissionStatus.isDenied) {
            if (kDebugMode) {
              debugPrint('⚠️ [SHOW] Android notification permission denied, requesting...');
            }
            final result = await Permission.notification.request();
            if (kDebugMode) {
              debugPrint('🔔 [SHOW] Android notification permission request result: $result');
            }
            if (result.isDenied || result.isPermanentlyDenied) {
              if (kDebugMode) {
                debugPrint('❌ [SHOW] Android notification permission not granted, cannot show notification');
              }
              permissionGranted = false;
            } else {
              permissionGranted = true;
            }
          } else if (permissionStatus.isPermanentlyDenied) {
            if (kDebugMode) {
              debugPrint('❌ [SHOW] Android notification permission permanently denied');
            }
            permissionGranted = false;
          } else {
            permissionGranted = true;
          }
        } catch (e) {
          // On Android 12 and below, proceed without permission check
          if (kDebugMode) {
            debugPrint('✅ [SHOW] Android < 13, proceeding without permission check: $e');
          }
          permissionGranted = true; // Assume granted for Android < 13
        }
        
        if (!permissionGranted) {
          if (kDebugMode) {
            debugPrint('❌ [SHOW] Cannot show notification - permission not granted');
          }
          return;
        }
        
        // Ensure Android channels exist and are properly configured
        final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          if (kDebugMode) {
            debugPrint('🔔 [SHOW] Ensuring Android notification channels exist...');
          }
          try {
            // Create high importance channel (required by Firebase/Google Play)
            await androidPlugin.createNotificationChannel(_highImportanceChannel);
            // Create foreground channel for in-app notifications
            await androidPlugin.createNotificationChannel(_foregroundChannel);
            if (kDebugMode) {
              debugPrint('✅ [SHOW] Android notification channels ready');
              debugPrint('🔔 [SHOW] High importance channel: ${_highImportanceChannel.id}');
              debugPrint('🔔 [SHOW] Foreground channel: ${_foregroundChannel.id}');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [SHOW] Error creating channels (might already exist): $e');
            }
            // Continue anyway - channels might already exist
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ [SHOW] Android plugin not available!');
          }
          return;
        }
      }

      // Use high_importance_channel for Android (required by Firebase/Google Play)
      // This matches the channel ID in AndroidManifest.xml
      final androidDetails = AndroidNotificationDetails(
        _highImportanceChannel.id, // Use high_importance_channel instead of _foregroundChannel
        _highImportanceChannel.name,
        channelDescription: _highImportanceChannel.description,
        importance: Importance.max, // Max importance for immediate display
        priority: Priority.max, // Max priority to show immediately
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: _androidNotificationIcon,
        largeIcon: const DrawableResourceAndroidBitmap('nano_notification'),
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.message,
        autoCancel: true,
        ongoing: false,
      );

      // iOS notification details with banner presentation
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Force banner presentation even in foreground
        interruptionLevel: InterruptionLevel.active,
      );

      // Use provided notificationId or generate a unique one
      // This ensures each notification gets a unique ID, preventing one from replacing another
      final finalNotificationId = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
      final title = notification.title ?? 'NANO Work';
      final body = notification.body ?? '';

      if (kDebugMode) {
        debugPrint('🔔 [SHOW] About to call _localNotificationsPlugin.show()');
        debugPrint('🔔 [SHOW] Notification ID: $finalNotificationId');
        debugPrint('🔔 [SHOW] Title: $title');
        debugPrint('🔔 [SHOW] Body: $body');
        debugPrint('🔔 [SHOW] Platform: ${isIOS ? "iOS" : "Android"}');
        debugPrint('🔔 [SHOW] Channel ID: ${isIOS ? "iOS" : _highImportanceChannel.id}');
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

      if (kDebugMode) {
        debugPrint('🔔 [SHOW] Calling _localNotificationsPlugin.show() NOW');
        debugPrint('🔔 [SHOW] Platform: ${isIOS ? "iOS" : "Android"}');
        debugPrint('🔔 [SHOW] Notification ID: $finalNotificationId');
      }

      // Show notification - this is the critical call
      if (kDebugMode) {
        debugPrint('🔔 [SHOW] EXECUTING _localNotificationsPlugin.show() NOW');
        if (!isIOS) {
          debugPrint('🔔 [SHOW] Channel ID: ${_highImportanceChannel.id}');
        }
        debugPrint('🔔 [SHOW] Importance: ${androidDetails.importance}');
        debugPrint('🔔 [SHOW] Priority: ${androidDetails.priority}');
      }

      await _localNotificationsPlugin.show(
        finalNotificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: data.isNotEmpty ? jsonEncode(data) : null,
      );

      if (kDebugMode) {
        debugPrint('✅ [SHOW] ===== Notification shown successfully =====');
        debugPrint('✅ [SHOW] Platform: ${isIOS ? "iOS" : "Android"}');
        debugPrint('✅ [SHOW] Notification ID: $finalNotificationId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [SHOW] ===== ERROR showing notification =====');
        debugPrint('❌ [SHOW] Error: $e');
        debugPrint('❌ [SHOW] Error type: ${e.runtimeType}');
        debugPrint('❌ [SHOW] Stack trace: $stackTrace');
        debugPrint('❌ [SHOW] Platform: ${defaultTargetPlatform == TargetPlatform.android ? "Android" : "iOS"}');
      }
      // Re-throw to see the error in logs
      rethrow;
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
