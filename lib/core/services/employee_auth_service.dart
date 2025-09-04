import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../features/employee/data/employee_model.dart';
import 'auth_service.dart';

class EmployeeAuthService {
  final ApiClient _apiClient;
  Employee? _currentEmployee;

  EmployeeAuthService(this._apiClient);

  // Get current employee
  Employee? get currentEmployee => _currentEmployee;

  // Check if employee is authenticated
  bool get isAuthenticated => _currentEmployee != null;

  // Set current employee (for internal use)
  void setCurrentEmployee(Employee? employee) {
    _currentEmployee = employee;
  }

  // Check if email exists in employees table
  Future<ApiResponse<Employee>> checkEmployeeEmail(String email) async {
    try {
      print('🔄 EmployeeAuthService: Checking email: $email');

      final response = await _apiClient.post(
        '/employee/check-email',
        data: {'email': email},
      );

      print('🔄 EmployeeAuthService: Backend response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['employee'] != null) {
        final employeeData = responseData['employee'] as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData);

        print('✅ EmployeeAuthService: Email found in employees table');
        return ApiResponse<Employee>(
          success: true,
          message: responseData['message'] ?? 'Email found',
          data: employee,
        );
      } else {
        print('❌ EmployeeAuthService: Email not found in employees table');
        throw Exception(
          responseData['message'] ?? 'Email not found in employees table',
        );
      }
    } catch (e) {
      print('❌ EmployeeAuthService: Error checking email: $e');
      throw Exception('Failed to check email: ${e.toString()}');
    }
  }

  // Set password for employee
  Future<ApiResponse<Employee>> setEmployeePassword(
    String email,
    String password,
  ) async {
    try {
      print('🔄 EmployeeAuthService: Setting password for email: $email');

      final response = await _apiClient.post(
        '/employee/register',
        data: {
          'email': email,
          'password': password,
          'confirmPassword': password,
        },
      );

      print('🔄 EmployeeAuthService: Backend response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['employee'] != null) {
        final employeeData = responseData['employee'] as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData);

        print('✅ EmployeeAuthService: Password set successfully');
        return ApiResponse<Employee>(
          success: true,
          message: responseData['message'] ?? 'Password set successfully',
          data: employee,
        );
      } else {
        print(
          '❌ EmployeeAuthService: Failed to set password: ${responseData['message']}',
        );
        throw Exception(responseData['message'] ?? 'Failed to set password');
      }
    } catch (e) {
      print('❌ EmployeeAuthService: Error setting password: $e');
      throw Exception('Failed to set password: ${e.toString()}');
    }
  }

  // Login with email and password from employees table
  Future<ApiResponse<Employee>> loginWithEmployeeCredentials(
    String email,
    String password,
  ) async {
    try {
      print('🔄 EmployeeAuthService: Logging in with email: $email');

      final response = await _apiClient.post(
        '/employee/login',
        data: {'email': email, 'password': password},
      );

      print('🔄 EmployeeAuthService: Backend response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['employee'] != null) {
        final employeeData = responseData['employee'] as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData);

        _currentEmployee = employee;
        print(
          '✅ EmployeeAuthService: Login successful for employee: ${employee.fullName}',
        );

        return ApiResponse<Employee>(
          success: true,
          message: responseData['message'] ?? 'Login successful',
          data: employee,
        );
      } else {
        print(
          '❌ EmployeeAuthService: Login failed: ${responseData['message']}',
        );
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ EmployeeAuthService: Login error: $e');
      throw Exception(e.toString());
    }
  }

  // Complete registration flow: check email + set password + login
  Future<ApiResponse<Employee>> registerAndLogin(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      // Validate passwords match
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      print('🔄 EmployeeAuthService: Starting registration for email: $email');

      // Check if email exists in employee table
      final checkResponse = await checkEmployeeEmail(email);

      if (!checkResponse.success || checkResponse.data == null) {
        throw Exception(
          'Email not found in employee records. Please contact HR to add your email.',
        );
      }

      final employee = checkResponse.data!;

      // Check if employee already has a password set
      // We need to check the backend response for hasPassword field
      final checkResponseData = await _apiClient.post(
        '/employee/check-email',
        data: {'email': email},
      );

      if (checkResponseData.data['employee']['hasPassword']) {
        throw Exception(
          'This email already has a password set. Please use login instead.',
        );
      }

      // Set password for the employee
      final setPasswordResponse = await setEmployeePassword(email, password);

      if (!setPasswordResponse.success || setPasswordResponse.data == null) {
        throw Exception('Failed to set password');
      }

      // Login with the new password
      final loginResponse = await loginWithEmployeeCredentials(email, password);

      if (!loginResponse.success || loginResponse.data == null) {
        throw Exception('Registration successful but login failed');
      }

      _currentEmployee = loginResponse.data;
      print(
        '✅ EmployeeAuthService: Registration and login successful for employee: ${loginResponse.data!.fullName}',
      );

      return loginResponse;
    } catch (e) {
      print('❌ EmployeeAuthService: Registration error: $e');
      throw Exception(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _currentEmployee = null;
      print('✅ EmployeeAuthService: Logout successful');
    } catch (e) {
      print('❌ EmployeeAuthService: Logout error: $e');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
}

// Provider for EmployeeAuthService
final employeeAuthServiceProvider = Provider<EmployeeAuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeAuthService(apiClient);
});

// Provider for current employee
final currentEmployeeProvider = Provider<Employee?>((ref) {
  final authService = ref.watch(employeeAuthServiceProvider);
  return authService.currentEmployee;
});

// Provider for employee authentication state
final employeeAuthStateProvider = Provider<bool>((ref) {
  final authService = ref.watch(employeeAuthServiceProvider);
  return authService.isAuthenticated;
});
