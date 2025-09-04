import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBFpkfsMPcIk-k62lCBXN_I1iKdEEfMic8",
    appId: "1:794565998064:web:c80c1afd1ec663f712d935",
    messagingSenderId: "794565998064",
    projectId: "nano-hr",
    authDomain: "nano-hr.firebaseapp.com",
    storageBucket: "nano-hr.firebasestorage.app",
    measurementId: "G-8B2B86RENZ",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBFpkfsMPcIk-k62lCBXN_I1iKdEEfMic8",
    appId: "1:794565998064:android:your_android_app_id",
    messagingSenderId: "794565998064",
    projectId: "nano-hr",
    storageBucket: "nano-hr.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBFpkfsMPcIk-k62lCBXN_I1iKdEEfMic8",
    appId: "1:794565998064:ios:1234567890abcdef",
    messagingSenderId: "794565998064",
    projectId: "nano-hr",
    storageBucket: "nano-hr.firebasestorage.app",
    iosBundleId: "com.example.nanoHrMobile",
  );
}
