import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

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
            employeeData['positionName'];
            

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
  // First checks Firebase Authentication, then gets employee data from backend
  Future<Map<String, dynamic>> signInWithEmailAndPasswordMobile(
    String email,
    String password,
  ) async {
    try {
      final firebaseAuth = FirebaseAuth.instance;
      
      // Step 1: Try to sign in with Firebase Auth first
      try {
        final userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Firebase Auth login successful - user exists in Firebase
        if (userCredential.user != null) {
          // Step 2: Get employee data from backend
          try {
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

              return {
                'success': true,
                'message': response['message'] ?? 'Login successful',
                'employee': employeeData,
                'token': token,
              };
            } else {
              // Backend API failed - provide detailed error message
              final errorMessage = response['message'] ?? 'Failed to get employee data from server';
              if (kDebugMode) {
                print('❌ Backend login failed: $errorMessage');
                print('Response: $response');
              }
              throw Exception('$errorMessage. Please check if your email exists in the employee system or contact HR.');
            }
          } catch (e) {
            // If backend API call throws an exception (network error, etc.)
            if (kDebugMode) {
              print('❌ Backend API error: $e');
            }
            // Re-throw with more context
            if (e is Exception) {
              throw Exception('Unable to connect to server: ${e.toString()}');
            }
            throw Exception('Backend error: ${e.toString()}');
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle different Firebase Auth error codes
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // 'invalid-credential' can mean either user-not-found OR wrong-password
          // We need to check if user exists in Firebase Auth to distinguish
          try {
            // Check if email exists in Firebase Auth by trying to fetch sign-in methods
            final signInMethods = await firebaseAuth.fetchSignInMethodsForEmail(email);
            
            if (kDebugMode) {
              print('🔍 Login check - Sign-in methods for $email: $signInMethods');
            }
            
            if (signInMethods.isNotEmpty) {
              // User exists in Firebase Auth - password must be wrong
              if (kDebugMode) {
                print('❌ Login: Email $email exists in Firebase Auth but password is wrong');
              }
              throw Exception('PASSWORD_INCORRECT');
            } else {
              // User doesn't exist in Firebase Auth - check if email exists in employee table
              if (kDebugMode) {
                print('✅ Login: Email $email does NOT exist in Firebase Auth - checking employee table');
              }
              final emailCheckResult = await checkEmailExists(email);
              if (emailCheckResult['success'] == true && emailCheckResult['exists'] == true) {
                // Email exists in employee table but not in Firebase Auth - needs registration
                if (kDebugMode) {
                  print('✅ Login: Email $email exists in employee table - needs registration');
                }
                throw Exception('EMAIL_EXISTS_IN_EMPLOYEE_TABLE');
              } else {
                // Email doesn't exist in employee table either
                if (kDebugMode) {
                  print('❌ Login: Email $email does NOT exist in employee table');
                }
                throw Exception('EMAIL_NOT_FOUND_IN_SYSTEM');
              }
            }
          } catch (checkError) {
            // If email check fails or returns specific error, rethrow it
            if (checkError.toString().contains('PASSWORD_INCORRECT') ||
                checkError.toString().contains('EMAIL_EXISTS_IN_EMPLOYEE_TABLE') ||
                checkError.toString().contains('EMAIL_NOT_FOUND_IN_SYSTEM')) {
              rethrow;
            }
            // If check itself fails, check employee table as fallback
            try {
              final emailCheckResult = await checkEmailExists(email);
              if (emailCheckResult['success'] == true && emailCheckResult['exists'] == true) {
                throw Exception('EMAIL_EXISTS_IN_EMPLOYEE_TABLE');
              } else {
                throw Exception('EMAIL_NOT_FOUND_IN_SYSTEM');
              }
            } catch (_) {
              throw Exception('You need to register first. Please sign up to create your account.');
            }
          }
        } else if (e.code == 'wrong-password') {
          // User exists but password is incorrect (older Firebase versions)
          throw Exception('PASSWORD_INCORRECT');
        } else if (e.code == 'invalid-email') {
          throw Exception('Invalid email address. Please check your email and try again.');
        } else if (e.code == 'user-disabled') {
          throw Exception('This account has been disabled. Please contact HR.');
        } else if (e.code == 'too-many-requests') {
          throw Exception('Too many failed login attempts. Please try again later.');
        } else if (e.code == 'network-request-failed') {
          throw Exception('Network error. Please check your internet connection and try again.');
        }
        // Other Firebase Auth errors - show user-friendly message
        final errorMessage = e.message ?? e.code;
        if (errorMessage.contains('malformed') || errorMessage.contains('expired')) {
          throw Exception('Invalid email or password. Please check your credentials and try again.');
        }
        throw Exception('Authentication failed: $errorMessage');
      }
      
      throw Exception('Login failed');
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
  // Flow:
  // 1. Check if email exists in employee table
  // 2. If exists, call backend API to register (backend will check Firebase Auth and create user)
  // 3. Backend returns customToken and employee data
  Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final firebaseAuth = FirebaseAuth.instance;
      
      // ✅ STEP 1: Check if email exists in employee table
      if (kDebugMode) {
        print('🔍 [REGISTER] Checking if email exists in employee table: $email');
      }
      
      final emailCheckResult = await checkEmailExists(email);
      if (emailCheckResult['success'] == false) {
        throw Exception('Failed to verify email. Please try again.');
      }
      
      if (emailCheckResult['exists'] == false || emailCheckResult['exists'] == null) {
        // Email doesn't exist in employee table - show "Contact HR" message
        if (kDebugMode) {
          print('❌ [REGISTER] Email $email not found in employee table');
        }
        throw Exception('EMAIL_NOT_FOUND_IN_EMPLOYEE_TABLE');
      }
      
      // ✅ STEP 2: Double-check Firebase Auth before calling backend
      // This prevents calling backend if email already exists in Firebase Auth
      try {
        final signInMethods = await firebaseAuth.fetchSignInMethodsForEmail(email);
        if (kDebugMode) {
          print('🔍 [REGISTER] Double-checking Firebase Auth for: $email');
          print('🔍 [REGISTER] Sign-in methods: $signInMethods');
        }
        
        if (signInMethods.isNotEmpty) {
          // Email already exists in Firebase Auth - user should login instead
          if (kDebugMode) {
            print('❌ [REGISTER] Email $email already exists in Firebase Auth - should login instead');
          }
          throw Exception('EMAIL_ALREADY_IN_FIREBASE_AUTH');
        }
        if (kDebugMode) {
          print('✅ [REGISTER] Email $email confirmed NOT in Firebase Auth - proceeding to backend...');
        }
      } catch (e) {
        // If it's our custom exception, rethrow it
        if (e.toString().contains('EMAIL_ALREADY_IN_FIREBASE_AUTH')) {
          rethrow;
        }
        // For other errors (network, etc.), continue to backend (backend will handle it)
        if (kDebugMode) {
          print('⚠️ [REGISTER] Firebase Auth check error (continuing): $e');
        }
      }
      
      // ✅ STEP 3: Email exists in employee table and NOT in Firebase Auth - Call backend API
      // Backend will:
      // - Create Firebase Auth user
      // - Link Firebase Auth user with employee record
      // - Return customToken and employee data
      if (kDebugMode) {
        print('✅ [REGISTER] Email $email found in employee table - calling backend API...');
      }
      
      final response = await _apiService.registerUser(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        // Backend returns: { success: true, employee: {...}, customToken: "...", ... }
        // But api_service wraps it: { success: true, data: { employee: {...}, customToken: "...", ... } }
        final backendResponse = response['data'] ?? response;
        final employeeData = backendResponse['employee'] ?? backendResponse['data'];
        final customToken = backendResponse['customToken'];
        
        // ✅ Sign in with Firebase Auth using the customToken returned by backend
        if (customToken != null) {
          try {
            await firebaseAuth.signInWithCustomToken(customToken);
            if (kDebugMode) {
              print('✅ Signed in with Firebase Auth using customToken');
            }
          } catch (signInError) {
            if (kDebugMode) {
              print('⚠️ Failed to sign in with customToken: $signInError');
            }
            // Continue even if sign-in fails - the backend already created the user
          }
        }
        
        if (employeeData != null) {
          _currentUserId = employeeData['authId'] ?? employeeData['id'] ?? email;
          _currentEmployeeId = employeeData['id'] ?? employeeData['uid'];
          
          // Store employee name and position information
          _currentEmployeeFirstName = employeeData['firstName'] ?? employeeData['first_name'];
          _currentEmployeeLastName = employeeData['lastName'] ?? employeeData['last_name'];
          _currentEmployeeName = '${_currentEmployeeFirstName ?? ''} ${_currentEmployeeLastName ?? ''}'.trim();
          _currentPositionName = employeeData['positionName'] ?? employeeData['position_name'];
        }

        return {
          'success': true,
          'message': backendResponse['message'] ?? response['message'] ?? 'Registration successful',
          'employee': employeeData,
          'token': customToken,
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
