import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

class AuthService {
  String? _currentUserId;
  String? _currentEmployeeId;
  final ApiService _apiService;

  AuthService(this._apiService);

  // Get current user
  String? get currentUserId => _currentUserId;
  String? get currentEmployeeId => _currentEmployeeId;

  // Set current user (for internal use)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  // Set current employee ID
  void setCurrentEmployeeId(String? employeeId) {
    _currentEmployeeId = employeeId;
  }

  // Check if user is authenticated
  bool get isAuthenticated =>
      _currentUserId != null && _currentEmployeeId != null;

  // Auth state stream
  Stream<String?> get authStateChanges => Stream.value(_currentUserId);

  // Sign in with email and password using API
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Call login API directly - backend handles email validation
      final response = await _apiService.loginUser(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        final employeeData = response['employee'];
        _currentUserId = employeeData['authId'] ?? employeeData['id'] ?? email;
        _currentEmployeeId = employeeData['id'] ?? employeeData['uid'];

        return {
          'success': true,
          'message': response['message'] ?? 'Login successful',
          'data': employeeData,
        };
      } else {
        // Return API error response directly
        return response;
      }
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Register user with email and password
  Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await _apiService.registerUser(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        final userData = response['data'];
        _currentUserId = userData['userId'] ?? userData['id'] ?? email;

        return {
          'success': true,
          'message': response['message'] ?? 'Registration successful',
          'data': userData,
        };
      } else {
        // Return API error response directly
        return response;
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Get employee profile
  Future<Map<String, dynamic>> getEmployeeProfile() async {
    try {
      if (_currentEmployeeId == null) {
        return {
          'success': false,
          'message': 'No employee ID found. Please login first.',
        };
      }

      final response = await _apiService.getEmployeeProfile(
        employeeId: _currentEmployeeId!,
      );

      if (response['success'] == true) {
        return response;
      } else {
        return response;
      }
    } catch (e) {
      throw Exception('Failed to get employee profile: ${e.toString()}');
    }
  }

  // Restore authentication state from SharedPreferences
  Future<void> restoreAuthState() async {
    try {
      // This will be called by the auth repository when checking login state
      // The actual restoration is handled in the auth repository
    } catch (e) {
      print('❌ Failed to restore auth state: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUserId = null;
      _currentEmployeeId = null;
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
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
