import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app/app.dart';
import 'core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  FirebaseOptions? firebaseOptions;

  if (kIsWeb) {
    firebaseOptions = FirebaseConfig.web;
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    firebaseOptions = FirebaseConfig.ios;
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    firebaseOptions = FirebaseConfig.android;
  }

  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ProviderScope(child: App()));
}
