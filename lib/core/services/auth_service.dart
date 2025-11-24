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

  String? get currentUserId => _currentUserId;
  String? get currentEmployeeId => _currentEmployeeId;
  String? get currentEmployeeName => _currentEmployeeName;
  String? get currentEmployeeFirstName => _currentEmployeeFirstName;
  String? get currentEmployeeLastName => _currentEmployeeLastName;
  String? get currentPositionName => _currentPositionName;

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  void setCurrentEmployeeId(String? employeeId) {
    _currentEmployeeId = employeeId;
  }

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

 
  bool get isAuthenticated =>
      _currentUserId != null && _currentEmployeeId != null;

 
  Stream<String?> get authStateChanges => Stream.value(_currentUserId);

  
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


  Future<Map<String, dynamic>> signInWithEmailAndPasswordMobile(
    String email,
    String password,
  ) async {
    try {
      final firebaseAuth = FirebaseAuth.instance;
      
     
      try {
        final userCredential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        

        if (userCredential.user != null) {
         
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
              final errorMessage = response['message'] ?? 'Failed to get employee data from server';
              throw Exception('$errorMessage. Please check if your email exists in the employee system or contact HR.');
            }
          } catch (e) {
            if (e is Exception) {
              throw Exception('Unable to connect to server: ${e.toString()}');
            }
            throw Exception('Backend error: ${e.toString()}');
          }
        }
      } on FirebaseAuthException catch (e) {
       
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          
          try {
            final signInMethods = await firebaseAuth.fetchSignInMethodsForEmail(email);
            
            if (signInMethods.isNotEmpty) {
              throw Exception('PASSWORD_INCORRECT');
            } else {
              final emailCheckResult = await checkEmailExists(email);
              if (emailCheckResult['success'] == true && emailCheckResult['exists'] == true) {
                throw Exception('EMAIL_EXISTS_IN_EMPLOYEE_TABLE');
              } else {
                throw Exception('EMAIL_NOT_FOUND_IN_SYSTEM');
              }
            }
          } catch (checkError) {
            
            if (checkError.toString().contains('PASSWORD_INCORRECT') ||
                checkError.toString().contains('EMAIL_EXISTS_IN_EMPLOYEE_TABLE') ||
                checkError.toString().contains('EMAIL_NOT_FOUND_IN_SYSTEM')) {
              rethrow;
            }
            
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
        
        final errorMessage = e.message ?? e.code;
        if (errorMessage.contains('malformed') || errorMessage.contains('expired')) {
          throw Exception('Invalid email or password. Please check your credentials and try again.');
        }
        throw Exception('Authentication failed: $errorMessage');
      }
      
      throw Exception('Login failed');
    } catch (e) {
     
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await _apiService.checkEmailExists(email: email);
      return response;
    } catch (e) {
      throw Exception('Email check failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final firebaseAuth = FirebaseAuth.instance;
      
      final emailCheckResult = await checkEmailExists(email);
      if (emailCheckResult['success'] == false) {
        throw Exception('Failed to verify email. Please try again.');
      }
      
      if (emailCheckResult['exists'] == false || emailCheckResult['exists'] == null) {
        throw Exception('EMAIL_NOT_FOUND_IN_EMPLOYEE_TABLE');
      }
     
      try {
        final signInMethods = await firebaseAuth.fetchSignInMethodsForEmail(email);
        
        if (signInMethods.isNotEmpty) {
          throw Exception('EMAIL_ALREADY_IN_FIREBASE_AUTH');
        }
      } catch (e) {
        if (e.toString().contains('EMAIL_ALREADY_IN_FIREBASE_AUTH')) {
          rethrow;
        }
      }
      
      final response = await _apiService.registerUser(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
       
        final backendResponse = response['data'] ?? response;
        final employeeData = backendResponse['employee'] ?? backendResponse['data'];
        final customToken = backendResponse['customToken'];
        
       
        if (customToken != null) {
          try {
            await firebaseAuth.signInWithCustomToken(customToken);
          } catch (signInError) {
            
          }
        }
        
        if (employeeData != null) {
          _currentUserId = employeeData['authId'] ?? employeeData['id'] ?? email;
          _currentEmployeeId = employeeData['id'] ?? employeeData['uid'];
          
         
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
        
        return response;
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  
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

  Future<void> restoreAuthState() async {
    try {
      // Auth state restoration
    } catch (e) {
      // Failed to restore auth state handled silently
    }
  }

  Future<void> signOut() async {
    try {
      _currentUserId = null;
      _currentEmployeeId = null;
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

final authStateProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});
