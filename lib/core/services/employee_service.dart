import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data_service.dart';

class EmployeeService {
  // Get employee profile
  Future<Map<String, dynamic>> getEmployeeProfile(String employeeId) async {
    try {
      print('🔄 EmployeeService: Getting profile for employee: $employeeId');
      
      // Return mock employee data
      final employee = MockDataService.mockEmployee;
      
      print('✅ EmployeeService: Profile retrieved successfully');
      return {
        'success': true,
        'message': 'Profile retrieved successfully',
        'data': employee,
      };
    } catch (e) {
      print('❌ EmployeeService: Error getting profile: $e');
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  // Update employee profile
  Future<Map<String, dynamic>> updateEmployeeProfile(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('🔄 EmployeeService: Updating profile for employee: $employeeId');
      
      // Simulate update delay
      await Future.delayed(const Duration(seconds: 1));
      
      print('✅ EmployeeService: Profile updated successfully');
      return {
        'success': true,
        'message': 'Profile updated successfully',
        'data': {...MockDataService.mockEmployee, ...updates},
      };
    } catch (e) {
      print('❌ EmployeeService: Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get all employees
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      print('🔄 EmployeeService: Getting all employees');
      
      // Return mock employee list
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ EmployeeService: Employees retrieved successfully');
      return [MockDataService.mockEmployee];
    } catch (e) {
      print('❌ EmployeeService: Error getting employees: $e');
      throw Exception('Failed to get employees: ${e.toString()}');
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      print('🔄 EmployeeService: Getting employee by ID: $id');
      
      // Return mock employee data
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('✅ EmployeeService: Employee retrieved successfully');
      return {
        'success': true,
        'message': 'Employee retrieved successfully',
        'data': MockDataService.mockEmployee,
      };
    } catch (e) {
      print('❌ EmployeeService: Error getting employee: $e');
      throw Exception('Failed to get employee: ${e.toString()}');
    }
  }

  // Search employees
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      print('🔄 EmployeeService: Searching employees with query: $query');
      
      // Return mock search results
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('✅ EmployeeService: Search completed successfully');
      return [MockDataService.mockEmployee];
    } catch (e) {
      print('❌ EmployeeService: Error searching employees: $e');
      throw Exception('Failed to search employees: ${e.toString()}');
    }
  }
}

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService();
});