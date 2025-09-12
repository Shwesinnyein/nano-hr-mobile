import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class EmployeeService {
  final ApiService _apiService;

  EmployeeService(this._apiService);

  // Get employee profile
  Future<Map<String, dynamic>> getEmployeeProfile(String employeeId) async {
    try {
      final response = await _apiService.getEmployeeProfile(
        employeeId: employeeId,
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Profile retrieved successfully',
          'data': response['data'],
        };
      } else {
        return response;
      }
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
  Future<List<Map<String, dynamic>>> getEmployees({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    try {
      final response = await _apiService.getEmployeeList(
        page: page,
        limit: limit,
        search: search,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data.containsKey('employees')) {
          return List<Map<String, dynamic>>.from(data['employees']);
        } else if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          // Fallback to mock data if API structure is unexpected
          return [MockDataService.mockEmployee];
        }
      } else {
        // Fallback to mock data on API error
        return [MockDataService.mockEmployee];
      }
    } catch (e) {
      // Fallback to mock data on exception
      return [MockDataService.mockEmployee];
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
  final apiService = ref.read(apiServiceProvider);
  return EmployeeService(apiService);
});
