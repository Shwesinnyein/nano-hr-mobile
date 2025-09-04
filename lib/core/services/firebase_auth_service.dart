import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID token
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔄 Firebase: Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Firebase: Sign in successful for user: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      print('❌ Firebase: Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔄 Firebase: Signing out');
      await _auth.signOut();
      print('✅ Firebase: Sign out successful');
    } catch (e) {
      print('❌ Firebase: Sign out error: $e');
      rethrow;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;
}

// Provider for FirebaseAuthService
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// Provider for authentication state
final firebaseAuthStateProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
