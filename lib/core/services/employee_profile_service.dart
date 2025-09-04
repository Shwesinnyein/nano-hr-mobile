import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../../features/employee/data/employee_model.dart';
import 'auth_service.dart';

class EmployeeProfileService {
  final ApiClient _apiClient;

  EmployeeProfileService(this._apiClient);

  // Get employee profile by UID
  Future<ApiResponse<Employee>> getEmployeeProfileByUid(String uid) async {
    try {
      print('🔄 EmployeeProfileService: Fetching profile for UID: $uid');

      final response = await _apiClient.get(ApiEndpoints.getEmployeeByUid(uid));

      print('🔄 EmployeeProfileService: Backend response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['employee'] != null) {
        final employeeData = responseData['employee'] as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData);

        print(
          '✅ EmployeeProfileService: Profile fetched successfully for: ${employee.fullName}',
        );
        return ApiResponse<Employee>(
          success: true,
          message: responseData['message'] ?? 'Profile retrieved successfully',
          data: employee,
        );
      } else {
        print('❌ EmployeeProfileService: Profile not found for UID: $uid');
        throw Exception(
          responseData['message'] ?? 'Employee profile not found',
        );
      }
    } catch (e) {
      print('❌ EmployeeProfileService: Error fetching profile: $e');
      throw Exception('Failed to fetch employee profile: ${e.toString()}');
    }
  }

  // Get employee profile by ID
  Future<ApiResponse<Employee>> getEmployeeProfileById(String id) async {
    try {
      print('🔄 EmployeeProfileService: Fetching profile for ID: $id');

      final response = await _apiClient.get(ApiEndpoints.getEmployeeById(id));

      print('🔄 EmployeeProfileService: Backend response: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['employee'] != null) {
        final employeeData = responseData['employee'] as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData);

        print(
          '✅ EmployeeProfileService: Profile fetched successfully for: ${employee.fullName}',
        );
        return ApiResponse<Employee>(
          success: true,
          message: responseData['message'] ?? 'Profile retrieved successfully',
          data: employee,
        );
      } else {
        print('❌ EmployeeProfileService: Profile not found for ID: $id');
        throw Exception(
          responseData['message'] ?? 'Employee profile not found',
        );
      }
    } catch (e) {
      print('❌ EmployeeProfileService: Error fetching profile: $e');
      throw Exception('Failed to fetch employee profile: ${e.toString()}');
    }
  }
}

// Provider for EmployeeProfileService
final employeeProfileServiceProvider = Provider<EmployeeProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmployeeProfileService(apiClient);
});

// Provider for employee profile by UID
final employeeProfileByUidProvider = FutureProvider.family<Employee?, String>((
  ref,
  uid,
) async {
  final profileService = ref.watch(employeeProfileServiceProvider);
  try {
    final response = await profileService.getEmployeeProfileByUid(uid);
    return response.data;
  } catch (e) {
    print('❌ Error fetching employee profile: $e');
    return null;
  }
});

// Provider for employee profile by ID
final employeeProfileByIdProvider = FutureProvider.family<Employee?, String>((
  ref,
  id,
) async {
  final profileService = ref.watch(employeeProfileServiceProvider);
  try {
    final response = await profileService.getEmployeeProfileById(id);
    return response.data;
  } catch (e) {
    print('❌ Error fetching employee profile: $e');
    return null;
  }
});
