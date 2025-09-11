import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  String? _currentUserId;

  AuthService();

  // Get current user
  String? get currentUserId => _currentUserId;

  // Set current user (for internal use)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  // Auth state stream
  Stream<String?> get authStateChanges => Stream.value(_currentUserId);

  // Sign in with email and password using Firebase
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔄 AuthService: Signing in with email: $email');

      // Simple mock login - accept any email/password combination
      await Future.delayed(const Duration(seconds: 1));

      _currentUserId = 'mock-user-id';
      print('✅ AuthService: Sign in successful');
      return {
        'success': true,
        'message': 'Sign in successful',
        'data': {'userId': _currentUserId},
      };
    } catch (e) {
      print('❌ AuthService: Sign in error: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign up with email and password using Firebase
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔄 AuthService: Signing up with email: $email');

      // Simple mock signup - accept any email/password combination
      await Future.delayed(const Duration(seconds: 1));

      _currentUserId = 'mock-user-id';
      print('✅ AuthService: Sign up successful');
      return {
        'success': true,
        'message': 'Sign up successful',
        'data': {'userId': _currentUserId},
      };
    } catch (e) {
      print('❌ AuthService: Sign up error: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🔄 AuthService: Signing out');

      _currentUserId = null;

      print('✅ AuthService: Sign out successful');
    } catch (e) {
      print('❌ AuthService: Sign out error: $e');
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

// Provider for authentication state
final authStateProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});
