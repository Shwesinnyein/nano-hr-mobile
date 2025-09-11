import 'mock_data_service.dart';

class LeaveService {
  // Create leave request
  Future<Map<String, dynamic>> createLeaveRequest(Map<String, dynamic> data) async {
    try {
      print('🔄 LeaveService: Creating leave request for employee: ${data['employeeId']}');
      
      final response = await MockDataService.createLeaveRequest(data);
      
      print('✅ LeaveService: Leave request created successfully');
      return response;
    } catch (e) {
      print('❌ LeaveService: Failed to create leave request: $e');
      throw Exception('Failed to create leave request: ${e.toString()}');
    }
  }

  // Get leave requests
  Future<List<Map<String, dynamic>>> getLeaveRequests(String employeeId) async {
    try {
      print('🔄 LeaveService: Getting leave requests for employee: $employeeId');
      
      final requests = await MockDataService.getLeaveRequests(employeeId);
      
      print('✅ LeaveService: Leave requests retrieved: ${requests.length} records');
      return requests;
    } catch (e) {
      print('❌ LeaveService: Failed to get leave requests: $e');
      throw Exception('Failed to get leave requests: ${e.toString()}');
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      print('🔄 LeaveService: Uploading file: $filePath');
      
      final response = await MockDataService.uploadFile(filePath);
      
      print('✅ LeaveService: File uploaded successfully');
      return response;
    } catch (e) {
      print('❌ LeaveService: Failed to upload file: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }
}