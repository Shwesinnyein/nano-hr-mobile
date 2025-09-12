import 'mock_data_service.dart';

class LeaveService {
  // Create leave request
  Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await MockDataService.createLeaveRequest(data);
      return response;
    } catch (e) {
      throw Exception('Failed to create leave request: ${e.toString()}');
    }
  }

  // Get leave requests
  Future<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) async {
    try {
      final requests = await MockDataService.getLeaveRequests(employeeId);
      return requests;
    } catch (e) {
      throw Exception('Failed to get leave requests: ${e.toString()}');
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      final response = await MockDataService.uploadFile(filePath);
      return response;
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }
}
