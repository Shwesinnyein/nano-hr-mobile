import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../api/network_client.dart';
import '../../features/employee/data/employee_repository.dart';
import 'auth_service.dart';

class EmployeeService {
  final ApiClient _apiClient;

  EmployeeService(this._apiClient);

  // Get all employees
  Future<List<Employee>> getEmployees() async {
    try {
      print('🔄 Calling Vercel API: ${ApiEndpoints.employees}');
      print(
        '🔄 Full URL: https://nano-hr-api.vercel.app${ApiEndpoints.employees}',
      );

      final response = await _apiClient.get(ApiEndpoints.employees);
      print('✅ API Response received: ${response.statusCode}');

      // Handle direct list response
      if (response.data is List) {
        final employees = (response.data as List)
            .map((item) => Employee.fromJson(item))
            .toList();
        print(
          '✅ Got ${employees.length} employees from Vercel API (direct list)',
        );
        return employees;
      }

      // Handle wrapped response
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final responseData = apiResponse.data as Map<String, dynamic>;
        final employees = (responseData['data'] as List)
            .map((item) => Employee.fromJson(item))
            .toList();
        print('✅ Got ${employees.length} employees from Vercel API (wrapped)');
        return employees;
      } else {
        print('❌ API Response failed: ${apiResponse.message}');
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      print('❌ Dio API Error: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Try platform-specific network client as fallback
      try {
        print('🔄 Trying platform-specific network client...');
        final data = await NetworkClient.get(ApiEndpoints.employees);

        if (data['success'] == true && data['data'] != null) {
          final employeesData = data['data'] as List;
          final employees = employeesData
              .map((json) => Employee.fromJson(json))
              .toList();

          print(
            '✅ Got ${employees.length} employees from platform network client',
          );
          return employees;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } catch (networkError) {
        print('❌ Platform Network Error: $networkError');
        print(
          '📝 No employee data available. Please check your API connection.',
        );
        return [];
      }
    }
  }

  // Get employee by ID
  Future<Employee> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getEmployeeById(id));
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Employee.fromJson(apiResponse.data!);
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Employee not found');
    }
  }

  // Search employees
  Future<List<Employee>> searchEmployees(String query) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.employees,
        queryParameters: {'search': query},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as List<dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return (apiResponse.data as List)
            .map((item) => Employee.fromJson(item))
            .toList();
      } else {
        throw Exception(apiResponse.message);
      }
    } catch (e) {
      print('❌ API Error: $e');
      return [];
    }
  }
}

// Provider for EmployeeService
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeService(apiClient);
});
