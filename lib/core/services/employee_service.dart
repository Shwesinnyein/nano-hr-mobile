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
      // Since updateEmployeeProfile API doesn't exist, return error
      return {
        'success': false,
        'message': 'Update profile API endpoint not available',
      };
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Get all employees
  Future<List<Map<String, dynamic>>> getEmployees({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.getEmployeeList(
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        final data = response['data'];

        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        } else {
          // API returns empty list - use mock data as fallback
          print('📋 Employee API returned empty list, using mock data');
          return MockDataService.mockEmployeeList;
        }
      } else {
        // API error - use mock data as fallback
        print('📋 Employee API error, using mock data: ${response['message']}');
        return MockDataService.mockEmployeeList;
      }
    } catch (e) {
      // Exception - use mock data as fallback
      print('📋 Employee API exception, using mock data: $e');
      return MockDataService.mockEmployeeList;
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      final response = await _apiService.getEmployeeProfile(employeeId: id);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Employee retrieved successfully',
          'data': response['data'],
        };
      } else {
        return response;
      }
    } catch (e) {
      throw Exception('Failed to get employee: ${e.toString()}');
    }
  }
}

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return EmployeeService(apiService);
});
