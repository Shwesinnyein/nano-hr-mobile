import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data_service.dart';

class EmployeeService {
  // Get employee profile
  Future<Map<String, dynamic>> getEmployeeProfile(String employeeId) async {
    try {
      final employee = MockDataService.mockEmployee;

      return {
        'success': true,
        'message': 'Profile retrieved successfully',
        'data': employee,
      };
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  // Update employee profile
  Future<Map<String, dynamic>> updateEmployeeProfile(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'data': {...MockDataService.mockEmployee, ...updates},
      };
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get all employees
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      return [MockDataService.mockEmployee];
    } catch (e) {
      throw Exception('Failed to get employees: ${e.toString()}');
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      return {
        'success': true,
        'message': 'Employee retrieved successfully',
        'data': MockDataService.mockEmployee,
      };
    } catch (e) {
      throw Exception('Failed to get employee: ${e.toString()}');
    }
  }

  // Search employees
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      return [MockDataService.mockEmployee];
    } catch (e) {
      throw Exception('Failed to search employees: ${e.toString()}');
    }
  }
}

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService();
});
