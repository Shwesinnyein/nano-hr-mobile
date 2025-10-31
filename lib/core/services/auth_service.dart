import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'push_notification_service.dart';

class AuthService {
  String? _currentUserId;
  String? _currentEmployeeId;
  String? _currentEmployeeName;
  String? _currentEmployeeFirstName;
  String? _currentEmployeeLastName;
  String? _currentPositionName;
  final ApiService _apiService;

  AuthService(this._apiService);

  // Get current user
  String? get currentUserId => _currentUserId;
  String? get currentEmployeeId => _currentEmployeeId;
  String? get currentEmployeeName => _currentEmployeeName;
  String? get currentEmployeeFirstName => _currentEmployeeFirstName;
  String? get currentEmployeeLastName => _currentEmployeeLastName;
  String? get currentPositionName => _currentPositionName;

  // Set current user (for internal use)
  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  // Set current employee ID
  void setCurrentEmployeeId(String? employeeId) {
    _currentEmployeeId = employeeId;
  }

  // Set current employee name and position
  void setCurrentEmployeeName(
    String? firstName,
    String? lastName,
    String? positionName,
  ) {
    _currentEmployeeFirstName = firstName;
    _currentEmployeeLastName = lastName;
    _currentEmployeeName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    _currentPositionName = positionName;
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

        // Store employee name and position information
        _currentEmployeeFirstName =
            employeeData['firstName'] ?? employeeData['first_name'];
        _currentEmployeeLastName =
            employeeData['lastName'] ?? employeeData['last_name'];
        _currentEmployeeName =
            '${_currentEmployeeFirstName ?? ''} ${_currentEmployeeLastName ?? ''}'
                .trim();
        _currentPositionName =
            employeeData['positionName'] ??
            employeeData['position_name'] ??
            employeeData['jobTitle'] ??
            employeeData['job_title'];

        // Persist UID for push registration (backend expects employees.uid)
        final uid = employeeData['uid'] ?? _currentEmployeeId;
        try {
          final prefs = await SharedPreferences.getInstance();
          if (uid != null) await prefs.setString('employee_uid', uid);
        } catch (_) {}

        // Initialize push notifications (requests permission and registers token)
        await PushNotificationService.init();

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

  // Sign in with email and password using mobile API (new endpoint)
  Future<Map<String, dynamic>> signInWithEmailAndPasswordMobile(
    String email,
    String password,
  ) async {
    try {
      // Call mobile login API directly
      final response = await _apiService.loginUserMobile(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        final employeeData = response['employee'];
        final token = response['token'];

        _currentUserId = employeeData['authId'] ?? employeeData['id'] ?? email;
        _currentEmployeeId = employeeData['id'] ?? employeeData['uid'];

        // Store employee name and position information
        _currentEmployeeFirstName =
            employeeData['firstName'] ?? employeeData['first_name'];
        _currentEmployeeLastName =
            employeeData['lastName'] ?? employeeData['last_name'];
        _currentEmployeeName =
            '${_currentEmployeeFirstName ?? ''} ${_currentEmployeeLastName ?? ''}'
                .trim();
        _currentPositionName =
            employeeData['positionName'] ??
            employeeData['position_name'] ??
            employeeData['jobTitle'] ??
            employeeData['job_title'];

        // Persist UID for push registration (backend expects employees.uid)
        final uid = employeeData['uid'] ?? _currentEmployeeId;
        try {
          final prefs = await SharedPreferences.getInstance();
          if (uid != null) await prefs.setString('employee_uid', uid);
        } catch (_) {}

        // Initialize push notifications (requests permission and registers token)
        await PushNotificationService.init();

        return {
          'success': true,
          'message': response['message'] ?? 'Mobile login successful',
          'employee': employeeData,
          'token': token, // Include token in response
        };
      } else {
        // Throw exception for failed login so it gets caught by the UI
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      // If it's already an Exception with the message, just rethrow it
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Check if email already exists
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await _apiService.checkEmailExists(email: email);
      return response;
    } catch (e) {
      throw Exception('Email check failed: ${e.toString()}');
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

      // SECURITY: Only allow users to get their own profile
      // The backend should also verify this on the server side
      final response = await _apiService.getEmployeeProfile(
        employeeId: _currentEmployeeId!, // Only current user's ID
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
      if (kDebugMode) {
        print('❌ Failed to restore auth state: $e');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUserId = null;
      _currentEmployeeId = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('employee_uid');
      } catch (_) {}
      await PushNotificationService.onLogout();
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
