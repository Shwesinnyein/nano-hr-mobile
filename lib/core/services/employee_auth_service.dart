import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/employee/data/employee_model.dart';
import 'mock_data_service.dart';

class EmployeeAuthService {
  Employee? _currentEmployee;

  EmployeeAuthService();

  // Get current employee
  Employee? get currentEmployee => _currentEmployee;

  // Check if employee is authenticated
  bool get isAuthenticated => _currentEmployee != null;

  // Set current employee (for internal use)
  void setCurrentEmployee(Employee? employee) {
    _currentEmployee = employee;
  }

  // Check if email exists in employees table
  Future<Map<String, dynamic>> checkEmployeeEmail(String email) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final employee = Employee.fromJson(MockDataService.mockEmployee);

      return {'success': true, 'message': 'Email found', 'data': employee};
    } catch (e) {
      throw Exception('Failed to check email: ${e.toString()}');
    }
  }

  // Set password for employee
  Future<Map<String, dynamic>> setEmployeePassword(
    String email,
    String password,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Password set successfully',
        'data': null,
      };
    } catch (e) {
      throw Exception('Failed to set password: ${e.toString()}');
    }
  }

  // Login with email and password from employees table
  Future<Map<String, dynamic>> loginWithEmployeeCredentials(
    String email,
    String password,
  ) async {
    try {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      final employee = Employee.fromJson(MockDataService.mockEmployee);
      _currentEmployee = employee;

      return {'success': true, 'message': 'Login successful', 'data': employee};
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Complete registration flow: check email + set password + login
  Future<Map<String, dynamic>> registerAndLogin(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      // Validate passwords match
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final checkResponse = await checkEmployeeEmail(email);

      if (!checkResponse['success'] || checkResponse['data'] == null) {
        throw Exception(
          'Email not found in employee records. Please contact HR to add your email.',
        );
      }

      final employee = checkResponse['data'] as Employee;

      // Set password for the employee
      final setPasswordResponse = await setEmployeePassword(email, password);

      if (!setPasswordResponse['success']) {
        throw Exception('Failed to set password');
      }

      // Login with the new password
      final loginResponse = await loginWithEmployeeCredentials(email, password);

      if (!loginResponse['success'] || loginResponse['data'] == null) {
        throw Exception('Registration successful but login failed');
      }

      _currentEmployee = loginResponse['data'] as Employee;

      return loginResponse;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _currentEmployee = null;
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
}

// Provider for EmployeeAuthService
final employeeAuthServiceProvider = Provider<EmployeeAuthService>((ref) {
  return EmployeeAuthService();
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
