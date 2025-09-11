import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data_service.dart';

class EmployeeProfileService {
  // Get employee profile
  Future<Map<String, dynamic>> getProfile(String employeeId) async {
    try {
      print(
        '🔄 EmployeeProfileService: Getting profile for employee: $employeeId',
      );

      // Return mock employee data
      final employee = MockDataService.mockEmployee;

      print('✅ EmployeeProfileService: Profile retrieved successfully');
      return {
        'success': true,
        'message': 'Profile retrieved successfully',
        'data': employee,
      };
    } catch (e) {
      print('❌ EmployeeProfileService: Error getting profile: $e');
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  // Update employee profile
  Future<Map<String, dynamic>> updateProfile(
    String employeeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print(
        '🔄 EmployeeProfileService: Updating profile for employee: $employeeId',
      );

      // Simulate update delay
      await Future.delayed(const Duration(seconds: 1));

      print('✅ EmployeeProfileService: Profile updated successfully');
      return {
        'success': true,
        'message': 'Profile updated successfully',
        'data': {...MockDataService.mockEmployee, ...updates},
      };
    } catch (e) {
      print('❌ EmployeeProfileService: Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}

// Provider for EmployeeProfileService
final employeeProfileServiceProvider = Provider<EmployeeProfileService>((ref) {
  return EmployeeProfileService();
});
