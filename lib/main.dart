import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // In release mode, we need to handle errors gracefully
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Initialize push notifications (FCM, local notifications)
  await PushNotificationService.init();

  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const ProviderScope(child: App()));
}
