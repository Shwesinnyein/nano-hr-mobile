import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data_service.dart';

class EmployeeProfileService {
  // Get employee profile
  Future<Map<String, dynamic>> getProfile(String employeeId) async {
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
  Future<Map<String, dynamic>> updateProfile(
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
}

// Provider for EmployeeProfileService
final employeeProfileServiceProvider = Provider<EmployeeProfileService>((ref) {
  return EmployeeProfileService();
});
