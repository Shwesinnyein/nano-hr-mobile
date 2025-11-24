import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class EmployeeService {
  final ApiService _apiService;

  EmployeeService(this._apiService);

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

  Future<Map<String, dynamic>> updateEmployeeProfile(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      return {
        'success': false,
        'message': 'Update profile API endpoint not available',
      };
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

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
          final startIndex = (page - 1) * limit;
          final endIndex = startIndex + limit;
          final paginatedMockData = MockDataService.mockEmployeeList
              .skip(startIndex)
              .take(limit)
              .toList();
          return paginatedMockData;
        }
      } else {
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;
        final paginatedMockData = MockDataService.mockEmployeeList
            .skip(startIndex)
            .take(limit)
            .toList();
        return paginatedMockData;
      }
    } catch (e) {
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedMockData = MockDataService.mockEmployeeList
          .skip(startIndex)
          .take(limit)
          .toList();
      return paginatedMockData;
    }
  }

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

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return EmployeeService(apiService);
});
